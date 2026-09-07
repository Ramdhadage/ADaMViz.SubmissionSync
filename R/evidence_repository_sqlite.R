.evidence_migrations_path <- function() {
  path <- system.file(
    "sql", "migrations",
    package = "ADaMViz.SubmissionSync"
  )
  if (!nzchar(path)) path <- fs::path("inst", "sql", "migrations")
  path
}

.read_sql_statements <- function(path) {
  sql <- paste(readLines(path, warn = FALSE), collapse = "\n")
  trimws(strsplit(sql, ";", fixed = TRUE)[[1]])
}

.sqlite_connect <- function(path) {
  con <- DBI::dbConnect(RSQLite::SQLite(), path)
  DBI::dbExecute(con, "PRAGMA foreign_keys = ON")
  DBI::dbExecute(con, "PRAGMA busy_timeout = 5000")
  con
}

.initialize_evidence_database <- function(path) {
  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  con <- .sqlite_connect(path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  DBI::dbExecute(con, paste(
    "CREATE TABLE IF NOT EXISTS schema_migrations(",
    "version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL)"
  ))
  migrations <- fs::dir_ls(
    .evidence_migrations_path(),
    regexp = "[0-9]+-.*[.]sql$",
    type = "file"
  )
  versions <- as.integer(sub("-.*$", "", fs::path_file(migrations)))
  if (!length(migrations) || anyNA(versions) || anyDuplicated(versions)) {
    cli::cli_abort("Evidence migrations must have unique numeric versions")
  }
  migrations <- migrations[order(versions)]
  versions <- sort(versions)
  applied <- DBI::dbGetQuery(
    con,
    "SELECT version FROM schema_migrations"
  )$version

  for (index in seq_along(migrations)) {
    if (versions[[index]] %in% applied) next
    DBI::dbWithTransaction(con, {
      statements <- .read_sql_statements(migrations[[index]])
      for (statement in statements[nzchar(statements)]) {
        DBI::dbExecute(con, statement)
      }
      DBI::dbExecute(
        con,
        paste(
          "INSERT INTO schema_migrations(version, applied_at)",
          "VALUES (?, ?)"
        ),
        params = list(versions[[index]], .utc_timestamp())
      )
    })
  }
}

.with_evidence_connection <- function(path, code) {
  con <- .sqlite_connect(path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  code(con)
}

.with_repository_lock <- function(database_path, code) {
  lock_path <- paste0(database_path, ".lock")
  fs::dir_create(fs::path_dir(lock_path), recurse = TRUE)
  con <- .sqlite_connect(lock_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  DBI::dbExecute(
    con,
    "CREATE TABLE IF NOT EXISTS repository_lock(id INTEGER PRIMARY KEY CHECK(id = 1))"
  )
  DBI::dbExecute(con, "INSERT OR IGNORE INTO repository_lock(id) VALUES (1)")
  DBI::dbExecute(con, "BEGIN IMMEDIATE")
  completed <- FALSE
  on.exit({
    if (!completed) try(DBI::dbExecute(con, "ROLLBACK"), silent = TRUE)
  }, add = TRUE)
  result <- code()
  DBI::dbExecute(con, "COMMIT")
  completed <- TRUE
  result
}

.register_command <- function(con, key, command) {
  .validate_identifier(key, "idempotency_key")
  command_hash <- canonical_hash(command)
  prior <- DBI::dbGetQuery(con, "SELECT command_hash FROM command_keys WHERE idempotency_key = ?", params = list(key))
  if (nrow(prior)) {
    if (!identical(prior$command_hash[[1]], command_hash)) {
      cli::cli_abort("Idempotency key was already used for a different command")
    }
    return(FALSE)
  }
  DBI::dbExecute(
    con, "INSERT INTO command_keys(idempotency_key, command_hash, created_at) VALUES (?, ?, ?)",
    params = list(key, command_hash, .utc_timestamp())
  )
  TRUE
}

.current_revision <- function(con, revision_id) {
  result <- DBI::dbGetQuery(con, paste(
    "SELECT r.*, p.status, p.version FROM revisions r",
    "JOIN revision_projection p USING(revision_id) WHERE r.revision_id = ?"
  ), params = list(revision_id))
  if (!nrow(result)) cli::cli_abort("Plot revision {.val {revision_id}} was not found")
  as.list(result[1, , drop = FALSE]) |>
    lapply(\(x) x[[1]])
}

.append_lifecycle_event <- function(con, revision, event_type, payload, idempotency_key) {
  last <- DBI::dbGetQuery(
    con,
    "SELECT event_sequence, chain_hash FROM lifecycle_events WHERE plot_id = ? ORDER BY event_sequence DESC LIMIT 1",
    params = list(revision$plot_id)
  )
  sequence <- if (nrow(last)) last$event_sequence[[1]] + 1L else 1L
  previous <- if (nrow(last)) last$chain_hash[[1]] else paste(rep("0", 64L), collapse = "")
  created_at <- .utc_timestamp()
  payload_json <- canonical_serialize(payload)
  chain_hash <- canonical_hash(list(
    plot_id = revision$plot_id, revision_id = revision$revision_id,
    event_sequence = sequence, event_type = event_type, payload_json = payload_json,
    previous_hash = previous, created_at = created_at
  ))
  event_id <- paste0("evt-", substr(canonical_hash(idempotency_key), 1L, 24L))
  DBI::dbExecute(con, paste(
    "INSERT INTO lifecycle_events(event_id, plot_id, revision_id, event_sequence, event_type,",
    "payload_json, previous_hash, chain_hash, created_at, idempotency_key)",
    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
  ), params = list(event_id, revision$plot_id, revision$revision_id, sequence, event_type,
    payload_json, previous, chain_hash, created_at, idempotency_key))
  list(plot_id = revision$plot_id, sequence = sequence, chain_hash = chain_hash)
}

.read_chain_roots <- function(path) {
  if (!fs::file_exists(path)) return(list())
  jsonlite::fromJSON(path, simplifyVector = TRUE)
}

.write_chain_root <- function(path, root) {
  roots <- .read_chain_roots(path)
  prior <- roots[[root$plot_id]]
  if (!is.null(prior) && prior$sequence > root$sequence) {
    cli::cli_abort("External chain root is newer than the database history")
  }
  if (!is.null(prior) && prior$sequence == root$sequence &&
      !identical(prior$chain_hash, root$chain_hash)) {
    cli::cli_abort("External chain root conflicts with the database history")
  }
  if (!is.null(prior) && prior$sequence == root$sequence) return(invisible(path))
  roots[[root$plot_id]] <- list(sequence = root$sequence, chain_hash = root$chain_hash)
  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  temporary <- fs::file_temp(tmp_dir = fs::path_dir(path), pattern = "chain-root-")
  writeLines(canonical_serialize(roots), temporary, useBytes = TRUE)
  fs::file_move(temporary, path)
}

.chain_tip <- function(con, plot_id) {
  tip <- DBI::dbGetQuery(con, "SELECT event_sequence, chain_hash FROM lifecycle_events WHERE plot_id = ? ORDER BY event_sequence DESC LIMIT 1", params = list(plot_id))
  if (!nrow(tip)) return(NULL)
  list(plot_id = plot_id, sequence = tip$event_sequence[[1]], chain_hash = tip$chain_hash[[1]])
}

.reconcile_chain_roots <- function(database_path, chain_root_path) {
  tips <- .with_evidence_connection(database_path, function(con) {
    DBI::dbGetQuery(con, paste(
      "SELECT e.plot_id, e.event_sequence AS sequence, e.chain_hash",
      "FROM lifecycle_events e",
      "JOIN (SELECT plot_id, MAX(event_sequence) AS sequence",
      "FROM lifecycle_events GROUP BY plot_id) latest",
      "ON e.plot_id = latest.plot_id AND e.event_sequence = latest.sequence"
    ))
  })
  if (nrow(tips)) {
    for (index in seq_len(nrow(tips))) {
      .write_chain_root(chain_root_path, as.list(tips[index, ]))
    }
  }
  invisible(chain_root_path)
}

.chain_roots_match <- function(database_path, chain_root_path) {
  tips <- .with_evidence_connection(database_path, function(con) {
    DBI::dbGetQuery(con, paste(
      "SELECT e.plot_id, e.event_sequence AS sequence, e.chain_hash",
      "FROM lifecycle_events e",
      "JOIN (SELECT plot_id, MAX(event_sequence) AS sequence",
      "FROM lifecycle_events GROUP BY plot_id) latest",
      "ON e.plot_id = latest.plot_id AND e.event_sequence = latest.sequence"
    ))
  })
  roots <- .read_chain_roots(chain_root_path)
  root_plot_ids <- names(roots) %||% character()
  if (!identical(sort(root_plot_ids), sort(tips$plot_id))) return(FALSE)
  for (index in seq_len(nrow(tips))) {
    root <- roots[[tips$plot_id[[index]]]]
    if (!identical(as.integer(root$sequence), as.integer(tips$sequence[[index]])) ||
        !identical(root$chain_hash, tips$chain_hash[[index]])) {
      return(FALSE)
    }
  }
  TRUE
}

.review_decision_hash <- function(record) {
  canonical_hash(record[c(
    "decision_id", "revision_id", "actor_id", "role", "decision",
    "authorization_json", "comment", "code_hash", "image_hash",
    "analytical_hash", "created_at", "idempotency_key"
  )])
}

.database_table_counts <- function(path) {
  .with_evidence_connection(path, function(con) {
    tables <- DBI::dbListTables(con)
    stats::setNames(
      lapply(tables, function(table) {
        DBI::dbGetQuery(
          con,
          paste0("SELECT COUNT(*) AS n FROM ", DBI::dbQuoteIdentifier(con, table))
        )$n[[1]]
      }),
      tables
    )
  })
}

.verify_backup_manifest <- function(backup_path) {
  manifest_path <- fs::path(backup_path, "backup-manifest.json")
  if (!fs::file_exists(manifest_path)) {
    cli::cli_abort("Backup completion manifest is missing")
  }
  manifest <- jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)
  database_path <- fs::path(backup_path, "evidence.sqlite")
  chain_root_path <- fs::path(backup_path, "chain-root.json")
  if (!fs::file_exists(database_path) || !fs::file_exists(chain_root_path)) {
    cli::cli_abort("Backup is incomplete")
  }
  database_hash <- digest::digest(file = database_path, algo = "sha256")
  chain_root_hash <- digest::digest(file = chain_root_path, algo = "sha256")
  if (!identical(database_hash, manifest$database_hash) ||
      !identical(chain_root_hash, manifest$chain_root_hash)) {
    cli::cli_abort("Backup file hashes do not match the completion manifest")
  }
  counts <- .database_table_counts(database_path)
  expected_counts <- unlist(manifest$table_counts, use.names = TRUE)
  actual_counts <- unlist(counts[names(expected_counts)], use.names = TRUE)
  if (!identical(as.numeric(actual_counts), as.numeric(expected_counts)) ||
      !identical(names(actual_counts), names(expected_counts))) {
    cli::cli_abort("Backup row counts do not match the completion manifest")
  }
  invisible(manifest)
}

.project_revision_history <- function(revisions, events) {
  if (!nrow(revisions)) {
    return(data.frame(
      revision_id = character(),
      status = character(),
      version = integer(),
      updated_at = character()
    ))
  }
  events_by_revision <- split(events, events$revision_id)
  projections <- lapply(seq_len(nrow(revisions)), \(index) {
    revision_id <- revisions$revision_id[[index]]
    revision_events <- events_by_revision[[revision_id]]
    if (is.null(revision_events) || !nrow(revision_events)) {
      cli::cli_abort(
        "Revision {.val {revision_id}} has no lifecycle history"
      )
    }
    status <- revisions$initial_status[[index]]
    for (payload_json in revision_events$payload_json) {
      payload <- jsonlite::fromJSON(payload_json, simplifyVector = TRUE)
      if (!is.null(payload$status)) status <- payload$status
      if (!is.null(payload$to)) status <- payload$to
    }
    data.frame(
      revision_id = revision_id,
      status = status,
      version = as.integer(nrow(revision_events)),
      updated_at = tail(revision_events$created_at, 1L)
    )
  })
  result <- do.call(rbind, projections)
  rownames(result) <- NULL
  result
}

sqlite_evidence_repository <- function(database_path, chain_root_path, artifact_store = NULL) {
  checkmate::assert_string(database_path, min.chars = 1)
  checkmate::assert_string(chain_root_path, min.chars = 1)
  .initialize_evidence_database(database_path)

  transact <- function(idempotency_key, command, code) {
    .with_repository_lock(database_path, function() {
      if (!.chain_roots_match(database_path, chain_root_path)) {
        prior <- .with_evidence_connection(database_path, function(con) {
          DBI::dbGetQuery(
            con,
            "SELECT command_hash FROM command_keys WHERE idempotency_key = ?",
            params = list(idempotency_key)
          )
        })
        is_exact_replay <- nrow(prior) == 1L && identical(
          prior$command_hash[[1]],
          canonical_hash(command)
        )
        if (!is_exact_replay) {
          cli::cli_abort(
            "External chain root must be reconciled before a new command"
          )
        }
        .reconcile_chain_roots(database_path, chain_root_path)
        if (!.chain_roots_match(database_path, chain_root_path)) {
          cli::cli_abort("External chain root cannot be reconciled safely")
        }
      }
      root <- .with_evidence_connection(database_path, function(con) {
        DBI::dbWithTransaction(con, code(con))
      })
      if (is.list(root) && all(c("plot_id", "sequence", "chain_hash") %in% names(root))) {
        .write_chain_root(chain_root_path, root)
      }
      invisible(root)
    })
  }

  write_transaction <- function(code) {
    .with_repository_lock(database_path, function() {
      .with_evidence_connection(database_path, function(con) {
        DBI::dbWithTransaction(con, code(con))
      })
    })
  }

  create_revision <- function(plot_id, revision_id, revision_number, creator_id,
                              spec_hash, code_hash, image_hash, analytical_hash,
                              idempotency_key, initial_status = "Draft",
                              parent_revision_id = NULL, correction_rationale = NULL,
                              correction_provenance = NULL) {
    lapply(list(plot_id = plot_id, revision_id = revision_id, creator_id = creator_id),
      \(x) .validate_identifier(x, "identifier"))
    checkmate::assert_int(revision_number, lower = 1L)
    if (!initial_status %in% c("Draft", "Experimental/Draft")) cli::cli_abort("Invalid initial revision status")
    if (!is.null(artifact_store)) {
      artifact_store$verify(code_hash)
      artifact_store$verify(image_hash)
    }
    command <- list(
      plot_id = plot_id,
      revision_id = revision_id,
      revision_number = revision_number,
      creator_id = creator_id,
      spec_hash = spec_hash,
      code_hash = code_hash,
      image_hash = image_hash,
      analytical_hash = analytical_hash,
      initial_status = initial_status,
      parent_revision_id = parent_revision_id,
      correction_rationale = correction_rationale,
      correction_provenance = correction_provenance
    )
    transact(idempotency_key, command, function(con) {
      if (!.register_command(con, idempotency_key, command)) {
        existing <- .current_revision(con, revision_id)
        return(.chain_tip(con, existing$plot_id))
      }
      if (!is.null(parent_revision_id)) {
        parent <- .current_revision(con, parent_revision_id)
        if (!identical(parent$plot_id, plot_id)) {
          cli::cli_abort("A correction successor must belong to its parent plot")
        }
        if (!parent$status %in% c("Rejected", "Reviewed")) {
          cli::cli_abort("Only a closed revision can have a correction successor")
        }
        if (!checkmate::test_string(correction_rationale, min.chars = 1) ||
            !checkmate::test_string(correction_provenance, min.chars = 1)) {
          cli::cli_abort(
            "A correction successor requires rationale and provenance"
          )
        }
      } else if (!is.null(correction_rationale) ||
                 !is.null(correction_provenance)) {
        cli::cli_abort(
          "Correction rationale and provenance require a parent revision"
        )
      }
      DBI::dbExecute(con, "INSERT OR IGNORE INTO plots(plot_id, created_at) VALUES (?, ?)", params = list(plot_id, .utc_timestamp()))
      created_at <- .utc_timestamp()
      nullable <- \(x) if (is.null(x)) NA_character_ else x
      DBI::dbExecute(con, paste(
        "INSERT INTO revisions(revision_id, plot_id, revision_number, creator_id, parent_revision_id,",
        "correction_rationale, correction_provenance, spec_hash, code_hash, image_hash, analytical_hash, initial_status, created_at)",
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
      ), params = list(revision_id, plot_id, revision_number, creator_id, nullable(parent_revision_id),
        nullable(correction_rationale), nullable(correction_provenance), spec_hash, code_hash, image_hash,
        analytical_hash, initial_status, created_at))
      DBI::dbExecute(con, "INSERT INTO revision_projection(revision_id, status, version, updated_at) VALUES (?, ?, 1, ?)",
        params = list(revision_id, initial_status, created_at))
      revision <- list(plot_id = plot_id, revision_id = revision_id)
      .append_lifecycle_event(con, revision, "revision_created", list(status = initial_status), idempotency_key)
    })
  }

  list_revisions <- function(plot_id) .with_evidence_connection(database_path, \(con) DBI::dbGetQuery(
    con, "SELECT * FROM revisions WHERE plot_id = ? ORDER BY revision_number", params = list(plot_id)
  ))
  list_events <- function(plot_id) .with_evidence_connection(database_path, \(con) DBI::dbGetQuery(
    con, "SELECT * FROM lifecycle_events WHERE plot_id = ? ORDER BY event_sequence", params = list(plot_id)
  ))
  get_revision <- function(revision_id) .with_evidence_connection(database_path, \(con) .current_revision(con, revision_id))

  record_attempt <- function(attempt_id, revision_id, run_id) {
    write_transaction(function(con) {
      .current_revision(con, revision_id)
      prior <- DBI::dbGetQuery(con, "SELECT revision_id, run_id FROM attempts WHERE attempt_id = ?", params = list(attempt_id))
      if (nrow(prior)) {
        if (!identical(prior$revision_id[[1]], revision_id) || !identical(prior$run_id[[1]], run_id)) {
          cli::cli_abort("Attempt identifier was already used for a different command")
        }
        return(invisible(NULL))
      }
      DBI::dbExecute(con, "INSERT INTO attempts(attempt_id, revision_id, run_id, created_at) VALUES (?, ?, ?, ?)",
        params = list(attempt_id, revision_id, run_id, .utc_timestamp()))
    })
    invisible(attempt_id)
  }
  list_attempts <- function(revision_id) .with_evidence_connection(database_path, \(con) DBI::dbGetQuery(
    con, paste(
      "SELECT a.*, o.outcome, o.created_at AS completed_at FROM attempts a",
      "LEFT JOIN attempt_outcomes o USING(attempt_id) WHERE a.revision_id = ? ORDER BY a.created_at, a.attempt_id"
    ), params = list(revision_id)
  ))
  complete_attempt <- function(attempt_id, outcome, idempotency_key) {
    if (!outcome %in% c("succeeded", "failed", "cancelled", "timed_out")) cli::cli_abort("Invalid terminal attempt outcome")
    write_transaction(function(con) {
      command <- list(attempt_id = attempt_id, outcome = outcome)
      if (!.register_command(con, idempotency_key, command)) return(invisible(NULL))
      prior <- DBI::dbGetQuery(con, "SELECT 1 FROM attempt_outcomes WHERE attempt_id = ?", params = list(attempt_id))
      if (nrow(prior)) cli::cli_abort("An attempt can have only one terminal outcome")
      if (!nrow(DBI::dbGetQuery(con, "SELECT 1 FROM attempts WHERE attempt_id = ?", params = list(attempt_id)))) cli::cli_abort("Execution attempt was not found")
      DBI::dbExecute(con, "INSERT INTO attempt_outcomes VALUES (?, ?, ?, ?)", params = list(attempt_id, outcome, .utc_timestamp(), idempotency_key))
    })
    invisible(attempt_id)
  }
  record_evidence <- function(evidence_id, revision_id, evidence_type, outcome, idempotency_key, details = list()) {
    if (!checkmate::test_list(details, names = "unique")) {
      cli::cli_abort("Evidence details must be a named list")
    }
    write_transaction(function(con) {
      command <- list(evidence_id = evidence_id, revision_id = revision_id, evidence_type = evidence_type, outcome = outcome, details = details)
      if (!.register_command(con, idempotency_key, command)) return(invisible(NULL))
      .current_revision(con, revision_id)
      details_json <- canonical_serialize(details)
      DBI::dbExecute(con, "INSERT INTO evidence_entries VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        params = list(evidence_id, revision_id, evidence_type, outcome, details_json,
          canonical_hash(details), .utc_timestamp(), idempotency_key))
    })
    invisible(evidence_id)
  }
  list_evidence <- function(revision_id) .with_evidence_connection(database_path, \(con) DBI::dbGetQuery(
    con, "SELECT * FROM evidence_entries WHERE revision_id = ? ORDER BY created_at, evidence_id", params = list(revision_id)
  ))
  accept_artifact_bundle <- function(bundle_id, revision_id, code_hash, image_hash, analytical_hash, idempotency_key) {
    write_transaction(function(con) {
      command <- list(bundle_id = bundle_id, revision_id = revision_id, code_hash = code_hash, image_hash = image_hash, analytical_hash = analytical_hash)
      if (!.register_command(con, idempotency_key, command)) return(invisible(NULL))
      revision <- .current_revision(con, revision_id)
      expected_hashes <- unlist(
        revision[c("code_hash", "image_hash", "analytical_hash")]
      )
      supplied_hashes <- c(
        code_hash = code_hash,
        image_hash = image_hash,
        analytical_hash = analytical_hash
      )
      if (!identical(supplied_hashes, expected_hashes)) {
        cli::cli_abort(
          "Artifact bundle hashes do not match the immutable revision"
        )
      }
      if (!is.null(artifact_store)) {
        artifact_store$verify(code_hash)
        artifact_store$verify(image_hash)
      }
      prior <- DBI::dbGetQuery(con, "SELECT 1 FROM artifact_bundles WHERE revision_id = ?", params = list(revision_id))
      if (nrow(prior)) cli::cli_abort("A revision can have only one accepted artifact bundle")
      DBI::dbExecute(con, "INSERT INTO artifact_bundles VALUES (?, ?, ?, ?, ?, ?, ?)",
        params = list(bundle_id, revision_id, code_hash, image_hash, analytical_hash, .utc_timestamp(), idempotency_key))
    })
    invisible(bundle_id)
  }

  mark_verified <- function(revision_id, expected_version, idempotency_key) {
    command <- list(
      revision_id = revision_id,
      expected_version = expected_version,
      action = "mark_verified"
    )
    transact(idempotency_key, command, function(con) {
      if (!.register_command(con, idempotency_key, command)) {
        existing <- .current_revision(con, revision_id)
        return(.chain_tip(con, existing$plot_id))
      }
      revision <- .current_revision(con, revision_id)
      if (!identical(as.integer(revision$version), as.integer(expected_version))) cli::cli_abort("The revision token is stale")
      if (!identical(revision$status, "Draft")) {
        cli::cli_abort(
          "Only a Draft revision can become Verified"
        )
      }
      DBI::dbExecute(con, "UPDATE revision_projection SET status = ?, version = version + 1, updated_at = ? WHERE revision_id = ?",
        params = list("Verified", .utc_timestamp(), revision_id))
      .append_lifecycle_event(
        con,
        revision,
        "revision_verified",
        list(from = "Draft", to = "Verified"),
        idempotency_key
      )
    })
  }

  record_review_decision <- function(
    revision_id,
    actor,
    decision,
    expected_version,
    idempotency_key,
    hashes,
    comment = NULL,
    role = NULL
  ) {
    command <- list(
      revision_id = revision_id,
      actor = actor,
      decision = decision,
      expected_version = expected_version,
      hashes = hashes,
      comment = comment,
      role = role
    )
    transact(idempotency_key, command, function(con) {
      if (!.register_command(con, idempotency_key, command)) {
        existing <- .current_revision(con, revision_id)
        return(.chain_tip(con, existing$plot_id))
      }
      revision <- .current_revision(con, revision_id)
      if (revision$status == "Reviewed") cli::cli_abort("Reviewed revisions are immutable")
      if (!identical(as.integer(revision$version), as.integer(expected_version))) cli::cli_abort("The revision token is stale")
      if (!revision$status %in% c("Verified")) cli::cli_abort("Only a Verified revision can be reviewed")
      expected_hashes <- unlist(revision[c("code_hash", "image_hash", "analytical_hash")])
      if (!identical(unlist(hashes[names(expected_hashes)]), expected_hashes)) cli::cli_abort("Review hashes do not match the immutable revision hashes")
      if (identical(actor$id, revision$creator_id)) cli::cli_abort("A revision creator cannot review their own revision")
      if (!isTRUE(actor$active)) cli::cli_abort("The authenticated reviewer must be active")
      eligible <- intersect(actor$roles, c("statistical_programmer", "biostatistician"))
      if (!length(eligible)) cli::cli_abort("The authenticated actor is not an eligible reviewer")
      if (is.null(role) && length(eligible) > 1L) {
        cli::cli_abort("A reviewer with multiple eligible roles must select one role")
      }
      role <- role %||% eligible[[1]]
      if (!checkmate::test_choice(role, eligible)) {
        cli::cli_abort("The claimed reviewer role is not authorized for this actor")
      }
      if (decision == "rejected" && !checkmate::test_string(comment, min.chars = 1)) cli::cli_abort("A rejection rationale is required")
      prior <- DBI::dbGetQuery(con, "SELECT actor_id FROM review_decisions WHERE revision_id = ?", params = list(revision_id))
      if (actor$id %in% prior$actor_id) cli::cli_abort("Review decisions require distinct authenticated identities")
      decision_id <- paste0("decision-", substr(canonical_hash(idempotency_key), 1L, 24L))
      created_at <- .utc_timestamp()
      authorization_json <- canonical_serialize(list(
        actor_id = actor$id,
        roles = actor$roles,
        active = actor$active
      ))
      stored_comment <- if (is.null(comment)) NA_character_ else comment
      decision_record <- list(
        decision_id = decision_id,
        revision_id = revision_id,
        actor_id = actor$id,
        role = role,
        decision = decision,
        authorization_json = authorization_json,
        comment = stored_comment,
        code_hash = revision$code_hash,
        image_hash = revision$image_hash,
        analytical_hash = revision$analytical_hash,
        created_at = created_at,
        idempotency_key = idempotency_key
      )
      decision_hash <- .review_decision_hash(decision_record)
      DBI::dbExecute(con, paste(
        "INSERT INTO review_decisions(decision_id, revision_id, actor_id, role, decision, authorization_json, comment,",
        "code_hash, image_hash, analytical_hash, created_at, idempotency_key, record_hash)",
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
      ), params = list(decision_id, revision_id, actor$id, role, decision,
        authorization_json, stored_comment, revision$code_hash, revision$image_hash,
        revision$analytical_hash, created_at, idempotency_key, decision_hash))
      next_status <- revision$status
      if (decision == "rejected") next_status <- "Rejected"
      if (decision == "approved") {
        approvals <- DBI::dbGetQuery(con, "SELECT actor_id, role FROM review_decisions WHERE revision_id = ? AND decision = 'approved'", params = list(revision_id))
        if (nrow(approvals) >= 2L && length(unique(approvals$actor_id)) >= 2L &&
            all(c("statistical_programmer", "biostatistician") %in% approvals$role)) next_status <- "Reviewed"
      }
      DBI::dbExecute(con, "UPDATE revision_projection SET status = ?, version = version + 1, updated_at = ? WHERE revision_id = ?",
        params = list(next_status, .utc_timestamp(), revision_id))
      .append_lifecycle_event(
        con,
        revision,
        paste0("review_", decision),
        list(
          status = next_status,
          actor_id = actor$id,
          role = role,
          decision_id = decision_id,
          decision_hash = decision_hash
        ),
        idempotency_key
      )
    })
  }

  list_review_decisions <- function(revision_id) .with_evidence_connection(database_path, \(con) DBI::dbGetQuery(
    con, "SELECT * FROM review_decisions WHERE revision_id = ? ORDER BY created_at, decision_id", params = list(revision_id)
  ))

  record_export_receipt <- function(receipt_id, revision_id, destination_id, code_hash, image_hash, idempotency_key) {
    write_transaction(function(con) {
      command <- list(receipt_id = receipt_id, revision_id = revision_id, destination_id = destination_id, code_hash = code_hash, image_hash = image_hash)
      if (!.register_command(con, idempotency_key, command)) return(invisible(NULL))
      revision <- .current_revision(con, revision_id)
      if (!identical(code_hash, revision$code_hash) || !identical(image_hash, revision$image_hash)) cli::cli_abort("Export receipt hashes do not match the immutable revision")
      DBI::dbExecute(con, "INSERT INTO export_receipts VALUES (?, ?, ?, ?, ?, ?, ?)",
        params = list(receipt_id, revision_id, destination_id, code_hash, image_hash, .utc_timestamp(), idempotency_key))
    })
    invisible(receipt_id)
  }
  list_export_receipts <- function(revision_id) .with_evidence_connection(database_path, \(con) DBI::dbGetQuery(
    con, "SELECT * FROM export_receipts WHERE revision_id = ? ORDER BY created_at, receipt_id", params = list(revision_id)
  ))

  rebuild_projections <- function() {
    .with_repository_lock(database_path, function() {
      .with_evidence_connection(database_path, function(con) {
        DBI::dbWithTransaction(con, {
          revisions <- DBI::dbGetQuery(
            con,
            "SELECT revision_id, initial_status, created_at FROM revisions"
          )
          events <- DBI::dbGetQuery(
            con,
            paste(
              "SELECT revision_id, payload_json, created_at",
              "FROM lifecycle_events ORDER BY plot_id, event_sequence"
            )
          )
          projections <- .project_revision_history(revisions, events)
          DBI::dbExecute(con, "DELETE FROM revision_projection")
          if (nrow(projections)) {
            DBI::dbAppendTable(con, "revision_projection", projections)
          }
        })
      })
    })
  }

  verify_integrity_unlocked <- function(require_artifacts = FALSE) {
    .with_evidence_connection(database_path, function(con) {
      foreign_key_violations <- DBI::dbGetQuery(
        con,
        "PRAGMA foreign_key_check"
      )
      if (nrow(foreign_key_violations) > 0L) {
        cli::cli_abort("Foreign-key integrity check failed")
      }
      plots <- DBI::dbGetQuery(con, "SELECT plot_id FROM plots")$plot_id
      events <- DBI::dbGetQuery(
        con,
        "SELECT * FROM lifecycle_events ORDER BY plot_id, event_sequence"
      )
      roots <- .read_chain_roots(chain_root_path)
      root_plot_ids <- names(roots) %||% character()
      if (!identical(sort(root_plot_ids), sort(plots))) {
        cli::cli_abort("External chain roots do not match persisted plots")
      }
      for (plot_id in plots) {
        plot_events <- events[events$plot_id == plot_id, , drop = FALSE]
        previous <- paste(rep("0", 64L), collapse = "")
        for (i in seq_len(nrow(plot_events))) {
          if (plot_events$event_sequence[[i]] != i || !identical(plot_events$previous_hash[[i]], previous)) cli::cli_abort("Lifecycle event chain order is invalid")
          calculated <- canonical_hash(list(plot_id = plot_id, revision_id = plot_events$revision_id[[i]], event_sequence = i,
            event_type = plot_events$event_type[[i]], payload_json = plot_events$payload_json[[i]], previous_hash = previous, created_at = plot_events$created_at[[i]]))
          if (!identical(calculated, plot_events$chain_hash[[i]])) cli::cli_abort("Lifecycle event chain hash is invalid")
          previous <- calculated
        }
        root <- roots[[plot_id]]
        if (is.null(root) || root$sequence != nrow(plot_events) || !identical(root$chain_hash, previous)) cli::cli_abort("External chain root does not match persisted history")
      }
      projections <- DBI::dbGetQuery(con, "SELECT * FROM revision_projection ORDER BY revision_id")
      revisions <- DBI::dbGetQuery(
        con,
        paste(
          "SELECT revision_id, initial_status, created_at",
          "FROM revisions ORDER BY revision_id"
        )
      )
      expected <- .project_revision_history(revisions, events)
      if (require_artifacts && nrow(revisions) && is.null(artifact_store)) {
        cli::cli_abort(
          "Complete integrity verification requires an artifact store"
        )
      }
      actual <- projections[, c("revision_id", "status", "version"), drop = FALSE]
      expected <- expected[, c("revision_id", "status", "version"), drop = FALSE]
      if (!identical(actual, expected)) cli::cli_abort("Revision projection does not match append-only history")
      evidence <- DBI::dbGetQuery(
        con,
        "SELECT evidence_id, details_json, content_hash FROM evidence_entries"
      )
      for (index in seq_len(nrow(evidence))) {
        calculated <- digest::digest(
          evidence$details_json[[index]],
          algo = "sha256",
          serialize = FALSE
        )
        if (!identical(calculated, evidence$content_hash[[index]])) {
          cli::cli_abort(
            "Evidence content hash is invalid for {.val {evidence$evidence_id[[index]]}}"
          )
        }
      }
      bundle_mismatches <- DBI::dbGetQuery(con, paste(
        "SELECT COUNT(*) AS n FROM artifact_bundles b",
        "JOIN revisions r USING(revision_id)",
        "WHERE b.code_hash <> r.code_hash",
        "OR b.image_hash <> r.image_hash",
        "OR b.analytical_hash <> r.analytical_hash"
      ))$n[[1]]
      if (bundle_mismatches > 0L) {
        cli::cli_abort(
          "Accepted artifact bundle hashes do not match their revisions"
        )
      }
      review_mismatches <- DBI::dbGetQuery(con, paste(
        "SELECT COUNT(*) AS n FROM review_decisions d",
        "JOIN revisions r USING(revision_id)",
        "WHERE d.code_hash <> r.code_hash",
        "OR d.image_hash <> r.image_hash",
        "OR d.analytical_hash <> r.analytical_hash"
      ))$n[[1]]
      if (review_mismatches > 0L) {
        cli::cli_abort(
          "Reviewer decision hashes do not match their revisions"
        )
      }
      decisions <- DBI::dbGetQuery(
        con,
        "SELECT * FROM review_decisions ORDER BY decision_id"
      )
      decision_events <- events[
        events$event_type %in% c("review_approved", "review_rejected"),
        ,
        drop = FALSE
      ]
      event_decisions <- lapply(
        decision_events$payload_json,
        jsonlite::fromJSON,
        simplifyVector = TRUE
      )
      event_ids <- vapply(event_decisions, `[[`, character(1), "decision_id")
      if (!identical(sort(decisions$decision_id), sort(event_ids))) {
        cli::cli_abort("Reviewer decisions do not match lifecycle history")
      }
      for (index in seq_len(nrow(decisions))) {
        record <- as.list(decisions[index, , drop = FALSE]) |>
          lapply(\(value) value[[1]])
        calculated <- .review_decision_hash(record)
        event_index <- match(record$decision_id, event_ids)
        if (!identical(calculated, record$record_hash) ||
            !identical(calculated, event_decisions[[event_index]]$decision_hash)) {
          cli::cli_abort("Reviewer decision integrity check failed")
        }
      }
      receipt_mismatches <- DBI::dbGetQuery(con, paste(
        "SELECT COUNT(*) AS n FROM export_receipts e",
        "JOIN revisions r USING(revision_id)",
        "WHERE e.code_hash <> r.code_hash",
        "OR e.image_hash <> r.image_hash"
      ))$n[[1]]
      if (receipt_mismatches > 0L) {
        cli::cli_abort(
          "Export receipt hashes do not match their revisions"
        )
      }
      if (!is.null(artifact_store)) {
        hashes <- DBI::dbGetQuery(con, "SELECT code_hash, image_hash FROM revisions")
        for (hash in unique(unlist(hashes))) artifact_store$verify(hash)
      }
      TRUE
    })
  }

  verify_integrity <- function(require_artifacts = FALSE) {
    checkmate::assert_flag(require_artifacts)
    .with_repository_lock(
      database_path,
      \() verify_integrity_unlocked(require_artifacts)
    )
  }

  foreign_keys_enabled <- function() .with_evidence_connection(database_path, \(con) identical(DBI::dbGetQuery(con, "PRAGMA foreign_keys")[[1]][[1]], 1L))

  cleanup_orphan_artifacts <- function(minimum_age_seconds = 3600) {
    checkmate::assert_number(
      minimum_age_seconds,
      lower = 0,
      finite = TRUE
    )
    if (is.null(artifact_store)) {
      cli::cli_abort("Artifact cleanup requires an artifact store")
    }
    .with_repository_lock(database_path, function() {
      referenced_hashes <- .with_evidence_connection(
        database_path,
        function(con) {
          hashes <- DBI::dbGetQuery(
            con,
            "SELECT code_hash, image_hash FROM revisions"
          )
          unique(unlist(hashes, use.names = FALSE))
        }
      )
      artifact_store$.cleanup_orphans(
        referenced_hashes,
        minimum_age_seconds
      )
    })
  }

  backup <- function(destination) {
    .with_repository_lock(database_path, function() {
      if (fs::dir_exists(destination) && length(fs::dir_ls(destination, fail = FALSE))) {
        cli::cli_abort("Backup destination must be empty")
      }
      verify_integrity_unlocked(require_artifacts = TRUE)
      parent <- fs::path_dir(destination)
      fs::dir_create(parent, recurse = TRUE)
      staging <- fs::file_temp(tmp_dir = parent, pattern = "evidence-backup-")
      fs::dir_create(staging)
      completed <- FALSE
      on.exit({
        if (!completed && fs::dir_exists(staging)) fs::dir_delete(staging)
      }, add = TRUE)
      source <- .sqlite_connect(database_path)
      target <- .sqlite_connect(fs::path(staging, "evidence.sqlite"))
      on.exit({
        if (DBI::dbIsValid(source)) DBI::dbDisconnect(source)
      }, add = TRUE)
      on.exit({
        if (DBI::dbIsValid(target)) DBI::dbDisconnect(target)
      }, add = TRUE)
      RSQLite::sqliteCopyDatabase(source, target)
      DBI::dbDisconnect(target)
      DBI::dbDisconnect(source)
      staged_chain_root <- fs::path(staging, "chain-root.json")
      if (fs::file_exists(chain_root_path)) {
        fs::file_copy(chain_root_path, staged_chain_root)
      } else {
        writeLines(canonical_serialize(list()), staged_chain_root, useBytes = TRUE)
      }
      if (!is.null(artifact_store)) {
        fs::dir_copy(
          artifact_store$root,
          fs::path(staging, "artifacts")
        )
      }
      copied_store <- if (fs::dir_exists(fs::path(staging, "artifacts"))) {
        local_artifact_store(fs::path(staging, "artifacts"))
      } else {
        NULL
      }
      copied <- sqlite_evidence_repository(
        fs::path(staging, "evidence.sqlite"),
        fs::path(staging, "chain-root.json"),
        copied_store
      )
      copied$verify_integrity()
      manifest <- list(
        database_hash = digest::digest(
          file = fs::path(staging, "evidence.sqlite"),
          algo = "sha256"
        ),
        chain_root_hash = digest::digest(
          file = fs::path(staging, "chain-root.json"),
          algo = "sha256"
        ),
        table_counts = .database_table_counts(
          fs::path(staging, "evidence.sqlite")
        ),
        completed_at = .utc_timestamp()
      )
      writeLines(
        canonical_serialize(manifest),
        fs::path(staging, "backup-manifest.json"),
        useBytes = TRUE
      )
      if (fs::dir_exists(destination)) fs::dir_delete(destination)
      fs::file_move(staging, destination)
      completed <- TRUE
      invisible(destination)
    })
  }

  structure(list(
    database_path = fs::path_abs(database_path), chain_root_path = fs::path_abs(chain_root_path), artifact_store = artifact_store,
    create_revision = create_revision, list_revisions = list_revisions, get_revision = get_revision, list_events = list_events,
    record_attempt = record_attempt, list_attempts = list_attempts, complete_attempt = complete_attempt,
    record_evidence = record_evidence, list_evidence = list_evidence,
    accept_artifact_bundle = accept_artifact_bundle,
    mark_verified = mark_verified,
    record_review_decision = record_review_decision,
    list_review_decisions = list_review_decisions, record_export_receipt = record_export_receipt,
    list_export_receipts = list_export_receipts, rebuild_projections = rebuild_projections,
    verify_integrity = verify_integrity, foreign_keys_enabled = foreign_keys_enabled,
    cleanup_orphan_artifacts = cleanup_orphan_artifacts, backup = backup,
    update_revision = function(...) cli::cli_abort("Updating historical revisions is not available"),
    delete_revision = function(...) cli::cli_abort("Deleting historical revisions is not available")
  ), class = "sqlite_evidence_repository")
}

restore_evidence_repository <- function(backup_path, destination) {
  checkmate::assert_directory_exists(backup_path)
  .verify_backup_manifest(backup_path)
  if (fs::dir_exists(destination) && length(fs::dir_ls(destination, fail = FALSE))) {
    cli::cli_abort("Restore destination must be empty")
  }
  parent <- fs::path_dir(destination)
  fs::dir_create(parent, recurse = TRUE)
  staging <- fs::file_temp(tmp_dir = parent, pattern = "evidence-restore-")
  fs::dir_create(staging)
  completed <- FALSE
  on.exit({
    if (!completed && fs::dir_exists(staging)) fs::dir_delete(staging)
  }, add = TRUE)
  fs::file_copy(
    fs::path(backup_path, "evidence.sqlite"),
    fs::path(staging, "evidence.sqlite")
  )
  fs::file_copy(
    fs::path(backup_path, "chain-root.json"),
    fs::path(staging, "chain-root.json")
  )
  store <- NULL
  if (fs::dir_exists(fs::path(backup_path, "artifacts"))) {
    fs::dir_copy(
      fs::path(backup_path, "artifacts"),
      fs::path(staging, "artifacts")
    )
    store <- local_artifact_store(fs::path(staging, "artifacts"))
  }
  repo <- sqlite_evidence_repository(
    fs::path(staging, "evidence.sqlite"),
    fs::path(staging, "chain-root.json"),
    store
  )
  repo$verify_integrity()
  if (fs::dir_exists(destination)) fs::dir_delete(destination)
  fs::file_move(staging, destination)
  completed <- TRUE
  restored_store <- if (fs::dir_exists(fs::path(destination, "artifacts"))) {
    local_artifact_store(fs::path(destination, "artifacts"))
  } else {
    NULL
  }
  sqlite_evidence_repository(
    fs::path(destination, "evidence.sqlite"),
    fs::path(destination, "chain-root.json"),
    restored_store
  )
}

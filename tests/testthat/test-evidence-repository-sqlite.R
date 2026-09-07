test_that("SQLite connections enforce foreign keys and projections rebuild", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(fs::path(root, "db.sqlite"), fs::path(root, "root.json"))
  repo$create_revision("plot-1", "rev-1", 1L, "creator", "spec", "code", "image", "analysis", "create")

  expect_identical(repo$foreign_keys_enabled(), TRUE)
  repo$rebuild_projections()
  expect_identical(repo$get_revision("rev-1")$status, "Draft")
  expect_identical(repo$verify_integrity(), TRUE)

  con <- DBI::dbConnect(RSQLite::SQLite(), fs::path(root, "db.sqlite"))
  DBI::dbExecute(con, "UPDATE revision_projection SET status = 'Verified'")
  DBI::dbDisconnect(con)
  expect_error(repo$verify_integrity(), "projection")
  repo$rebuild_projections()
  expect_identical(repo$verify_integrity(), TRUE)
})

test_that("event corruption and external-root rollback are detected", {
  root <- withr::local_tempdir()
  db <- fs::path(root, "db.sqlite")
  chain <- fs::path(root, "root.json")
  repo <- sqlite_evidence_repository(db, chain)
  repo$create_revision("plot-1", "rev-1", 1L, "creator", "spec", "code", "image", "analysis", "create")

  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  withr::defer(DBI::dbDisconnect(con))
  DBI::dbExecute(con, "UPDATE lifecycle_events SET chain_hash = 'corrupt' WHERE event_sequence = 1")
  expect_error(repo$verify_integrity(), "chain")
})

test_that("event omission and previous-hash tampering are detected", {
  root <- withr::local_tempdir()
  db <- fs::path(root, "db.sqlite")
  chain <- fs::path(root, "root.json")
  repo <- sqlite_evidence_repository(db, chain)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verify")

  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  DBI::dbExecute(
    con,
    "UPDATE lifecycle_events SET previous_hash = 'changed' WHERE event_sequence = 2"
  )
  DBI::dbDisconnect(con)
  expect_error(repo$verify_integrity(), "chain")

  repo <- sqlite_evidence_repository(db, chain)
  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  DBI::dbExecute(con, "DELETE FROM lifecycle_events WHERE event_sequence = 1")
  DBI::dbDisconnect(con)
  expect_error(repo$verify_integrity(), "chain")
})

test_that("rollback to an older database copy is detected by the external root", {
  root <- withr::local_tempdir()
  db <- fs::path(root, "db.sqlite")
  chain <- fs::path(root, "root.json")
  old_db <- fs::path(root, "old.sqlite")
  repo <- sqlite_evidence_repository(db, chain)
  repo$create_revision("plot-1", "rev-1", 1L, "creator", "spec", "code", "image", "analysis", "create-1")
  fs::file_copy(db, old_db)
  repo$create_revision("plot-1", "rev-2", 2L, "creator", "spec2", "code2", "image2", "analysis2", "create-2")

  fs::file_copy(old_db, db, overwrite = TRUE)
  expect_error(repo$verify_integrity(), "External chain root")
})

test_that("integrity checks reconcile bound evidence hashes", {
  root <- withr::local_tempdir()
  db <- fs::path(root, "db.sqlite")
  repo <- sqlite_evidence_repository(db, fs::path(root, "root.json"))
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  repo$accept_artifact_bundle(
    "bundle-1", "rev-1", "code", "image", "analysis", "bundle"
  )
  repo$record_export_receipt(
    "receipt-1", "rev-1", "workspace", "code", "image", "receipt"
  )

  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  DBI::dbExecute(
    con,
    "UPDATE artifact_bundles SET analytical_hash = 'changed'"
  )
  DBI::dbDisconnect(con)

  expect_error(repo$verify_integrity(), "artifact bundle")
})

test_that("integrity checks detect evidence and decision metadata tampering", {
  root <- withr::local_tempdir()
  db <- fs::path(root, "db.sqlite")
  chain <- fs::path(root, "root.json")
  repo <- sqlite_evidence_repository(db, chain)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  repo$record_evidence(
    "evidence-1", "rev-1", "check", "passed", "evidence",
    details = list(result = "ok")
  )
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verify")
  review <- new_review_service(
    repo,
    local_identity_provider(list(new_actor("sp", "statistical_programmer")))
  )
  review$approve("rev-1", "sp", 2L, "approve", comment = "Reviewed")

  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  DBI::dbExecute(
    con,
    "UPDATE evidence_entries SET details_json = '{\"result\":\"changed\"}'"
  )
  DBI::dbDisconnect(con)
  expect_error(repo$verify_integrity(), "Evidence content hash")

  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  DBI::dbExecute(
    con,
    "UPDATE evidence_entries SET details_json = '{\"result\":\"ok\"}'"
  )
  DBI::dbExecute(con, "UPDATE review_decisions SET comment = 'Changed'")
  DBI::dbDisconnect(con)
  expect_error(repo$verify_integrity(), "decision integrity")
})

test_that("external roots cannot contain plots absent from the database", {
  root <- withr::local_tempdir()
  chain <- fs::path(root, "root.json")
  repo <- sqlite_evidence_repository(fs::path(root, "db.sqlite"), chain)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  roots <- jsonlite::fromJSON(chain, simplifyVector = TRUE)
  roots[["missing-plot"]] <- list(
    sequence = 1L,
    chain_hash = paste(rep("0", 64L), collapse = "")
  )
  writeLines(canonical_serialize(roots), chain, useBytes = TRUE)

  expect_error(repo$verify_integrity(), "roots")
})

test_that("retry reconciles a root publication failure", {
  root <- withr::local_tempdir()
  database <- fs::path(root, "db.sqlite")
  chain_root <- fs::path(root, "root.json")
  repo <- sqlite_evidence_repository(database, chain_root)
  local({
    testthat::local_mocked_bindings(
      .write_chain_root = function(...) cli::cli_abort("simulated root failure")
    )
    expect_error(
      repo$create_revision(
        "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
        "analysis", "create"
      ),
      "simulated root failure"
    )
  })
  expect_false(fs::file_exists(chain_root))

  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  expect_identical(repo$verify_integrity(), TRUE)
  expect_equal(nrow(repo$list_events("plot-1")), 1L)
})

test_that("a missing external root blocks new lifecycle commands", {
  root <- withr::local_tempdir()
  database <- fs::path(root, "db.sqlite")
  chain_root <- fs::path(root, "root.json")
  repo <- sqlite_evidence_repository(database, chain_root)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  fs::file_delete(chain_root)

  expect_error(
    new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "create"),
    "chain root"
  )
  expect_false(fs::file_exists(chain_root))
  expect_error(
    repo$create_revision(
      "plot-1", "rev-2", 2L, "creator", "spec", "code", "image",
      "analysis", "new-command"
    ),
    "chain root"
  )
  expect_equal(nrow(repo$list_revisions("plot-1")), 1L)
})

test_that("attempt identifiers cannot be reused for a different command", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "root.json")
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create-1"
  )
  repo$create_revision(
    "plot-1", "rev-2", 2L, "creator", "spec", "code", "image",
    "analysis", "create-2"
  )
  repo$record_attempt("attempt-1", "rev-1", "run-1")

  expect_error(
    repo$record_attempt("attempt-1", "rev-1", "run-2"),
    "different command"
  )
  expect_error(
    repo$record_attempt("attempt-1", "rev-2", "run-1"),
    "different command"
  )
  expect_equal(nrow(repo$list_attempts("rev-1")), 1L)
  expect_equal(nrow(repo$list_attempts("rev-2")), 0L)
})

test_that("evidence details must use unique names", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "root.json")
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )

  expect_error(
    repo$record_evidence(
      "evidence-1", "rev-1", "check", "passed", "evidence",
      details = list("value")
    ),
    "named list"
  )
  expect_error(
    repo$record_evidence(
      "evidence-2", "rev-1", "check", "passed", "evidence-2",
      details = structure(list(1, 2), names = c("x", "x"))
    ),
    "named list"
  )
})

test_that("database initialization applies versioned migrations", {
  root <- withr::local_tempdir()
  migrations <- fs::path(root, "migrations")
  fs::dir_create(migrations)
  writeLines(
    "CREATE TABLE migration_probe(id TEXT PRIMARY KEY NOT NULL);",
    fs::path(migrations, "001-probe.sql")
  )
  testthat::local_mocked_bindings(
    .evidence_migrations_path = \() migrations
  )

  database <- fs::path(root, "migration.sqlite")
  .initialize_evidence_database(database)
  con <- DBI::dbConnect(RSQLite::SQLite(), database)
  withr::defer(DBI::dbDisconnect(con))

  expect_identical(DBI::dbExistsTable(con, "migration_probe"), TRUE)
  expect_identical(
    DBI::dbGetQuery(con, "SELECT version FROM schema_migrations")$version,
    1L
  )
})

test_that("schema snapshot matches the numbered migrations", {
  root <- withr::local_tempdir()
  migrated_path <- fs::path(root, "migrated.sqlite")
  snapshot_path <- fs::path(root, "snapshot.sqlite")
  .initialize_evidence_database(migrated_path)
  snapshot <- DBI::dbConnect(RSQLite::SQLite(), snapshot_path)
  withr::defer(DBI::dbDisconnect(snapshot))
  statements <- .read_sql_statements(
    fs::path(fs::path_dir(.evidence_migrations_path()), "schema.sql")
  )
  for (statement in statements[nzchar(statements)]) {
    DBI::dbExecute(snapshot, statement)
  }
  migrated <- DBI::dbConnect(RSQLite::SQLite(), migrated_path)
  withr::defer(DBI::dbDisconnect(migrated))
  tables <- sort(DBI::dbListTables(migrated))

  expect_identical(sort(DBI::dbListTables(snapshot)), tables)
  for (table in tables) {
    expect_equal(DBI::dbListFields(snapshot, table), DBI::dbListFields(migrated, table))
    expect_equal(
      DBI::dbGetQuery(snapshot, paste0("PRAGMA foreign_key_list('", table, "')")),
      DBI::dbGetQuery(migrated, paste0("PRAGMA foreign_key_list('", table, "')"))
    )
    expect_equal(
      DBI::dbGetQuery(snapshot, paste0("PRAGMA index_list('", table, "')"))$name,
      DBI::dbGetQuery(migrated, paste0("PRAGMA index_list('", table, "')"))$name
    )
  }
})

test_that("writes, projection rebuilds, and integrity checks serialize", {
  skip_if_not_installed("callr")
  root <- withr::local_tempdir()
  database <- fs::path(root, "db.sqlite")
  chain_root <- fs::path(root, "root.json")
  gate <- fs::path(root, "go")
  repo <- sqlite_evidence_repository(database, chain_root)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  source_root <- normalizePath(
    testthat::test_path("..", ".."),
    winslash = "/",
    mustWork = FALSE
  )
  if (!file.exists(file.path(source_root, "DESCRIPTION"))) source_root <- NULL
  worker <- function(source_root, database, chain_root, gate, action) {
    if (!is.null(source_root)) devtools::load_all(source_root, quiet = TRUE)
    package <- asNamespace("ADaMViz.SubmissionSync")
    repository <- get("sqlite_evidence_repository", package)
    lifecycle_service <- get("new_lifecycle_service", package)
    while (!file.exists(gate)) Sys.sleep(0.01)
    repo <- repository(database, chain_root)
    if (action == "write") {
      lifecycle_service(repo)$mark_verified("rev-1", 1L, "verify")
    } else if (action == "rebuild") {
      repo$rebuild_projections()
    } else {
      repo$verify_integrity()
    }
    TRUE
  }
  processes <- lapply(c("write", "rebuild", "verify"), function(action) {
    callr::r_bg(
      worker,
      args = list(source_root, database, chain_root, gate, action),
      libpath = .libPaths()
    )
  })
  file.create(gate)
  lapply(processes, function(process) process$wait(timeout = 60000))

  expect_true(all(!vapply(processes, \(process) process$is_alive(), logical(1))))
  expect_true(all(vapply(processes, \(process) process$get_result(), logical(1))))
  expect_identical(repo$get_revision("rev-1")$status, "Verified")
  expect_identical(repo$verify_integrity(), TRUE)
})

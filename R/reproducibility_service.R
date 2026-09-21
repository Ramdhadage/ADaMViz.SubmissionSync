.latest_revision_context <- function(repository, revision_id) {
  evidence <- repository$list_evidence(revision_id)
  evidence <- evidence[evidence$evidence_type == "revision_context", , drop = FALSE]
  if (!nrow(evidence)) {
    cli::cli_abort("Revision {.val {revision_id}} has no revision context evidence")
  }
  jsonlite::fromJSON(
    evidence$details_json[[nrow(evidence)]],
    simplifyVector = FALSE
  )
}

.evidence_selected_data <- function(details) {
  columns <- lapply(details$input_data$selected_data, function(column) {
    if (is.list(column)) unlist(column, use.names = FALSE) else column
  })
  column_order <- unlist(
    details$input_data$selected_data_columns %||% names(columns),
    use.names = FALSE
  )
  columns <- columns[column_order]
  columns <- lapply(columns, function(column) {
    column[column == "NA"] <- NA
    column
  })
  classes <- unlist(
    details$input_data$selected_data_classes %||% list(),
    use.names = TRUE
  )
  if (!is.null(names(classes))) {
    names(classes) <- sub("^.*[.]", "", names(classes))
  }
  if (!length(names(classes)) && identical(length(classes), length(columns))) {
    names(classes) <- column_order
  }
  for (name in intersect(names(columns), names(classes))) {
    if (classes[[name]] %in% c("numeric", "integer")) {
      columns[[name]] <- as.numeric(columns[[name]])
    }
    if (identical(classes[[name]], "integer")) {
      columns[[name]] <- as.integer(columns[[name]])
    }
  }
  data <- as.data.frame(columns, stringsAsFactors = FALSE)
  data
}

.evidence_execution_request <- function(details) {
  structure(details$request, class = "execution_request")
}

new_reproducibility_service <- function(
  repository,
  artifact_store,
  runner = new_execution_runner(),
  verification_service = new_verification_service()
) {
  .validate_evidence_repository(
    repository,
    c("get_revision", "list_evidence", "record_evidence")
  )
  if (!is.list(artifact_store) ||
      !is.function(artifact_store$get) ||
      !is.function(artifact_store$verify)) {
    cli::cli_abort("Reproducibility service requires a readable artifact store")
  }
  if (!is.function(runner$run)) {
    cli::cli_abort("Reproducibility runner must provide {.fn run}")
  }
  if (!is.function(verification_service$verify)) {
    cli::cli_abort("Verification service must provide {.fn verify}")
  }

  reproduce_revision <- function(revision_id, idempotency_key = NULL) {
    .validate_identifier(revision_id, "revision_id")
    if (!is.null(idempotency_key)) {
      .validate_identifier(idempotency_key, "idempotency_key")
    }
    revision <- repository$get_revision(revision_id)
    details <- .latest_revision_context(repository, revision_id)
    request <- .evidence_execution_request(details)
    script <- rawToChar(artifact_store$get(revision$code_hash))
    analysis_data <- .evidence_selected_data(details)
    runner_result <- runner$run(
      request = request,
      script = script,
      analysis_data = analysis_data,
      data_classification = details$input_data$classification %||% "synthetic"
    )
    verification <- verification_service$verify(
      request = request,
      script = script,
      analysis_data = analysis_data,
      runner_result = runner_result
    )
    environment_match <- identical(
      runner_result$result$environment_fingerprint,
      details$environment$fingerprint
    )
    checks <- list(
      specification = identical(request$spec_hash, revision$spec_hash),
      generated_r_code = identical(.execution_hash_text(script), revision$code_hash),
      analytical_result = identical(
        runner_result$result$analytical_hash,
        revision$analytical_hash
      ),
      environment = environment_match,
      image_bytes = if (environment_match) {
        identical(runner_result$result$image_hash, revision$image_hash)
      } else {
        NA
      }
    )
    failed <- names(checks)[vapply(checks, identical, logical(1), FALSE)]
    status <- if (length(failed)) "failed" else "passed"
    result <- structure(
      list(
        reproducibility_version = "revision-reproducibility-v1",
        status = status,
        checks = checks,
        failed_checks = failed,
        verification = unclass(verification)
      ),
      class = "revision_reproducibility_result"
    )
    if (!is.null(idempotency_key)) {
      repository$record_evidence(
        evidence_id = .revision_evidence_id(revision_id, idempotency_key),
        revision_id = revision_id,
        evidence_type = "reproducibility_rerun",
        outcome = status,
        idempotency_key = idempotency_key,
        details = unclass(result)
      )
    }
    result
  }

  structure(
    list(reproduce_revision = reproduce_revision),
    class = "reproducibility_service"
  )
}

.execution_request_fingerprint <- function(request, script, analysis_data) {
  canonical_hash(list(
    request = unclass(request),
    script_hash = .execution_hash_text(script),
    snapshot_hash = canonical_hash(analysis_data)
  ))
}

.execution_attempt_id <- function(idempotency_key) {
  paste0("attempt-", substr(canonical_hash(idempotency_key), 1L, 24L))
}

.execution_id <- function(prefix, attempt_id, suffix) {
  paste(prefix, substr(canonical_hash(list(attempt_id, suffix)), 1L, 24L), sep = "-")
}

new_execution_service <- function(
  repository,
  runner = new_callr_execution_runner(),
  verification_service = new_verification_service(),
  artifact_store = NULL
) {
  .validate_evidence_repository(
    repository,
    c(
      "record_attempt", "list_attempts", "complete_attempt",
      "record_evidence", "accept_artifact_bundle", "mark_verified",
      "get_revision"
    )
  )
  if (!is.function(runner$run)) cli::cli_abort("Execution runner must provide {.fn run}")
  if (!is.function(verification_service$verify)) {
    cli::cli_abort("Verification service must provide {.fn verify}")
  }

  start <- function(revision_id, request, script, analysis_data, idempotency_key) {
    revision <- repository$get_revision(revision_id)
    if (!identical(revision$status, "Draft")) {
      cli::cli_abort("Only Draft revisions can be submitted for verification")
    }
    attempts <- repository$list_attempts(revision_id)
    active <- attempts[is.na(attempts$outcome), , drop = FALSE]
    attempt_id <- .execution_attempt_id(idempotency_key)
    fingerprint <- .execution_request_fingerprint(request, script, analysis_data)
    if (nrow(active) && !attempt_id %in% active$attempt_id) {
      cli::cli_abort("A revision can have only one active execution attempt")
    }
    repository$record_attempt(attempt_id, revision_id, fingerprint)
    invisible(list(
      revision_id = revision_id,
      revision_version = as.integer(revision$version),
      attempt_id = attempt_id,
      idempotency_key = idempotency_key,
      request = request,
      script = script,
      analysis_data = analysis_data,
      work_dir = fs::file_temp(pattern = paste0(attempt_id, "-"))
    ))
  }

  complete <- function(attempt, runner_result) {
    verification <- verification_service$verify(
      request = attempt$request,
      script = attempt$script,
      analysis_data = attempt$analysis_data,
      runner_result = runner_result
    )
    evidence_id <- .execution_id("evidence", attempt$attempt_id, "verification")
    repository$record_evidence(
      evidence_id = evidence_id,
      revision_id = attempt$revision_id,
      evidence_type = "execution_verification",
      outcome = verification$status,
      idempotency_key = paste0(attempt$idempotency_key, ":evidence"),
      details = list(
        attempt_id = attempt$attempt_id,
        verification = unclass(verification),
        execution_result = unclass(runner_result$result %||% list()),
        environment = runner_result$environment %||% list(
          fingerprint = runner_result$result$environment_fingerprint %||% NA_character_
        ),
        diagnostics = runner_result$diagnostics
      )
    )
    if (!identical(verification$status, "passed")) {
      repository$complete_attempt(
        attempt$attempt_id,
        "failed",
        paste0(attempt$idempotency_key, ":terminal")
      )
      return(invisible(list(
        attempt_id = attempt$attempt_id,
        status = "failed",
        verification = verification,
        runner_result = runner_result
      )))
    }
    if (!is.null(artifact_store)) {
      artifact_store$put(.execution_text_bytes(attempt$script))
      artifact_store$put(readBin(
        runner_result$image_path,
        what = "raw",
        n = fs::file_size(runner_result$image_path)
      ))
    }
    repository$accept_artifact_bundle(
      bundle_id = .execution_id("bundle", attempt$attempt_id, "accepted"),
      revision_id = attempt$revision_id,
      code_hash = attempt$request$script_hash,
      image_hash = runner_result$result$image_hash,
      analytical_hash = runner_result$result$analytical_hash,
      idempotency_key = paste0(attempt$idempotency_key, ":bundle")
    )
    repository$complete_attempt(
      attempt$attempt_id,
      "succeeded",
      paste0(attempt$idempotency_key, ":terminal")
    )
    repository$mark_verified(
      attempt$revision_id,
      attempt$revision_version,
      paste0(attempt$idempotency_key, ":verified")
    )
    invisible(list(
      attempt_id = attempt$attempt_id,
      status = "verified",
      verification = verification,
      result = runner_result$result,
      runner_result = runner_result
    ))
  }

  submit <- function(
    revision_id,
    request,
    script,
    analysis_data,
    idempotency_key,
    data_classification = "synthetic"
  ) {
    attempt <- start(revision_id, request, script, analysis_data, idempotency_key)
    runner_result <- tryCatch(
      runner$run(
        request = request,
        script = script,
        analysis_data = analysis_data,
        data_classification = data_classification,
        work_dir = attempt$work_dir
      ),
      error = \(error) structure(
        list(
          status = "failed",
          manifest_version = "execution-runner-result-v1",
          diagnostics = list(stdout = "", stderr = conditionMessage(error))
        ),
        class = "execution_runner_result"
      )
    )
    complete(attempt, runner_result)
  }

  structure(
    list(submit = submit, start = start, complete = complete),
    class = "execution_service"
  )
}

.verification_checks <- function(request, script, analysis_data, runner_result) {
  checks <- list(
    schema = inherits(request, "execution_request"),
    script_hash = identical(.execution_hash_text(script), request$script_hash),
    snapshot_hash = identical(canonical_hash(analysis_data), request$snapshot_hash),
    runner_success = identical(runner_result$status, "succeeded"),
    result_manifest = inherits(runner_result$result, "execution_result"),
    analytical_hash = FALSE,
    image_hash = FALSE,
    environment_fingerprint = FALSE
  )
  if (isTRUE(checks$result_manifest)) {
    checks$analytical_hash <- identical(
      runner_result$result$analytical_hash,
      canonical_hash(runner_result$analytical_output)
    )
    checks$image_hash <- checkmate::test_string(
      runner_result$result$image_hash,
      pattern = "^[0-9a-f]{64}$"
    )
    checks$environment_fingerprint <- checkmate::test_string(
      runner_result$result$environment_fingerprint,
      pattern = "^[0-9a-f]{64}$"
    )
  }
  checks
}

verify_execution_result <- function(request, script, analysis_data, runner_result) {
  checks <- .verification_checks(request, script, analysis_data, runner_result)
  failed <- names(checks)[!unlist(checks, use.names = FALSE)]
  structure(
    list(
      verification_version = "execution-verification-v1",
      status = if (length(failed)) "failed" else "passed",
      checks = checks,
      failed_checks = failed
    ),
    class = "execution_verification"
  )
}

new_verification_service <- function() {
  structure(
    list(verify = verify_execution_result),
    class = "verification_service"
  )
}

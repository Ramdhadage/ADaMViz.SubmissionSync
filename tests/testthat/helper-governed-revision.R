prepare_passing_execution <- function(repo, revision_id) {
  revision <- repo$get_revision(revision_id)
  attempt_id <- paste0("test-attempt-", revision_id)
  prefix <- paste0("test-execution-", revision_id)
  repo$record_attempt(attempt_id, revision_id, paste0(prefix, "-run"))
  repo$record_evidence(
    paste0("test-evidence-", revision_id),
    revision_id,
    "execution_verification",
    "passed",
    paste0(prefix, "-evidence"),
    details = list(attempt_id = attempt_id)
  )
  bundle <- tryCatch(
    repo$get_artifact_bundle(revision_id),
    error = \(error) NULL
  )
  if (is.null(bundle)) {
    repo$accept_artifact_bundle(
      paste0("test-bundle-", revision_id),
      revision_id,
      revision$code_hash,
      revision$image_hash,
      revision$analytical_hash,
      paste0(prefix, "-bundle")
    )
  }
  repo$complete_attempt(
    attempt_id,
    "succeeded",
    paste0(prefix, "-complete")
  )
  invisible(revision)
}

record_passing_execution <- function(repo, revision_id) {
  revision <- prepare_passing_execution(repo, revision_id)
  repo$mark_verified(
    revision_id, as.integer(revision$version),
    paste0("test-execution-", revision_id, "-verified")
  )
  invisible(repo$get_revision(revision_id))
}

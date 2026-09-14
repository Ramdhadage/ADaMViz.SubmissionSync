reconcile_execution_attempts <- function(repository, revision_ids) {
  .validate_evidence_repository(
    repository,
    c("list_attempts", "complete_attempt")
  )
  if (!checkmate::test_character(revision_ids, any.missing = FALSE, unique = TRUE)) {
    cli::cli_abort("{.arg revision_ids} must contain unique revision identifiers")
  }
  reconciled <- list()
  for (revision_id in revision_ids) {
    attempts <- repository$list_attempts(revision_id)
    active <- attempts[is.na(attempts$outcome), , drop = FALSE]
    if (!nrow(active)) next
    for (index in seq_len(nrow(active))) {
      attempt_id <- active$attempt_id[[index]]
      repository$complete_attempt(
        attempt_id,
        "failed",
        paste0("reconcile:", attempt_id)
      )
      reconciled[[attempt_id]] <- "failed"
    }
  }
  structure(
    list(
      reconciliation_version = "attempt-reconciliation-v1",
      reconciled = reconciled
    ),
    class = "attempt_reconciliation"
  )
}

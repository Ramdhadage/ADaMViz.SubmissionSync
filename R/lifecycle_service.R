new_lifecycle_service <- function(repository) {
  .validate_evidence_repository(
    repository,
    c("mark_verified", "get_revision", "list_revisions", "create_revision")
  )

  mark_verified <- function(revision_id, expected_version, idempotency_key) {
    repository$mark_verified(revision_id, expected_version, idempotency_key)
    invisible(repository$get_revision(revision_id))
  }
  create_correction <- function(parent_revision_id, revision_id, creator_id, spec_hash,
                                code_hash, image_hash, analytical_hash, rationale,
                                provenance, idempotency_key) {
    if (!checkmate::test_string(rationale, min.chars = 1)) cli::cli_abort("Correction rationale is required")
    if (!checkmate::test_string(provenance, min.chars = 1)) cli::cli_abort("Correction provenance is required")
    parent <- repository$get_revision(parent_revision_id)
    if (!parent$status %in% c("Rejected", "Reviewed")) cli::cli_abort("Only a closed revision can have a correction successor")
    revisions <- repository$list_revisions(parent$plot_id)
    repository$create_revision(parent$plot_id, revision_id, max(revisions$revision_number) + 1L,
      creator_id, spec_hash, code_hash, image_hash, analytical_hash, idempotency_key,
      parent_revision_id = parent_revision_id, correction_rationale = rationale,
      correction_provenance = provenance)
    invisible(repository$get_revision(revision_id))
  }
  structure(
    list(
      mark_verified = mark_verified,
      create_correction = create_correction
    ),
    class = "lifecycle_service"
  )
}

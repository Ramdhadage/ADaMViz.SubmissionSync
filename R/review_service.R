new_review_service <- function(repository, identity_provider) {
  .validate_evidence_repository(
    repository,
    c("get_revision", "record_review_decision")
  )
  .validate_identity_provider(identity_provider)

  record_decision <- function(
    revision_id,
    actor_id,
    decision,
    expected_version,
    idempotency_key,
    hashes,
    comment,
    role
  ) {
    actor <- identity_provider$get_actor(actor_id)
    if (is.null(hashes)) {
      revision <- repository$get_revision(revision_id)
      hashes <- revision[c("code_hash", "image_hash", "analytical_hash")]
    }
    repository$record_review_decision(
      revision_id,
      actor,
      decision,
      expected_version,
      idempotency_key,
      hashes,
      comment = comment,
      role = role
    )
    invisible(repository$get_revision(revision_id))
  }

  approve <- function(
    revision_id,
    actor_id,
    expected_version,
    idempotency_key,
    hashes = NULL,
    comment = NULL,
    role = NULL
  ) {
    record_decision(
      revision_id,
      actor_id,
      "approved",
      expected_version,
      idempotency_key,
      hashes,
      comment,
      role
    )
  }
  reject <- function(
    revision_id,
    actor_id,
    expected_version,
    idempotency_key,
    rationale,
    hashes = NULL,
    role = NULL
  ) {
    record_decision(
      revision_id,
      actor_id,
      "rejected",
      expected_version,
      idempotency_key,
      hashes,
      rationale,
      role
    )
  }
  structure(list(approve = approve, reject = reject), class = "review_service")
}

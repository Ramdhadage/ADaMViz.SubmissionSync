.export_receipt_id <- function(idempotency_key) {
  paste0("receipt-", substr(canonical_hash(idempotency_key), 1L, 24L))
}

.export_actor_roles <- c(
  "clinical_scientist", "statistical_programmer",
  "biostatistician", "export_publisher"
)

.authorize_export_actor <- function(actor) {
  if (!inherits(actor, "submission_sync_actor")) {
    cli::cli_abort("Export authorization requires an authenticated actor")
  }
  if (!isTRUE(actor$active)) {
    cli::cli_abort("The current actor is not active")
  }
  if (!any(actor$roles %in% .export_actor_roles)) {
    cli::cli_abort("The current actor is not authorized to export revisions")
  }
  invisible(TRUE)
}

.assert_exportable_revision <- function(revision, expected_version) {
  if (!identical(as.integer(revision$version), as.integer(expected_version))) {
    cli::cli_abort("The revision token is stale")
  }
  if (!revision$status %in% c("Draft", "Verified", "Reviewed")) {
    cli::cli_abort("Only Draft, Verified, or Reviewed revisions can be exported")
  }
  invisible(revision)
}

new_export_service <- function(
  repository,
  artifact_store,
  workspace_provider,
  identity_provider
) {
  .validate_evidence_repository(
    repository,
    c(
      "get_revision", "get_artifact_bundle", "record_export_receipt",
      "list_export_receipts"
    )
  )
  if (!is.list(artifact_store) ||
      !is.function(artifact_store$get) ||
      !is.function(artifact_store$verify)) {
    cli::cli_abort("Export service requires a readable artifact store")
  }
  .validate_workspace_provider(workspace_provider)
  .validate_identity_provider(identity_provider)

  export_revision <- function(
    revision_id,
    actor_id,
    destination_id,
    expected_version,
    idempotency_key
  ) {
    .validate_identifier(revision_id, "revision_id")
    .validate_workspace_token(destination_id, "destination_id")
    .validate_identifier(idempotency_key, "idempotency_key")

    receipt_id <- .export_receipt_id(idempotency_key)
    prior <- repository$list_export_receipts(revision_id)
    prior <- prior[prior$receipt_id == receipt_id, , drop = FALSE]
    if (nrow(prior)) {
      return(invisible(as.list(prior[1, , drop = FALSE])))
    }

    actor <- identity_provider$get_actor(actor_id)
    .authorize_export_actor(actor)
    revision <- repository$get_revision(revision_id)
    .assert_exportable_revision(revision, expected_version)
    bundle <- repository$get_artifact_bundle(revision_id)

    code_bytes <- artifact_store$get(bundle$code_hash)
    image_bytes <- artifact_store$get(bundle$image_hash)
    export_id <- receipt_id

    published <- workspace_provider$inspect_published(destination_id, export_id)
    if (is.null(published)) {
      stage <- workspace_provider$stage_bundle(
        destination_id = destination_id,
        export_id = export_id,
        code_bytes = code_bytes,
        image_bytes = image_bytes
      )

      actor <- identity_provider$get_actor(actor_id)
      .authorize_export_actor(actor)
      current <- repository$get_revision(revision_id)
      .assert_exportable_revision(current, expected_version)
      if (!identical(current$code_hash, bundle$code_hash) ||
          !identical(current$image_hash, bundle$image_hash)) {
        workspace_provider$quarantine_staged(stage, "stale-revision")
        cli::cli_abort("The accepted artifact bundle no longer matches the revision")
      }
      published <- workspace_provider$publish_staged(stage)
    }

    if (!identical(published$code_hash, bundle$code_hash) ||
        !identical(published$image_hash, bundle$image_hash)) {
      cli::cli_abort("Published export hashes do not match the accepted bundle")
    }

    repository$record_export_receipt(
      receipt_id = receipt_id,
      revision_id = revision_id,
      destination_id = destination_id,
      code_hash = bundle$code_hash,
      image_hash = bundle$image_hash,
      idempotency_key = idempotency_key
    )
    invisible(c(
      list(receipt_id = receipt_id, revision_id = revision_id),
      published
    ))
  }

  structure(
    list(export_revision = export_revision),
    class = "export_service"
  )
}

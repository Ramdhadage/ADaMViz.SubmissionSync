.revision_evidence_id <- function(revision_id, evidence_type) {
  paste(
    "evidence",
    substr(canonical_hash(list(revision_id, evidence_type)), 1L, 24L),
    sep = "-"
  )
}

.record_revision_context_evidence <- function(state, request, runner_result) {
  if (is.null(state$repository) || is.null(state$revision)) {
    cli::cli_abort("Revision evidence requires a persisted revision")
  }
  revision <- state$repository$get_revision(state$revision$revision_id)
  details <- .revision_context_details(state, request, runner_result, revision)
  state$repository$record_evidence(
    evidence_id = .revision_evidence_id(revision$revision_id, "revision_context"),
    revision_id = revision$revision_id,
    evidence_type = "revision_context",
    outcome = "recorded",
    idempotency_key = paste0("evidence:revision-context:", revision$revision_id),
    details = details
  )
  invisible(details)
}

.revision_context_details <- function(state, request, runner_result, revision) {
  profile <- state$profile
  snapshot <- state$snapshot
  environment <- runner_result$environment %||% .execution_environment_details()
  environment$fingerprint <- runner_result$result$environment_fingerprint
  list(
    evidence_version = "revision-context-evidence-v1",
    revision = unclass(revision),
    prompt = state$prompt,
    specification = unclass(state$spec),
    input_data = list(
      dataset_id = snapshot$dataset_id,
      snapshot_id = snapshot$snapshot_id,
      snapshot_hash = request$snapshot_hash,
      content_hash = snapshot$content_hash,
      metadata_version = snapshot$metadata_version,
      classification = snapshot$classification,
      selected_data_columns = names(profile$selected_data),
      selected_data_classes = as.list(
        stats::setNames(
          vapply(
            profile$selected_data,
            \(column) class(column)[[1]],
            character(1)
          ),
          names(profile$selected_data)
        )
      ),
      selected_data = as.list(profile$selected_data)
    ),
    generated_r_code = state$script,
    request = unclass(request),
    execution_result = unclass(runner_result$result),
    environment = environment,
    checks = list(
      bds_profile_blocked = profile$blocked,
      verification = unclass(state$verification %||% list())
    ),
    rendered_output = list(
      image_hash = revision$image_hash,
      analytical_hash = revision$analytical_hash
    ),
    warnings = lapply(profile$warnings, unclass)
  )
}

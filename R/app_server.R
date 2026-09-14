#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @param runtime_config Injected runtime configuration.
#' @import shiny
#' @noRd
app_server <- function(input, output, session, runtime_config = new_runtime_config()) {
  output$runtime_profile <- renderText(runtime_config$profile)
  provider <- local_study_data_provider()
  catalog <- shiny::reactive(list_study_catalog(provider))
  current_revision <- shiny::reactiveVal(.empty_assurance_state())

  create_revision <- function(dataset_id, prompt, confirm_free_scale) {
    state <- .create_assurance_revision(
      provider = provider,
      dataset_id = dataset_id,
      prompt = prompt,
      confirm_free_scale = confirm_free_scale
    )
    current_revision(state)
    invisible(state)
  }

  mod_prompt_server("prompt", catalog, create_revision)
  mod_specification_server("specification", current_revision)
  mod_run_status_server("run_status", current_revision)
  mod_plot_preview_server("plot_preview", current_revision)
  mod_evidence_server("evidence", current_revision)
  mod_revision_history_server("revision_history", current_revision)
  mod_review_server("review", current_revision, current_revision)
}

.empty_assurance_state <- function() {
  list(
    plot_id = NULL,
    repository = NULL,
    review_service = NULL,
    revision = NULL,
    spec = NULL,
    profile = NULL,
    script = NULL,
    artifact = NULL,
    verification = NULL
  )
}

.create_assurance_revision <- function(provider, dataset_id, prompt, confirm_free_scale) {
  if (!checkmate::test_string(dataset_id, min.chars = 1L)) {
    cli::cli_abort("Select one authorized synthetic BDS scenario")
  }
  snapshot <- pin_study_snapshot(provider, dataset_id)
  interpretation <- interpret_prompt(
    prompt,
    build_prompt_context(snapshot),
    mock_prompt_interpreter(),
    snapshot = NULL
  )
  if (is.null(interpretation$candidate)) {
    cli::cli_abort(c(
      "The prompt could not create an executable candidate",
      "i" = "Reason: {.val {interpretation$clarifications$reason %||% interpretation$status}}"
    ))
  }
  if (identical(interpretation$candidate$fields$scale_mode, "free") &&
      !isTRUE(confirm_free_scale)) {
    cli::cli_abort(
      "Free Y scales require confirmation because they create an Experimental/Draft revision"
    )
  }

  spec <- confirm_plot_spec(interpretation$candidate)
  profile <- validate_bds_profile(
    snapshot,
    spec$fields[setdiff(.plot_spec_fields, c("dataset_id", "scale_mode"))]
  )
  if (profile$blocked) {
    diagnostic <- profile$blocking_diagnostics[[1]]
    cli::cli_abort(c(
      "The selected records are outside the supported BDS profile",
      "x" = "{diagnostic$code}: {diagnostic$message}"
    ))
  }

  script <- compile_boxplot_script(spec, profile$low_n_policy)
  request <- new_execution_request(
    spec = spec,
    script_hash = canonical_hash(script),
    snapshot_id = profile$snapshot_id,
    snapshot_hash = canonical_hash(profile$selected_data),
    harness_version = "execution-harness-v1"
  )
  runner_result <- run_execution_locally(
    request = request,
    script = script,
    analysis_data = profile$selected_data,
    data_classification = snapshot$classification
  )
  if (!identical(runner_result$status, "succeeded")) {
    cli::cli_abort(c(
      "The generated R script did not complete",
      "x" = runner_result$diagnostics$stderr
    ))
  }

  root <- fs::file_temp(pattern = "assurance-session-")
  artifact_store <- local_artifact_store(fs::path(root, "artifacts"))
  repository <- sqlite_evidence_repository(
    fs::path(root, "evidence.sqlite"),
    fs::path(root, "chain-root.json"),
    artifact_store
  )
  plot_id <- paste0("plot-", substr(spec$hash, 1L, 12L))
  revision_id <- paste0("rev-", substr(canonical_hash(list(spec$hash, Sys.time())), 1L, 12L))
  initial_status <- if (identical(spec$fields$scale_mode, "free")) {
    "Experimental/Draft"
  } else {
    "Draft"
  }

  code_hash <- artifact_store$put(charToRaw(canonical_serialize(enc2utf8(script))))
  image_hash <- artifact_store$put(readBin(
    runner_result$image_path,
    what = "raw",
    n = fs::file_size(runner_result$image_path)
  ))
  repository$create_revision(
    plot_id = plot_id,
    revision_id = revision_id,
    revision_number = 1L,
    creator_id = "creator",
    spec_hash = spec$hash,
    code_hash = code_hash,
    image_hash = image_hash,
    analytical_hash = runner_result$result$analytical_hash,
    idempotency_key = paste0("create:", revision_id),
    initial_status = initial_status
  )

  verification <- NULL
  if (identical(initial_status, "Draft")) {
    execution_service <- new_execution_service(
      repository,
      runner = new_execution_runner(function(...) runner_result),
      artifact_store = artifact_store
    )
    execution <- execution_service$submit(
      revision_id = revision_id,
      request = request,
      script = script,
      analysis_data = profile$selected_data,
      idempotency_key = paste0("execute:", revision_id),
      data_classification = snapshot$classification
    )
    verification <- execution$verification
  }

  identities <- local_identity_provider(list(
    new_actor("creator", "clinical_scientist"),
    new_actor("stat-programmer", "statistical_programmer"),
    new_actor("biostatistician", "biostatistician")
  ))
  analysis <- calculate_boxplot_statistics(
    profile$display_data,
    treatment_variable = spec$fields$treatment_variable,
    y_variable = spec$fields$y_variable,
    facet_levels = profile$facet_levels,
    visit_levels = profile$visit_levels,
    low_n_policy = profile$low_n_policy
  )
  artifact <- assemble_boxplot(
    analysis,
    scale_mode = spec$fields$scale_mode,
    unit = spec$fields$unit
  )

  list(
    plot_id = plot_id,
    repository = repository,
    review_service = new_review_service(repository, identities),
    revision = repository$get_revision(revision_id),
    spec = spec,
    profile = profile,
    script = script,
    artifact = artifact,
    verification = verification
  )
}

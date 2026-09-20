#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @param runtime_config Injected runtime configuration.
#' @import shiny
#' @noRd
app_server <- function(input, output, session, runtime_config = new_runtime_config()) {
  output$runtime_profile <- renderText(runtime_config$profile)
  workspace_root <- fs::path(
    fs::path_temp(),
    "adamviz-submissionsync-workspace",
    runtime_config$workspace
  )
  fs::dir_create(workspace_root, recurse = TRUE)
  workspace_provider <- local_workspace_provider(
    stats::setNames(workspace_root, runtime_config$workspace)
  )
  current_revision <- shiny::reactiveVal(.empty_assurance_state())
  execution_task <- new_async_task_service() |>
    bslib::bind_task_button("plot_generation-specification-execute") |>
    bslib::bind_task_button("plot_generation-specification-correct")

  shiny::observe({
    status <- execution_task$status()
    if (identical(status, "success")) {
      current_revision(execution_task$result())
    } else if (identical(status, "error")) {
      tryCatch(
        execution_task$result(),
        error = \(error) shiny::showNotification(
          conditionMessage(error),
          type = "error"
        )
      )
    }
  })

  execute_revision <- function(fields) {
    state <- current_revision()
    if (is.null(state$pending)) {
      cli::cli_abort("Create an inspectable specification before execution")
    }
    execution_task$invoke(list(
      function_name = ".execute_assurance_revision",
      args = list(
        snapshot = state$pending$snapshot,
        prompt = state$pending$prompt,
        fields = fields,
        repository_root = fs::file_temp(pattern = "assurance-session-")
      )
    ))
    invisible(state)
  }

  create_correction <- function(fields, rationale, provenance) {
    state <- current_revision()
    execution_task$invoke(list(
      function_name = ".execute_correction_revision",
      args = list(
        state = state,
        fields = fields,
        rationale = rationale,
        provenance = provenance
      )
    ))
    invisible(state)
  }

  mod_plot_generation_server(
    "plot_generation",
    current_revision = current_revision,
    execute_revision = execute_revision,
    create_correction = create_correction,
    execution_status = execution_task$status,
    workspace_provider = workspace_provider
  )
}

.empty_assurance_state <- function() {
  list(
    pending = NULL,
    plot_id = NULL,
    repository = NULL,
    identity_provider = NULL,
    review_service = NULL,
    revision = NULL,
    spec = NULL,
    snapshot = NULL,
    prompt = NULL,
    choices = NULL,
    profile = NULL,
    script = NULL,
    artifact = NULL,
    verification = NULL
  )
}

.create_assurance_candidate <- function(provider, dataset_id, prompt, suggest = TRUE) {
  if (!checkmate::test_string(dataset_id, min.chars = 1L)) {
    cli::cli_abort("Select one authorized BDS dataset")
  }
  snapshot <- pin_study_snapshot(provider, dataset_id)
  if (!is.null(provider$source_metadata)) {
    snapshot$source_metadata <- provider$source_metadata
  }
  context <- build_prompt_context(snapshot)
  interpretation <- if (isTRUE(suggest)) {
    interpret_prompt(prompt, context, mock_prompt_interpreter(), snapshot = NULL)
  } else {
    list(status = "manual_selection", candidate = NULL, clarifications = list(), metadata = list())
  }
  if (is.null(interpretation$candidate) &&
      !interpretation$status %in% c("clarification", "manual_selection")) {
    cli::cli_abort(c(
      "The prompt could not create an executable candidate",
      "i" = "Reason: {.val {interpretation$clarifications$reason %||% interpretation$status}}"
    ))
  }

  spec <- interpretation$candidate %||% new_plot_spec(dataset_id = dataset_id)
  choices <- .spec_choices_from_context(context)
  list(
    pending = list(
      snapshot = snapshot,
      prompt = prompt,
      interpretation = interpretation,
      choices = choices
    ),
    plot_id = NULL,
    repository = NULL,
    identity_provider = NULL,
    review_service = NULL,
    revision = NULL,
    spec = spec,
    snapshot = snapshot,
    prompt = prompt,
    choices = choices,
    profile = NULL,
    script = NULL,
    artifact = NULL,
    verification = NULL
  )
}

.spec_choices_from_context <- function(context) {
  profile <- context$aggregate_profile
  list(
    parameters = names(profile$parameters),
    units = lapply(profile$parameters, `[[`, "units"),
    y_variables = profile$y_variables,
    treatment_variables = profile$treatment_variables,
    treatment_levels = profile$treatment_levels,
    visits = vapply(profile$visits, `[[`, "", "label"),
    scale_modes = profile$scale_modes
  )
}

.execute_assurance_revision <- function(
  snapshot,
  prompt,
  fields,
  repository_root = NULL
) {
  spec <- .confirmed_spec_from_fields(snapshot$dataset_id, fields)
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
  .materialize_revision(snapshot, prompt, spec, profile, repository_root)
}

.execute_correction_revision <- function(state, fields, rationale, provenance) {
  if (is.null(state$repository) || is.null(state$revision) ||
      is.null(state$snapshot)) {
    cli::cli_abort("Create a revision before starting a correction")
  }
  parent <- state$repository$get_revision(state$revision$revision_id)
  if (!parent$status %in% c("Rejected", "Reviewed")) {
    cli::cli_abort("Only a Rejected or Reviewed revision can start a correction")
  }
  if (!checkmate::test_string(rationale, min.chars = 1L) ||
      !checkmate::test_string(provenance, min.chars = 1L)) {
    cli::cli_abort("Correction rationale and provenance are required")
  }
  spec <- .confirmed_spec_from_fields(state$snapshot$dataset_id, fields)
  profile <- validate_bds_profile(
    state$snapshot,
    spec$fields[setdiff(.plot_spec_fields, c("dataset_id", "scale_mode"))]
  )
  if (profile$blocked) {
    diagnostic <- profile$blocking_diagnostics[[1]]
    cli::cli_abort(c(
      "The selected records are outside the supported BDS profile",
      "x" = "{diagnostic$code}: {diagnostic$message}"
    ))
  }

  .materialize_correction_revision(
    state,
    spec,
    profile,
    rationale,
    provenance
  )
}

.create_assurance_revision <- function(provider, dataset_id, prompt, confirm_free_scale) {
  snapshot <- pin_study_snapshot(provider, dataset_id)
  context <- build_prompt_context(snapshot)
  interpretation <- interpret_prompt(prompt, context, mock_prompt_interpreter(), snapshot = NULL)
  if (is.null(interpretation$candidate)) {
    cli::cli_abort("The prompt could not create an executable candidate")
  }
  fields <- interpretation$candidate$fields
  if (identical(fields$scale_mode, "free") && !isTRUE(confirm_free_scale)) {
    cli::cli_abort(
      "Free Y scales require confirmation because they create an Experimental/Draft revision"
    )
  }
  .execute_assurance_revision(snapshot, prompt, fields)
}

.confirmed_spec_from_fields <- function(dataset_id, fields) {
  if (!checkmate::test_string(fields$paramcd, min.chars = 1L) ||
      !checkmate::test_choice(fields$y_variable, c("AVAL", "CHG", "PCHG")) ||
      !checkmate::test_string(fields$unit, min.chars = 1L) ||
      !checkmate::test_string(fields$treatment_variable, min.chars = 1L) ||
      !checkmate::test_character(fields$treatment_levels, min.len = 1L, any.missing = FALSE, unique = TRUE) ||
      !checkmate::test_character(fields$visits, min.len = 1L, any.missing = FALSE, unique = TRUE)) {
    cli::cli_abort("Confirm one parameter, one Y variable, one unit, one treatment facet, and at least one treatment level and visit")
  }
  provenance <- as.list(stats::setNames(
    rep("user_confirmed", length(.plot_spec_fields)),
    .plot_spec_fields
  ))
  provenance$dataset_id <- "metadata"
  spec <- new_plot_spec(
    dataset_id = dataset_id,
    paramcd = fields$paramcd,
    y_variable = fields$y_variable,
    unit = fields$unit,
    treatment_variable = fields$treatment_variable,
    treatment_levels = fields$treatment_levels,
    visits = fields$visits,
    scale_mode = fields$scale_mode %||% "fixed",
    provenance = as.list(provenance),
    state = "candidate"
  )
  confirm_plot_spec(spec)
}

.materialize_revision <- function(
  snapshot,
  prompt,
  spec,
  profile,
  repository_root = NULL
) {
  script <- compile_boxplot_script(spec, profile$low_n_policy)
  request <- new_execution_request(
    spec = spec,
    script_hash = .execution_hash_text(script),
    snapshot_id = profile$snapshot_id,
    snapshot_hash = canonical_hash(profile$selected_data),
    harness_version = "execution-harness-v1"
  )
  root <- repository_root %||% fs::file_temp(pattern = "assurance-session-")
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

  code_hash <- artifact_store$put(.execution_text_bytes(script))
  repository$create_revision(
    plot_id = plot_id,
    revision_id = revision_id,
    revision_number = 1L,
    creator_id = "creator",
    spec_hash = spec$hash,
    code_hash = code_hash,
    image_hash = NULL,
    analytical_hash = NULL,
    idempotency_key = paste0("create:", revision_id),
    initial_status = initial_status
  )

  verification <- NULL
  if (identical(initial_status, "Draft")) {
    execution_service <- new_execution_service(
      repository,
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
    runner_result <- execution$runner_result
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
  context <- build_prompt_context(snapshot)

  state <- list(
    pending = NULL,
    plot_id = plot_id,
    repository = repository,
    identity_provider = identities,
    review_service = new_review_service(repository, identities),
    revision = repository$get_revision(revision_id),
    spec = spec,
    snapshot = snapshot,
    prompt = prompt,
    choices = .spec_choices_from_context(context),
    profile = profile,
    script = script,
    artifact = artifact,
    verification = verification
  )
  if (!is.null(verification)) {
    .record_revision_context_evidence(
      state,
      request = request,
      runner_result = runner_result
    )
  }
  state
}

.materialize_correction_revision <- function(
  state,
  spec,
  profile,
  rationale,
  provenance
) {
  script <- compile_boxplot_script(spec, profile$low_n_policy)
  request <- new_execution_request(
    spec = spec,
    script_hash = .execution_hash_text(script),
    snapshot_id = profile$snapshot_id,
    snapshot_hash = canonical_hash(profile$selected_data),
    harness_version = "execution-harness-v1"
  )
  artifact_store <- state$repository$artifact_store
  if (is.null(artifact_store)) {
    cli::cli_abort("Correction revisions require an artifact store")
  }
  parent <- state$repository$get_revision(state$revision$revision_id)
  revisions <- state$repository$list_revisions(parent$plot_id)
  revision_number <- max(revisions$revision_number) + 1L
  revision_id <- paste0("rev-", substr(canonical_hash(list(
    parent$revision_id,
    spec$hash,
    revision_number,
    Sys.time()
  )), 1L, 12L))
  code_hash <- artifact_store$put(.execution_text_bytes(script))
  lifecycle <- new_lifecycle_service(state$repository)
  lifecycle$create_correction(
    parent_revision_id = parent$revision_id,
    revision_id = revision_id,
    creator_id = "creator",
    spec_hash = spec$hash,
    code_hash = code_hash,
    image_hash = NULL,
    analytical_hash = NULL,
    rationale = rationale,
    provenance = provenance,
    idempotency_key = paste0("correct:", revision_id),
    initial_status = .initial_revision_status(spec$fields$scale_mode)
  )

  verification <- NULL
  if (identical(spec$fields$scale_mode, "fixed")) {
    execution <- new_execution_service(
      state$repository,
      artifact_store = artifact_store
    )$submit(
      revision_id = revision_id,
      request = request,
      script = script,
      analysis_data = profile$selected_data,
      idempotency_key = paste0("execute:", revision_id),
      data_classification = state$snapshot$classification
    )
    verification <- execution$verification
    runner_result <- execution$runner_result
  }

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

  state$pending <- NULL
  state$revision <- state$repository$get_revision(revision_id)
  state$spec <- spec
  state$profile <- profile
  state$script <- script
  state$artifact <- artifact
  state$verification <- verification
  if (!is.null(verification)) {
    .record_revision_context_evidence(
      state,
      request = request,
      runner_result = runner_result
    )
  }
  state
}

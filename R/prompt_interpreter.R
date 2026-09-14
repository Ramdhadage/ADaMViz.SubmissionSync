.validate_prompt_context <- function(context) {
  if (!inherits(context, "prompt_context")) {
    cli::cli_abort("{.arg context} must be a {.cls prompt_context}")
  }
  invisible(context)
}

.validate_prompt_interpreter <- function(interpreter) {
  if (!inherits(interpreter, "prompt_interpreter")) {
    cli::cli_abort("{.arg interpreter} must be a {.cls prompt_interpreter}")
  }
  invisible(interpreter)
}

#' Interpret a prompt through a provider-neutral adapter
#'
#' @param prompt One natural-language request.
#' @param context A `prompt_context`.
#' @param interpreter A prompt interpreter, such as `mock_prompt_interpreter()`.
#' @param snapshot Optional pinned snapshot used for U3 semantic validation.
#'
#' @return A `prompt_interpretation` with status, candidate, choices, and
#'   provider metadata. It never includes executable code.
#' @export
interpret_prompt <- function(prompt, context, interpreter, snapshot = NULL) {
  if (!checkmate::test_string(prompt, min.chars = 1L)) {
    cli::cli_abort("{.arg prompt} must be one non-empty string")
  }
  .validate_prompt_context(context)
  .validate_prompt_interpreter(interpreter)

  blocked <- .detect_blocked_prompt(prompt)
  if (!is.null(blocked)) {
    return(.prompt_interpretation(
      status = "manual_selection",
      candidate = NULL,
      clarifications = list(reason = blocked),
      metadata = list(provider = interpreter$provider, provider_called = FALSE)
    ))
  }

  raw <- interpreter$interpret(prompt = prompt, context = context)
  result <- .normalize_prompt_provider_result(raw, context, interpreter)
  if (identical(result$status, "candidate") && !is.null(snapshot)) {
    .validate_interpreted_candidate(result$candidate, snapshot)
  }
  result
}

.detect_blocked_prompt <- function(prompt) {
  checks <- c(
    arbitrary_r_deferred = paste(
      "\\b(run|write|execute|compile)\\b.*\\b(r|code|script)\\b",
      "\\b(log[- ]?transform|transform|derive|calculate|compute|mutate|normaliz\\w*|standardiz\\w*)\\b",
      "\\b(AVAL|CHG|PCHG)\\b\\s*[-+*/^]",
      "[-+*/^]\\s*\\b(AVAL|CHG|PCHG)\\b",
      "library\\s*\\(|ggplot\\s*\\(|system\\s*\\(",
      sep = "|"
    ),
    prompt_injection = "ignore (all )?(previous|system)|developer message|tool instruction",
    path_or_url = "https?://|[A-Za-z]:[\\\\/]|\\\\\\\\|\\.rds\\b|\\.csv\\b",
    sensitive_content = "USUBJID|patient|secret|credential|workspace"
  )
  matched <- names(checks)[vapply(checks, grepl, logical(1), x = prompt, ignore.case = TRUE)]
  if (length(matched)) matched[[1]] else NULL
}

.normalize_prompt_provider_result <- function(raw, context, interpreter) {
  allowed <- c("status", "fields", "clarifications", "required_confirmations", "metadata")
  extras <- setdiff(names(raw), allowed)
  if (length(extras)) {
    return(.prompt_interpretation(
      status = "manual_selection",
      candidate = NULL,
      clarifications = list(reason = "extra_provider_fields"),
      metadata = list(provider = interpreter$provider, provider_called = TRUE)
    ))
  }
  if (!checkmate::test_choice(raw$status, c("candidate", "clarification", "manual_selection"))) {
    return(.prompt_interpretation(
      status = "manual_selection",
      candidate = NULL,
      clarifications = list(reason = "malformed_provider_response"),
      metadata = list(provider = interpreter$provider, provider_called = TRUE)
    ))
  }
  if (!identical(raw$status, "candidate")) {
    return(.prompt_interpretation(
      status = raw$status,
      candidate = NULL,
      clarifications = raw$clarifications %||% list(reason = raw$status),
      metadata = c(list(provider = interpreter$provider, provider_called = TRUE), raw$metadata %||% list())
    ))
  }

  fields <- raw$fields
  field_extras <- setdiff(names(fields), .plot_spec_fields)
  if (length(field_extras)) {
    return(.prompt_interpretation(
      status = "manual_selection",
      candidate = NULL,
      clarifications = list(reason = "extra_candidate_fields"),
      metadata = list(provider = interpreter$provider, provider_called = TRUE)
    ))
  }
  candidate <- new_plot_spec(
    dataset_id = context$dataset_id,
    paramcd = fields$paramcd %||% NULL,
    y_variable = fields$y_variable %||% NULL,
    unit = fields$unit %||% NULL,
    treatment_variable = fields$treatment_variable %||% NULL,
    treatment_levels = fields$treatment_levels %||% NULL,
    visits = fields$visits %||% NULL,
    scale_mode = fields$scale_mode %||% "fixed",
    provenance = .candidate_provenance(fields),
    state = "candidate"
  )
  clarifications <- plot_spec_clarifications(candidate)
  status <- if (length(clarifications) || length(raw$required_confirmations %||% list())) {
    "clarification"
  } else {
    "candidate"
  }
  .prompt_interpretation(
    status = status,
    candidate = candidate,
    clarifications = list(
      missing_fields = clarifications,
      required_confirmations = raw$required_confirmations %||% list()
    ),
    metadata = c(
      list(
        provider = interpreter$provider,
        model = interpreter$model,
        provider_called = TRUE,
        interpreter_version = "prompt-interpreter-v1",
        schema_version = "plot-spec-v1",
        response_retention = "none"
      ),
      raw$metadata %||% list()
    )
  )
}

.candidate_provenance <- function(fields) {
  provenance <- rep("prompt", length(fields))
  names(provenance) <- names(fields)
  provenance <- as.list(provenance)
  provenance$dataset_id <- "metadata"
  if (is.null(fields$scale_mode)) provenance$scale_mode <- "default"
  provenance
}

.validate_interpreted_candidate <- function(candidate, snapshot) {
  selections <- candidate$fields[setdiff(.plot_spec_fields, c("dataset_id", "scale_mode"))]
  result <- validate_bds_profile(snapshot, selections)
  if (result$blocked) {
    cli::cli_abort("The interpreted candidate does not satisfy the supported BDS profile")
  }
  invisible(candidate)
}

.prompt_interpretation <- function(status, candidate, clarifications, metadata) {
  structure(
    list(
      version = "prompt-interpretation-v1",
      status = status,
      candidate = candidate,
      clarifications = clarifications,
      metadata = metadata,
      executable_code = NULL
    ),
    class = "prompt_interpretation"
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

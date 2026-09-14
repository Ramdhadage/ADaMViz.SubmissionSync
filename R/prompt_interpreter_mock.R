#' Create a deterministic prompt interpreter for tests and local development
#'
#' @return A provider-neutral `prompt_interpreter`.
#' @export
mock_prompt_interpreter <- function() {
  structure(
    list(
      port = new_provider_port("prompt_interpreter", c("structured_candidate", "clarification")),
      provider = "deterministic-mock",
      model = "mock-rule-set-v1",
      interpret = .mock_interpret_prompt
    ),
    class = "prompt_interpreter"
  )
}

.mock_interpret_prompt <- function(prompt, context) {
  profile <- context$aggregate_profile
  parameters <- profile$parameters
  paramcd <- .mock_match_parameter(prompt, parameters)
  if (is.null(paramcd)) {
    return(list(
      status = "clarification",
      clarifications = list(field = "paramcd", choices = names(parameters))
    ))
  }
  units <- parameters[[paramcd]]$units
  unit <- .mock_match_value(prompt, units)
  if (is.null(unit) && length(units) == 1L) unit <- units[[1]]

  treatment_variable <- profile$treatment_variables[[1]]
  treatment_levels <- profile$treatment_levels[[treatment_variable]]
  included_treatment_levels <- .mock_exclude_values(prompt, treatment_levels)
  visits <- vapply(profile$visits, `[[`, "", "label")
  included_visits <- .mock_exclude_values(prompt, visits)
  scale_mode <- if (grepl("free[- ]?scale|free y|separate scale", prompt, ignore.case = TRUE)) {
    "free"
  } else {
    "fixed"
  }
  required_confirmations <- if (identical(scale_mode, "free")) {
    list(scale_mode = "Free scales create an Experimental/Draft candidate")
  } else {
    list()
  }
  clarifications <- if (length(units) > 1L && is.null(unit)) {
    list(field = "unit", choices = units)
  } else {
    list()
  }

  list(
    status = "candidate",
    fields = list(
      paramcd = paramcd,
      y_variable = .mock_y_variable(prompt, profile$y_variables),
      unit = unit,
      treatment_variable = treatment_variable,
      treatment_levels = included_treatment_levels,
      visits = included_visits,
      scale_mode = scale_mode
    ),
    clarifications = clarifications,
    required_confirmations = required_confirmations,
    metadata = list(prompt_template = "mock-prompt-template-v1")
  )
}

.mock_match_parameter <- function(prompt, parameters) {
  matches <- names(parameters)[vapply(names(parameters), function(paramcd) {
    grepl(paste0("\\b", paramcd, "\\b"), prompt, ignore.case = TRUE) ||
      grepl(tolower(parameters[[paramcd]]$label), tolower(prompt), fixed = TRUE)
  }, logical(1))]
  if (length(matches) == 1L) matches[[1]] else NULL
}

.mock_match_value <- function(prompt, values) {
  matches <- values[vapply(tolower(values), grepl, logical(1), x = tolower(prompt), fixed = TRUE)]
  if (length(matches) == 1L) matches[[1]] else NULL
}

.mock_y_variable <- function(prompt, choices) {
  if ("PCHG" %in% choices && grepl("percent|percentage|pct|PCHG", prompt, ignore.case = TRUE)) {
    return("PCHG")
  }
  if ("CHG" %in% choices && grepl("change|CHG", prompt, ignore.case = TRUE)) {
    return("CHG")
  }
  "AVAL"
}

.mock_exclude_values <- function(prompt, values) {
  kept <- values
  for (value in values) {
    pattern <- paste0("\\b(exclude|without|omit)\\b[^.]*\\b", gsub(" ", "\\\\s+", value), "\\b")
    if (grepl(pattern, prompt, ignore.case = TRUE)) {
      kept <- setdiff(kept, value)
    }
  }
  kept
}

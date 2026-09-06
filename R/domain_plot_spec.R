.plot_spec_fields <- c(
  "dataset_id", "paramcd", "y_variable", "unit", "treatment_variable",
  "treatment_levels", "visits", "scale_mode"
)

new_plot_spec <- function(
  dataset_id,
  paramcd = NULL,
  y_variable = NULL,
  unit = NULL,
  treatment_variable = NULL,
  treatment_levels = NULL,
  visits = NULL,
  scale_mode = "fixed",
  provenance = list(),
  state = c("candidate", "confirmed")
) {
  state <- match.arg(state)
  if (!checkmate::test_string(dataset_id, min.chars = 1)) {
    cli::cli_abort("{.arg dataset_id} must be one non-empty identifier")
  }
  if (!is.null(y_variable) && !checkmate::test_choice(
    y_variable,
    choices = c("AVAL", "CHG", "PCHG")
  )) {
    cli::cli_abort("{.arg y_variable} must be one of {.val {c('AVAL', 'CHG', 'PCHG')}}")
  }
  if (!checkmate::test_choice(scale_mode, choices = c("fixed", "free"))) {
    cli::cli_abort("{.arg scale_mode} must be {.val fixed} or {.val free}")
  }
  unknown_provenance <- setdiff(names(provenance), .plot_spec_fields)
  if (length(unknown_provenance)) {
    cli::cli_abort("Unknown provenance field{?s}: {.field {unknown_provenance}}")
  }
  invalid_sources <- unlist(provenance, use.names = FALSE)
  if (length(invalid_sources) && any(!invalid_sources %in% c(
    "prompt", "metadata", "default", "user_confirmed"
  ))) {
    cli::cli_abort("Provenance values must be prompt, metadata, default, or user_confirmed")
  }

  fields <- list(
    dataset_id = dataset_id,
    paramcd = paramcd,
    y_variable = y_variable,
    unit = unit,
    treatment_variable = treatment_variable,
    treatment_levels = treatment_levels,
    visits = visits,
    scale_mode = scale_mode
  )
  structure(
    list(
      schema_version = "plot-spec-v1",
      state = state,
      fields = fields,
      provenance = provenance,
      hash = canonical_hash(list(fields = fields, provenance = provenance))
    ),
    class = "plot_spec"
  )
}

plot_spec_clarifications <- function(spec) {
  .validate_plot_spec(spec)
  required <- .plot_spec_fields[.plot_spec_fields != "scale_mode"]
  required[vapply(spec$fields[required], is.null, logical(1))]
}

confirm_plot_spec <- function(spec) {
  missing_fields <- plot_spec_clarifications(spec)
  if (length(missing_fields)) {
    cli::cli_abort("The plot specification needs clarification for {.field {missing_fields}}")
  }
  unconfirmed <- setdiff(.plot_spec_fields, names(spec$provenance))
  if (length(unconfirmed)) {
    cli::cli_abort("The plot specification lacks provenance for {.field {unconfirmed}}")
  }
  new_plot_spec(
    dataset_id = spec$fields$dataset_id,
    paramcd = spec$fields$paramcd,
    y_variable = spec$fields$y_variable,
    unit = spec$fields$unit,
    treatment_variable = spec$fields$treatment_variable,
    treatment_levels = spec$fields$treatment_levels,
    visits = spec$fields$visits,
    scale_mode = spec$fields$scale_mode,
    provenance = spec$provenance,
    state = "confirmed"
  )
}

.validate_plot_spec <- function(spec) {
  if (!inherits(spec, "plot_spec")) {
    cli::cli_abort("{.arg spec} must be a {.cls plot_spec}")
  }
  invisible(spec)
}

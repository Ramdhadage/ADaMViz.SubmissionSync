.r_string_literal <- function(value) {
  encodeString(value, quote = '"', na.encode = FALSE)
}

.r_character_literal <- function(values) {
  if (!length(values)) {
    return("character()")
  }
  paste0("c(", paste(vapply(values, .r_string_literal, character(1)), collapse = ", "), ")")
}

.r_policy_literal <- function(policy) {
  paste0(
    "list(value = ", canonical_serialize(as.numeric(policy$value)), ", ",
    "rationale = ", .r_string_literal(policy$rationale), ", ",
    "authority = ", .r_string_literal(policy$authority), ", ",
    "version = ", .r_string_literal(policy$version), ")"
  )
}

#' Compile the deterministic governed boxplot script
#'
#' The returned script expects the controlled runner to provide the validated,
#' pinned selected records as `analysis_data`. It contains resolved literals and
#' package-qualified calls only.
#'
#' @param spec A confirmed `plot_spec`.
#' @param low_n_policy Retained policy with `value`, `rationale`, `authority`,
#'   and `version`.
#'
#' @return A length-one UTF-8 R script.
#' @export
compile_boxplot_script <- function(spec, low_n_policy) {
  .validate_plot_spec(spec)
  if (!identical(spec$state, "confirmed")) {
    cli::cli_abort("Only a confirmed plot specification can be compiled")
  }
  .validate_boxplot_design(
    spec$fields$treatment_levels,
    spec$fields$visits,
    low_n_policy
  )
  lines <- c(
    "boxplot_analysis <- ADaMViz.SubmissionSync::calculate_boxplot_statistics(",
    "  data = analysis_data,",
    paste0("  treatment_variable = ", .r_string_literal(spec$fields$treatment_variable), ","),
    paste0("  y_variable = ", .r_string_literal(spec$fields$y_variable), ","),
    paste0("  facet_levels = ", .r_character_literal(spec$fields$treatment_levels), ","),
    paste0("  visit_levels = ", .r_character_literal(spec$fields$visits), ","),
    paste0("  low_n_policy = ", .r_policy_literal(low_n_policy)),
    ")",
    "",
    "boxplot_artifact <- ADaMViz.SubmissionSync::assemble_boxplot(",
    "  analysis = boxplot_analysis,",
    paste0("  scale_mode = ", .r_string_literal(spec$fields$scale_mode), ","),
    paste0("  unit = ", .r_string_literal(spec$fields$unit)),
    ")",
    "",
    "boxplot_artifact$combined"
  )
  enc2utf8(paste0(paste(lines, collapse = "\n"), "\n"))
}

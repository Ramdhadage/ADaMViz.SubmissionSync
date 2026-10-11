.standalone_script_expressions <- function(spec, low_n_policy) {
  calculate_expression <- rlang::call2(
    "<-",
    rlang::sym("calculate_boxplot_statistics"),
    rlang::call2(
      "function",
      formals(.standalone_boxplot_stats), # nolint: object_usage_linter.
      body(.standalone_boxplot_stats) # nolint: object_usage_linter.
    )
  )
  assemble_expression <- rlang::call2(
    "<-",
    rlang::sym("assemble_boxplot"),
    rlang::call2(
      "function",
      formals(.standalone_assemble_boxplot),
      body(.standalone_assemble_boxplot)
    )
  )
  treatment_variable <- spec$fields$treatment_variable
  y_variable <- spec$fields$y_variable
  facet_levels <- spec$fields$treatment_levels
  visit_levels <- spec$fields$visits
  scale_mode <- spec$fields$scale_mode
  unit <- spec$fields$unit
  list(
    calculate_expression,
    assemble_expression,
    rlang::expr(boxplot_analysis <- calculate_boxplot_statistics(
      data = !!rlang::sym("analysis_data"),
      treatment_variable = !!treatment_variable,
      y_variable = !!y_variable,
      facet_levels = !!facet_levels,
      visit_levels = !!visit_levels,
      low_n_policy = list(
        value = !!as.numeric(low_n_policy$value),
        rationale = !!low_n_policy$rationale,
        authority = !!low_n_policy$authority,
        version = !!low_n_policy$version
      )
    )),
    rlang::expr(boxplot_artifact <- assemble_boxplot(
      analysis = boxplot_analysis,
      scale_mode = !!scale_mode,
      unit = !!unit
    )),
    rlang::expr(if (sys.nframe() == 0L) print(boxplot_artifact$combined))
  )
}

#' Compile the deterministic governed boxplot script
#'
#' The controlled runner provides validated selected records as `analysis_data`.
#' The caller must supply `analysis_data`. The script contains resolved
#' literals, inlined helpers, and uses `ggplot2`, `cli`, and `patchwork`.
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
  script_expressions <- .standalone_script_expressions(spec, low_n_policy)
  script_text <- vapply(
    script_expressions,
    \(expression) rlang::expr_text(expression, width = 80L),
    character(1)
  )
  lines <- c(
    "# Boxplot Analysis Script",
    "# Required packages: ggplot2, cli, patchwork",
    "# The generated script does not require the source application package.",
    "# Source this script after defining analysis_data.",
    "",
    "library(ggplot2)",
    "library(cli)",
    "library(patchwork)",
    "",
    "# Data loading ----",
    "if (!exists(\"analysis_data\", inherits = FALSE)) {",
    "  stop(\"analysis_data must be supplied\", call. = FALSE)",
    "}",
    "",
    "# Analysis and plotting functions ----",
    script_text[1:2],
    "",
    "# Execute analysis ----",
    script_text[3:5]
  )
  enc2utf8(paste0(paste(lines, collapse = "\n"), "\n"))
}

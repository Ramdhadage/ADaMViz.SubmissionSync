.standalone_script_expressions <- function(spec, low_n_policy) {
  calculate_expression <- rlang::call2(
    "<-",
    rlang::sym(".standalone_calculate_boxplot_statistics"),
    rlang::call2(
      "function",
      formals(.standalone_calculate_boxplot_statistics),
      body(.standalone_calculate_boxplot_statistics)
    )
  )
  assemble_expression <- rlang::call2(
    "<-",
    rlang::sym(".standalone_assemble_boxplot"),
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
    rlang::expr(boxplot_analysis <- .standalone_calculate_boxplot_statistics(
      data = analysis_data,
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
    rlang::expr(boxplot_artifact <- .standalone_assemble_boxplot(
      analysis = boxplot_analysis,
      scale_mode = !!scale_mode,
      unit = !!unit
    )),
    rlang::expr(boxplot_artifact$combined)
  )
}

#' Compile the deterministic governed boxplot script
#'
#' The returned script expects the controlled runner to provide the validated,
#' pinned selected records as `analysis_data`. It contains resolved literals,
#' inlined helpers, and `ggplot2` and `cli` as its external R packages.
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
  lines <- c(
    "# Required R packages: ggplot2 and cli.",
    "# The generated script does not require the source application package.",
    "# Run with: Rscript --vanilla boxplot_script.R",
    "if (!requireNamespace(\"ggplot2\", quietly = TRUE)) install.packages(\"ggplot2\", repos = \"https://cloud.r-project.org\")",
    "if (!requireNamespace(\"cli\", quietly = TRUE)) install.packages(\"cli\", repos = \"https://cloud.r-project.org\")",
    "",
    "# Run locally by uncommenting and updating the data path below.",
    "# analysis_data <- read.csv(\"D:/R shiny Apps/ADaMViz.SubmissionSync/inst/extdata/synthetic/adlb-standard.csv\", stringsAsFactors = FALSE)",
    "",
    unlist(lapply(script_expressions, rlang::expr_text, width = 500L), use.names = FALSE)
  )
  enc2utf8(paste0(paste(lines, collapse = "\n"), "\n"))
}

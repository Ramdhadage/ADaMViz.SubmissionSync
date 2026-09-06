.factor_boxplot_layers <- function(analysis) {
  layers <- analysis[c("boxes", "outliers", "medians", "n_strip")]
  layers <- lapply(layers, function(data) {
    data$treatment <- factor(data$treatment, levels = analysis$facet_levels)
    data$visit <- factor(data$visit, levels = analysis$visit_levels)
    data
  })
  layers$n_strip$fontface <- ifelse(layers$n_strip$low_n, "bold", "plain")
  layers
}

#' Assemble the governed boxplot and aligned N strip
#'
#' Uses the independent analytical object as identity statistics, preserving
#' treatment facets and global visit positions in both panels.
#'
#' @param analysis A `boxplot_analysis` object.
#' @param scale_mode Either `"fixed"` or `"free"` for facet Y scales.
#' @param unit Optional selected unit appended to the Y-axis label.
#'
#' @return A `boxplot_artifact` containing plot, N strip, composition, and data.
#' @export
assemble_boxplot <- function(analysis, scale_mode = c("fixed", "free"), unit = NULL) {
  if (!inherits(analysis, "boxplot_analysis")) {
    cli::cli_abort("{.arg analysis} must be a {.cls boxplot_analysis}")
  }
  scale_mode <- match.arg(scale_mode)
  plot_data <- .factor_boxplot_layers(analysis)
  y_label <- if (is.null(unit) || !nzchar(unit)) {
    analysis$y_variable
  } else {
    paste0(analysis$y_variable, " (", unit, ")")
  }
  facet_scales <- if (identical(scale_mode, "free")) "free_y" else "fixed"

  plot <- ggplot2::ggplot(
    plot_data$boxes,
    ggplot2::aes(
      x = visit,
      ymin = ymin,
      lower = lower,
      middle = middle,
      upper = upper,
      ymax = ymax
    )
  ) +
    ggplot2::geom_boxplot(stat = "identity", outlier.shape = NA) +
    ggplot2::geom_line(
      data = plot_data$medians,
      mapping = ggplot2::aes(x = visit, y = median, group = treatment),
      inherit.aes = FALSE
    ) +
    ggplot2::geom_point(
      data = plot_data$medians,
      mapping = ggplot2::aes(x = visit, y = median),
      inherit.aes = FALSE
    ) +
    ggplot2::geom_point(
      data = plot_data$outliers,
      mapping = ggplot2::aes(x = visit, y = value),
      inherit.aes = FALSE,
      shape = 1
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(treatment),
      scales = facet_scales,
      drop = FALSE
    ) +
    ggplot2::scale_x_discrete(drop = FALSE, limits = analysis$visit_levels) +
    ggplot2::labs(x = NULL, y = y_label) +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())

  n_strip <- ggplot2::ggplot(
    plot_data$n_strip,
    ggplot2::aes(x = visit, y = 1, label = label, fontface = fontface)
  ) +
    ggplot2::geom_text(na.rm = TRUE, size = 3) +
    ggplot2::scale_discrete_identity(aesthetics = "fontface") +
    ggplot2::facet_wrap(ggplot2::vars(treatment), drop = FALSE) +
    ggplot2::scale_x_discrete(drop = FALSE, limits = analysis$visit_levels) +
    ggplot2::scale_y_continuous(limits = c(0.5, 1.5)) +
    ggplot2::labs(x = "Analysis visit", y = NULL) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      strip.text = ggplot2::element_blank()
    )

  structure(
    list(
      artifact_version = "boxplot-artifact-v1",
      status = .initial_revision_status(scale_mode),
      warning = if (identical(scale_mode, "free")) {
        "Free Y scales weaken cross-facet visual comparison."
      } else {
        NULL
      },
      scale_mode = scale_mode,
      analysis = analysis,
      plot_data = plot_data,
      plot = plot,
      n_strip = n_strip,
      combined = patchwork::wrap_plots(plot, n_strip, ncol = 1L, heights = c(4, 1))
    ),
    class = "boxplot_artifact"
  )
}

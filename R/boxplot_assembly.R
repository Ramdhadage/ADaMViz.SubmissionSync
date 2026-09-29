.factor_boxplot_layers <- function(analysis) {
  layers <- analysis[c("boxes", "outliers", "medians", "n_strip")]
  layers <- lapply(layers, function(data) {
    data$treatment <- factor(data$treatment, levels = analysis$facet_levels)
    data$visit <- factor(data$visit, levels = analysis$visit_levels)
    data
  })
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
    ggplot2::geom_boxplot(
      stat = "identity", outlier.shape = NA, fill = "white", color = "black", linewidth = 0.6
    ) +
    ggplot2::geom_line(
      data = plot_data$medians,
      mapping = ggplot2::aes(x = visit, y = median, group = treatment),
      inherit.aes = FALSE,
      linewidth = 0.8,
      color = "black"
    ) +
    ggplot2::geom_point(
      data = plot_data$medians,
      mapping = ggplot2::aes(x = visit, y = median),
      inherit.aes = FALSE,
      shape = 21,
      size = 3,
      fill = "white",
      color = "black",
      stroke = 1.2
    ) +
    ggplot2::geom_point(
      data = plot_data$outliers,
      mapping = ggplot2::aes(x = visit, y = value),
      inherit.aes = FALSE,
      shape = 1,
      size = 2.5,
      color = "black",
      stroke = 1
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(treatment),
      scales = facet_scales,
      drop = FALSE
    ) +
    ggplot2::scale_x_discrete(drop = FALSE, limits = analysis$visit_levels) +
    ggplot2::labs(x = NULL, y = y_label) +
    ggplot2::theme_bw(base_size = 12) +
    ggplot2::theme(
      text = ggplot2::element_text(face = "bold"),
      panel.border = ggplot2::element_rect(color = "black", fill = NA, linewidth = 1),
      panel.grid.major = ggplot2::element_line(color = "grey90", linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(face = "bold", color = "black"),
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      strip.background = ggplot2::element_rect(fill = "grey85", color = "black", linewidth = 1),
      strip.text = ggplot2::element_text(face = "bold", color = "black")
    )

  n_strip <- ggplot2::ggplot(
    plot_data$n_strip,
    ggplot2::aes(x = visit, y = 1, label = label)
  ) +
    ggplot2::geom_text(na.rm = TRUE, size = 4, color = "black", fontface = "bold") +
    ggplot2::facet_wrap(ggplot2::vars(treatment), drop = FALSE) +
    ggplot2::scale_x_discrete(drop = FALSE, limits = analysis$visit_levels) +
    ggplot2::scale_y_continuous(limits = c(0.5, 1.5)) +
    ggplot2::labs(x = "Analysis Visit", y = NULL) +
    ggplot2::theme_bw(base_size = 12) +
    ggplot2::theme(
      text = ggplot2::element_text(face = "bold"),
      panel.border = ggplot2::element_rect(color = "black", fill = NA, linewidth = 1),
      axis.text = ggplot2::element_text(face = "bold", color = "black"),
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      strip.text = ggplot2::element_blank(),
      strip.background = ggplot2::element_rect(fill = "grey85", color = "black", linewidth = 1)
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

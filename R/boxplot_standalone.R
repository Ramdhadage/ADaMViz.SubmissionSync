.standalone_calculate_boxplot_statistics <- function(
  data,
  treatment_variable,
  y_variable,
  facet_levels,
  visit_levels,
  low_n_policy
) {
  required_columns <- c("USUBJID", "AVISIT", "AVISITN", treatment_variable, y_variable)
  if (!is.data.frame(data) || length(setdiff(required_columns, names(data)))) {
    cli::cli_abort("analysis_data must contain USUBJID, AVISIT, AVISITN, treatment, and Y columns")
  }
  if (!is.numeric(data[[y_variable]])) {
    cli::cli_abort("The selected Y variable must be numeric")
  }
  if (!is.character(facet_levels) || !length(facet_levels) || anyDuplicated(facet_levels) ||
      !is.character(visit_levels) || !length(visit_levels) || anyDuplicated(visit_levels)) {
    cli::cli_abort("Facet and visit levels must be ordered, unique character vectors")
  }
  if (!is.list(low_n_policy) ||
      !identical(sort(names(low_n_policy)), sort(c("value", "rationale", "authority", "version"))) ||
      !is.numeric(low_n_policy$value) || length(low_n_policy$value) != 1L ||
      !is.finite(low_n_policy$value) || low_n_policy$value < 1) {
    cli::cli_abort("low_n_policy must retain value, rationale, authority, and version")
  }
  if (!all(vapply(low_n_policy[c("rationale", "authority", "version")],
                  function(value) is.character(value) && length(value) == 1L && nzchar(value),
                  logical(1)))) {
    cli::cli_abort("low_n_policy text fields must be non-empty strings")
  }
  type7_quantile <- function(values, probability) {
    position <- (length(values) - 1) * probability + 1
    lower_index <- floor(position)
    fraction <- position - lower_index
    if (fraction == 0 || lower_index == length(values)) {
      return(values[[lower_index]])
    }
    values[[lower_index]] + fraction * (values[[lower_index + 1L]] - values[[lower_index]])
  }
  summarize_box <- function(rows) {
    values <- rows[[y_variable]]
    sorted_values <- sort(values, method = "radix")
    lower <- type7_quantile(sorted_values, 0.25)
    middle <- type7_quantile(sorted_values, 0.5)
    upper <- type7_quantile(sorted_values, 0.75)
    interquartile_range <- upper - lower
    inside <- values >= lower - 1.5 * interquartile_range &
      values <= upper + 1.5 * interquartile_range
    distinct_n <- length(unique(as.character(rows$USUBJID)))
    list(
      box = data.frame(
        treatment = as.character(rows[[treatment_variable]][[1]]),
        visit = as.character(rows$AVISIT[[1]]),
        visit_n = rows$AVISITN[[1]],
        n = as.integer(distinct_n),
        ymin = min(values[inside]),
        lower = lower,
        middle = middle,
        upper = upper,
        ymax = max(values[inside]),
        low_n = distinct_n < low_n_policy$value,
        stringsAsFactors = FALSE
      ),
      outliers = data.frame(
        treatment = as.character(rows[[treatment_variable]][!inside]),
        visit = as.character(rows$AVISIT[!inside]),
        visit_n = rows$AVISITN[!inside],
        USUBJID = as.character(rows$USUBJID[!inside]),
        value = values[!inside],
        stringsAsFactors = FALSE
      )
    )
  }
  empty_outliers <- function() {
    data.frame(
      treatment = character(), visit = character(), visit_n = numeric(),
      USUBJID = character(), value = numeric(), stringsAsFactors = FALSE
    )
  }
  low_n_policy$value <- as.numeric(low_n_policy$value)
  display <- data[
    !is.na(data[[y_variable]]) &
      !is.na(data[[treatment_variable]]) &
      data[[treatment_variable]] %in% facet_levels &
      !is.na(data$AVISIT) & data$AVISIT %in% visit_levels,
    ,
    drop = FALSE
  ]
  if (any(!is.finite(display[[y_variable]]))) {
    cli::cli_abort("The selected Y variable must contain only finite values")
  }
  if (nrow(display)) {
    ordering <- order(
      match(as.character(display[[treatment_variable]]), facet_levels),
      match(as.character(display$AVISIT), visit_levels),
      as.character(display$USUBJID),
      method = "radix"
    )
    display <- display[ordering, , drop = FALSE]
    row.names(display) <- NULL
    group_start <- c(
      TRUE,
      as.character(display[[treatment_variable]][-1L]) !=
        as.character(display[[treatment_variable]][-nrow(display)]) |
        as.character(display$AVISIT[-1L]) != as.character(display$AVISIT[-nrow(display)])
    )
    summaries <- lapply(split(seq_len(nrow(display)), cumsum(group_start)), function(index) {
      summarize_box(display[index, , drop = FALSE])
    })
    boxes <- do.call(rbind, lapply(summaries, `[[`, "box"))
    outlier_rows <- lapply(summaries, `[[`, "outliers")
    outliers <- if (sum(vapply(outlier_rows, nrow, integer(1))) > 0L) {
      do.call(rbind, outlier_rows)
    } else {
      empty_outliers()
    }
    box_order <- order(
      match(boxes$treatment, facet_levels),
      match(boxes$visit, visit_levels),
      method = "radix"
    )
    boxes <- boxes[box_order, , drop = FALSE]
    row.names(boxes) <- NULL
    if (nrow(outliers)) {
      outlier_order <- order(
        match(outliers$treatment, facet_levels),
        match(outliers$visit, visit_levels),
        outliers$value,
        outliers$USUBJID,
        method = "radix"
      )
      outliers <- outliers[outlier_order, , drop = FALSE]
      row.names(outliers) <- NULL
    }
  } else {
    boxes <- data.frame(
      treatment = character(), visit = character(), visit_n = numeric(),
      n = integer(), ymin = numeric(), lower = numeric(), middle = numeric(),
      upper = numeric(), ymax = numeric(), low_n = logical(),
      stringsAsFactors = FALSE
    )
    outliers <- empty_outliers()
  }
  medians <- boxes[c("treatment", "visit", "visit_n", "middle")]
  names(medians)[[4]] <- "median"
  n_strip <- boxes[c("treatment", "visit", "visit_n", "n", "low_n")]
  n_strip$label <- ifelse(
    n_strip$low_n,
    paste0("N = ", n_strip$n, " - Low N"),
    paste0("N = ", n_strip$n)
  )
  structure(
    list(
      analysis_version = "boxplot-analysis-v1",
      treatment_variable = treatment_variable,
      y_variable = y_variable,
      facet_levels = facet_levels,
      visit_levels = visit_levels,
      low_n_policy = low_n_policy,
      boxes = boxes,
      outliers = outliers,
      medians = medians,
      n_strip = n_strip
    ),
    class = "boxplot_analysis"
  )
}

.standalone_assemble_boxplot <- function(analysis, scale_mode = c("fixed", "free"), unit = NULL) {
  if (!inherits(analysis, "boxplot_analysis")) {
    cli::cli_abort("analysis must be a boxplot_analysis object")
  }
  scale_mode <- match.arg(scale_mode)
  plot_data <- analysis[c("boxes", "outliers", "medians", "n_strip")]
  plot_data <- lapply(plot_data, function(data) {
    data$treatment <- factor(data$treatment, levels = analysis$facet_levels)
    data$visit <- factor(data$visit, levels = analysis$visit_levels)
    data
  })
  y_label <- if (is.null(unit) || !nzchar(unit)) analysis$y_variable else paste0(analysis$y_variable, " (", unit, ")")
  facet_scales <- if (identical(scale_mode, "free")) "free_y" else "fixed"
  plot_theme <- ggplot2::theme_bw(base_size = 12) +
    ggplot2::theme(
      panel.border = ggplot2::element_rect(color = "black", fill = NA, linewidth = 1),
      panel.grid.major = ggplot2::element_line(color = "grey90", linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank(),
      text = ggplot2::element_text(face = "bold"),
      axis.text = ggplot2::element_text(face = "bold", color = "black"),
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      strip.background = ggplot2::element_rect(fill = "grey85", color = "black", linewidth = 1),
      strip.text = ggplot2::element_text(face = "bold", color = "black")
    )
  plot <- ggplot2::ggplot(
    plot_data$boxes,
    ggplot2::aes(x = visit, ymin = ymin, lower = lower, middle = middle, upper = upper, ymax = ymax)
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
    ggplot2::facet_wrap(ggplot2::vars(treatment), scales = facet_scales, drop = FALSE) +
    ggplot2::scale_x_discrete(drop = FALSE, limits = analysis$visit_levels) +
    ggplot2::labs(x = NULL, y = y_label) +
    plot_theme
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
      panel.border = ggplot2::element_rect(color = "black", fill = NA, linewidth = 1),
      text = ggplot2::element_text(face = "bold"),
      axis.text = ggplot2::element_text(face = "bold", color = "black"),
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      strip.text = ggplot2::element_blank(),
      strip.background = ggplot2::element_rect(fill = "grey85", color = "black", linewidth = 1)
    )
  combined <- patchwork::wrap_plots(
    plot,
    n_strip,
    ncol = 1L,
    heights = c(4, 1)
  )
  structure(
    list(
      artifact_version = "boxplot-artifact-v1",
      status = if (identical(scale_mode, "free")) "Experimental/Draft" else "Draft",
      warning = if (identical(scale_mode, "free")) "Free Y scales weaken cross-facet visual comparison." else NULL,
      scale_mode = scale_mode,
      analysis = analysis,
      plot_data = plot_data,
      plot = plot,
      n_strip = n_strip,
      combined = combined
    ),
    class = "boxplot_artifact"
  )
}

.standalone_function_text <- function(name, fn) {
  paste0(name, " <- ", paste(deparse(fn), collapse = "\n"))
}

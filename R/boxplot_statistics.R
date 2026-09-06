.validate_boxplot_design <- function(facet_levels, visit_levels, low_n_policy) {
  if (!checkmate::test_character(facet_levels, min.len = 1L, any.missing = FALSE, unique = TRUE) ||
      !checkmate::test_character(visit_levels, min.len = 1L, any.missing = FALSE, unique = TRUE)) {
    cli::cli_abort("Facet and visit levels must be ordered, unique character vectors")
  }
  required_policy <- c("value", "rationale", "authority", "version")
  if (!is.list(low_n_policy) || !setequal(names(low_n_policy), required_policy) ||
      !checkmate::test_number(low_n_policy$value, lower = 1, finite = TRUE) ||
      !all(vapply(low_n_policy[setdiff(required_policy, "value")], checkmate::test_string, logical(1), min.chars = 1L))) {
    cli::cli_abort("{.arg low_n_policy} must retain value, rationale, authority, and version")
  }
  invisible(TRUE)
}

.validate_boxplot_inputs <- function(
  data,
  treatment_variable,
  y_variable,
  facet_levels,
  visit_levels,
  low_n_policy
) {
  required_columns <- c("USUBJID", "AVISIT", "AVISITN", treatment_variable, y_variable)
  missing_columns <- setdiff(required_columns, names(data))
  if (!is.data.frame(data) || length(missing_columns)) {
    cli::cli_abort(
      "{.arg data} must contain the governed analytical columns: {.field {required_columns}}"
    )
  }
  if (!is.numeric(data[[y_variable]])) {
    cli::cli_abort("The selected Y variable must be numeric")
  }
  .validate_boxplot_design(facet_levels, visit_levels, low_n_policy)
}

.type7_quantile_from_sorted <- function(values, probability) {
  count <- length(values)
  position <- (count - 1) * probability + 1
  lower_index <- floor(position)
  fraction <- position - lower_index
  if (fraction == 0 || lower_index == count) {
    return(values[[lower_index]])
  }
  values[[lower_index]] + fraction * (values[[lower_index + 1L]] - values[[lower_index]])
}

.summarize_box <- function(rows, treatment_variable, y_variable, low_n_threshold) {
  values <- rows[[y_variable]]
  sorted_values <- sort(values, method = "radix")
  lower <- .type7_quantile_from_sorted(sorted_values, 0.25)
  middle <- .type7_quantile_from_sorted(sorted_values, 0.5)
  upper <- .type7_quantile_from_sorted(sorted_values, 0.75)
  interquartile_range <- upper - lower
  lower_fence <- lower - 1.5 * interquartile_range
  upper_fence <- upper + 1.5 * interquartile_range
  inside <- values >= lower_fence & values <= upper_fence
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
      low_n = distinct_n < low_n_threshold,
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

.summarize_box_indices <- function(
  index,
  data,
  treatment_variable,
  y_variable,
  low_n_threshold
) {
  .summarize_box(
    data[index, , drop = FALSE],
    treatment_variable,
    y_variable,
    low_n_threshold
  )
}

.empty_outlier_data <- function() {
  data.frame(
    treatment = character(),
    visit = character(),
    visit_n = numeric(),
    USUBJID = character(),
    value = numeric(),
    stringsAsFactors = FALSE
  )
}

#' Calculate governed longitudinal boxplot statistics
#'
#' Calculates type-7 hinges, 1.5-IQR whiskers, visible outlier membership,
#' distinct-subject counts, low-N flags, and median-line rows from the selected
#' analytical data. Missing selected Y values do not contribute.
#'
#' @param data Selected records from a validated visit-based BDS profile.
#' @param treatment_variable Name of the selected treatment variable.
#' @param y_variable Name of the selected numeric Y variable.
#' @param facet_levels Ordered included treatment values.
#' @param visit_levels Ordered included visit labels.
#' @param low_n_policy Retained policy with `value`, `rationale`, `authority`,
#'   and `version`.
#'
#' @return A deterministic `boxplot_analysis` object.
#' @export
calculate_boxplot_statistics <- function(
  data,
  treatment_variable,
  y_variable,
  facet_levels,
  visit_levels,
  low_n_policy
) {
  .validate_boxplot_inputs(
    data,
    treatment_variable,
    y_variable,
    facet_levels,
    visit_levels,
    low_n_policy
  )
  low_n_policy$value <- as.numeric(low_n_policy$value)
  display <- data[
    !is.na(data[[y_variable]]) &
      !is.na(data[[treatment_variable]]) &
      data[[treatment_variable]] %in% facet_levels &
      !is.na(data$AVISIT) &
      data$AVISIT %in% visit_levels,
    ,
    drop = FALSE
  ]
  if (nrow(display)) {
    treatment_order <- match(as.character(display[[treatment_variable]]), facet_levels)
    visit_order <- match(as.character(display$AVISIT), visit_levels)
    ordering <- order(treatment_order, visit_order, as.character(display$USUBJID), method = "radix")
    display <- display[ordering, , drop = FALSE]
    row.names(display) <- NULL
    group_key <- paste(display[[treatment_variable]], display$AVISIT, sep = "\u001f")
    summaries <- lapply(
      split(seq_len(nrow(display)), group_key),
      .summarize_box_indices,
      data = display,
      treatment_variable = treatment_variable,
      y_variable = y_variable,
      low_n_threshold = low_n_policy$value
    )
    boxes <- do.call(rbind, lapply(summaries, `[[`, "box"))
    outlier_rows <- lapply(summaries, `[[`, "outliers")
    outliers <- if (sum(vapply(outlier_rows, nrow, integer(1))) > 0L) {
      do.call(rbind, outlier_rows)
    } else {
      .empty_outlier_data()
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
    outliers <- .empty_outlier_data()
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

#' Build minimum-necessary prompt context from an authorized snapshot
#'
#' @param snapshot A pinned `study_data_snapshot`.
#'
#' @return A `prompt_context` containing only authorized labels and aggregate
#'   choices.
#' @export
build_prompt_context <- function(snapshot) {
  if (!inherits(snapshot, "study_data_snapshot")) {
    cli::cli_abort("{.arg snapshot} must be a {.cls study_data_snapshot}")
  }

  data <- snapshot$data
  parameters <- .prompt_parameter_choices(data)
  visits <- .prompt_visit_choices(data)
  treatment_levels <- lapply(snapshot$permitted_treatment_variables, function(variable) {
    sort(unique(stats::na.omit(as.character(data[[variable]]))), method = "radix")
  })
  names(treatment_levels) <- snapshot$permitted_treatment_variables

  new_prompt_context(
    dataset_id = snapshot$dataset_id,
    labels = list(
      dataset_id = snapshot$dataset_id,
      adam_designation = snapshot$adam_designation,
      classification = snapshot$classification
    ),
    aggregate_profile = list(
      parameters = parameters,
      y_variables = intersect(c("AVAL", "CHG", "PCHG"), names(data)),
      treatment_variables = snapshot$permitted_treatment_variables,
      treatment_levels = treatment_levels,
      visits = visits,
      scale_modes = c("fixed", "free"),
      default_scale_mode = "fixed"
    )
  )
}

.prompt_parameter_choices <- function(data) {
  if (!all(c("PARAMCD", "PARAM") %in% names(data))) {
    return(list())
  }
  parameter_rows <- unique(data[c("PARAMCD", "PARAM", intersect("AVALU", names(data)))])
  parameter_rows <- parameter_rows[order(parameter_rows$PARAMCD, method = "radix"), , drop = FALSE]
  lapply(split(parameter_rows, parameter_rows$PARAMCD), function(rows) {
    unit <- if ("AVALU" %in% names(rows)) {
      sort(unique(stats::na.omit(as.character(rows$AVALU))), method = "radix")
    } else {
      character()
    }
    list(
      paramcd = rows$PARAMCD[[1]],
      label = rows$PARAM[[1]],
      units = unit
    )
  })
}

.prompt_visit_choices <- function(data) {
  if (!all(c("AVISIT", "AVISITN") %in% names(data))) {
    return(list())
  }
  visits <- unique(data[c("AVISIT", "AVISITN")])
  visits <- visits[!is.na(visits$AVISIT) & !is.na(visits$AVISITN), , drop = FALSE]
  visits <- visits[order(visits$AVISITN, visits$AVISIT, method = "radix"), , drop = FALSE]
  lapply(seq_len(nrow(visits)), function(i) {
    list(label = as.character(visits$AVISIT[[i]]), order = visits$AVISITN[[i]])
  })
}

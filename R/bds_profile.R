.new_profile_diagnostic <- function(code, message, count = NULL, integrity_ref = NULL) {
  compact <- list(code = code, message = message)
  if (!is.null(count)) compact$count <- as.integer(count)
  if (!is.null(integrity_ref)) compact$integrity_ref <- integrity_ref
  compact
}

.resolve_low_n_policy <- function(low_n_threshold) {
  if (is.numeric(low_n_threshold) && length(low_n_threshold) == 1L &&
      !is.na(low_n_threshold) && identical(as.numeric(low_n_threshold), 5)) {
    return(list(
      value = 5,
      rationale = "Assurance Cell default",
      authority = "plot-pattern-assurance-cell-v1",
      version = "low-n-default-v1"
    ))
  }
  required <- c("value", "rationale", "authority", "version")
  valid <- is.list(low_n_threshold) && identical(sort(names(low_n_threshold)), sort(required)) &&
    checkmate::test_number(low_n_threshold$value, lower = 1, finite = TRUE) &&
    all(vapply(low_n_threshold[required[-1]], checkmate::test_string, logical(1), min.chars = 1L))
  if (!valid) {
    cli::cli_abort(
      "A non-default low-N threshold requires sponsor-approved value, rationale, authority, and version"
    )
  }
  low_n_threshold$value <- as.numeric(low_n_threshold$value)
  low_n_threshold
}

.profile_result <- function(snapshot, selections, choices, policy) {
  structure(
    list(
      profile_version = "visit-based-numeric-bds-v1",
      snapshot_id = snapshot$snapshot_id,
      snapshot_hash = snapshot$content_hash,
      blocked = FALSE,
      dataset_conformance = "not_assessed",
      selections = selections,
      choices = choices,
      facet_levels = choices$included_treatment_levels,
      visit_levels = choices$included_visits,
      low_n_policy = policy,
      selected_data = data.frame(),
      display_data = data.frame(),
      counts = data.frame(),
      blocking_diagnostics = list(),
      warnings = list(),
      authorized_diagnostics = list(),
      durable_diagnostics = list(),
      analytical_input_hash = NULL
    ),
    class = "bds_profile_result"
  )
}

.block_profile <- function(result, diagnostic, authorized = list()) {
  result$blocked <- TRUE
  result$blocking_diagnostics <- list(diagnostic)
  result$durable_diagnostics <- list(diagnostic)
  result$authorized_diagnostics <- authorized
  result
}

.sort_profile_data <- function(data, treatment_variable) {
  columns <- intersect(
    c(treatment_variable, "AVISITN", "AVISIT", "USUBJID", "PARAMCD"),
    names(data)
  )
  ordering <- do.call(order, c(data[columns], list(method = "radix", na.last = TRUE)))
  result <- data[ordering, , drop = FALSE]
  row.names(result) <- NULL
  result
}

.validate_profile_inputs <- function(snapshot, selections) {
  if (!inherits(snapshot, "study_data_snapshot")) {
    cli::cli_abort("{.arg snapshot} must be a {.cls study_data_snapshot}")
  }
  required <- c("paramcd", "y_variable", "unit", "treatment_variable", "treatment_levels", "visits")
  if (!is.list(selections) || !setequal(names(selections), required)) {
    cli::cli_abort("{.arg selections} must contain the complete visit-based BDS selection fields")
  }
  if (!checkmate::test_string(selections$paramcd, min.chars = 1L) ||
      !checkmate::test_choice(selections$y_variable, c("AVAL", "CHG", "PCHG")) ||
      !checkmate::test_string(selections$treatment_variable, min.chars = 1L)) {
    cli::cli_abort("The parameter, Y variable, and treatment selections must each be singular and valid")
  }
  invisible(TRUE)
}

#' Validate the supported visit-based numeric BDS profile
#'
#' Explicit parameter, unit, treatment, and visit selections are applied before
#' visit-key and selected-Y checks. Blocking diagnostics are separated from
#' nonblocking sparse-data warnings.
#'
#' @param snapshot A pinned `study_data_snapshot`.
#' @param selections A complete list containing `paramcd`, `y_variable`, `unit`,
#'   `treatment_variable`, `treatment_levels`, and `visits`.
#' @param low_n_threshold The default value `5`, or a sponsor-approved list with
#'   `value`, `rationale`, `authority`, and `version`.
#'
#' @return A deterministic `bds_profile_result`.
#' @export
validate_bds_profile <- function(snapshot, selections, low_n_threshold = 5) {
  .validate_profile_inputs(snapshot, selections)
  policy <- .resolve_low_n_policy(low_n_threshold)
  data <- snapshot$data
  treatment <- selections$treatment_variable
  y <- selections$y_variable
  choices <- list(
    parameters = sort(unique(stats::na.omit(as.character(data$PARAMCD))), method = "radix"),
    y_variables = intersect(c("AVAL", "CHG", "PCHG"), names(data)),
    units = character(),
    treatment_variables = snapshot$permitted_treatment_variables,
    treatment_levels = character(),
    visits = character(),
    included_treatment_levels = character(),
    included_visits = character()
  )
  result <- .profile_result(snapshot, selections, choices, policy)

  classification_allowed <- if (is.null(snapshot$classification)) {
    identical(snapshot$source_metadata$source, "direct_upload")
  } else {
    snapshot$classification %in% c("public", "synthetic", "deidentified")
  }
  if (!classification_allowed ||
      !identical(snapshot$adam_designation, "BDS")) {
    return(.block_profile(result, .new_profile_diagnostic(
      "unsupported_source_metadata",
      "The authorized source is outside the permitted BDS profile metadata envelope"
    )))
  }
  required_columns <- unique(c(
    "USUBJID", "PARAMCD", "AVISIT", "AVISITN", y, treatment,
    if ("AVALU" %in% names(data)) "AVALU"
  ))
  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns)) {
    return(.block_profile(result, .new_profile_diagnostic(
      "missing_required_variables",
      "The selected source lacks variables required by the supported BDS profile",
      length(missing_columns),
      canonical_hash(sort(missing_columns, method = "radix"))
    )))
  }
  if (!treatment %in% snapshot$permitted_treatment_variables) {
    return(.block_profile(result, .new_profile_diagnostic(
      "treatment_not_permitted",
      "The selected treatment variable is not permitted by the authorized catalog"
    )))
  }
  if (!selections$paramcd %in% choices$parameters) {
    return(.block_profile(result, .new_profile_diagnostic(
      "parameter_not_available",
      "The selected parameter is not present in the authorized snapshot"
    )))
  }
  if (!is.numeric(data[[y]])) {
    return(.block_profile(result, .new_profile_diagnostic(
      "selected_y_not_numeric",
      "The selected Y variable must be numeric for this BDS profile"
    )))
  }

  selected <- data[data$PARAMCD == selections$paramcd & !is.na(data$PARAMCD), , drop = FALSE]
  units <- if ("AVALU" %in% names(selected)) {
    sort(unique(stats::na.omit(as.character(selected$AVALU))), method = "radix")
  } else {
    character()
  }
  result$choices$units <- units
  if (length(units) > 1L && is.null(selections$unit)) {
    return(.block_profile(result, .new_profile_diagnostic(
      "unit_selection_required",
      "Multiple non-missing units require one explicit unit selection",
      length(units),
      canonical_hash(units)
    )))
  }
  if (!is.null(selections$unit)) {
    if (!checkmate::test_string(selections$unit, min.chars = 1L) || !selections$unit %in% units) {
      return(.block_profile(result, .new_profile_diagnostic(
        "unit_not_available",
        "The selected unit is not present for the selected parameter"
      )))
    }
    selected <- selected[!is.na(selected$AVALU) & selected$AVALU == selections$unit, , drop = FALSE]
  }

  missing_subject <- is.na(selected$USUBJID) | !nzchar(as.character(selected$USUBJID))
  if (any(missing_subject)) {
    return(.block_profile(result, .new_profile_diagnostic(
      "missing_profile_key",
      "The selected records contain a missing supported-profile key value",
      sum(missing_subject),
      canonical_hash(list(snapshot_id = snapshot$snapshot_id, count = sum(missing_subject)))
    )))
  }
  missing_treatment <- is.na(selected[[treatment]]) |
    !nzchar(as.character(selected[[treatment]]))
  if (any(missing_treatment)) {
    return(.block_profile(result, .new_profile_diagnostic(
      "missing_treatment_value",
      "The selected records contain a missing treatment value required for faceting",
      sum(missing_treatment),
      canonical_hash(list(snapshot_id = snapshot$snapshot_id, count = sum(missing_treatment)))
    )))
  }

  treatment_levels <- sort(unique(stats::na.omit(as.character(selected[[treatment]]))), method = "radix")
  result$choices$treatment_levels <- treatment_levels
  included_treatments <- selections$treatment_levels
  if (is.null(included_treatments)) included_treatments <- treatment_levels
  if (!checkmate::test_character(included_treatments, any.missing = FALSE, unique = TRUE) ||
      length(setdiff(included_treatments, treatment_levels))) {
    return(.block_profile(result, .new_profile_diagnostic(
      "treatment_level_not_available",
      "Every included treatment level must be present in the authorized snapshot"
    )))
  }
  included_treatments <- treatment_levels[treatment_levels %in% included_treatments]
  selected <- selected[!is.na(selected[[treatment]]) & selected[[treatment]] %in% included_treatments, , drop = FALSE]

  available_visits <- unique(data.frame(
    AVISIT = as.character(selected$AVISIT),
    AVISITN = selected$AVISITN,
    stringsAsFactors = FALSE
  ))
  requested_visits <- selections$visits
  if (!is.null(requested_visits)) {
    if (!checkmate::test_character(requested_visits, any.missing = FALSE, unique = TRUE)) {
      return(.block_profile(result, .new_profile_diagnostic(
        "visit_not_available",
        "Included visits must be unique non-missing labels"
      )))
    }
    selected <- selected[is.na(selected$AVISIT) | selected$AVISIT %in% requested_visits, , drop = FALSE]
    available_visits <- available_visits[
      !is.na(available_visits$AVISIT) & available_visits$AVISIT %in% requested_visits,
      , drop = FALSE
    ]
  }

  mapping_missing <- any(is.na(selected$AVISIT) | !nzchar(as.character(selected$AVISIT)) | is.na(selected$AVISITN))
  label_counts <- tapply(selected$AVISITN, selected$AVISIT, function(x) length(unique(x[!is.na(x)])))
  order_counts <- tapply(as.character(selected$AVISIT), selected$AVISITN, function(x) length(unique(x[!is.na(x)])))
  mapping_conflict <- any(label_counts != 1L) || any(order_counts != 1L)
  if (mapping_missing || mapping_conflict) {
    mapping_ref <- canonical_hash(list(
      missing_count = sum(is.na(selected$AVISIT) | is.na(selected$AVISITN)),
      mappings = .normalize_study_data(available_visits)
    ))
    return(.block_profile(result, .new_profile_diagnostic(
      "invalid_visit_mapping",
      "The selected AVISIT and AVISITN mapping does not provide a deterministic visit order",
      nrow(selected),
      mapping_ref
    )))
  }

  mapping <- unique(selected[c("AVISIT", "AVISITN")])
  mapping <- mapping[order(mapping$AVISITN, mapping$AVISIT, method = "radix"), , drop = FALSE]
  available_visit_labels <- as.character(mapping$AVISIT)
  if (!is.null(requested_visits) && length(setdiff(requested_visits, available_visit_labels))) {
    return(.block_profile(result, .new_profile_diagnostic(
      "visit_not_available",
      "Every included visit must be present after explicit parameter, unit, and treatment selections"
    )))
  }
  included_visits <- available_visit_labels
  result$choices$visits <- available_visit_labels
  result$choices$included_treatment_levels <- included_treatments
  result$choices$included_visits <- included_visits
  result$facet_levels <- included_treatments
  result$visit_levels <- included_visits

  key_columns <- c("USUBJID", "PARAMCD", "AVISIT")
  duplicate_rows <- duplicated(selected[key_columns]) | duplicated(selected[key_columns], fromLast = TRUE)
  if (any(duplicate_rows)) {
    duplicate_keys <- unique(selected[duplicate_rows, key_columns, drop = FALSE])
    duplicate_keys <- .sort_profile_data(duplicate_keys, "PARAMCD")
    additional_keys <- setdiff(snapshot$declared_keys, c(
      "STUDYID", "USUBJID", "PARAMCD", "AVISIT", "AVISITN"
    ))
    code <- if (length(additional_keys)) {
      "unsupported_additional_timepoint_keys"
    } else {
      "unsupported_duplicate_visit_key"
    }
    message <- if (length(additional_keys)) {
      "The ADaM source declares additional legitimate keys and is unsupported by this visit-based cell"
    } else {
      "Duplicate subject-parameter-visit keys are unsupported by this visit-based cell"
    }
    diagnostic <- .new_profile_diagnostic(
      code,
      message,
      nrow(duplicate_keys),
      canonical_hash(.normalize_study_data(duplicate_keys))
    )
    return(.block_profile(
      result,
      diagnostic,
      list(duplicate_keys = duplicate_keys, additional_keys = additional_keys)
    ))
  }

  selected <- .sort_profile_data(selected, treatment)
  display <- selected[!is.na(selected[[y]]), , drop = FALSE]
  display <- .sort_profile_data(display, treatment)
  if (nrow(display)) {
    groups <- split(
      seq_len(nrow(display)),
      interaction(display[[treatment]], display$AVISIT, drop = TRUE, lex.order = TRUE)
    )
    count_rows <- lapply(groups, function(index) {
      rows <- display[index, , drop = FALSE]
      source_rows <- selected[
        selected[[treatment]] == rows[[treatment]][1] & selected$AVISIT == rows$AVISIT[1],
        , drop = FALSE
      ]
      data.frame(
        treatment_value = as.character(rows[[treatment]][1]),
        AVISIT = as.character(rows$AVISIT[1]),
        AVISITN = rows$AVISITN[1],
        source_n = length(unique(source_rows$USUBJID)),
        n = length(unique(rows$USUBJID)),
        stringsAsFactors = FALSE
      )
    })
    counts <- do.call(rbind, count_rows)
    names(counts)[1] <- treatment
    counts$source_n <- as.integer(counts$source_n)
    counts$n <- as.integer(counts$n)
    counts$low_n <- counts$n < policy$value
    counts <- counts[order(counts[[treatment]], counts$AVISITN, method = "radix"), , drop = FALSE]
    row.names(counts) <- NULL
  } else {
    counts <- data.frame()
  }

  all_combinations <- expand.grid(
    treatment_value = included_treatments,
    AVISIT = included_visits,
    stringsAsFactors = FALSE
  )
  displayed_keys <- if (nrow(counts)) {
    paste(counts[[treatment]], counts$AVISIT, sep = "\u001f")
  } else {
    character()
  }
  empty_combinations <- all_combinations[
    !paste(all_combinations$treatment_value, all_combinations$AVISIT, sep = "\u001f") %in% displayed_keys,
    , drop = FALSE
  ]
  warnings <- list()
  if (nrow(counts) && any(counts$low_n)) {
    sparse <- counts[counts$low_n, c(treatment, "AVISIT", "AVISITN", "n"), drop = FALSE]
    warnings[[length(warnings) + 1L]] <- .new_profile_diagnostic(
      "low_sample_size",
      "One or more displayed treatment-visit boxes are below the retained low-N threshold",
      nrow(sparse),
      canonical_hash(sparse)
    )
  }
  if (nrow(empty_combinations)) {
    warnings[[length(warnings) + 1L]] <- .new_profile_diagnostic(
      "empty_treatment_visit",
      "One or more included treatment-visit combinations have no non-missing selected Y value",
      nrow(empty_combinations),
      canonical_hash(empty_combinations)
    )
  }
  empty_treatments <- setdiff(included_treatments, unique(as.character(display[[treatment]])))
  if (length(empty_treatments)) {
    warnings[[length(warnings) + 1L]] <- .new_profile_diagnostic(
      "empty_treatment_level",
      "One or more included treatment levels remain as empty facets",
      length(empty_treatments),
      canonical_hash(empty_treatments)
    )
  }

  result$selected_data <- selected
  result$display_data <- display
  result$counts <- counts
  result$warnings <- warnings
  result$durable_diagnostics <- warnings
  result$analytical_input_hash <- canonical_hash(list(
    data = .normalize_study_data(display),
    selections = selections,
    facet_levels = result$facet_levels,
    visit_levels = result$visit_levels,
    low_n_policy = policy
  ))
  result
}

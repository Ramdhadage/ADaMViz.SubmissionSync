#' Calculate a stable content hash for study data
#'
#' The hash is independent of row order while preserving column names, types,
#' missing values, and stored values.
#'
#' @param data A data frame containing a study-data snapshot.
#'
#' @return A SHA-256 content hash.
#' @export
study_data_content_hash <- function(data) {
  if (!checkmate::test_data_frame(data, min.rows = 1L, min.cols = 1L)) {
    cli::cli_abort("{.arg data} must be a non-empty data frame")
  }

  normalized <- .normalize_study_data(data)
  payload <- lapply(normalized, function(column) {
    list(type = typeof(column), class = class(column), values = unname(column))
  })
  canonical_hash(list(columns = names(normalized), data = payload))
}

.normalize_study_data <- function(data) {
  data <- data[, sort(names(data), method = "radix"), drop = FALSE]
  row_keys <- do.call(
    paste,
    c(lapply(data, .stable_column_text), sep = "\u001f")
  )
  result <- data[order(row_keys, method = "radix", na.last = TRUE), , drop = FALSE]
  row.names(result) <- NULL
  result
}

.stable_column_text <- function(x) {
  if (inherits(x, "POSIXt")) {
    value <- format(x, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC")
  } else if (inherits(x, "Date")) {
    value <- format(x, "%Y-%m-%d")
  } else if (is.numeric(x)) {
    value <- ifelse(is.na(x), NA_character_, sprintf("%.17g", x))
  } else {
    value <- enc2utf8(as.character(x))
  }
  paste0(typeof(x), ":", ifelse(is.na(value), "<NA>", value))
}

.validate_study_data_provider <- function(provider) {
  if (!inherits(provider, "study_data_provider")) {
    cli::cli_abort("{.arg provider} must be a {.cls study_data_provider}")
  }
  invisible(provider)
}

#' List datasets authorized by a study-data provider
#'
#' @param provider A study-data provider.
#'
#' @return A deterministic data frame of authorized, non-patient metadata.
#' @export
list_study_catalog <- function(provider) {
  .validate_study_data_provider(provider)
  scenarios <- provider$manifest$scenarios
  catalog <- data.frame(
    dataset_id = vapply(scenarios, `[[`, "", "dataset_id"),
    classification = vapply(scenarios, `[[`, "", "classification"),
    adam_designation = vapply(scenarios, `[[`, "", "adam_designation"),
    metadata_version = vapply(scenarios, `[[`, "", "metadata_version"),
    content_hash = vapply(scenarios, `[[`, "", "content_hash"),
    snapshot_id = vapply(scenarios, `[[`, "", "snapshot_id"),
    scenario_id = vapply(scenarios, `[[`, "", "scenario_id"),
    purpose = vapply(scenarios, `[[`, "", "purpose"),
    expected_behavior = vapply(scenarios, `[[`, "", "expected_behavior"),
    stringsAsFactors = FALSE
  )
  catalog$declared_keys <- I(lapply(scenarios, `[[`, "declared_keys"))
  catalog$permitted_treatment_variables <- I(lapply(
    scenarios,
    `[[`,
    "permitted_treatment_variables"
  ))
  catalog <- catalog[, c(
    "dataset_id", "classification", "adam_designation", "declared_keys",
    "metadata_version", "content_hash", "permitted_treatment_variables",
    "snapshot_id", "scenario_id", "purpose", "expected_behavior"
  )]
  catalog <- catalog[order(catalog$dataset_id, method = "radix"), , drop = FALSE]
  row.names(catalog) <- NULL
  catalog
}

#' Pin an authorized immutable study-data snapshot
#'
#' @param provider A study-data provider.
#' @param dataset_id One opaque dataset identifier from the authorized catalog.
#'
#' @return A hash-verified `study_data_snapshot`.
#' @export
pin_study_snapshot <- function(provider, dataset_id) {
  .validate_study_data_provider(provider)
  if (!checkmate::test_string(dataset_id, min.chars = 1L)) {
    cli::cli_abort("{.arg dataset_id} must be one non-empty identifier")
  }

  matches <- which(vapply(
    provider$manifest$scenarios,
    function(x) identical(x$dataset_id, dataset_id),
    logical(1)
  ))
  if (length(matches) != 1L) {
    cli::cli_abort("{.val {dataset_id}} is not present in the authorized catalog")
  }
  metadata <- provider$manifest$scenarios[[matches]]
  data <- provider$read_data(metadata)
  observed_hash <- study_data_content_hash(data)
  if (!identical(observed_hash, metadata$content_hash)) {
    cli::cli_abort("The authorized snapshot content hash does not match its catalog entry")
  }

  structure(
    list(
      snapshot_contract_version = "study-snapshot-v1",
      snapshot_id = metadata$snapshot_id,
      dataset_id = metadata$dataset_id,
      classification = metadata$classification,
      adam_designation = metadata$adam_designation,
      declared_keys = unlist(metadata$declared_keys, use.names = FALSE),
      metadata_version = metadata$metadata_version,
      content_hash = metadata$content_hash,
      permitted_treatment_variables = unlist(
        metadata$permitted_treatment_variables,
        use.names = FALSE
      ),
      data = .normalize_study_data(data)
    ),
    class = "study_data_snapshot"
  )
}

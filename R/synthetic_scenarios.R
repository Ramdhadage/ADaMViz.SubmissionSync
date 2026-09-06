.base_synthetic_bds <- function() {
  data.frame(
    STUDYID = "SYNTH001",
    USUBJID = rep(sprintf("SYNTH001-%03d", 1:6), each = 3L),
    PARAMCD = "ALT",
    PARAM = "Alanine aminotransferase",
    AVISIT = rep(c("Baseline", "Week 4", "Week 8"), times = 6L),
    AVISITN = rep(c(0, 4, 8), times = 6L),
    AVAL = c(
      20, 24, 26, 22, 25, 28, 24, 27, 30,
      26, 29, 32, 28, NA, 34, 30, NA, 36
    ),
    CHG = c(
      0, 4, 6, 0, 3, 6, 0, 3, 6,
      0, 3, 6, 0, NA, 6, 0, NA, 6
    ),
    PCHG = c(
      0, 20, 30, 0, 13.6363636364, 27.2727272727,
      0, 12.5, 25, 0, 11.5384615385, 23.0769230769,
      0, NA, 21.4285714286, 0, NA, 20
    ),
    AVALU = "U/L",
    TRT01A = rep(c("Placebo", "Active"), each = 9L),
    ANL01FL = rep(c("Y", "N"), 9L),
    stringsAsFactors = FALSE
  )
}

.synthetic_scenario_data <- function() {
  standard <- .base_synthetic_bds()

  multiple_units <- standard
  multiple_units$AVALU[multiple_units$USUBJID == "SYNTH001-006"] <- "ukat/L"

  duplicate_keys <- standard
  duplicate_keys <- rbind(
    duplicate_keys,
    transform(
      duplicate_keys[duplicate_keys$USUBJID == "SYNTH001-001" & duplicate_keys$AVISIT == "Week 4", ],
      AVAL = 999
    )
  )

  sparse_missing <- standard
  sparse_missing$AVAL[sparse_missing$AVISIT == "Week 4" &
    sparse_missing$USUBJID %in% c("SYNTH001-005", "SYNTH001-006")] <- NA_real_

  empty_combination <- standard
  empty_combination$AVAL[
    empty_combination$TRT01A == "Active" & empty_combination$AVISIT == "Week 4"
  ] <- NA_real_

  bad_visit_mapping <- standard
  bad_visit_mapping$AVISITN[
    bad_visit_mapping$USUBJID == "SYNTH001-001" & bad_visit_mapping$AVISIT == "Week 4"
  ] <- 5

  empty_treatment <- standard
  empty_treatment$AVAL[empty_treatment$TRT01A == "Placebo"] <- NA_real_

  extra_timepoint_keys <- standard
  extra_timepoint_keys$ATPTN <- 1L
  repeated <- extra_timepoint_keys[
    extra_timepoint_keys$USUBJID == "SYNTH001-001" & extra_timepoint_keys$AVISIT == "Week 4",
  ]
  repeated$ATPTN <- 2L
  extra_timepoint_keys <- rbind(extra_timepoint_keys, repeated)

  identifier_canary <- standard
  canary <- identifier_canary[
    identifier_canary$USUBJID == "SYNTH001-001" & identifier_canary$AVISIT == "Week 4",
  ]
  canary$USUBJID <- "SYNTH-CANARY-DO-NOT-RETAIN"
  identifier_canary <- rbind(identifier_canary, canary, transform(canary, AVAL = 999))

  exclusions <- standard
  exclusions <- rbind(
    exclusions,
    exclusions[exclusions$USUBJID == "SYNTH001-001" & exclusions$AVISIT == "Week 8", ]
  )

  list(
    standard = standard,
    `multiple-units` = multiple_units,
    `duplicate-keys` = duplicate_keys,
    `sparse-missing` = sparse_missing,
    `empty-combination` = empty_combination,
    `bad-visit-mapping` = bad_visit_mapping,
    `empty-treatment` = empty_treatment,
    `extra-timepoint-keys` = extra_timepoint_keys,
    `identifier-canary` = identifier_canary,
    exclusions = exclusions
  )
}

.synthetic_scenario_purpose <- c(
  standard = "Passing visit-based numeric BDS profile",
  `multiple-units` = "Unresolved multiple-unit selection",
  `duplicate-keys` = "Unsupported duplicate subject-parameter-visit key",
  `sparse-missing` = "Six source subjects and four non-missing selected values",
  `empty-combination` = "No display data for one treatment-visit combination",
  `bad-visit-mapping` = "Conflicting AVISIT to AVISITN mapping",
  `empty-treatment` = "Included treatment level with all selected Y values missing",
  `extra-timepoint-keys` = "Legitimate additional timepoint key outside the cell profile",
  `identifier-canary` = "Authorization-scoped duplicate identifier canary",
  exclusions = "Explicit selections remove an otherwise blocking duplicate"
)

.synthetic_expected_behavior <- c(
  standard = "passes",
  `multiple-units` = "blocks:unit_selection_required",
  `duplicate-keys` = "blocks:unsupported_duplicate_visit_key",
  `sparse-missing` = "warns:low_sample_size",
  `empty-combination` = "warns:empty_treatment_visit",
  `bad-visit-mapping` = "blocks:invalid_visit_mapping",
  `empty-treatment` = "warns:empty_treatment_level",
  `extra-timepoint-keys` = "blocks:unsupported_additional_timepoint_keys",
  `identifier-canary` = "blocks:unsupported_duplicate_visit_key",
  exclusions = "passes:explicit_exclusions_precede_key_check"
)

.synthetic_declared_keys <- function(scenario_id) {
  keys <- c("STUDYID", "USUBJID", "PARAMCD", "AVISITN")
  if (identical(scenario_id, "extra-timepoint-keys")) c(keys, "ATPTN") else keys
}

.build_synthetic_manifest <- function(scenarios) {
  entries <- lapply(names(scenarios), function(scenario_id) {
    list(
      scenario_id = scenario_id,
      dataset_id = paste0("adlb-", scenario_id),
      snapshot_id = paste0("synthetic-adlb-", scenario_id, "-v1"),
      file = paste0("adlb-", scenario_id, ".rds"),
      purpose = unname(.synthetic_scenario_purpose[[scenario_id]]),
      expected_behavior = unname(.synthetic_expected_behavior[[scenario_id]]),
      generator_version = "synthetic-bds-generator-v1",
      seed = 20260906,
      classification = "synthetic",
      adam_designation = "BDS",
      declared_keys = .synthetic_declared_keys(scenario_id),
      metadata_version = "synthetic-adlb-metadata-v1",
      permitted_treatment_variables = "TRT01A",
      content_hash = study_data_content_hash(scenarios[[scenario_id]])
    )
  })
  list(
    manifest_version = "synthetic-bds-manifest-v1",
    generator_version = "synthetic-bds-generator-v1",
    classification = "synthetic",
    clinical_evidence_use = FALSE,
    scenarios = entries
  )
}

.validate_synthetic_manifest <- function(manifest) {
  required_top <- c(
    "manifest_version", "generator_version", "classification",
    "clinical_evidence_use", "scenarios"
  )
  required_scenario <- c(
    "scenario_id", "dataset_id", "snapshot_id", "file", "purpose",
    "expected_behavior", "generator_version", "seed", "classification",
    "adam_designation", "declared_keys", "metadata_version",
    "permitted_treatment_variables", "content_hash"
  )
  valid <- is.list(manifest) && all(required_top %in% names(manifest)) &&
    identical(manifest$manifest_version, "synthetic-bds-manifest-v1") &&
    identical(manifest$classification, "synthetic") &&
    identical(manifest$clinical_evidence_use, FALSE) &&
    is.list(manifest$scenarios) && length(manifest$scenarios) > 0L &&
    all(vapply(manifest$scenarios, function(x) {
      all(required_scenario %in% names(x)) &&
        identical(x$classification, "synthetic") &&
        identical(x$adam_designation, "BDS") &&
        identical(x$generator_version, manifest$generator_version) &&
        all(vapply(
          x[c(
            "scenario_id", "dataset_id", "snapshot_id", "file", "purpose",
            "expected_behavior", "metadata_version", "content_hash"
          )],
          checkmate::test_string,
          logical(1),
          min.chars = 1L
        )) &&
        checkmate::test_string(x$file, pattern = "^adlb-[a-z0-9-]+\\.rds$") &&
        checkmate::test_string(x$content_hash, pattern = "^[a-f0-9]{64}$") &&
        checkmate::test_number(x$seed, finite = TRUE) &&
        checkmate::test_character(
          unlist(x$declared_keys, use.names = FALSE),
          min.len = 3L,
          any.missing = FALSE,
          unique = TRUE
        ) &&
        all(c("USUBJID", "PARAMCD", "AVISITN") %in%
          unlist(x$declared_keys, use.names = FALSE)) &&
        checkmate::test_character(
          unlist(x$permitted_treatment_variables, use.names = FALSE),
          min.len = 1L,
          any.missing = FALSE,
          unique = TRUE
        )
    }, logical(1)))
  if (valid) {
    identifiers <- lapply(c("scenario_id", "dataset_id", "snapshot_id", "file"), function(field) {
      vapply(manifest$scenarios, `[[`, "", field)
    })
    valid <- all(vapply(identifiers, function(x) !anyDuplicated(x), logical(1)))
  }
  if (!valid) {
    cli::cli_abort("The governed synthetic scenario manifest is invalid")
  }
  invisible(manifest)
}

#' Read the governed synthetic scenario manifest
#'
#' @param root Governed synthetic-data directory.
#'
#' @return The validated versioned manifest.
#' @export
synthetic_scenario_manifest <- function(root = .synthetic_data_root()) {
  manifest <- jsonlite::read_json(
    file.path(root, "scenario-manifest.json"),
    simplifyVector = FALSE
  )
  .validate_synthetic_manifest(manifest)
  manifest
}

#' Load a governed synthetic BDS scenario
#'
#' @param scenario_id Scenario identifier from [synthetic_scenario_manifest()].
#' @param root Governed synthetic-data directory.
#'
#' @return A hash-verified synthetic BDS data frame.
#' @export
load_synthetic_scenario <- function(scenario_id, root = .synthetic_data_root()) {
  if (!checkmate::test_string(scenario_id, min.chars = 1L)) {
    cli::cli_abort("{.arg scenario_id} must be one non-empty identifier")
  }
  manifest <- synthetic_scenario_manifest(root)
  matches <- which(vapply(
    manifest$scenarios,
    function(x) identical(x$scenario_id, scenario_id),
    logical(1)
  ))
  if (length(matches) != 1L) {
    cli::cli_abort("{.val {scenario_id}} is not a governed synthetic scenario")
  }
  metadata <- manifest$scenarios[[matches]]
  data <- readRDS(file.path(root, metadata$file))
  if (!identical(study_data_content_hash(data), metadata$content_hash)) {
    cli::cli_abort("The synthetic scenario content hash does not match its manifest")
  }
  data
}

.write_synthetic_scenarios <- function(root = .synthetic_data_root()) {
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  scenarios <- .synthetic_scenario_data()
  manifest <- .build_synthetic_manifest(scenarios)
  for (scenario in manifest$scenarios) {
    saveRDS(
      scenarios[[scenario$scenario_id]],
      file.path(root, scenario$file),
      version = 3,
      compress = "xz"
    )
  }
  jsonlite::write_json(
    manifest,
    file.path(root, "scenario-manifest.json"),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    digits = NA
  )
  invisible(manifest)
}

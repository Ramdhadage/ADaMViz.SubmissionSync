synthetic_bds_fixture <- function() {
  data.frame(
    STUDYID = "SYNTH001",
    USUBJID = rep(sprintf("SYNTH001-%03d", 1:6), each = 3L),
    PARAMCD = "ALT",
    PARAM = "Alanine aminotransferase",
    AVISIT = rep(c("Baseline", "Week 4", "Week 8"), times = 6L),
    AVISITN = rep(c(0, 4, 8), times = 6L),
    AVAL = c(
      20, 24, 26,
      22, 25, 28,
      24, 27, 30,
      26, 29, 32,
      28, NA, 34,
      30, NA, 36
    ),
    CHG = c(
      0, 4, 6,
      0, 3, 6,
      0, 3, 6,
      0, 3, 6,
      0, NA, 6,
      0, NA, 6
    ),
    PCHG = c(
      0, 20, 30,
      0, 13.6363636364, 27.2727272727,
      0, 12.5, 25,
      0, 11.5384615385, 23.0769230769,
      0, NA, 21.4285714286,
      0, NA, 20
    ),
    AVALU = "U/L",
    TRT01A = rep(c("Placebo", "Active"), each = 9L),
    ANL01FL = rep(c("Y", "N"), 9L),
    stringsAsFactors = FALSE
  )
}

expected_week4_counts <- data.frame(
  TRT01A = c("Active", "Placebo"),
  AVISIT = c("Week 4", "Week 4"),
  AVISITN = c(4, 4),
  source_n = c(3L, 3L),
  n = c(1L, 3L),
  low_n = c(TRUE, TRUE),
  stringsAsFactors = FALSE
)

make_test_snapshot <- function(data = synthetic_bds_fixture(), declared_keys = c(
  "STUDYID", "USUBJID", "PARAMCD", "AVISITN"
)) {
  structure(
    list(
      snapshot_contract_version = "study-snapshot-v1",
      snapshot_id = "fixture-v1",
      dataset_id = "fixture-adlb",
      classification = "synthetic",
      adam_designation = "BDS",
      declared_keys = declared_keys,
      metadata_version = "fixture-metadata-v1",
      content_hash = "fixture-hash",
      permitted_treatment_variables = "TRT01A",
      data = data
    ),
    class = "study_data_snapshot"
  )
}

default_profile_selections <- function(...) {
  selections <- list(
    paramcd = "ALT",
    y_variable = "AVAL",
    unit = "U/L",
    treatment_variable = "TRT01A",
    treatment_levels = c("Active", "Placebo"),
    visits = c("Baseline", "Week 4", "Week 8")
  )
  utils::modifyList(selections, list(...), keep.null = TRUE)
}

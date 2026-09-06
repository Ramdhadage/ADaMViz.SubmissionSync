test_that("profile keeps stored selected records and counts distinct nonmissing subjects", {
  result <- validate_bds_profile(
    make_test_snapshot(),
    default_profile_selections(),
    low_n_threshold = 5
  )

  expect_false(result$blocked)
  expect_length(result$blocking_diagnostics, 0L)
  expect_identical(nrow(result$selected_data), 18L)
  expect_identical(nrow(result$display_data), 16L)
  week4_counts <- result$counts[result$counts$AVISIT == "Week 4", ]
  row.names(week4_counts) <- NULL
  expect_identical(week4_counts, expected_week4_counts)
  expect_true("low_sample_size" %in% vapply(result$warnings, `[[`, "", "code"))
  expect_true(all(result$selected_data$ANL01FL %in% c("Y", "N")))
})

test_that("multiple units require an explicit authorized choice", {
  data <- synthetic_bds_fixture()
  data$AVALU[data$USUBJID == "SYNTH001-006"] <- "ukat/L"

  unresolved <- validate_bds_profile(
    make_test_snapshot(data),
    default_profile_selections(unit = NULL)
  )
  expect_true(unresolved$blocked)
  expect_identical(unresolved$blocking_diagnostics[[1]]$code, "unit_selection_required")
  expect_identical(unresolved$choices$units, c("U/L", "ukat/L"))
  expect_equal(nrow(unresolved$display_data), 0L)

  resolved <- validate_bds_profile(
    make_test_snapshot(data),
    default_profile_selections(unit = "U/L")
  )
  expect_false(resolved$blocked)
  expect_false(any(resolved$selected_data$USUBJID == "SYNTH001-006"))
})

test_that("duplicate visit keys block with ephemeral authorized detail only", {
  data <- synthetic_bds_fixture()
  duplicate <- data[data$USUBJID == "SYNTH001-001" & data$AVISIT == "Week 4", ]
  duplicate$AVAL <- 999
  result <- validate_bds_profile(
    make_test_snapshot(rbind(data, duplicate)),
    default_profile_selections()
  )

  expect_true(result$blocked)
  expect_identical(result$blocking_diagnostics[[1]]$code, "unsupported_duplicate_visit_key")
  expect_match(result$blocking_diagnostics[[1]]$message, "unsupported")
  expect_identical(result$authorized_diagnostics$duplicate_keys$USUBJID, "SYNTH001-001")
  expect_false(grepl("SYNTH001-001", canonical_serialize(result$durable_diagnostics), fixed = TRUE))
  expect_identical(result$dataset_conformance, "not_assessed")
  expect_equal(nrow(result$display_data), 0L)
})

test_that("visit mapping defects block deterministically", {
  cases <- list(
    missing_order = transform(synthetic_bds_fixture(), AVISITN = replace(AVISITN, AVISIT == "Week 4", NA)),
    conflicting_order = transform(synthetic_bds_fixture(), AVISITN = replace(AVISITN, USUBJID == "SYNTH001-001" & AVISIT == "Week 4", 5)),
    reused_order = transform(synthetic_bds_fixture(), AVISITN = replace(AVISITN, AVISIT == "Week 8", 4)),
    missing_label = transform(synthetic_bds_fixture(), AVISIT = replace(AVISIT, AVISIT == "Week 4", NA))
  )

  results <- lapply(cases, function(data) {
    validate_bds_profile(make_test_snapshot(data), default_profile_selections())
  })
  expect_true(all(vapply(results, `[[`, FALSE, "blocked")))
  expect_true(all(vapply(results, function(x) {
    x$blocking_diagnostics[[1]]$code == "invalid_visit_mapping"
  }, logical(1))))
})

test_that("numeric Y and complete selected profile keys are required", {
  nonnumeric <- synthetic_bds_fixture()
  nonnumeric$AVAL <- as.character(nonnumeric$AVAL)
  nonnumeric_result <- validate_bds_profile(
    make_test_snapshot(nonnumeric),
    default_profile_selections()
  )
  expect_true(nonnumeric_result$blocked)
  expect_identical(
    nonnumeric_result$blocking_diagnostics[[1]]$code,
    "selected_y_not_numeric"
  )

  missing_subject <- synthetic_bds_fixture()
  missing_subject$USUBJID[[1]] <- NA_character_
  missing_subject_result <- validate_bds_profile(
    make_test_snapshot(missing_subject),
    default_profile_selections()
  )
  expect_true(missing_subject_result$blocked)
  expect_identical(
    missing_subject_result$blocking_diagnostics[[1]]$code,
    "missing_profile_key"
  )

  missing_treatment <- synthetic_bds_fixture()
  missing_treatment$TRT01A[[1]] <- NA_character_
  missing_treatment_result <- validate_bds_profile(
    make_test_snapshot(missing_treatment),
    default_profile_selections()
  )
  expect_true(missing_treatment_result$blocked)
  expect_identical(
    missing_treatment_result$blocking_diagnostics[[1]]$code,
    "missing_treatment_value"
  )
})

test_that("explicit exclusions precede key checks and propagate downstream", {
  data <- synthetic_bds_fixture()
  excluded_duplicate <- data[data$USUBJID == "SYNTH001-001" & data$AVISIT == "Week 8", ]
  data <- rbind(data, excluded_duplicate)

  result <- validate_bds_profile(
    make_test_snapshot(data),
    default_profile_selections(
      treatment_levels = "Placebo",
      visits = c("Baseline", "Week 4")
    )
  )
  expect_false(result$blocked)
  expect_identical(unique(result$selected_data$TRT01A), "Placebo")
  expect_identical(unique(result$selected_data$AVISIT), c("Baseline", "Week 4"))
  expect_identical(result$choices$included_treatment_levels, "Placebo")
  expect_identical(result$choices$included_visits, c("Baseline", "Week 4"))
})

test_that("empty combinations and empty included facets do not create display rows", {
  data <- synthetic_bds_fixture()
  data$AVAL[data$TRT01A == "Active" & data$AVISIT == "Week 4"] <- NA_real_
  data$AVAL[data$TRT01A == "Placebo"] <- NA_real_
  result <- validate_bds_profile(make_test_snapshot(data), default_profile_selections())

  expect_false(result$blocked)
  expect_false(any(result$display_data$AVISIT == "Week 4"))
  expect_identical(result$facet_levels, c("Active", "Placebo"))
  warning_codes <- vapply(result$warnings, `[[`, "", "code")
  expect_true("empty_treatment_visit" %in% warning_codes)
  expect_true("empty_treatment_level" %in% warning_codes)
  expect_false(any(result$counts$TRT01A == "Placebo"))
})

test_that("additional legitimate timepoint keys are unsupported rather than invalid ADaM", {
  data <- synthetic_bds_fixture()
  data$ATPTN <- 1L
  repeated <- data[data$USUBJID == "SYNTH001-001" & data$AVISIT == "Week 4", ]
  repeated$ATPTN <- 2L
  result <- validate_bds_profile(
    make_test_snapshot(rbind(data, repeated), declared_keys = c(
      "STUDYID", "USUBJID", "PARAMCD", "AVISITN", "ATPTN"
    )),
    default_profile_selections()
  )

  expect_true(result$blocked)
  expect_identical(result$blocking_diagnostics[[1]]$code, "unsupported_additional_timepoint_keys")
  expect_identical(result$dataset_conformance, "not_assessed")
})

test_that("row permutation preserves diagnostics counts choices and analytical input", {
  data <- synthetic_bds_fixture()
  first <- validate_bds_profile(make_test_snapshot(data), default_profile_selections())
  second <- validate_bds_profile(
    make_test_snapshot(data[sample.int(nrow(data)), , drop = FALSE]),
    default_profile_selections()
  )

  expect_identical(first$choices, second$choices)
  expect_identical(first$blocking_diagnostics, second$blocking_diagnostics)
  expect_identical(first$warnings, second$warnings)
  expect_identical(first$counts, second$counts)
  expect_identical(first$selected_data, second$selected_data)
  expect_identical(first$display_data, second$display_data)
  expect_identical(first$analytical_input_hash, second$analytical_input_hash)
})

test_that("non-default low-N thresholds require retained sponsor approval", {
  expect_error(
    validate_bds_profile(make_test_snapshot(), default_profile_selections(), 4),
    "sponsor-approved"
  )

  approval <- list(
    value = 4,
    rationale = "Protocol-defined sparse threshold",
    authority = "Synthetic sponsor policy",
    version = "threshold-policy-v1"
  )
  result <- validate_bds_profile(make_test_snapshot(), default_profile_selections(), approval)
  expect_identical(result$low_n_policy, approval)
})

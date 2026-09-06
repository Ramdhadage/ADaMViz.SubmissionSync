test_that("governed synthetic manifest is versioned complete and hash-bound", {
  manifest <- synthetic_scenario_manifest()
  expect_identical(manifest$manifest_version, "synthetic-bds-manifest-v1")
  expect_identical(manifest$generator_version, "synthetic-bds-generator-v1")
  expect_true(length(manifest$scenarios) >= 9L)

  required <- c(
    "standard", "multiple-units", "duplicate-keys", "sparse-missing",
    "empty-combination", "bad-visit-mapping", "empty-treatment",
    "extra-timepoint-keys", "identifier-canary"
  )
  expect_true(all(required %in% vapply(manifest$scenarios, `[[`, "", "scenario_id")))
  expect_true(all(vapply(manifest$scenarios, function(x) {
    all(nzchar(c(
      x$scenario_id, x$dataset_id, x$purpose, x$expected_behavior,
      x$generator_version, x$content_hash
    ))) && is.numeric(x$seed)
  }, logical(1))))

  for (scenario in manifest$scenarios) {
    data <- load_synthetic_scenario(scenario$scenario_id)
    expect_s3_class(data, "data.frame")
    expect_identical(study_data_content_hash(data), scenario$content_hash)
  }
})

test_that("manifest expectations agree with profile behavior", {
  provider <- local_study_data_provider()
  cases <- list(
    standard = default_profile_selections(),
    `multiple-units` = default_profile_selections(unit = NULL),
    `duplicate-keys` = default_profile_selections(),
    `sparse-missing` = default_profile_selections(),
    `empty-combination` = default_profile_selections(),
    `bad-visit-mapping` = default_profile_selections(),
    `empty-treatment` = default_profile_selections(),
    `extra-timepoint-keys` = default_profile_selections(),
    `identifier-canary` = default_profile_selections()
  )

  results <- lapply(names(cases), function(id) {
    validate_bds_profile(
      pin_study_snapshot(provider, paste0("adlb-", id)),
      cases[[id]]
    )
  })
  names(results) <- names(cases)

  expect_false(results$standard$blocked)
  expect_identical(results$`multiple-units`$blocking_diagnostics[[1]]$code, "unit_selection_required")
  expect_identical(results$`duplicate-keys`$blocking_diagnostics[[1]]$code, "unsupported_duplicate_visit_key")
  expect_true("low_sample_size" %in% vapply(results$`sparse-missing`$warnings, `[[`, "", "code"))
  expect_true("empty_treatment_visit" %in% vapply(results$`empty-combination`$warnings, `[[`, "", "code"))
  expect_identical(results$`bad-visit-mapping`$blocking_diagnostics[[1]]$code, "invalid_visit_mapping")
  expect_true("empty_treatment_level" %in% vapply(results$`empty-treatment`$warnings, `[[`, "", "code"))
  expect_identical(results$`extra-timepoint-keys`$blocking_diagnostics[[1]]$code, "unsupported_additional_timepoint_keys")

  canary <- "SYNTH-CANARY-DO-NOT-RETAIN"
  expect_true(any(grepl(canary, results$`identifier-canary`$authorized_diagnostics$duplicate_keys$USUBJID, fixed = TRUE)))
  expect_false(grepl(canary, canonical_serialize(results$`identifier-canary`$durable_diagnostics), fixed = TRUE))
  expect_false(grepl(canary, canonical_serialize(list_study_catalog(provider)), fixed = TRUE))
})

test_that("manifest rejects ambiguous authorization metadata", {
  manifest <- synthetic_scenario_manifest()
  manifest$scenarios[[2]]$dataset_id <- manifest$scenarios[[1]]$dataset_id
  expect_error(.validate_synthetic_manifest(manifest), "invalid")

  manifest <- synthetic_scenario_manifest()
  manifest$scenarios[[1]]$declared_keys <- "STUDYID"
  expect_error(.validate_synthetic_manifest(manifest), "invalid")

  manifest <- synthetic_scenario_manifest()
  manifest$scenarios[[1]]$content_hash <- "not-a-sha256-hash"
  expect_error(.validate_synthetic_manifest(manifest), "invalid")
})

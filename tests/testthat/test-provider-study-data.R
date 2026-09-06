test_that("local provider exposes authorized metadata and pins a verified snapshot", {
  provider <- local_study_data_provider()
  catalog <- list_study_catalog(provider)

  expect_s3_class(provider, "study_data_provider")
  expect_true(nrow(catalog) >= 9L)
  expect_named(catalog, c(
    "dataset_id", "classification", "adam_designation", "declared_keys",
    "metadata_version", "content_hash", "permitted_treatment_variables",
    "snapshot_id", "scenario_id", "purpose", "expected_behavior"
  ))
  expect_true(all(catalog$classification == "synthetic"))
  expect_true(all(catalog$adam_designation == "BDS"))
  expect_false(any(grepl("\\.rds$|[/\\\\]", unlist(catalog), ignore.case = TRUE)))

  snapshot <- pin_study_snapshot(provider, "adlb-standard")
  expect_s3_class(snapshot, "study_data_snapshot")
  expect_identical(snapshot$content_hash, catalog$content_hash[catalog$dataset_id == "adlb-standard"])
  expect_identical(snapshot$classification, "synthetic")
  expect_identical(snapshot$adam_designation, "BDS")
  expect_identical(snapshot$permitted_treatment_variables, "TRT01A")
  expect_identical(snapshot$content_hash, study_data_content_hash(snapshot$data))
})

test_that("snapshot hashes and catalog order do not depend on source row order", {
  data <- synthetic_bds_fixture()
  expect_identical(
    study_data_content_hash(data),
    study_data_content_hash(data[rev(seq_len(nrow(data))), , drop = FALSE])
  )

  provider <- local_study_data_provider()
  first <- list_study_catalog(provider)
  second <- list_study_catalog(provider)
  expect_identical(first, second)
  expect_identical(first$dataset_id, sort(first$dataset_id, method = "radix"))
})

test_that("provider rejects unauthorized and modified snapshots", {
  provider <- local_study_data_provider()
  expect_error(pin_study_snapshot(provider, "not-authorized"), "authorized catalog")

  tampered <- provider
  tampered$manifest$scenarios[[1]]$content_hash <- paste0(
    tampered$manifest$scenarios[[1]]$content_hash,
    "0"
  )
  expect_error(pin_study_snapshot(tampered, tampered$manifest$scenarios[[1]]$dataset_id), "hash")
})

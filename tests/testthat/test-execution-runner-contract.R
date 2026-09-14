test_that("local execution runner returns a bounded versioned result manifest", {
  skip_if_graphics_device_unavailable()
  fixture <- execution_fixture()
  result <- run_execution_locally(
    request = fixture$request,
    script = fixture$script,
    analysis_data = fixture$profile$selected_data,
    work_dir = withr::local_tempdir()
  )

  expect_s3_class(result, "execution_runner_result")
  expect_identical(result$status, "succeeded")
  expect_s3_class(result$result, "execution_result")
  expect_identical(result$result$manifest_version, "execution-result-v1")
  expect_identical(result$result$script_hash, .execution_hash_text(fixture$script))
  expect_identical(
    result$result$analytical_hash,
    canonical_hash(result$analytical_output)
  )
  expect_match(result$result$image_hash, "^[0-9a-f]{64}$")
  expect_true(fs::file_exists(result$image_path))
})

test_that("runner rejects mismatched scripts and non-POC classifications", {
  fixture <- execution_fixture()

  expect_error(
    run_execution_locally(
      request = fixture$request,
      script = paste0(fixture$script, "\n"),
      analysis_data = fixture$profile$selected_data,
      work_dir = withr::local_tempdir()
    ),
    "script hash"
  )
  expect_error(
    run_execution_locally(
      request = fixture$request,
      script = fixture$script,
      analysis_data = fixture$profile$selected_data,
      data_classification = "clinical",
      work_dir = withr::local_tempdir()
    ),
    "synthetic or de-identified"
  )
})

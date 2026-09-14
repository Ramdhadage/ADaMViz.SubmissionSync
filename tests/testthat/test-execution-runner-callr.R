test_that("callr runner executes in a clean subprocess", {
  skip_if_not_installed("callr")
  skip_if_not_installed("devtools")
  skip_if_graphics_device_unavailable()
  fixture <- execution_fixture()
  source_root <- normalizePath(
    testthat::test_path("..", ".."),
    winslash = "/",
    mustWork = TRUE
  )

  result <- run_execution_callr(
    request = fixture$request,
    script = fixture$script,
    analysis_data = fixture$profile$selected_data,
    work_dir = withr::local_tempdir(),
    timeout = 60,
    source_root = source_root
  )
  skip_if(
    identical(result$status, "failed") &&
      grepl("Graphics API version mismatch", result$diagnostics$stderr, fixed = TRUE),
    "callr subprocess graphics device is incompatible in this R environment"
  )

  expect_s3_class(result, "execution_runner_result")
  expect_identical(result$status, "succeeded")
  expect_s3_class(result$result, "execution_result")
  expect_identical(result$result$snapshot_hash, fixture$request$snapshot_hash)
})

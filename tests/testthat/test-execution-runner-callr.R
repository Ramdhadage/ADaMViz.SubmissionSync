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

test_that("callr runner resolves the active source root from a nested working directory", {
  source_root <- normalizePath(
    testthat::test_path("..", ".."),
    winslash = "/",
    mustWork = TRUE
  )
  withr::local_dir(fs::path(source_root, "tests", "testthat"))

  expect_identical(.execution_source_root(), source_root)
})

test_that("callr runner honors an explicitly configured source root", {
  source_root <- normalizePath(
    testthat::test_path("..", ".."),
    winslash = "/",
    mustWork = TRUE
  )
  withr::local_envvar(ADAMVIZ_SUBMISSIONSYNC_SOURCE_ROOT = source_root)
  withr::local_dir(tempdir())

  expect_identical(.execution_source_root(), source_root)
})

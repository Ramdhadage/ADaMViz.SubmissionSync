test_that("verification passes only complete runtime evidence", {
  fixture <- execution_fixture()
  runner_result <- fake_successful_runner_result(fixture)

  verification <- verify_execution_result(
    request = fixture$request,
    script = fixture$script,
    analysis_data = fixture$profile$selected_data,
    runner_result = runner_result
  )
  expect_s3_class(verification, "execution_verification")
  expect_identical(verification$status, "passed")
  expect_length(verification$failed_checks, 0L)

  runner_result$result$image_hash <- NULL
  failed <- verify_execution_result(
    request = fixture$request,
    script = fixture$script,
    analysis_data = fixture$profile$selected_data,
    runner_result = runner_result
  )
  expect_identical(failed$status, "failed")
  expect_setequal(failed$failed_checks, "image_hash")
})

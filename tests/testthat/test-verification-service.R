test_that("verification passes only complete runtime evidence", {
  fixture <- execution_fixture()
  runner_result <- fake_success_runner_result(fixture)

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

test_that("verification binds the result manifest to the execution request", {
  fixture <- execution_fixture()
  runner_result <- fake_success_runner_result(fixture)
  runner_result$result$spec_hash <- "different-specification"

  verification <- verify_execution_result(
    request = fixture$request,
    script = fixture$script,
    analysis_data = fixture$profile$selected_data,
    runner_result = runner_result
  )

  expect_identical(verification$status, "failed")
  expect_setequal(verification$failed_checks, "request_binding")
})

test_that("verification hashes the produced image bytes", {
  fixture <- execution_fixture()
  runner_result <- fake_success_runner_result(fixture)
  writeBin(charToRaw("tampered png bytes"), runner_result$image_path)

  verification <- verify_execution_result(
    request = fixture$request,
    script = fixture$script,
    analysis_data = fixture$profile$selected_data,
    runner_result = runner_result
  )

  expect_identical(verification$status, "failed")
  expect_setequal(verification$failed_checks, "image_hash")
})

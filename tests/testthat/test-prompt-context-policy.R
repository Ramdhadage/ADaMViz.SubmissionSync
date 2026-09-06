test_that("prompt context keeps only approved aggregate content", {
  context <- new_prompt_context("adlb-v1", labels = list(parameter = "ALT"))
  expect_s3_class(context, "prompt_context")
  expect_snapshot(error = TRUE, new_prompt_context("adlb-v1", labels = list(id = "USUBJID")))
})

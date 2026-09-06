test_that("limits reject content above their configured boundary", {
  policy <- new_limits_policy(max_prompt_chars = 4L)
  expect_identical(policy$max_prompt_chars, 4L)
  expect_snapshot(error = TRUE, enforce_limit("12345", policy$max_prompt_chars, "prompt"))
})

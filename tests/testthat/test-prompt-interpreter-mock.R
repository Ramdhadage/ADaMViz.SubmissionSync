test_that("mock interpreter converts a representative boxplot prompt to a candidate", {
  snapshot <- make_test_snapshot()
  context <- build_prompt_context(snapshot)
  result <- interpret_prompt(
    "Create a boxplot of ALT AVAL by treatment over all visits.",
    context,
    mock_prompt_interpreter(),
    snapshot = snapshot
  )

  expect_s3_class(result, "prompt_interpretation")
  expect_identical(result$status, "candidate")
  expect_s3_class(result$candidate, "plot_spec")
  expect_identical(result$candidate$fields$paramcd, "ALT")
  expect_identical(result$candidate$fields$y_variable, "AVAL")
  expect_identical(result$candidate$fields$treatment_levels, c("Active", "Placebo"))
  expect_identical(result$candidate$fields$visits, c("Baseline", "Week 4", "Week 8"))
  expect_null(result$executable_code)
})

test_that("mock interpreter preserves explicit visit exclusions", {
  snapshot <- make_test_snapshot()
  context <- build_prompt_context(snapshot)
  result <- interpret_prompt(
    "Create an ALT AVAL boxplot by treatment but exclude Week 8.",
    context,
    mock_prompt_interpreter(),
    snapshot = snapshot
  )

  expect_identical(result$status, "candidate")
  expect_identical(result$candidate$fields$visits, c("Baseline", "Week 4"))
})

test_that("mock interpreter requires confirmation for free scales", {
  snapshot <- make_test_snapshot()
  context <- build_prompt_context(snapshot)
  result <- interpret_prompt(
    "Create an ALT AVAL boxplot by treatment with free scale facets.",
    context,
    mock_prompt_interpreter(),
    snapshot = snapshot
  )

  expect_identical(result$status, "clarification")
  expect_identical(result$candidate$fields$scale_mode, "free")
  expect_named(result$clarifications$required_confirmations, "scale_mode")
})

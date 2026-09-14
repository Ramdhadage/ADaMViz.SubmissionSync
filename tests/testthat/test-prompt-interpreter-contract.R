test_that("ambiguous parameter cannot create an executable specification", {
  snapshot <- make_test_snapshot()
  context <- build_prompt_context(snapshot)
  result <- interpret_prompt(
    "Create the lab boxplot.",
    context,
    mock_prompt_interpreter(),
    snapshot = snapshot
  )

  expect_identical(result$status, "clarification")
  expect_null(result$candidate)
  expect_null(result$executable_code)
})

test_that("arbitrary R requests are deferred before provider calls", {
  snapshot <- make_test_snapshot()
  context <- build_prompt_context(snapshot)
  result <- interpret_prompt(
    "Write and run R code with ggplot(analysis_data) for ALT.",
    context,
    mock_prompt_interpreter(),
    snapshot = snapshot
  )

  expect_identical(result$status, "manual_selection")
  expect_identical(result$metadata$provider_called, FALSE)
  expect_identical(result$clarifications$reason, "arbitrary_r_deferred")
  expect_null(result$candidate)
})

test_that("extra provider and candidate fields fail closed", {
  snapshot <- make_test_snapshot()
  context <- build_prompt_context(snapshot)
  extra_response <- structure(
    list(
      provider = "extra-mock",
      model = "extra-v1",
      interpret = function(prompt, context) {
        list(status = "candidate", fields = list(paramcd = "ALT"), markdown = "ignored")
      }
    ),
    class = "prompt_interpreter"
  )
  result <- interpret_prompt("Create ALT boxplot.", context, extra_response, snapshot = snapshot)
  expect_identical(result$status, "manual_selection")
  expect_identical(result$clarifications$reason, "extra_provider_fields")

  extra_field <- extra_response
  extra_field$interpret <- function(prompt, context) {
    list(status = "candidate", fields = list(paramcd = "ALT", code = "system('whoami')"))
  }
  result <- interpret_prompt("Create ALT boxplot.", context, extra_field, snapshot = snapshot)
  expect_identical(result$status, "manual_selection")
  expect_identical(result$clarifications$reason, "extra_candidate_fields")
})

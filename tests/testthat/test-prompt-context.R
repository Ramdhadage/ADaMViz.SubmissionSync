test_that("prompt context is built from authorized aggregate choices only", {
  snapshot <- make_test_snapshot()
  context <- build_prompt_context(snapshot)

  expect_s3_class(context, "prompt_context")
  expect_identical(context$dataset_id, "fixture-adlb")
  expect_identical(names(context$aggregate_profile$parameters), "ALT")
  expect_identical(context$aggregate_profile$y_variables, c("AVAL", "CHG", "PCHG"))
  expect_identical(
    vapply(context$aggregate_profile$visits, `[[`, "", "label"),
    c("Baseline", "Week 4", "Week 8")
  )
  expect_false(any(grepl("USUBJID|SYNTH001-[0-9]+", unlist(context), ignore.case = TRUE)))
})

test_that("prompt context blocks prohibited labels and metadata", {
  expect_error(new_prompt_context("adlb-v1", labels = list(id = "USUBJID")), "prohibited")
  expect_error(
    new_prompt_context("adlb-v1", aggregate_profile = list(uri = "https://example.test")),
    "prohibited"
  )
})

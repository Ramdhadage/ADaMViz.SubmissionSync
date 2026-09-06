test_that("a complete plot specification becomes confirmable", {
  spec <- new_plot_spec(
    dataset_id = "adlb-v1", paramcd = "ALT", y_variable = "AVAL",
    unit = "U/L", treatment_variable = "TRT01A",
    treatment_levels = c("Placebo", "Drug"), visits = c("Baseline", "Week 4"),
    provenance = setNames(rep("user_confirmed", 8), .plot_spec_fields)
  )
  confirmed <- confirm_plot_spec(spec)
  expect_identical(confirmed$state, "confirmed")
  expect_identical(confirmed$hash, spec$hash)
})

test_that("incomplete specifications require clarification", {
  spec <- new_plot_spec(dataset_id = "adlb-v1")
  expect_setequal(
    plot_spec_clarifications(spec),
    setdiff(.plot_spec_fields, c("dataset_id", "scale_mode"))
  )
})

test_that("unsupported y variables and unknown provenance are rejected", {
  expect_snapshot(error = TRUE, new_plot_spec("adlb-v1", y_variable = "BASE"))
  expect_snapshot(error = TRUE, new_plot_spec("adlb-v1", provenance = list(path = "prompt")))
})

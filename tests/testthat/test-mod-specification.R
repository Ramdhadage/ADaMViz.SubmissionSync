test_that("specification module renders confirmed fields and provenance", {
  spec <- new_plot_spec(
    dataset_id = "fixture-adlb",
    paramcd = "ALT",
    y_variable = "AVAL",
    unit = "U/L",
    treatment_variable = "TRT01A",
    treatment_levels = c("Active", "Placebo"),
    visits = c("Baseline", "Week 4"),
    provenance = stats::setNames(rep("user_confirmed", 8L), .plot_spec_fields),
    state = "confirmed"
  )
  current_revision <- shiny::reactiveVal(list(spec = spec))

  shiny::testServer(
    mod_specification_server,
    args = list(current_revision = current_revision),
    {
      rendered <- output$fields
      expect_match(rendered, "paramcd")
      expect_match(rendered, "ALT")
      expect_match(rendered, "user_confirmed")
    }
  )
})

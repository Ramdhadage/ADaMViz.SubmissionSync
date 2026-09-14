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

test_that("specification module executes user-confirmed selections", {
  spec <- new_plot_spec(
    dataset_id = "fixture-adlb",
    paramcd = "ALT",
    y_variable = "AVAL",
    unit = NULL,
    treatment_variable = "TRT01A",
    treatment_levels = c("Active", "Placebo"),
    visits = c("Baseline", "Week 4", "Week 8"),
    provenance = list(
      dataset_id = "metadata",
      paramcd = "prompt",
      y_variable = "prompt",
      treatment_variable = "prompt",
      treatment_levels = "prompt",
      visits = "prompt",
      scale_mode = "default"
    )
  )
  current_revision <- shiny::reactiveVal(list(
    spec = spec,
    pending = list(
      choices = list(
        parameters = "ALT",
        units = list(ALT = c("U/L", "ukat/L")),
        y_variables = c("AVAL", "CHG", "PCHG"),
        treatment_variables = "TRT01A",
        treatment_levels = list(TRT01A = c("Active", "Placebo")),
        visits = c("Baseline", "Week 4", "Week 8"),
        scale_modes = c("fixed", "free")
      )
    )
  ))
  requests <- list()
  execute_revision <- function(fields) {
    requests[[length(requests) + 1L]] <<- fields
  }

  shiny::testServer(
    mod_specification_server,
    args = list(current_revision = current_revision, execute_revision = execute_revision),
    {
      session$flushReact()
      session$setInputs(unit = "U/L", visits = c("Baseline", "Week 4"))
      session$setInputs(execute = 1)
      session$flushReact()

      expect_length(requests, 1L)
      expect_identical(requests[[1]]$unit, "U/L")
      expect_identical(requests[[1]]$visits, c("Baseline", "Week 4"))
      expect_identical(requests[[1]]$treatment_levels, c("Active", "Placebo"))
    }
  )
})

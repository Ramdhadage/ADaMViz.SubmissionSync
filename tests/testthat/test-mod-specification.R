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

test_that("specification module keeps generated settings visible but read-only", {
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
  current_revision <- shiny::reactiveVal(list(
    spec = spec,
    revision = list(status = "Draft"),
    choices = list(
      parameters = "ALT",
      units = list(ALT = "U/L"),
      y_variables = c("AVAL", "CHG", "PCHG"),
      treatment_variables = "TRT01A",
      treatment_levels = list(TRT01A = c("Active", "Placebo")),
      visits = c("Baseline", "Week 4"),
      scale_modes = c("fixed", "free")
    )
  ))

  shiny::testServer(
    mod_specification_server,
    args = list(current_revision = current_revision),
    {
      session$flushReact()
      controls <- htmltools::renderTags(output$controls)$html

      expect_match(controls, "Parameter")
      expect_match(controls, "disabled")
      expect_no_match(controls, "Confirm and generate")
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
    args = list(
      current_revision = current_revision,
      execute_revision = execute_revision
    ),
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

test_that("specification module blocks unconfirmed free-scale execution", {
  spec <- new_plot_spec(
    dataset_id = "fixture-adlb",
    paramcd = "ALT",
    y_variable = "AVAL",
    unit = "U/L",
    treatment_variable = "TRT01A",
    treatment_levels = c("Active", "Placebo"),
    visits = c("Baseline", "Week 4", "Week 8"),
    scale_mode = "free",
    provenance = stats::setNames(rep("prompt", 8L), .plot_spec_fields)
  )
  current_revision <- shiny::reactiveVal(list(
    spec = spec,
    pending = list(
      choices = list(
        parameters = "ALT",
        units = list(ALT = "U/L"),
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
    args = list(
      current_revision = current_revision,
      execute_revision = execute_revision
    ),
    {
      session$flushReact()
      session$setInputs(scale_mode = "free", confirm_free_scale = FALSE)
      session$setInputs(execute = 1)
      session$flushReact()

      expect_length(requests, 0L)
      expect_match(
        htmltools::renderTags(output$message)$html,
        "Free Y scales require confirmation"
      )

      session$setInputs(confirm_free_scale = TRUE)
      session$setInputs(execute = 2)
      session$flushReact()

      expect_length(requests, 1L)
      expect_identical(requests[[1]]$scale_mode, "free")
    }
  )
})

test_that("specification module creates corrections from closed revisions", {
  spec <- new_plot_spec(
    dataset_id = "fixture-adlb",
    paramcd = "ALT",
    y_variable = "AVAL",
    unit = "U/L",
    treatment_variable = "TRT01A",
    treatment_levels = c("Active", "Placebo"),
    visits = c("Baseline", "Week 4", "Week 8"),
    provenance = stats::setNames(rep("user_confirmed", 8L), .plot_spec_fields),
    state = "confirmed"
  )
  current_revision <- shiny::reactiveVal(list(
    spec = spec,
    revision = list(status = "Reviewed"),
    choices = list(
      parameters = "ALT",
      units = list(ALT = "U/L"),
      y_variables = c("AVAL", "CHG", "PCHG"),
      treatment_variables = "TRT01A",
      treatment_levels = list(TRT01A = c("Active", "Placebo")),
      visits = c("Baseline", "Week 4", "Week 8"),
      scale_modes = c("fixed", "free")
    )
  ))
  corrections <- list()
  create_correction <- function(fields, rationale, provenance) {
    corrections[[length(corrections) + 1L]] <<- list(
      fields = fields,
      rationale = rationale,
      provenance = provenance
    )
  }

  shiny::testServer(
    mod_specification_server,
    args = list(
      current_revision = current_revision,
      create_correction = create_correction
    ),
    {
      session$flushReact()
      session$setInputs(
        visits = c("Baseline", "Week 4"),
        correction_rationale = "Refine reviewed visit scope",
        correction_provenance = "Reviewer change request"
      )
      session$setInputs(correct = 1)
      session$flushReact()

      expect_length(corrections, 1L)
      expect_identical(corrections[[1]]$fields$visits, c("Baseline", "Week 4"))
      expect_identical(corrections[[1]]$rationale, "Refine reviewed visit scope")
      expect_identical(corrections[[1]]$provenance, "Reviewer change request")
    }
  )
})

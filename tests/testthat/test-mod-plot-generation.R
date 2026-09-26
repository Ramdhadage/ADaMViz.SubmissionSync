test_that("plot generation UI gives traceability, review, and export its own step", {
  html <- as.character(mod_plot_generation_ui("plot_generation"))

  result_condition <- regexpr(
    "plot_generation-step_signal&#39;] === &#39;result",
    html,
    fixed = TRUE
  )[[1]]
  export_condition <- regexpr(
    "plot_generation-step_signal&#39;] === &#39;export",
    html,
    fixed = TRUE
  )[[1]]
  export_panel <- regexpr(
    "Traceability, review, and export",
    html,
    fixed = TRUE
  )[[1]]
  result_content <- vapply(
    c("Run Status", "Plot preview", "Optional: view automated checks", "Continue to export"),
    function(label) regexpr(label, html, fixed = TRUE)[[1]],
    integer(1)
  )
  export_content <- vapply(
    c("Revision History", "Two-Person Review", "Controlled export", "Back to result"),
    function(label) regexpr(label, html, fixed = TRUE)[[1]],
    integer(1)
  )

  expect_gt(result_condition, 0L)
  expect_gt(export_condition, 0L)
  expect_true(all(result_content > result_condition))
  expect_true(all(result_content < export_condition))
  expect_gt(export_panel, export_condition)
  expect_true(all(export_content > export_panel))
  expect_length(gregexpr("Traceability, review, and export", html, fixed = TRUE)[[1]], 1L)
  expect_match(html, "<details class=\"f001-panel\" open>\\s*<summary>Traceability, review, and export</summary>")
})

test_that("plot generation navigation reaches Export and returns to Result", {
  current_revision <- shiny::reactiveVal(.empty_assurance_state())
  execution_status <- shiny::reactiveVal("initial")

  shiny::testServer(
    mod_plot_generation_server,
    args = list(
      current_revision = current_revision,
      execute_revision = function(fields) NULL,
      create_correction = function(fields, rationale, provenance) NULL,
      execution_status = execution_status,
      workspace_provider = NULL
    ),
    {
      stepper <- paste(as.character(output$stepper), collapse = "")
      step_positions <- vapply(
        c("Data", "Ask", "Confirm", "Result", "Export"),
        function(label) regexpr(label, stepper, fixed = TRUE)[[1]],
        integer(1)
      )
      expect_true(all(step_positions > 0L))
      expect_true(all(diff(step_positions) > 0L))

      session$setInputs(to_export = 0)
      session$setInputs(to_export = 1)
      expect_match(
        paste(as.character(output$step_mark), collapse = ""),
        "Step 5 of 5",
        fixed = TRUE
      )

      session$setInputs(back_to_result = 0)
      session$setInputs(back_to_result = 1)
      expect_match(
        paste(as.character(output$step_mark), collapse = ""),
        "Step 4 of 5",
        fixed = TRUE
      )
    }
  )
})

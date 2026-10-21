test_that("revised questions replace the proposed Y variable before execution", {
  current_revision <- shiny::reactiveVal(.empty_assurance_state())
  executions <- 0L

  shiny::testServer(
    mod_plot_generation_server,
    args = list(
      current_revision = current_revision,
      execute_revision = function(fields) executions <<- executions + 1L,
      create_correction = NULL,
      workspace_provider = NULL
    ),
    {
      session$flushReact()
      session$setInputs(data_file = data.frame(
        name = "adlb-standard.csv",
        datapath = system.file(
          "extdata", "synthetic", "adlb-standard.csv",
          package = "ADaMViz.SubmissionSync"
        )
      ))
      for (y in c("AVAL", "CHG", "PCHG", "AVAL")) {
        question <- paste(
          "Create a boxplot of ALT", y, "by visit, split by treatment.",
          "Include all visits and treatment groups,",
          "show the number of subjects below each box, and connect the medians"
        )
        session$setInputs(question = question)
        session$setInputs(to_confirm = which(c("AVAL", "CHG", "PCHG") == y))
        state <- current_revision()
        expect_identical(state$spec$fields$y_variable, y)
        expect_identical(state$spec$fields$paramcd, "ALT")
        expect_identical(state$spec$fields$visits, state$choices$visits)
        expect_identical(
          state$spec$fields$treatment_levels,
          state$choices$treatment_levels$TRT01A
        )
        expect_identical(state$pending$prompt, question)
        expect_identical(state$spec$state, "candidate")
        expect_null(state$revision)
        session$setInputs(back_to_ask = 1)
      }
      expect_identical(executions, 0L)
    }
  )
})

test_that("questions without an interpreted candidate retain manual selection", {
  provider <- local_study_data_provider()
  for (question in c("Create a boxplot", "Execute R code for ALT CHG")) {
    state <- .create_assurance_candidate(provider, "adlb-standard", question)
    expect_null(state$spec$fields$y_variable)
    expect_identical(state$choices$y_variables, c("AVAL", "CHG", "PCHG"))
    expect_identical(state$pending$prompt, question)
    expect_null(state$revision)
  }
})

test_that("plot generation UI gives traceability, review, and export a step", {
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
    c(
      "Run Status", "Plot preview", "Optional: view automated checks",
      "Continue to export"
    ),
    function(label) regexpr(label, html, fixed = TRUE)[[1]],
    integer(1)
  )
  export_content <- vapply(
    c(
      "Revision History", "Two-Person Review", "Controlled export",
      "Back to result"
    ),
    function(label) regexpr(label, html, fixed = TRUE)[[1]],
    integer(1)
  )

  expect_gt(result_condition, 0L)
  expect_gt(export_condition, 0L)
  expect_true(all(result_content > result_condition))
  expect_true(all(result_content < export_condition))
  expect_gt(export_panel, export_condition)
  expect_true(all(export_content > export_panel))
  expect_length(
    gregexpr("Traceability, review, and export", html, fixed = TRUE)[[1]],
    1L
  )
  expect_match(
    html,
    paste0(
      "<details class=\"f001-panel\" open>\\s*",
      "<summary>Traceability, review, and export</summary>"
    )
  )
  expect_match(html, "id=\"plot_generation-back_to_ask_ui\"", fixed = TRUE)
  expect_match(
    html,
    "id=\"plot_generation-back_to_result_from_confirm_ui\"",
    fixed = TRUE
  )
})

test_that("plot generation navigation reaches Export and returns to Result", {
  current_revision <- shiny::reactiveVal(.empty_assurance_state())

  shiny::testServer(
    mod_plot_generation_server,
    args = list(
      current_revision = current_revision,
      execute_revision = function(fields) NULL,
      create_correction = function(fields, rationale, provenance) NULL,
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

test_that("plot generation returns from read-only Confirm to Result", {
  state <- .empty_assurance_state()
  state$revision <- list(status = "Draft")
  current_revision <- shiny::reactiveVal(state)

  shiny::testServer(
    mod_plot_generation_server,
    args = list(
      current_revision = current_revision,
      execute_revision = function(fields) NULL,
      create_correction = function(fields, rationale, provenance) NULL,
      workspace_provider = NULL
    ),
    {
      session$setInputs(back_to_confirm = 1)
      session$flushReact()
      expect_match(
        htmltools::renderTags(output$back_to_result_from_confirm_ui)$html,
        "Back to result"
      )

      session$setInputs(back_to_result_from_confirm = 1)
      session$flushReact()
      expect_match(
        paste(as.character(output$step_mark), collapse = ""),
        "Step 4 of 5",
        fixed = TRUE
      )
    }
  )
})

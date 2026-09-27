local_submission_sync_app <- function(name) {
  app <- shiny::shinyApp(
    ui = function(request) app_ui(request),
    server = app_server
  )
  driver <- local_browser_app(app, name)
  withr::defer(driver$stop(), envir = parent.frame())
  driver
}

create_standard_revision <- function(app) {
  app$upload_file(
    `plot_generation-data_file` = system.file(
      "extdata", "synthetic", "adlb-standard.csv",
      package = "ADaMViz.SubmissionSync"
    )
  )
  app$wait_for_js("document.querySelector('#plot_generation-to_ask')?.disabled === false")
  app$click("plot_generation-to_ask")
  app$set_inputs(`plot_generation-question` = "Create a boxplot of ALT AVAL by treatment over all visits.")
  app$click("plot_generation-to_confirm")
  app$wait_for_value(output = "plot_generation-specification-fields")
  app$click("plot_generation-specification-execute")
  app$wait_for_js("document.querySelector('#plot_generation-run_status-status').textContent.includes('Verified')", timeout = 120000)
  invisible(app)
}

test_that("browser prompt journey creates a Verified draft with evidence", {
  app <- local_submission_sync_app("prompt-to-verified")

  create_standard_revision(app)
  app$run_js("document.querySelector('#plot_generation-plot_preview-code').closest('details').open = true")
  app$run_js("document.querySelector('#plot_generation-evidence-checks').closest('details').open = true")
  app$wait_for_value(output = "plot_generation-evidence-checks")
  body <- app$get_text(selector = "body")

  expect_match(body, "Verified", fixed = TRUE)
  expect_match(body, "Executed R script", fixed = TRUE)
  expect_match(body, "Analytical output", fixed = TRUE)
  expect_match(body, "runner_success", fixed = TRUE)
})

test_that("browser prompt journey exports verified image and code", {
  app <- local_submission_sync_app("prompt-to-export")

  create_standard_revision(app)
  app$click("plot_generation-to_export")
  app$click("plot_generation-export-export")
  app$wait_for_js("document.querySelector('#plot_generation-export-message').textContent.includes('Exported receipt-')")

  body <- app$get_text(selector = "body")
  expect_match(body, "Exported receipt-", fixed = TRUE)
  expect_match(body, "rev-", fixed = TRUE)
})

test_that("browser review journey reaches Reviewed with two distinct approvals", {
  app <- local_submission_sync_app("two-person-review")

  create_standard_revision(app)
  app$click("plot_generation-to_export")
  app$set_inputs(
    `plot_generation-review-actor_id` = "stat-programmer",
    `plot_generation-review-role` = "statistical_programmer",
    `plot_generation-review-comment` = "Programmer browser acceptance approval."
  )
  app$click("plot_generation-review-approve")
  app$wait_for_js("document.querySelector('#plot_generation-review-decisions').textContent.includes('stat-programmer')")

  app$set_inputs(
    `plot_generation-review-actor_id` = "biostatistician",
    `plot_generation-review-role` = "biostatistician",
    `plot_generation-review-comment` = "Biostatistician browser acceptance approval."
  )
  app$click("plot_generation-review-approve")
  app$wait_for_js("document.querySelector('#plot_generation-revision_history-history').textContent.includes('Reviewed')")

  body <- app$get_text(selector = "body")
  expect_match(body, "Reviewed", fixed = TRUE)
  expect_match(body, "stat-programmer", fixed = TRUE)
  expect_match(body, "biostatistician", fixed = TRUE)

  app$click("plot_generation-review-approve")
  app$wait_for_js("document.querySelector('#plot_generation-review-message').textContent.includes('Reviewed revisions are immutable')")
  expect_match(
    app$get_text(selector = "body"),
    "Reviewed revisions are immutable",
    fixed = TRUE
  )
})

test_that("browser rejection closes the revision and blocks further review", {
  app <- local_submission_sync_app("review-rejection")

  create_standard_revision(app)
  app$click("plot_generation-to_export")
  app$set_inputs(
    `plot_generation-review-actor_id` = "stat-programmer",
    `plot_generation-review-role` = "statistical_programmer",
    `plot_generation-review-comment` = "Rejecting from browser acceptance."
  )
  app$click("plot_generation-review-reject")
  app$wait_for_js("document.querySelector('#plot_generation-revision_history-history').textContent.includes('Rejected')")

  body <- app$get_text(selector = "body")
  expect_match(body, "Rejected", fixed = TRUE)
  expect_match(body, "stat-programmer", fixed = TRUE)

  app$set_inputs(
    `plot_generation-review-actor_id` = "biostatistician",
    `plot_generation-review-role` = "biostatistician",
    `plot_generation-review-comment` = "Attempted post-rejection approval."
  )
  app$click("plot_generation-review-approve")
  app$wait_for_js("document.querySelector('#plot_generation-review-message').textContent.includes('Only a Verified revision can be reviewed')")
  expect_match(
    app$get_text(selector = "body"),
    "Only a Verified revision can be reviewed",
    fixed = TRUE
  )
})

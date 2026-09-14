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
  app$set_inputs(
    `prompt-dataset_id` = "adlb-standard",
    `prompt-prompt` = "Create a boxplot of ALT AVAL by treatment over all visits."
  )
  app$click("prompt-submit")
  app$wait_for_value(output = "specification-fields")
  app$click("specification-execute")
  app$wait_for_value(output = "run_status-status")
  app$wait_for_value(output = "specification-fields")
  app$wait_for_value(output = "plot_preview-code")
  app$wait_for_value(output = "evidence-checks")
  invisible(app)
}

test_that("browser prompt journey creates a Verified draft with evidence", {
  app <- local_submission_sync_app("prompt-to-verified")

  create_standard_revision(app)
  body <- app$get_text(selector = "body")

  expect_match(body, "Verified", fixed = TRUE)
  expect_match(body, "Specification hash", fixed = TRUE)
  expect_match(body, "Executed R script", fixed = TRUE)
  expect_match(body, "Analytical output", fixed = TRUE)
})

test_that("browser review journey reaches Reviewed with two distinct approvals", {
  app <- local_submission_sync_app("two-person-review")

  create_standard_revision(app)
  app$set_inputs(
    `review-actor_id` = "stat-programmer",
    `review-role` = "statistical_programmer",
    `review-comment` = "Programmer browser acceptance approval."
  )
  app$click("review-approve")
  app$wait_for_value(output = "review-decisions")

  app$set_inputs(
    `review-actor_id` = "biostatistician",
    `review-role` = "biostatistician",
    `review-comment` = "Biostatistician browser acceptance approval."
  )
  app$click("review-approve")
  app$wait_for_value(output = "run_status-status")

  body <- app$get_text(selector = "body")
  expect_match(body, "Reviewed", fixed = TRUE)
  expect_match(body, "stat-programmer", fixed = TRUE)
  expect_match(body, "biostatistician", fixed = TRUE)

  app$click("review-approve")
  app$wait_for_value(output = "review-message")
  expect_match(
    app$get_text(selector = "body"),
    "Reviewed revisions are immutable",
    fixed = TRUE
  )
})

test_that("browser rejection closes the revision and blocks further review", {
  app <- local_submission_sync_app("review-rejection")

  create_standard_revision(app)
  app$set_inputs(
    `review-actor_id` = "stat-programmer",
    `review-role` = "statistical_programmer",
    `review-comment` = "Rejecting from browser acceptance."
  )
  app$click("review-reject")
  app$wait_for_value(output = "run_status-status")

  body <- app$get_text(selector = "body")
  expect_match(body, "Rejected", fixed = TRUE)
  expect_match(body, "stat-programmer", fixed = TRUE)

  app$set_inputs(
    `review-actor_id` = "biostatistician",
    `review-role` = "biostatistician",
    `review-comment` = "Attempted post-rejection approval."
  )
  app$click("review-approve")
  app$wait_for_value(output = "review-message")
  expect_match(
    app$get_text(selector = "body"),
    "Only a Verified revision can be reviewed",
    fixed = TRUE
  )
})

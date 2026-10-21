local_submission_sync_app <- function(name) {
  # Build inside the subprocess so browser tests use the current source.
  app <- function() {
    source_root <- Sys.getenv("ADAMVIZ_SUBMISSIONSYNC_SOURCE_ROOT")
    if (nzchar(source_root)) devtools::load_all(source_root, quiet = TRUE)
    app_ui <- getFromNamespace("app_ui", "ADaMViz.SubmissionSync")
    app_server <- getFromNamespace("app_server", "ADaMViz.SubmissionSync")
    shiny::shinyApp(ui = function(request) app_ui(request), server = app_server)
  }
  driver <- local_browser_app(app, name) # nolint: object_usage_linter.
  cleanup_env <- parent.frame()
  if (!identical(cleanup_env, globalenv())) {
    withr::defer(driver$stop(), envir = cleanup_env)
  }
  driver
}

create_standard_revision <- function(app) {
  app$upload_file(
    `plot_generation-data_file` = system.file(
      "extdata", "synthetic", "adlb-standard.csv",
      package = "ADaMViz.SubmissionSync"
    )
  )
  app$wait_for_js(paste0(
    "document.querySelector('#plot_generation-to_ask')?.disabled ===",
    " false"
  ))
  app$click("plot_generation-to_ask")
  app$set_inputs(
    `plot_generation-question` = paste0(
      "Create a boxplot of ALT AVAL by treatment over all ",
      "visits."
    )
  )
  app$click("plot_generation-to_confirm")
  app$wait_for_value(output = "plot_generation-specification-fields")
  app$click("plot_generation-specification-execute")
  app$wait_for_idle()
  app$wait_for_js(
    paste0(
      "document.querySelector('#plot_generation-run_status-status')?",
      ".textContent.includes('Verified')"
    ),
    timeout = 120000
  )
  invisible(app)
}

open_export_step <- function(app) {
  app$click("plot_generation-to_export")
  app$wait_for_js(paste0(
    paste0(
      "document.querySelector('#plot_generation-export-heading')?",
      ".getClientRects().length > 0 && "
    ),
    paste0(
      "document.querySelector('#plot_generation-export-message')?",
      ".textContent.includes('No export attempted.')"
    )
  ))
  app$wait_for_idle()
  invisible(app)
}

review_standard_revision <- function(app) {
  app$set_inputs(
    `plot_generation-review-actor_id` = "stat-programmer",
    `plot_generation-review-role` = "statistical_programmer",
    `plot_generation-review-comment` = "Programmer browser acceptance approval."
  )
  app$click("plot_generation-review-approve")
  app$wait_for_idle()
  app$wait_for_js(paste0(
    "document.querySelector('#plot_generation-review-decisions')",
    ".textContent.includes('stat-programmer')"
  ))

  app$set_inputs(
    `plot_generation-review-actor_id` = "biostatistician",
    `plot_generation-review-role` = "biostatistician",
    `plot_generation-review-comment` =
      "Biostatistician browser acceptance approval."
  )
  app$click("plot_generation-review-approve")
  app$wait_for_idle()
  app$wait_for_js(paste0(
    "document.querySelector('#plot_generation-revision_history-history')",
    ".textContent.includes('Reviewed')"
  ))
  invisible(app)
}

test_that("browser revised questions replace the Y variable in Confirm", {
  app <- local_submission_sync_app("revised-question-y-variable")
  app$upload_file(
    `plot_generation-data_file` = system.file(
      "extdata", "synthetic", "adlb-standard.csv",
      package = "ADaMViz.SubmissionSync"
    )
  )
  app$wait_for_js(
    "document.querySelector('#plot_generation-to_ask')?.disabled === false"
  )
  app$click("plot_generation-to_ask")

  for (y in c("AVAL", "CHG", "PCHG", "AVAL")) {
    app$set_inputs(`plot_generation-question` = paste(
      "Create a boxplot of ALT", y, "by visit, split by treatment.",
      "Include all visits and treatment groups,",
      "show the number of subjects below each box, and connect the medians"
    ))
    app$click("plot_generation-to_confirm")
    app$wait_for_js(paste0(
      "document.querySelector('#plot_generation-specification-y_variable')",
      "?.value === '", y, "'"
    ))
    expect_identical(
      app$get_value(input = "plot_generation-specification-y_variable"), y
    )
    app$click("plot_generation-back_to_ask")
  }
})

test_that("browser prompt journey creates a Verified draft with evidence", {
  app <- local_submission_sync_app("prompt-to-verified")

  create_standard_revision(app)
  app$run_js(paste0(
    "document.querySelector('#plot_generation-plot_preview-code')",
    ".closest('details').open = true"
  ))
  app$run_js(paste0(
    "document.querySelector('#plot_generation-evidence-checks')",
    ".closest('details').open = true"
  ))
  app$wait_for_value(output = "plot_generation-evidence-checks")
  body <- app$get_text(selector = "body")

  expect_match(body, "Verified", fixed = TRUE)
  expect_match(body, "Analytical output", fixed = TRUE)
  expect_match(body, "runner_success", fixed = TRUE)
})

test_that("browser prompt journey exports Reviewed image and code", {
  app <- local_submission_sync_app("prompt-to-export")

  create_standard_revision(app)
  open_export_step(app)
  expect_true(app$get_js(paste0(
    "document.getElementById('plot_generation-export-download_zip')",
    ".getAttribute('aria-disabled') === 'true'"
  )))
  review_standard_revision(app)
  zipfile <- app$get_download("plot_generation-export-download_zip")
  expect_setequal(
    utils::unzip(zipfile, list = TRUE)$Name, c("script.R", "plot.png")
  )
  app$wait_for_idle()
  app$wait_for_js(paste0(
    "document.querySelector('#plot_generation-export-message')",
    ".textContent.includes('Exported receipt-')"
  ))

  body <- app$get_text(selector = "body")
  expect_match(body, "Exported receipt-", fixed = TRUE)
  expect_match(body, "rev-", fixed = TRUE)
})

test_that("browser review reaches Reviewed with two distinct approvals", {
  app <- local_submission_sync_app("two-person-review")

  create_standard_revision(app)
  open_export_step(app)
  review_standard_revision(app)

  body <- app$get_text(selector = "body")
  expect_match(body, "Reviewed", fixed = TRUE)
  expect_match(body, "stat-programmer", fixed = TRUE)
  expect_match(body, "biostatistician", fixed = TRUE)

  app$click("plot_generation-review-approve")
  app$wait_for_idle()
  app$wait_for_js(paste0(
    "document.querySelector('#plot_generation-review-message')",
    ".textContent.includes('Reviewed revisions are immutable')"
  ))
  expect_match(
    app$get_text(selector = "body"),
    "Reviewed revisions are immutable",
    fixed = TRUE
  )
})

test_that("browser rejection closes the revision and blocks further review", {
  app <- local_submission_sync_app("review-rejection")

  create_standard_revision(app)
  open_export_step(app)
  app$set_inputs(
    `plot_generation-review-actor_id` = "stat-programmer",
    `plot_generation-review-role` = "statistical_programmer",
    `plot_generation-review-comment` = "Rejecting from browser acceptance."
  )
  app$click("plot_generation-review-reject")
  app$wait_for_idle()
  app$wait_for_js(paste0(
    "document.querySelector('#plot_generation-revision_history-history')",
    ".textContent.includes('Rejected')"
  ))

  body <- app$get_text(selector = "body")
  expect_match(body, "Rejected", fixed = TRUE)
  expect_match(body, "stat-programmer", fixed = TRUE)

  app$set_inputs(
    `plot_generation-review-actor_id` = "biostatistician",
    `plot_generation-review-role` = "biostatistician",
    `plot_generation-review-comment` = "Attempted post-rejection approval."
  )
  app$click("plot_generation-review-approve")
  app$wait_for_idle()
  app$wait_for_js(paste0(
    "document.querySelector('#plot_generation-review-message')",
    ".textContent.includes('Only a Verified revision can be reviewed')"
  ))
  expect_match(
    app$get_text(selector = "body"),
    "Only a Verified revision can be reviewed",
    fixed = TRUE
  )
})
utils::globalVariables("local_browser_app")

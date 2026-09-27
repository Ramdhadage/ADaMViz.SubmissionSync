test_that("the app exposes the current plot workflow", {
  config <- new_runtime_config(profile = "local", prompt_provider = "mock")
  ui <- getFromNamespace("app_ui", "ADaMViz.SubmissionSync")(NULL, runtime_config = config)

  expect_s3_class(ui, "shiny.tag.list")
  expect_match(as.character(ui), "Start with your data", fixed = TRUE)
  expect_match(as.character(ui), "What would you like to see?", fixed = TRUE)
  expect_match(as.character(ui), "Two-Person Review", fixed = TRUE)
})

test_that("the app server starts with injected runtime configuration", {
  config <- new_runtime_config(profile = "local", prompt_provider = "mock")
  server <- function(input, output, session) {
    getFromNamespace("app_server", "ADaMViz.SubmissionSync")(
      input,
      output,
      session,
      runtime_config = config
    )
  }

  expect_no_error(
    shiny::testServer(
      server,
      {}
    )
  )
})

test_that("the app server completes execution synchronously", {
  result <- .empty_assurance_state()
  result$revision <- list(status = "Verified")
  testthat::local_mocked_bindings(
    .execute_assurance_revision = function(...) result
  )

  shiny::testServer(app_server, {
    state <- .empty_assurance_state()
    state$pending <- list(snapshot = make_test_snapshot(), prompt = "Plot ALT")
    current_revision(state)

    execute_revision(as.list(execution_spec()$fields))

    expect_identical(current_revision(), result)
  })
})

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

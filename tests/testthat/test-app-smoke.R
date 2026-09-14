test_that("the app exposes a labeled empty-state shell", {
  config <- new_runtime_config(profile = "local", prompt_provider = "mock")
  ui <- getFromNamespace("app_ui", "ADaMViz.SubmissionSync")(NULL, runtime_config = config)

  expect_s3_class(ui, "shiny.tag.list")
  expect_match(as.character(ui), "Plot-Pattern Assurance Cell")
  expect_match(as.character(ui), "Prompt and Dataset")
  expect_match(as.character(ui), "Two-Person Review")
})

test_that("the app server accepts injected runtime configuration", {
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
      {
        expect_identical(output$runtime_profile, "local")
      }
    )
  )
})

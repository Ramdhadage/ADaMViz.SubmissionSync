test_that("the app exposes a labeled empty-state shell", {
  config <- new_runtime_config(profile = "local", prompt_provider = "mock")
  ui <- getFromNamespace("app_ui", "ADaMViz.SubmissionSync")(NULL, runtime_config = config)

  expect_true(shiny::isTruthy(ui))
  expect_match(as.character(ui), "Plot-Pattern Assurance Cell")
  expect_match(as.character(ui), "No plot revision selected")
})

test_that("the app server accepts injected runtime configuration", {
  config <- new_runtime_config(profile = "local", prompt_provider = "mock")

  expect_no_error(
    shiny::testServer(
      getFromNamespace("app_server", "ADaMViz.SubmissionSync"),
      args = list(runtime_config = config),
      {
        expect_identical(output$runtime_profile, "local")
      }
    )
  )
})

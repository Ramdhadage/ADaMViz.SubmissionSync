test_that("the app exposes the current plot workflow", {
  config <- new_runtime_config(profile = "local", prompt_provider = "mock")
  ui <- getFromNamespace(
    "app_ui", "ADaMViz.SubmissionSync"
  )(NULL, runtime_config = config)

  expect_s3_class(ui, "shiny.tag.list")
  expect_match(as.character(ui), "Start with your data", fixed = TRUE)
  expect_match(as.character(ui), "What would you like to see?", fixed = TRUE)
  expect_match(as.character(ui), "Two-Person Review", fixed = TRUE)
})

test_that("the app server starts with injected runtime configuration", {
  config <- new_runtime_config(
    profile = "local",
    prompt_provider = "mock",
    evidence_root = withr::local_tempdir()
  )
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
  withr::local_envvar(ADAMVIZ_EVIDENCE_ROOT = withr::local_tempdir())
  result <- .empty_assurance_state()
  result$revision <- list(status = "Verified")
  testthat::local_mocked_bindings(
    .execute_assurance_revision = function(...) result
  )

  shiny::testServer(app_server, {
    state <- .empty_assurance_state()
    state$pending <- list(
      snapshot = make_test_snapshot(),
      prompt = "Plot ALT"
    )
    current_revision(state)

    execute_revision(as.list(execution_spec()$fields))

    expect_identical(current_revision(), result)
  )
})

test_that("app sessions share the configured evidence root", {
  evidence_root <- withr::local_tempdir()
  config <- new_runtime_config(
    profile = "test",
    prompt_provider = "mock",
    evidence_root = evidence_root
  )
  roots <- character()
  result <- .empty_assurance_state()
  result$revision <- list(status = "Verified")
  testthat::local_mocked_bindings(
    .execute_assurance_revision = function(..., repository_root) {
      roots <<- c(roots, repository_root)
      result
    }
  )
  withr::local_envvar(ADAMVIZ_EVIDENCE_ROOT = evidence_root)

  for (index in seq_len(2L)) {
    shiny::testServer(app_server, {
      state <- .empty_assurance_state()
      state$pending <- list(
        snapshot = make_test_snapshot(),
        prompt = paste("Plot ALT", index)
      )
      current_revision(state)
      execute_revision(as.list(execution_spec()$fields))
    })
  }

  expect_identical(roots, rep(config$evidence_root, 2L))
})

test_that("repeated specifications persist as separate plots", {
  evidence_root <- withr::local_tempdir()
  fields <- as.list(execution_spec()$fields)
  fields$scale_mode <- "free"
  snapshot <- make_test_snapshot()

  first <- .execute_assurance_revision(
    snapshot,
    "First ALT plot",
    fields,
    repository_root = evidence_root
  )
  second <- .execute_assurance_revision(
    snapshot,
    "Second ALT plot",
    fields,
    repository_root = evidence_root
  )

  expect_false(identical(first$plot_id, second$plot_id))
  expect_identical(
    first$repository$get_revision(second$revision$revision_id)$revision_id,
    second$revision$revision_id
  )
  expect_true(fs::file_exists(fs::path(evidence_root, "evidence.sqlite")))
})

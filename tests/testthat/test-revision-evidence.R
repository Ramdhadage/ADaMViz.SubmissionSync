fake_revision_context_runner <- function(request, script, analysis_data, ...) {
  environment <- new.env(parent = globalenv())
  environment$analysis_data <- analysis_data
  connection <- textConnection(script)
  withr::defer(close(connection), envir = parent.frame())
  source(connection, local = environment, keep.source = FALSE)
  image_path <- tempfile(fileext = ".png")
  withr::defer(unlink(image_path), envir = parent.frame())
  writeBin(charToRaw("png bytes"), image_path)
  execution_environment <- .execution_environment_details()
  execution_environment$image_width <- 1200
  execution_environment$image_height <- 840
  structure(
    list(
      status = "succeeded",
      manifest_version = "execution-runner-result-v1",
      result = new_execution_result(
        request,
        analytical_hash = canonical_hash(environment$boxplot_analysis),
        image_hash = digest::digest(file = image_path, algo = "sha256"),
        environment_fingerprint = canonical_hash(execution_environment)
      ),
      analytical_output = environment$boxplot_analysis,
      image_path = image_path,
      code_hash = request$script_hash,
      environment = execution_environment,
      diagnostics = list(stdout = "", stderr = "")
    ),
    class = "execution_runner_result"
  )
}

test_that("app revisions persist complete context evidence for R36", {
  snapshot <- make_test_snapshot()
  profile <- validate_bds_profile(snapshot, default_profile_selections())
  spec <- execution_spec()
  testthat::local_mocked_bindings(
    new_callr_execution_runner = function(...) {
      new_execution_runner(fake_revision_context_runner)
    }
  )

  state <- .materialize_revision(
    snapshot,
    "Create an ALT boxplot by treatment.",
    spec,
    profile
  )
  evidence <- state$repository$list_evidence(state$revision$revision_id)
  context <- evidence[evidence$evidence_type == "revision_context", ]
  details <- jsonlite::fromJSON(context$details_json[[1]], simplifyVector = FALSE)

  expect_equal(nrow(context), 1L)
  expect_identical(details$prompt, "Create an ALT boxplot by treatment.")
  expect_identical(details$specification$hash, spec$hash)
  expect_identical(details$input_data$snapshot_id, snapshot$snapshot_id)
  expect_identical(details$generated_r_code, state$script)
  expect_identical(details$request$script_hash, state$revision$code_hash)
  expect_named(details$environment$packages, c(
    "ADaMViz.SubmissionSync", "ggplot2", "patchwork"
  ))
  expect_identical(rawToChar(state$repository$artifact_store$get(
    state$revision$code_hash
  )), state$script)
})

test_that("reproducibility service reruns retained evidence exactly", {
  snapshot <- make_test_snapshot()
  profile <- validate_bds_profile(snapshot, default_profile_selections())
  spec <- execution_spec()
  testthat::local_mocked_bindings(
    new_callr_execution_runner = function(...) {
      new_execution_runner(fake_revision_context_runner)
    }
  )
  state <- .materialize_revision(
    snapshot,
    "Create an ALT boxplot by treatment.",
    spec,
    profile
  )
  service <- new_reproducibility_service(
    state$repository,
    state$repository$artifact_store,
    runner = new_execution_runner(fake_revision_context_runner)
  )

  result <- service$reproduce_revision(
    state$revision$revision_id,
    idempotency_key = "reproduce-1"
  )

  expect_s3_class(result, "revision_reproducibility_result")
  expect_identical(result$status, "passed")
  expect_equal(
    nrow(state$repository$list_evidence(state$revision$revision_id)),
    3L
  )
})

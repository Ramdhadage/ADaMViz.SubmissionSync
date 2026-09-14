fake_correction_runner <- function(request, script, analysis_data, ...) {
  environment <- new.env(parent = globalenv())
  environment$analysis_data <- analysis_data
  connection <- textConnection(script)
  withr::defer(close(connection), envir = parent.frame())
  source(connection, local = environment, keep.source = FALSE)
  image_path <- tempfile(fileext = ".png")
  withr::defer(unlink(image_path), envir = parent.frame())
  writeBin(charToRaw("png bytes"), image_path)
  structure(
    list(
      status = "succeeded",
      manifest_version = "execution-runner-result-v1",
      result = new_execution_result(
        request,
        analytical_hash = canonical_hash(environment$boxplot_analysis),
        image_hash = paste(rep("a", 64L), collapse = ""),
        environment_fingerprint = .execution_environment_fingerprint()
      ),
      analytical_output = environment$boxplot_analysis,
      image_path = image_path,
      code_hash = request$script_hash,
      environment = .execution_environment_details(),
      diagnostics = list(stdout = "", stderr = "")
    ),
    class = "execution_runner_result"
  )
}

test_that("app correction creates child Draft and preserves reviewed parent", {
  root <- withr::local_tempdir()
  store <- local_artifact_store(fs::path(root, "artifacts"))
  repo <- sqlite_evidence_repository(
    fs::path(root, "evidence.sqlite"),
    fs::path(root, "chain-root.json"),
    store
  )
  code_hash <- store$put(charToRaw("script"))
  image_hash <- store$put(charToRaw("image"))
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", code_hash,
    image_hash, "analysis", "create"
  )
  lifecycle <- new_lifecycle_service(repo)
  lifecycle$mark_verified("rev-1", 1L, "verify")
  identities <- local_identity_provider(list(
    new_actor("sp", "statistical_programmer"),
    new_actor("bio", "biostatistician")
  ))
  review <- new_review_service(repo, identities)
  review$approve("rev-1", "sp", 2L, "sp-approval")
  review$approve("rev-1", "bio", 3L, "bio-approval")

  snapshot <- make_test_snapshot()
  state <- list(
    pending = NULL,
    plot_id = "plot-1",
    repository = repo,
    review_service = review,
    revision = repo$get_revision("rev-1"),
    spec = execution_spec(),
    snapshot = snapshot,
    prompt = "Create a boxplot of ALT AVAL by treatment.",
    choices = .spec_choices_from_context(build_prompt_context(snapshot)),
    profile = NULL,
    script = NULL,
    artifact = NULL,
    verification = NULL
  )
  fields <- as.list(execution_spec()$fields)
  fields$visits <- c("Baseline", "Week 4")

  testthat::local_mocked_bindings(
    run_execution_locally = fake_correction_runner
  )
  corrected <- .execute_correction_revision(
    state,
    fields,
    rationale = "Refine reviewed visit scope",
    provenance = "Reviewer change request"
  )

  expect_identical(repo$get_revision("rev-1")$status, "Reviewed")
  expect_identical(corrected$revision$status, "Draft")
  expect_identical(corrected$revision$parent_revision_id, "rev-1")
  expect_identical(corrected$revision$plot_id, "plot-1")
  expect_identical(corrected$spec$fields$visits, c("Baseline", "Week 4"))
  expect_equal(nrow(repo$list_revisions("plot-1")), 2L)
  expect_identical(corrected$verification, NULL)
})

test_that("execution service promotes only a complete passing attempt", {
  fixture <- execution_fixture()
  runner_result <- fake_successful_runner_result(fixture)
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "chain-root.json")
  )
  repo$create_revision(
    "plot-1",
    "rev-1",
    1L,
    "creator",
    fixture$spec$hash,
    canonical_hash(fixture$script),
    runner_result$result$image_hash,
    runner_result$result$analytical_hash,
    "create"
  )
  runner <- new_execution_runner(function(...) runner_result)
  service <- new_execution_service(repo, runner = runner, artifact_store = NULL)

  result <- service$submit(
    revision_id = "rev-1",
    request = fixture$request,
    script = fixture$script,
    analysis_data = fixture$profile$selected_data,
    idempotency_key = "execute-1"
  )

  expect_identical(result$status, "verified")
  expect_identical(repo$get_revision("rev-1")$status, "Verified")
  expect_identical(repo$list_attempts("rev-1")$outcome, "succeeded")
  expect_identical(repo$list_evidence("rev-1")$outcome, "passed")
})

test_that("failed verification records terminal failure without promotion", {
  fixture <- execution_fixture()
  runner <- new_execution_runner(function(...) {
    structure(
      list(
        status = "failed",
        manifest_version = "execution-runner-result-v1",
        diagnostics = list(stdout = "", stderr = "simulated failure")
      ),
      class = "execution_runner_result"
    )
  })
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "chain-root.json")
  )
  repo$create_revision(
    "plot-1",
    "rev-1",
    1L,
    "creator",
    fixture$spec$hash,
    canonical_hash(fixture$script),
    paste(rep("0", 64L), collapse = ""),
    paste(rep("1", 64L), collapse = ""),
    "create"
  )
  service <- new_execution_service(repo, runner = runner, artifact_store = NULL)

  result <- service$submit(
    revision_id = "rev-1",
    request = fixture$request,
    script = fixture$script,
    analysis_data = fixture$profile$selected_data,
    idempotency_key = "execute-1"
  )

  expect_identical(result$status, "failed")
  expect_identical(repo$get_revision("rev-1")$status, "Draft")
  expect_identical(repo$list_attempts("rev-1")$outcome, "failed")
  expect_identical(repo$list_evidence("rev-1")$outcome, "failed")
})

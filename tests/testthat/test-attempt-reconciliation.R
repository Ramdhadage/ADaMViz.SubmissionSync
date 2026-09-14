test_that("attempt reconciliation closes abandoned active attempts", {
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
    "spec",
    "code",
    "image",
    "analysis",
    "create"
  )
  repo$record_attempt("attempt-1", "rev-1", "run-1")

  result <- reconcile_execution_attempts(repo, "rev-1")

  expect_s3_class(result, "attempt_reconciliation")
  expect_identical(result$reconciled$`attempt-1`, "failed")
  expect_identical(repo$list_attempts("rev-1")$outcome, "failed")
})

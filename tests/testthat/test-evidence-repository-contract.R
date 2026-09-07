test_that("repository history is append only and idempotent", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "evidence.sqlite"),
    fs::path(root, "chain-root.json")
  )

  repo$create_revision(
    plot_id = "plot-1", revision_id = "rev-1", revision_number = 1L,
    creator_id = "creator", spec_hash = "spec", code_hash = "code",
    image_hash = "image", analytical_hash = "analysis",
    idempotency_key = "create-rev-1"
  )
  repo$create_revision(
    plot_id = "plot-1", revision_id = "rev-1", revision_number = 1L,
    creator_id = "creator", spec_hash = "spec", code_hash = "code",
    image_hash = "image", analytical_hash = "analysis",
    idempotency_key = "create-rev-1"
  )

  expect_equal(nrow(repo$list_revisions("plot-1")), 1L)
  expect_equal(nrow(repo$list_events("plot-1")), 1L)
  expect_error(repo$update_revision("rev-1"), "not available")
  expect_error(repo$delete_revision("rev-1"), "not available")
})

test_that("attempt outcomes, evidence, and bundles enforce relationships", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "evidence.sqlite"),
    fs::path(root, "chain-root.json")
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image", "analysis",
    "create-rev-1"
  )

  repo$record_attempt("attempt-1", "rev-1", "run-1")
  repo$record_attempt("attempt-1", "rev-1", "run-1")
  repo$record_attempt("attempt-2", "rev-1", "run-2")
  expect_equal(nrow(repo$list_attempts("rev-1")), 2L)
  repo$complete_attempt("attempt-1", "succeeded", "done-1")
  expect_error(repo$complete_attempt("attempt-1", "failed", "done-2"), "terminal")
  repo$record_evidence(
    "evidence-1", "rev-1", "governed_threshold", "passed", "evidence-1",
    details = list(value = 5L, rationale = "Governed default", authority = "product contract", version = "1")
  )
  threshold <- repo$list_evidence("rev-1")
  expect_match(threshold$details_json, '"authority":"product contract"', fixed = TRUE)
  expect_match(threshold$details_json, '"value":5', fixed = TRUE)
  repo$accept_artifact_bundle("bundle-1", "rev-1", "code", "image", "analysis", "bundle-1")
  expect_error(
    repo$accept_artifact_bundle("bundle-2", "rev-1", "code", "image", "analysis", "bundle-2"),
    "accepted artifact bundle"
  )
  expect_error(
    repo$record_evidence("orphan", "missing", "check", "passed", "orphan"),
    "revision"
  )

  repo$record_export_receipt("receipt-1", "rev-1", "workspace-1", "code", "image", "receipt-1")
  repo$record_export_receipt("receipt-1", "rev-1", "workspace-1", "code", "image", "receipt-1")
  expect_equal(nrow(repo$list_export_receipts("rev-1")), 1L)
  expect_error(
    repo$record_export_receipt("receipt-2", "rev-1", "workspace-1", "wrong", "image", "receipt-2"),
    "hashes"
  )
})

test_that("generic lifecycle commands cannot bypass governed review", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "evidence.sqlite"),
    fs::path(root, "chain-root.json")
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )

  expect_null(repo$transition)
  expect_identical(repo$get_revision("rev-1")$status, "Draft")
  expect_equal(nrow(repo$list_events("plot-1")), 1L)
})

test_that("direct repository calls cannot bypass correction rules", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "evidence.sqlite"),
    fs::path(root, "chain-root.json")
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )

  expect_error(
    repo$create_revision(
      "plot-1", "rev-2", 2L, "creator", "spec", "code", "image",
      "analysis", "child", parent_revision_id = "rev-1",
      correction_rationale = "Correction",
      correction_provenance = "source"
    ),
    "closed revision"
  )
  expect_error(
    repo$create_revision(
      "plot-1", "rev-2", 2L, "creator", "spec", "code", "image",
      "analysis", "orphan-metadata",
      correction_rationale = "Correction"
    ),
    "require a parent"
  )
  expect_equal(nrow(repo$list_revisions("plot-1")), 1L)
})

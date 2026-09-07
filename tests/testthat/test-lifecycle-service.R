test_that("rejection closes a revision and correction creates a child Draft", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(fs::path(root, "db.sqlite"), fs::path(root, "root.json"))
  lifecycle <- new_lifecycle_service(repo)
  identities <- local_identity_provider(list(
    new_actor("reviewer", "statistical_programmer")
  ))
  review <- new_review_service(repo, identities)
  repo$create_revision("plot-1", "rev-1", 1L, "creator", "spec", "code", "image", "analysis", "create")

  lifecycle$mark_verified("rev-1", expected_version = 1L, idempotency_key = "verify")
  review$reject(
    "rev-1", "reviewer", 2L, "reject", "Incorrect analysis"
  )
  expect_identical(repo$get_revision("rev-1")$status, "Rejected")
  expect_null(lifecycle$reject)
  expect_error(
    lifecycle$create_correction("rev-1", "rev-2", "creator", "spec2", "code2", "image2", "analysis2", "", "source", "correct"),
    "rationale"
  )
  lifecycle$create_correction(
    "rev-1", "rev-2", "creator", "spec2", "code2", "image2", "analysis2",
    "Correct mislabeled treatment", "review decision", "correct"
  )
  child <- repo$get_revision("rev-2")
  expect_identical(child$status, "Draft")
  expect_identical(child$parent_revision_id, "rev-1")
})

test_that("stale lifecycle commands do not append partial history", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(fs::path(root, "db.sqlite"), fs::path(root, "root.json"))
  lifecycle <- new_lifecycle_service(repo)
  repo$create_revision("plot-1", "rev-1", 1L, "creator", "spec", "code", "image", "analysis", "create")

  lifecycle$mark_verified("rev-1", 1L, "verified")
  before <- nrow(repo$list_events("plot-1"))
  expect_error(lifecycle$mark_verified("rev-1", 1L, "stale"), "stale")
  expect_equal(nrow(repo$list_events("plot-1")), before)
})

test_that("Experimental drafts cannot be promoted to Verified", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "root.json")
  )
  lifecycle <- new_lifecycle_service(repo)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create", initial_status = "Experimental/Draft"
  )
  events_before <- nrow(repo$list_events("plot-1"))

  expect_error(lifecycle$mark_verified("rev-1", 1L, "verify"), "Draft")
  expect_identical(repo$get_revision("rev-1")$status, "Experimental/Draft")
  expect_equal(nrow(repo$list_events("plot-1")), events_before)
})

test_that("only closed revisions can have correction successors", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "root.json")
  )
  lifecycle <- new_lifecycle_service(repo)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  expect_error(
    lifecycle$create_correction(
      "rev-1", "rev-2", "creator", "spec", "code", "image",
      "analysis", "Correction", "source", "correct-draft"
    ),
    "closed revision"
  )
  lifecycle$mark_verified("rev-1", 1L, "verify")
  expect_error(
    lifecycle$create_correction(
      "rev-1", "rev-2", "creator", "spec", "code", "image",
      "analysis", "Correction", "source", "correct-verified"
    ),
    "closed revision"
  )
  expect_equal(nrow(repo$list_revisions("plot-1")), 1L)
})

test_that("changes to a Reviewed revision create a child Draft", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"), fs::path(root, "root.json")
  )
  identities <- local_identity_provider(list(
    new_actor("sp", "statistical_programmer"),
    new_actor("bio", "biostatistician")
  ))
  review <- new_review_service(repo, identities)
  lifecycle <- new_lifecycle_service(repo)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  lifecycle$mark_verified("rev-1", 1L, "verified")
  review$approve("rev-1", "sp", 2L, "sp-approval")
  review$approve("rev-1", "bio", 3L, "bio-approval")

  lifecycle$create_correction(
    "rev-1", "rev-2", "creator", "spec-2", "code-2", "image-2",
    "analysis-2", "Update requested after review", "change request",
    "correction"
  )

  expect_identical(repo$get_revision("rev-1")$status, "Reviewed")
  expect_identical(repo$get_revision("rev-2")$status, "Draft")
  expect_identical(repo$get_revision("rev-2")$parent_revision_id, "rev-1")
})

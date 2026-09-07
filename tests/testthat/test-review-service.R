test_that("two independent eligible reviewers are required", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(fs::path(root, "db.sqlite"), fs::path(root, "root.json"))
  identities <- local_identity_provider(list(
    new_actor("creator", "statistical_programmer"),
    new_actor("sp", "statistical_programmer"),
    new_actor("bio", "biostatistician")
  ))
  lifecycle <- new_lifecycle_service(repo)
  review <- new_review_service(repo, identities)
  repo$create_revision("plot-1", "rev-1", 1L, "creator", "spec", "code", "image", "analysis", "create")
  lifecycle$mark_verified("rev-1", 1L, "verified")

  expect_error(review$approve("rev-1", "creator", 2L, "creator-approval"), "creator")
  review$approve("rev-1", "sp", 2L, "sp-approval")
  expect_identical(repo$get_revision("rev-1")$status, "Verified")
  expect_error(review$reject("rev-1", "bio", 2L, "stale-reject", "Incorrect analysis"), "stale")
  expect_equal(nrow(repo$list_review_decisions("rev-1")), 1L)
  expect_error(review$approve("rev-1", "sp", 3L, "sp-again"), "distinct")
  review$approve("rev-1", "bio", 3L, "bio-approval")
  expect_identical(repo$get_revision("rev-1")$status, "Reviewed")
  expect_error(
    review$reject(
      "rev-1", "bio", 4L, "late-reject", "Post-review concern"
    ),
    "Reviewed"
  )
})

test_that("review decisions bind exact immutable hashes", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(fs::path(root, "db.sqlite"), fs::path(root, "root.json"))
  identities <- local_identity_provider(list(new_actor("sp", "statistical_programmer")))
  review <- new_review_service(repo, identities)
  repo$create_revision("plot-1", "rev-1", 1L, "creator", "spec", "code", "image", "analysis", "create")
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verified")

  expect_error(
    review$approve("rev-1", "sp", 2L, "approval", hashes = list(code_hash = "wrong", image_hash = "image", analytical_hash = "analysis")),
    "hashes"
  )
  expect_equal(nrow(repo$list_review_decisions("rev-1")), 0L)
})

test_that("review decisions retain comments and an authorized role claim", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"), fs::path(root, "root.json")
  )
  identities <- local_identity_provider(list(
    new_actor(
      "dual-role", c("statistical_programmer", "biostatistician")
    ),
    new_actor("inactive", "statistical_programmer", active = FALSE)
  ))
  review <- new_review_service(repo, identities)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verified")

  expect_error(
    review$approve("rev-1", "dual-role", 2L, "ambiguous-role"),
    "role"
  )
  expect_error(
    review$approve("rev-1", "inactive", 2L, "inactive-review"),
    "active"
  )
  review$approve(
    "rev-1", "dual-role", 2L, "role-claim",
    comment = "Programming review complete",
    role = "statistical_programmer"
  )

  decision <- repo$list_review_decisions("rev-1")
  expect_identical(decision$role, "statistical_programmer")
  expect_identical(decision$comment, "Programming review complete")
  expect_error(
    review$approve(
      "rev-1", "dual-role", 3L, "second-role-claim",
      role = "biostatistician"
    ),
    "distinct"
  )
})

test_that("rejection rationale is required and retained", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"), fs::path(root, "root.json")
  )
  identities <- local_identity_provider(list(
    new_actor("reviewer", "biostatistician")
  ))
  review <- new_review_service(repo, identities)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verified")

  expect_error(
    review$reject("rev-1", "reviewer", 2L, "blank", ""),
    "rationale"
  )
  review$reject(
    "rev-1", "reviewer", 2L, "reject", "Analytical mismatch"
  )

  decision <- repo$list_review_decisions("rev-1")
  expect_identical(decision$decision, "rejected")
  expect_identical(decision$comment, "Analytical mismatch")
})

test_that("a competing approval cannot follow a committed rejection", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"), fs::path(root, "root.json")
  )
  identities <- local_identity_provider(list(
    new_actor("sp", "statistical_programmer"),
    new_actor("bio", "biostatistician")
  ))
  review <- new_review_service(repo, identities)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verified")

  review$reject("rev-1", "bio", 2L, "reject", "Incorrect result")
  expect_error(
    review$approve("rev-1", "sp", 2L, "competing-approval"),
    "stale"
  )
  expect_equal(nrow(repo$list_review_decisions("rev-1")), 1L)
  expect_identical(repo$get_revision("rev-1")$status, "Rejected")
})

test_that("required approvals may arrive in either role order", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"), fs::path(root, "root.json")
  )
  identities <- local_identity_provider(list(
    new_actor("sp", "statistical_programmer"),
    new_actor("bio", "biostatistician")
  ))
  review <- new_review_service(repo, identities)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verified")

  review$approve("rev-1", "bio", 2L, "bio-first")
  review$approve("rev-1", "sp", 3L, "sp-second")

  expect_identical(repo$get_revision("rev-1")$status, "Reviewed")
})

test_that("concurrent approval and rejection commit exactly one decision", {
  skip_if_not_installed("callr")
  root <- withr::local_tempdir()
  database <- fs::path(root, "db.sqlite")
  chain_root <- fs::path(root, "root.json")
  gate <- fs::path(root, "go")
  repo <- sqlite_evidence_repository(database, chain_root)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verify")
  source_root <- normalizePath(
    testthat::test_path("..", ".."),
    winslash = "/",
    mustWork = FALSE
  )
  if (!file.exists(file.path(source_root, "DESCRIPTION"))) source_root <- NULL
  worker <- function(
    source_root,
    database,
    chain_root,
    gate,
    actor_id,
    role,
    decision
  ) {
    if (!is.null(source_root)) devtools::load_all(source_root, quiet = TRUE)
    package <- asNamespace("ADaMViz.SubmissionSync")
    repository <- get("sqlite_evidence_repository", package)
    actor <- get("new_actor", package)
    identity_provider <- get("local_identity_provider", package)
    review_service <- get("new_review_service", package)
    deadline <- Sys.time() + 30
    while (!file.exists(gate) && Sys.time() < deadline) Sys.sleep(0.01)
    identities <- identity_provider(list(actor(actor_id, role)))
    review <- review_service(
      repository(database, chain_root),
      identities
    )
    tryCatch({
      if (decision == "approved") {
        review$approve("rev-1", actor_id, 2L, paste0(actor_id, "-decision"))
      } else {
        review$reject(
          "rev-1", actor_id, 2L, paste0(actor_id, "-decision"),
          "Incorrect result"
        )
      }
      "committed"
    }, error = conditionMessage)
  }
  approval <- callr::r_bg(
    worker,
    args = list(
      source_root, database, chain_root, gate, "sp",
      "statistical_programmer", "approved"
    ),
    libpath = .libPaths()
  )
  rejection <- callr::r_bg(
    worker,
    args = list(
      source_root, database, chain_root, gate, "bio",
      "biostatistician", "rejected"
    ),
    libpath = .libPaths()
  )
  file.create(gate)
  approval$wait(timeout = 60000)
  rejection$wait(timeout = 60000)
  expect_false(approval$is_alive())
  expect_false(rejection$is_alive())
  results <- c(approval$get_result(), rejection$get_result())

  expect_equal(sum(results == "committed"), 1L)
  expect_equal(nrow(repo$list_review_decisions("rev-1")), 1L)
  expect_identical(repo$verify_integrity(), TRUE)
})

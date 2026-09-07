test_that("backup and restore preserve history, projections, and artifacts", {
  root <- withr::local_tempdir()
  artifacts <- local_artifact_store(fs::path(root, "artifacts"))
  code_hash <- artifacts$put(charToRaw("plot(1)"))
  image_hash <- artifacts$put(charToRaw("png bytes"))
  db <- fs::path(root, "db.sqlite")
  chain <- fs::path(root, "root.json")
  repo <- sqlite_evidence_repository(db, chain, artifacts)
  repo$create_revision("plot-1", "rev-1", 1L, "creator", "spec", code_hash, image_hash, "analysis", "create")
  repo$record_attempt("attempt-1", "rev-1", "run-1")
  repo$complete_attempt("attempt-1", "succeeded", "attempt-complete")
  repo$record_evidence(
    "evidence-1", "rev-1", "reproducibility", "passed", "evidence"
  )
  repo$accept_artifact_bundle(
    "bundle-1", "rev-1", code_hash, image_hash, "analysis", "bundle"
  )
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verified")
  identities <- local_identity_provider(list(
    new_actor("sp", "statistical_programmer"),
    new_actor("bio", "biostatistician")
  ))
  review <- new_review_service(repo, identities)
  review$approve("rev-1", "sp", 2L, "sp-approval")
  review$approve("rev-1", "bio", 3L, "bio-approval")
  repo$record_export_receipt(
    "receipt-1", "rev-1", "workspace", code_hash, image_hash, "receipt"
  )
  backup <- fs::path(root, "backup")

  repo$backup(backup)
  expect_true(fs::file_exists(fs::path(backup, "backup-manifest.json")))
  restored <- restore_evidence_repository(backup, fs::path(root, "restored"))

  expect_identical(restored$get_revision("rev-1")$revision_id, "rev-1")
  expect_identical(restored$get_revision("rev-1")$status, "Reviewed")
  expect_equal(nrow(restored$list_attempts("rev-1")), 1L)
  expect_equal(nrow(restored$list_evidence("rev-1")), 1L)
  expect_equal(nrow(restored$list_review_decisions("rev-1")), 2L)
  expect_equal(nrow(restored$list_export_receipts("rev-1")), 1L)
  expect_identical(restored$verify_integrity(), TRUE)
  expect_identical(restored$artifact_store$verify(code_hash), TRUE)
  expect_identical(restored$artifact_store$verify(image_hash), TRUE)
})

test_that("restore rejects incomplete or modified backups", {
  root <- withr::local_tempdir()
  database <- fs::path(root, "db.sqlite")
  chain_root <- fs::path(root, "root.json")
  artifacts <- local_artifact_store(fs::path(root, "artifacts"))
  code_hash <- artifacts$put(charToRaw("plot(1)"))
  image_hash <- artifacts$put(charToRaw("png bytes"))
  repo <- sqlite_evidence_repository(database, chain_root, artifacts)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", code_hash, image_hash,
    "analysis", "create"
  )
  backup <- fs::path(root, "backup")
  repo$backup(backup)
  writeLines("changed", fs::path(backup, "chain-root.json"))

  expect_error(
    restore_evidence_repository(backup, fs::path(root, "restored")),
    "manifest"
  )
  expect_false(fs::dir_exists(fs::path(root, "restored")))
})

test_that("backup remains consistent with a concurrent lifecycle write", {
  skip_if_not_installed("callr")
  root <- withr::local_tempdir()
  database <- fs::path(root, "db.sqlite")
  chain_root <- fs::path(root, "root.json")
  backup <- fs::path(root, "backup")
  gate <- fs::path(root, "go")
  artifact_root <- fs::path(root, "artifacts")
  artifacts <- local_artifact_store(artifact_root)
  code_hash <- artifacts$put(charToRaw("plot(1)"))
  image_hash <- artifacts$put(charToRaw("png bytes"))
  repo <- sqlite_evidence_repository(database, chain_root, artifacts)
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", code_hash, image_hash,
    "analysis", "create"
  )
  source_root <- normalizePath(
    testthat::test_path("..", ".."),
    winslash = "/",
    mustWork = FALSE
  )
  if (!file.exists(file.path(source_root, "DESCRIPTION"))) source_root <- NULL
  writer <- function(source_root, database, chain_root, artifact_root, gate) {
    if (!is.null(source_root)) devtools::load_all(source_root, quiet = TRUE)
    package <- asNamespace("ADaMViz.SubmissionSync")
    repository <- get("sqlite_evidence_repository", package)
    lifecycle_service <- get("new_lifecycle_service", package)
    artifact_store <- get("local_artifact_store", package)
    while (!file.exists(gate)) Sys.sleep(0.01)
    lifecycle_service(
      repository(
        database,
        chain_root,
        artifact_store(artifact_root)
      )
    )$mark_verified("rev-1", 1L, "verify")
    TRUE
  }
  copier <- function(source_root, database, chain_root, artifact_root, gate, backup) {
    if (!is.null(source_root)) devtools::load_all(source_root, quiet = TRUE)
    package <- asNamespace("ADaMViz.SubmissionSync")
    repository <- get("sqlite_evidence_repository", package)
    artifact_store <- get("local_artifact_store", package)
    while (!file.exists(gate)) Sys.sleep(0.01)
    repository(
      database,
      chain_root,
      artifact_store(artifact_root)
    )$backup(backup)
    TRUE
  }
  writer_process <- callr::r_bg(
    writer,
    args = list(source_root, database, chain_root, artifact_root, gate),
    libpath = .libPaths()
  )
  backup_process <- callr::r_bg(
    copier,
    args = list(
      source_root, database, chain_root, artifact_root, gate, backup
    ),
    libpath = .libPaths()
  )
  file.create(gate)
  writer_process$wait(timeout = 60000)
  backup_process$wait(timeout = 60000)
  expect_false(writer_process$is_alive())
  expect_false(backup_process$is_alive())
  expect_identical(writer_process$get_result(), TRUE)
  expect_identical(backup_process$get_result(), TRUE)

  restored <- restore_evidence_repository(backup, fs::path(root, "restored"))
  expect_true(restored$get_revision("rev-1")$status %in% c("Draft", "Verified"))
  expect_identical(restored$verify_integrity(), TRUE)
})

test_that("empty repositories can be backed up and restored", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "root.json")
  )
  backup <- fs::path(root, "backup")

  repo$backup(backup)
  restored <- restore_evidence_repository(backup, fs::path(root, "restored"))

  expect_identical(restored$verify_integrity(), TRUE)
  expect_equal(nrow(restored$list_revisions("missing-plot")), 0L)
})

test_that("nonempty backups require artifact reconciliation", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "root.json")
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )

  expect_error(repo$backup(fs::path(root, "backup")), "artifact store")
})

test_that("failed artifact verification leaves no restore destination", {
  root <- withr::local_tempdir()
  artifacts <- local_artifact_store(fs::path(root, "artifacts"))
  code_hash <- artifacts$put(charToRaw("plot(1)"))
  image_hash <- artifacts$put(charToRaw("png bytes"))
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "root.json"),
    artifacts
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", code_hash, image_hash,
    "analysis", "create"
  )
  backup <- fs::path(root, "backup")
  repo$backup(backup)
  writeBin(
    charToRaw("corrupt"),
    fs::path(backup, "artifacts", substr(image_hash, 1L, 2L), image_hash)
  )
  destination <- fs::path(root, "restored")

  expect_error(
    restore_evidence_repository(backup, destination),
    "Artifact hash"
  )
  expect_false(fs::dir_exists(destination))
})

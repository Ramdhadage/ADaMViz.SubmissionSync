test_that("local artifact store is content addressed and detects corruption", {
  root <- withr::local_tempdir()
  store <- local_artifact_store(root)
  content <- charToRaw("immutable artifact")

  first <- store$put(content)
  second <- store$put(content)

  expect_identical(first, second)
  expect_identical(store$get(first), content)
  expect_identical(store$verify(first), TRUE)

  writeBin(charToRaw("changed"), store$path(first))
  expect_error(store$verify(first), "hash")
  expect_error(store$get(first), "hash")
  expect_error(store$put(content), "hash")
})

test_that("repository cleanup preserves referenced content", {
  root <- withr::local_tempdir()
  store <- local_artifact_store(fs::path(root, "artifacts"))
  keep <- store$put(charToRaw("keep"))
  remove <- store$put(charToRaw("remove"))
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "root.json"),
    store
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", keep, keep,
    "analysis", "create"
  )

  expect_identical(repo$cleanup_orphan_artifacts(0), remove)
  expect_identical(store$exists(keep), TRUE)
  expect_identical(store$exists(remove), FALSE)
})

test_that("artifact cleanup ignores files outside the content-addressed layout", {
  root <- withr::local_tempdir()
  store <- local_artifact_store(fs::path(root, "artifacts"))
  keep <- store$put(charToRaw("keep"))
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "root.json"),
    store
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", keep, keep,
    "analysis", "create"
  )
  marker <- fs::path(store$root, "store-metadata.json")
  writeLines("metadata", marker)

  expect_identical(repo$cleanup_orphan_artifacts(0), character())
  expect_true(fs::file_exists(marker))
})

test_that("artifact stores retain their resolved root after working-directory changes", {
  parent <- withr::local_tempdir()
  original <- fs::path(parent, "original")
  elsewhere <- fs::path(parent, "elsewhere")
  fs::dir_create(original)
  fs::dir_create(elsewhere)
  withr::local_dir(original)
  store <- local_artifact_store("artifacts")
  withr::local_dir(elsewhere)

  hash <- store$put(charToRaw("stable root"))

  expect_true(fs::path_has_parent(store$path(hash), store$root))
  expect_true(fs::file_exists(store$path(hash)))
})

test_that("accepted bundles recheck durable artifact hashes", {
  root <- withr::local_tempdir()
  store <- local_artifact_store(fs::path(root, "artifacts"))
  code_hash <- store$put(charToRaw("plot(1)"))
  image_hash <- store$put(charToRaw("png bytes"))
  repo <- sqlite_evidence_repository(
    fs::path(root, "evidence.sqlite"),
    fs::path(root, "chain-root.json"),
    store
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", code_hash, image_hash,
    "analysis", "create"
  )
  writeBin(charToRaw("corrupt"), store$path(image_hash))

  expect_error(
    repo$accept_artifact_bundle(
      "bundle-1", "rev-1", code_hash, image_hash, "analysis", "bundle"
    ),
    "hash"
  )
})

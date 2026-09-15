test_that("local workspace provider is explicitly development-only", {
  provider <- local_workspace_provider(c(local = withr::local_tempdir()))

  expect_identical(provider$assurance_class, "development-only")
  expect_s3_class(provider, "development_only_workspace_provider")
})

test_that("local workspace provider publishes only complete image and script pairs", {
  root <- withr::local_tempdir()
  provider <- local_workspace_provider(c(controlled = root))

  stage <- provider$stage_bundle(
    "controlled",
    "receipt-1",
    charToRaw("plot(1)\n"),
    charToRaw("png bytes")
  )
  published <- provider$publish_staged(stage)

  expect_true(fs::dir_exists(published$path))
  expect_equal(sort(fs::path_file(fs::dir_ls(published$path))), c("plot.png", "script.R"))
  expect_equal(readLines(published$code_path, warn = FALSE), "plot(1)")
  expect_equal(readBin(published$image_path, "raw", n = 9L), charToRaw("png bytes"))
  expect_error(
    provider$stage_bundle(
      "controlled",
      "receipt-1",
      charToRaw("plot(2)\n"),
      charToRaw("other bytes")
    ),
    "already exists"
  )
})

test_that("workspace provider rejects unregistered and unsafe identifiers", {
  root <- withr::local_tempdir()
  provider <- local_workspace_provider(c(controlled = root))

  expect_error(
    provider$stage_bundle("missing", "receipt-1", raw(), raw()),
    "not registered"
  )
  for (value in c("../escape", "nested/path", "C:drive", "CON", "..")) {
    expect_error(
      provider$stage_bundle("controlled", value, raw(), raw()),
      "safe logical identifier"
    )
  }
})

test_that("workspace reconciliation quarantines leftover staged exports", {
  root <- withr::local_tempdir()
  provider <- local_workspace_provider(c(controlled = root))
  provider$stage_bundle(
    "controlled",
    "receipt-1",
    charToRaw("plot(1)\n"),
    charToRaw("png bytes")
  )

  result <- reconcile_workspace_exports(provider, "controlled")

  expect_equal(result$action, "quarantined")
  expect_false(fs::dir_exists(fs::path(root, ".staging", "receipt-1")))
  expect_true(fs::dir_exists(fs::path(root, ".quarantine")))
})

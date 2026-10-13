make_export_fixture <- function(status = "Draft") {
  root <- tempfile("export-fixture-")
  fs::dir_create(root)
  store <- local_artifact_store(fs::path(root, "artifacts"))
  code <- "plot(1)\n# status-like words stay only if code owns them\n"
  image <- charToRaw("png bytes")
  code_hash <- store$put(charToRaw(code))
  image_hash <- store$put(image)
  repo <- sqlite_evidence_repository(
    fs::path(root, "evidence.sqlite"),
    fs::path(root, "chain-root.json"),
    store
  )
  initial_status <- if (identical(status, "Experimental/Draft")) {
    "Experimental/Draft"
  } else {
    "Draft"
  }
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", code_hash,
    image_hash, "analysis", "create",
    initial_status = initial_status
  )
  repo$accept_artifact_bundle(
    "bundle-1", "rev-1", code_hash, image_hash, "analysis", "bundle"
  )
  if (identical(status, "Verified") || identical(status, "Reviewed")) {
    record_passing_execution(repo, "rev-1") # nolint: object_usage_linter.
  }
  if (identical(status, "Reviewed")) {
    identities <- local_identity_provider(list(
      new_actor("sp", "statistical_programmer"),
      new_actor("bio", "biostatistician")
    ))
    review <- new_review_service(repo, identities)
    review$approve("rev-1", "sp", 2L, "sp-approval")
    review$approve("rev-1", "bio", 3L, "bio-approval")
  }
  identities <- local_identity_provider(list(
    new_actor("creator", "clinical_scientist"),
    new_actor("inactive", "clinical_scientist", active = FALSE),
    new_actor("viewer", "viewer")
  ))
  workspace_root <- fs::path(root, "workspace")
  fs::dir_create(workspace_root)
  list(
    root = root,
    store = store,
    repo = repo,
    identities = identities,
    provider = local_workspace_provider(c(controlled = workspace_root)),
    code = code,
    image = image,
    code_hash = code_hash,
    image_hash = image_hash
  )
}

test_that("export service publishes accepted bundles and records receipts", {
  fixture <- make_export_fixture("Reviewed")
  service <- new_export_service(
    fixture$repo,
    fixture$store,
    fixture$provider,
    fixture$identities
  )
  revision <- fixture$repo$get_revision("rev-1")

  receipt <- service$export_revision(
    "rev-1", "creator", "controlled",
    expected_version = revision$version,
    idempotency_key = "export-1"
  )

  expect_equal(
    readLines(receipt$code_path, warn = FALSE),
    strsplit(fixture$code, "\n", fixed = TRUE)[[1]]
  )
  expect_equal(
    readBin(receipt$image_path, "raw", n = length(fixture$image)),
    fixture$image
  )
  expect_equal(sort(fs::path_file(fs::dir_ls(receipt$path))), c(
    "plot.png",
    "script.R"
  ))
  expect_equal(nrow(fixture$repo$list_export_receipts("rev-1")), 1L)
  expect_identical(
    fixture$repo$verify_integrity(require_artifacts = TRUE),
    TRUE
  )

  retry <- service$export_revision(
    "rev-1", "creator", "controlled",
    expected_version = revision$version,
    idempotency_key = "export-1"
  )
  expect_equal(nrow(fixture$repo$list_export_receipts("rev-1")), 1L)
  expect_equal(retry$code_path, receipt$code_path)
  expect_equal(retry$image_path, receipt$image_path)
  expect_error(
    service$export_revision(
      "rev-1", "creator", "another-destination",
      expected_version = revision$version,
      idempotency_key = "export-1"
    ),
    "different destination"
  )
  expect_error(
    service$export_revision(
      "rev-1", "inactive", "controlled",
      expected_version = revision$version,
      idempotency_key = "export-1"
    ),
    "not active"
  )
  expect_error(
    service$export_revision(
      "rev-1", "creator", "controlled",
      expected_version = revision$version - 1L,
      idempotency_key = "export-1"
    ),
    "stale"
  )
})

test_that("export denies actors, revisions, destinations and tokens", {
  fixture <- make_export_fixture("Reviewed")
  service <- new_export_service(
    fixture$repo,
    fixture$store,
    fixture$provider,
    fixture$identities
  )
  revision <- fixture$repo$get_revision("rev-1")

  expect_error(
    service$export_revision("rev-1", "inactive", "controlled", 1L, "inactive"),
    "not active"
  )
  expect_error(
    service$export_revision("rev-1", "viewer", "controlled", 1L, "viewer"),
    "not authorized"
  )
  expect_error(
    service$export_revision(
      "rev-1", "creator", "missing", revision$version, "missing"
    ),
    "not registered"
  )
  expect_error(
    service$export_revision("rev-1", "creator", "controlled", 2L, "stale"),
    "stale"
  )

  ineligible_statuses <- c("Draft", "Verified", "Experimental/Draft")
  for (index in seq_along(ineligible_statuses)) {
    status <- ineligible_statuses[[index]]
    ineligible <- make_export_fixture(status)
    ineligible_service <- new_export_service(
      ineligible$repo,
      ineligible$store,
      ineligible$provider,
      ineligible$identities
    )
    revision <- ineligible$repo$get_revision("rev-1")
    expect_error(
      ineligible_service$export_revision(
        "rev-1", "creator", "controlled", revision$version,
        paste0("ineligible-", index)
      ),
      "Only Reviewed revisions",
      info = status
    )
  }
})

test_that("export requires one accepted bundle and matching final hashes", {
  root <- withr::local_tempdir()
  store <- local_artifact_store(fs::path(root, "artifacts"))
  code_hash <- store$put(charToRaw("plot(1)\n"))
  image_hash <- store$put(charToRaw("png bytes"))
  repo <- sqlite_evidence_repository(
    fs::path(root, "evidence.sqlite"),
    fs::path(root, "chain-root.json"),
    store
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", code_hash,
    image_hash, "analysis", "create"
  )
  repo$accept_artifact_bundle(
    "bundle-1", "rev-1", code_hash, image_hash, "analysis", "bundle"
  )
  record_passing_execution(repo, "rev-1")
  reviewers <- local_identity_provider(list(
    new_actor("sp", "statistical_programmer"),
    new_actor("bio", "biostatistician")
  ))
  review <- new_review_service(repo, reviewers)
  review$approve("rev-1", "sp", 2L, "sp-approval")
  review$approve("rev-1", "bio", 3L, "bio-approval")
  database <- fs::path(root, "evidence.sqlite")
  connection <- DBI::dbConnect(RSQLite::SQLite(), database)
  withr::defer(DBI::dbDisconnect(connection), envir = parent.frame())
  DBI::dbExecute(connection, "DELETE FROM artifact_bundles")
  identities <- local_identity_provider(list(new_actor(
    "creator",
    "clinical_scientist"
  )))
  workspace <- fs::path(root, "workspace")
  fs::dir_create(workspace)
  service <- new_export_service(
    repo,
    store,
    local_workspace_provider(c(controlled = workspace)),
    identities
  )

  expect_error(
    service$export_revision("rev-1", "creator", "controlled", 4L, "export"),
    "accepted artifact bundle"
  )
})

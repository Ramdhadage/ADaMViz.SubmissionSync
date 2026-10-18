make_mod_export_state <- function(status = "Reviewed", revision_id = "rev-1") {
  root <- fs::file_temp("mod-export-fixture-")
  fs::dir_create(root)
  withr::defer(fs::dir_delete(root), envir = parent.frame())
  store <- local_artifact_store(fs::path(root, "artifacts"))
  code <- "plot(1)\n"
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
    "plot-1", revision_id, 1L, "creator", "spec", code_hash,
    image_hash, "analysis", "create",
    initial_status = initial_status
  )
  repo$accept_artifact_bundle(
    "bundle-1", revision_id, code_hash, image_hash, "analysis", "bundle"
  )
  if (status %in% c("Verified", "Reviewed")) {
    record_passing_execution(repo, revision_id) # nolint: object_usage_linter.
  }
  if (identical(status, "Reviewed")) {
    reviewers <- local_identity_provider(list(
      new_actor("sp", "statistical_programmer"),
      new_actor("bio", "biostatistician")
    ))
    review <- new_review_service(repo, reviewers)
    review$approve(revision_id, "sp", 2L, "sp-approval")
    review$approve(revision_id, "bio", 3L, "bio-approval")
  }
  list(
    repository = repo,
    revision = repo$get_revision(revision_id),
    identity_provider = local_identity_provider(list(
      new_actor("creator", "clinical_scientist"),
      new_actor("viewer", "viewer")
    ))
  )
}

test_that("export module publishes real app revision artifacts", {
  workspace <- withr::local_tempdir()
  provider <- local_workspace_provider(c(local = workspace))
  current_revision <- shiny::reactiveVal(make_mod_export_state())

  shiny::testServer(
    mod_export_server,
    args = list(
      current_revision = current_revision,
      workspace_provider = provider
    ),
    {
      session$setInputs(destination_id = "local")
      session$setInputs(actor_id = "creator")
      expect_no_match(output$receipts, "receipt-", fixed = TRUE)
      zipfile <- output$download_zip
      session$flushReact()

      expect_match(output$message, "Exported receipt-", fixed = TRUE)
      expect_setequal(
        utils::unzip(zipfile, list = TRUE)$Name, c("script.R", "plot.png")
      )
      receipts <- current_revision()$repository$list_export_receipts("rev-1")
      expect_equal(nrow(receipts), 1L)
      expect_match(output$receipts, receipts$receipt_id[[1]], fixed = TRUE)
      published <- provider$inspect_published("local", receipts$receipt_id[[1]])
      expect_equal(
        sort(fs::path_file(fs::dir_ls(published$path))),
        c("plot.png", "script.R")
      )
      expect_identical(readLines(published$code_path, warn = FALSE), "plot(1)")
      expect_setequal(
        utils::unzip(output$download_zip, list = TRUE)$Name,
        c("script.R", "plot.png")
      )
      expect_equal(
        nrow(current_revision()$repository$list_export_receipts("rev-1")), 1L
      )
    }
  )
})

test_that("export module packages revision artifacts as a ZIP download", {
  workspace <- withr::local_tempdir()
  provider <- local_workspace_provider(c(local = workspace))
  state <- make_mod_export_state()
  service <- new_export_service(
    state$repository,
    state$repository$artifact_store,
    provider,
    state$identity_provider
  )
  export <- service$export_revision(
    revision_id = "rev-1",
    actor_id = "creator",
    destination_id = "local",
    expected_version = as.integer(state$revision$version),
    idempotency_key = "download-test"
  )
  zipfile <- tempfile(fileext = ".zip")

  .write_export_zip(export, zipfile, "rev-1")

  listing <- utils::unzip(zipfile, list = TRUE)
  expect_setequal(listing$Name, c("script.R", "plot.png"))
  extracted <- withr::local_tempdir()
  utils::unzip(zipfile, exdir = extracted)
  expect_identical(
    readLines(fs::path(extracted, "script.R"), warn = FALSE),
    "plot(1)"
  )
  expect_equal(
    readBin(fs::path(extracted, "plot.png"), "raw", n = 9L),
    charToRaw("png bytes")
  )
  expect_error(
    .write_export_zip(export, tempfile(fileext = ".zip"), "rev-2"),
    "current revision"
  )
})

test_that("export module surfaces service denials", {
  workspace <- withr::local_tempdir()
  provider <- local_workspace_provider(c(local = workspace))
  current_revision <- shiny::reactiveVal(make_mod_export_state())

  shiny::testServer(
    mod_export_server,
    args = list(
      current_revision = current_revision,
      workspace_provider = provider
    ),
    {
      session$setInputs(destination_id = "local")
      session$setInputs(actor_id = "viewer")
      expect_error(output$download_zip, class = "shiny.silent.error")

      session$flushReact()
      expect_match(output$message, "not authorized", fixed = TRUE)
      receipts <- current_revision()$repository$list_export_receipts("rev-1")
      expect_equal(nrow(receipts), 0L)
    }
  )
})

test_that("one export and download action requires both approvals", {
  workspace <- withr::local_tempdir()
  provider <- local_workspace_provider(c(local = workspace))
  state <- make_mod_export_state("Verified")
  current_revision <- shiny::reactiveVal(state)
  review <- new_review_service(state$repository, local_identity_provider(list(
    new_actor("sp", "statistical_programmer"),
    new_actor("bio", "biostatistician")
  )))

  shiny::testServer(
    mod_export_server,
    args = list(
      current_revision = current_revision,
      workspace_provider = provider
    ),
    {
      session$flushReact()
      expect_match(output$controls$html, "<fieldset disabled")
      expect_match(output$controls$html, "Export and download ZIP", fixed = TRUE)
      expect_no_match(output$controls$html, "action-button", fixed = TRUE)
      expect_error(output$download_zip, class = "shiny.silent.error")

      state$revision <- review$approve("rev-1", "sp", 2L, "first-approval")
      current_revision(state)
      session$flushReact()
      expect_match(output$controls$html, "<fieldset disabled")
      expect_error(output$download_zip, class = "shiny.silent.error")

      state$revision <- review$approve("rev-1", "bio", 3L, "second-approval")
      current_revision(state)
      session$flushReact()
      expect_no_match(output$controls$html, "<fieldset disabled")
      expect_no_match(output$controls$html, "aria-disabled")

      session$setInputs(actor_id = "creator", destination_id = "local")
      expect_setequal(
        utils::unzip(output$download_zip, list = TRUE)$Name,
        c("script.R", "plot.png")
      )
      session$flushReact()
      expect_match(output$message, "Exported receipt-", fixed = TRUE)

      replacement <- make_mod_export_state(revision_id = "rev-2")
      current_revision(replacement)
      session$flushReact()
      expect_setequal(
        utils::unzip(output$download_zip, list = TRUE)$Name,
        c("script.R", "plot.png")
      )
      session$flushReact()
      expect_match(output$message, "rev-2", fixed = TRUE)
      expect_equal(nrow(replacement$repository$list_export_receipts("rev-2")), 1L)

      for (status in c("Draft", "Experimental/Draft", "Verified")) {
        current_revision(make_mod_export_state(status))
        session$flushReact()
        expect_match(output$controls$html, "<fieldset disabled")
        expect_match(output$controls$html, "aria-disabled=\"true\"", fixed = TRUE)
        expect_error(output$download_zip, class = "shiny.silent.error")
      }
    }
  )
})

test_that("ZIP failures show a message and allow an idempotent retry", {
  workspace <- withr::local_tempdir()
  provider <- local_workspace_provider(c(local = workspace))
  current_revision <- shiny::reactiveVal(make_mod_export_state())
  write_zip <- .write_export_zip
  attempts <- 0L
  local_mocked_bindings(.write_export_zip = function(...) {
    attempts <<- attempts + 1L
    if (attempts == 1L) stop("ZIP creation failed")
    write_zip(...)
  })

  shiny::testServer(
    mod_export_server,
    args = list(
      current_revision = current_revision,
      workspace_provider = provider
    ),
    {
      session$setInputs(actor_id = "creator", destination_id = "local")
      expect_error(output$download_zip, class = "shiny.silent.error")
      session$flushReact()
      expect_match(output$message, "ZIP creation failed", fixed = TRUE)
      expect_setequal(
        utils::unzip(output$download_zip, list = TRUE)$Name,
        c("script.R", "plot.png")
      )
      session$flushReact()
      expect_match(output$message, "Exported receipt-", fixed = TRUE)
      expect_equal(
        nrow(current_revision()$repository$list_export_receipts("rev-1")), 1L
      )
    }
  )
})

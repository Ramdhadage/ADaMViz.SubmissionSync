make_mod_export_state <- function(status = "Verified") {
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
    "plot-1", "rev-1", 1L, "creator", "spec", code_hash,
    image_hash, "analysis", "create", initial_status = initial_status
  )
  repo$accept_artifact_bundle(
    "bundle-1", "rev-1", code_hash, image_hash, "analysis", "bundle"
  )
  if (identical(status, "Verified")) {
    new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verify")
  }
  list(
    repository = repo,
    revision = repo$get_revision("rev-1"),
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
      session$setInputs(export = 1)

      expect_match(output$message, "Exported receipt-", fixed = TRUE)
      receipts <- current_revision()$repository$list_export_receipts("rev-1")
      expect_equal(nrow(receipts), 1L)
      published <- provider$inspect_published("local", receipts$receipt_id[[1]])
      expect_equal(
        sort(fs::path_file(fs::dir_ls(published$path))),
        c("plot.png", "script.R")
      )
      expect_identical(readLines(published$code_path, warn = FALSE), "plot(1)")
    }
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
      session$setInputs(export = 1)

      expect_match(output$message, "not authorized", fixed = TRUE)
      receipts <- current_revision()$repository$list_export_receipts("rev-1")
      expect_equal(nrow(receipts), 0L)
    }
  )
})

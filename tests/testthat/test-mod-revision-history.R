test_that("revision history shows parent and child current statuses", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "chain-root.json")
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", "code", "image",
    "analysis", "create"
  )
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verify")
  lifecycle <- new_lifecycle_service(repo)
  identities <- local_identity_provider(list(
    new_actor("sp", "statistical_programmer"),
    new_actor("bio", "biostatistician")
  ))
  review <- new_review_service(repo, identities)
  review$approve("rev-1", "sp", 2L, "sp-approval")
  review$approve("rev-1", "bio", 3L, "bio-approval")
  lifecycle$create_correction(
    "rev-1", "rev-2", "creator", "spec-2", "code-2", "image-2",
    "analysis-2", "Update requested after review", "change request",
    "correction"
  )
  current_revision <- shiny::reactiveVal(list(
    repository = repo,
    plot_id = "plot-1"
  ))

  shiny::testServer(
    mod_revision_history_server,
    args = list(current_revision = current_revision),
    {
      history <- output$history
      expect_match(history, "rev-1")
      expect_match(history, "Reviewed")
      expect_match(history, "rev-2")
      expect_match(history, "Draft")
    }
  )
})

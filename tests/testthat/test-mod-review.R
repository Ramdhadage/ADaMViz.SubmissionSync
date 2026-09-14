test_that("review module records distinct approvals and reaches Reviewed", {
  root <- withr::local_tempdir()
  repo <- sqlite_evidence_repository(
    fs::path(root, "db.sqlite"),
    fs::path(root, "chain-root.json")
  )
  repo$create_revision("plot-1", "rev-1", 1L, "creator", "spec", "code", "image", "analysis", "create")
  new_lifecycle_service(repo)$mark_verified("rev-1", 1L, "verify")
  identities <- local_identity_provider(list(
    new_actor("creator", "clinical_scientist"),
    new_actor("stat-programmer", "statistical_programmer"),
    new_actor("biostatistician", "biostatistician")
  ))
  state <- shiny::reactiveVal(list(
    repository = repo,
    review_service = new_review_service(repo, identities),
    revision = repo$get_revision("rev-1")
  ))

  shiny::testServer(
    mod_review_server,
    args = list(current_revision = state, set_current_revision = state),
    {
      session$setInputs(
        actor_id = "stat-programmer",
        role = "statistical_programmer",
        comment = "Programmer review complete."
      )
      session$flushReact()
      session$setInputs(
        approve = 1
      )
      session$flushReact()
      expect_identical(state()$revision$status, "Verified")

      session$setInputs(
        actor_id = "biostatistician",
        role = "biostatistician",
        comment = "Statistical review complete."
      )
      session$flushReact()
      session$setInputs(
        approve = 2
      )
      session$flushReact()
      expect_identical(state()$revision$status, "Reviewed")
      expect_equal(nrow(repo$list_review_decisions("rev-1")), 2L)
    }
  )
})

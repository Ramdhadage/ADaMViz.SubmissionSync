test_that("reconciliation has no effect when no staged exports exist", {
  root <- withr::local_tempdir()
  provider <- local_workspace_provider(c(controlled = root))

  result <- reconcile_workspace_exports(provider, "controlled")

  expect_equal(nrow(result), 0L)
  expect_equal(names(result), c("destination_id", "export_id", "action", "path"))
})

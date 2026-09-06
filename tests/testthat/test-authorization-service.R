test_that("revision creators and ineligible actors cannot approve", {
  spec <- new_plot_spec("adlb-v1")
  revision <- new_plot_revision("plot-1", "creator-1", spec)
  creator <- new_actor("creator-1", "statistical_programmer")
  observer <- new_actor("observer-1", "clinical_scientist")
  expect_snapshot(error = TRUE, authorize_revision_action(creator, revision, "approve"))
  expect_snapshot(error = TRUE, authorize_revision_action(observer, revision, "approve"))
})

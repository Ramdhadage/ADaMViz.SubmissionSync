test_that("only legal lifecycle transitions are accepted", {
  expect_identical(transition_revision_status("Draft", "Verified"), "Verified")
  expect_snapshot(error = TRUE, transition_revision_status("Reviewed", "Draft"))
})

test_that("free-scale revisions start as experimental drafts", {
  spec <- new_plot_spec("adlb-v1", scale_mode = "free")
  revision <- new_plot_revision("plot-1", "creator-1", spec)
  expect_identical(revision$status, "Experimental/Draft")
})

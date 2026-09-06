test_that("provider ports declare only named capabilities", {
  port <- new_provider_port("dataset", c("read_snapshot", "list_catalog"))
  expect_identical(port$name, "dataset")
  expect_setequal(port$capabilities, c("read_snapshot", "list_catalog"))
})

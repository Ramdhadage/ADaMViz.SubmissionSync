test_that("execution manifests bind the specification and environment", {
  spec <- new_plot_spec("adlb-v1")
  request <- new_execution_request(spec, "script", "snapshot", "data-hash", "runner-v1")
  result <- new_execution_result(request, "analysis", "image", "environment")
  expect_identical(request$spec_hash, spec$hash)
  expect_identical(result$manifest_version, "execution-result-v1")
})

test_that("canonical serialization is order stable", {
  expect_identical(canonical_serialize(list(b = 2, a = 1)), canonical_serialize(list(a = 1, b = 2)))
})

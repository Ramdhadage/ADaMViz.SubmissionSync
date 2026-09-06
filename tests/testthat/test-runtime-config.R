test_that("local runtime configuration is explicit and safe", {
  config <- new_runtime_config(
    profile = "local",
    prompt_provider = "mock",
    workspace = "local"
  )

  expect_s3_class(config, "submission_sync_runtime_config")
  expect_identical(config$profile, "local")
  expect_identical(config$prompt_provider, "mock")
  expect_identical(config$workspace, "local")
  expect_false("secret" %in% names(config))
})

test_that("production provider configuration cannot be selected locally", {
  expect_error(
    new_runtime_config(profile = "local", prompt_provider = "production"),
    "production provider"
  )
})

test_that("secret references are resolved only by the injected provider", {
  secret_provider <- function(reference) {
    if (identical(reference, "MODEL_API_KEY")) "canary-secret" else NULL
  }

  config <- new_runtime_config(
    profile = "local",
    prompt_provider = "mock",
    secret_provider = secret_provider,
    required_secret_references = "MODEL_API_KEY"
  )

  expect_identical(resolve_runtime_secret(config, "MODEL_API_KEY"), "canary-secret")
  expect_error(resolve_runtime_secret(config, "MISSING"), "not configured")
  expect_false("canary-secret" %in% capture.output(print(config)))
})

test_that("invalid runtime profiles fail closed", {
  expect_error(new_runtime_config(profile = "unknown"), "profile")
})

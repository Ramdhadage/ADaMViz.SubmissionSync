local_browser_app <- function(app, name) {
  testthat::skip_if_not_installed("shinytest2")
  testthat::skip_if_not_installed("chromote")
  source_root <- test_source_root() # nolint: object_usage_linter.
  environment <- c(NOT_CRAN = "true")
  if (!is.null(source_root)) {
    environment <- c(
      environment,
      ADAMVIZ_SUBMISSIONSYNC_SOURCE_ROOT = source_root
    )
  }
  withr::local_envvar(environment)
  tryCatch(
    withCallingHandlers(
      shinytest2::AppDriver$new(
        app,
        name = name,
        load_timeout = 30000,
        timeout = 30000,
        height = 900,
        width = 1400
      ),
      warning = function(warning) {
        invokeRestart("muffleWarning")
      }
    ),
    error = function(error) {
      testthat::skip(paste(
        "Pinned shinytest2 browser is unavailable:",
        conditionMessage(error)
      ))
    }
  )
}

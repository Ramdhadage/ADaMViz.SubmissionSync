local_browser_app <- function(app, name) {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  withr::local_envvar(NOT_CRAN = "true")
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
      skip(paste("Pinned shinytest2 browser is unavailable:", conditionMessage(error)))
    }
  )
}

#' Run the Shiny Application
#'
#' @param ... arguments to pass to golem_opts.
#' See `?golem::get_golem_options` for more details.
#' @param runtime_config Injected runtime configuration.
#' @inheritParams shiny::shinyApp
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
run_app <- function(
  onStart = NULL, # nolint: object_name_linter
  options = list(),
  enableBookmarking = NULL, # nolint: object_name_linter
  uiPattern = "/", # nolint: object_name_linter
  runtime_config = new_runtime_config(),
  ...
) {
  with_golem_options(
    app = shinyApp(
      ui = function(request) app_ui(request, runtime_config = runtime_config),
      server = function(input, output, session) {
        app_server(input, output, session, runtime_config = runtime_config)
      },
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(...)
  )
}

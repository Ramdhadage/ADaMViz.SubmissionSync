#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @param runtime_config Injected runtime configuration.
#' @import shiny
#' @noRd
app_server <- function(input, output, session, runtime_config = new_runtime_config()) {
  output$runtime_profile <- renderText(runtime_config$profile)
}

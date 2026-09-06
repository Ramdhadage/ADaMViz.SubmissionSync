#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @param runtime_config Injected runtime configuration.
#' @import shiny
#' @importFrom bslib page_fillable card card_header card_body
#' @noRd
app_ui <- function(request, runtime_config = new_runtime_config()) {
  tagList(
    golem_add_external_resources(),
    bslib::page_fillable(
      title = "ADaMViz SubmissionSync",
      theme = app_theme(),
      fillable = FALSE,
      bslib::card(
        bslib::card_header("Plot-Pattern Assurance Cell"),
        bslib::card_body(
          h1("Plot-Pattern Assurance Cell"),
          p("A governed workspace for review-ready clinical visualizations."),
          div(
            class = "alert alert-secondary",
            role = "status",
            h2("No plot revision selected", class = "h5"),
            p("Start with a natural-language plotting request or select a permitted dataset.")
          ),
          tags$small(
            sprintf("Runtime profile: %s", runtime_config$profile),
            class = "text-body-secondary"
          )
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "ADaMViz.SubmissionSync"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}

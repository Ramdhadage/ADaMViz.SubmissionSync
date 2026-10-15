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
      div(
        class = "assurance-shell",
        tags$header(
          class = "f001-app-header",
          tags$span(class = "f001-app-title", "ADaMViz SubmissionSync"),
          tags$a(
            class = "f001-repo-link",
            href = "https://github.com/Ramdhadage/ADaMViz.SubmissionSync",
            target = "_blank",
            rel = "noopener noreferrer",
            `aria-label` = paste(
              "ADaMViz SubmissionSync on GitHub (opens in a new tab)"
            ),
            shiny::icon("github")
          )
        ),
        mod_plot_generation_ui("plot_generation"),
        tags$footer(
          class = "f001-app-footer",
          "This app is brought to you by Ramnath Dhadage. ",
          "For more information, please visit the ",
          tags$a(
            "Source Code",
            href = "https://github.com/Ramdhadage/ADaMViz.SubmissionSync",
            target = "_blank",
            rel = "noopener noreferrer"
          ),
          " and ",
          tags$a(
            "Report Issues",
            href = paste0(
              "https://github.com/Ramdhadage/",
              "ADaMViz.SubmissionSync/issues/new"
            ),
            target = "_blank",
            rel = "noopener noreferrer"
          ),
          "."
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

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
        h1("Plot-Pattern Assurance Cell"),
        p("A governed workspace for review-ready clinical visualizations."),
        div(
          class = "assurance-grid",
          div(
            class = "assurance-stack",
            mod_prompt_ui("prompt"),
            mod_specification_ui("specification"),
            mod_run_status_ui("run_status"),
            mod_review_ui("review")
          ),
          div(
            class = "assurance-stack",
            mod_plot_preview_ui("plot_preview"),
            mod_evidence_ui("evidence"),
            mod_revision_history_ui("revision_history")
          )
        ),
        tags$small(
          sprintf("Runtime profile: %s", runtime_config$profile),
          class = "text-body-secondary"
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

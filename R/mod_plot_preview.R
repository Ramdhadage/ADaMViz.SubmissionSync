mod_plot_preview_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Plot preview"),
    bslib::card_body(
      shiny::plotOutput(ns("plot"), height = "520px"),
      tags$details(
        class = "f001-panel",
        tags$summary("Executed R script"),
        tags$div(
          class = "f001-panel-body",
          shiny::verbatimTextOutput(ns("code"), placeholder = TRUE)
        )
      )
    )
  )
}

mod_plot_preview_server <- function(id, current_revision) {
  shiny::moduleServer(id, function(input, output, session) {
    output$plot <- shiny::renderPlot({
      state <- current_revision()
      shiny::validate(shiny::need(!is.null(state$artifact), "No plot artifact yet."))
      state$artifact$combined
    }, alt = function() {
      state <- current_revision()
      if (is.null(state$profile)) {
        return("No governed plot revision has been generated.")
      }
      paste(
        "Longitudinal boxplot for",
        state$spec$fields$paramcd,
        "using",
        state$spec$fields$y_variable,
        "faceted by",
        state$spec$fields$treatment_variable,
        "with N values in an aligned lower strip."
      )
    })

    output$code <- shiny::renderText({
      state <- current_revision()
      shiny::validate(shiny::need(!is.null(state$script), "No executed R script yet."))
      state$script
    })
  })
}

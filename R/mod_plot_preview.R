mod_plot_preview_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Plot and Code"),
    bslib::card_body(
      shiny::plotOutput(ns("plot"), height = "520px"),
      tags$h3("Executed R script", class = "h6 mt-3"),
      shiny::verbatimTextOutput(ns("code"), placeholder = TRUE)
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

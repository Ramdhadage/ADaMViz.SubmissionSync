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

mod_plot_preview_server <- function(id, current_revision, execution_status) {
  shiny::moduleServer(id, function(input, output, session) {
    plot_waiter <- waiter::Waiter$new(
      id = session$ns("plot"),
      html = waiter::spin_fading_circles(),
      color = "rgba(255, 255, 255, 0.85)"
    )
    progress <- NULL

    close_progress <- function() {
      if (!is.null(progress)) {
        progress$close()
        progress <<- NULL
      }
    }

    session$onSessionEnded(close_progress)

    shiny::observeEvent(execution_status(), {
      status <- execution_status()
      if (identical(status, "running")) {
        close_progress()
        progress <<- shiny::Progress$new(session, min = 0, max = 1)
        progress$set(value = 0.1, message = "Generating plot")
        plot_waiter$show()
      } else {
        if (identical(status, "success") && !is.null(progress)) {
          progress$set(value = 1, message = "Plot ready")
        }
        close_progress()
        plot_waiter$hide()
      }
    }, ignoreInit = FALSE)

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

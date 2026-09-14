mod_run_status_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Run Status"),
    bslib::card_body(
      shiny::uiOutput(ns("status")),
      shiny::uiOutput(ns("warnings"))
    )
  )
}

mod_run_status_server <- function(id, current_revision) {
  shiny::moduleServer(id, function(input, output, session) {
    output$status <- shiny::renderUI({
      state <- current_revision()
      if (is.null(state$revision)) {
        return(div(class = "text-body-secondary", "No revision has been created."))
      }
      status <- state$revision$status
      div(
        class = "status-row",
        span(class = paste("status-badge", .status_class(status)), status),
        span(class = "text-body-secondary", paste("Revision", state$revision$revision_id))
      )
    })

    output$warnings <- shiny::renderUI({
      state <- current_revision()
      if (is.null(state$profile)) return(NULL)
      warnings <- state$profile$warnings
      if (!length(warnings)) {
        return(div(class = "text-body-secondary", "No nonblocking profile warnings."))
      }
      tags$ul(
        class = "warning-list",
        lapply(warnings, function(warning) {
          tags$li(
            tags$strong(warning$code),
            paste0(": ", warning$message),
            if (!is.null(warning$count)) paste0(" (", warning$count, ")") else ""
          )
        })
      )
    })
  })
}

.status_class <- function(status) {
  switch(
    status,
    "Verified" = "status-verified",
    "Reviewed" = "status-reviewed",
    "Rejected" = "status-rejected",
    "Experimental/Draft" = "status-experimental",
    "status-draft"
  )
}

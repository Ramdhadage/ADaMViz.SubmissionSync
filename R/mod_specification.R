mod_specification_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Resolved Specification"),
    bslib::card_body(
      shiny::uiOutput(ns("summary")),
      shiny::tableOutput(ns("fields"))
    )
  )
}

mod_specification_server <- function(id, current_revision) {
  shiny::moduleServer(id, function(input, output, session) {
    output$summary <- shiny::renderUI({
      state <- current_revision()
      if (is.null(state$spec)) {
        return(div(class = "text-body-secondary", "No confirmed specification yet."))
      }
      div(
        class = "assurance-summary",
        tags$strong("Specification hash"),
        tags$code(state$spec$hash)
      )
    })

    output$fields <- shiny::renderTable({
      state <- current_revision()
      if (is.null(state$spec)) return(data.frame())
      fields <- state$spec$fields
      data.frame(
        field = names(fields),
        value = vapply(fields, .display_value, character(1)),
        provenance = vapply(names(fields), function(name) {
          state$spec$provenance[[name]] %||% ""
        }, character(1)),
        stringsAsFactors = FALSE
      )
    }, striped = TRUE, bordered = FALSE, spacing = "s")
  })
}

.display_value <- function(value) {
  if (is.null(value)) return("")
  paste(as.character(value), collapse = ", ")
}

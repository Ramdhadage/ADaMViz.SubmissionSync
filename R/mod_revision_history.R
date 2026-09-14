mod_revision_history_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Revision History"),
    bslib::card_body(
      shiny::tableOutput(ns("history"))
    )
  )
}

mod_revision_history_server <- function(id, current_revision) {
  shiny::moduleServer(id, function(input, output, session) {
    output$history <- shiny::renderTable({
      state <- current_revision()
      if (is.null(state$repository) || is.null(state$plot_id)) return(data.frame())
      revisions <- state$repository$list_revisions(state$plot_id)
      revisions$status <- vapply(
        revisions$revision_id,
        function(revision_id) state$repository$get_revision(revision_id)$status,
        character(1)
      )
      revisions[, c("revision_id", "revision_number", "initial_status", "status", "created_at"), drop = FALSE]
    }, striped = TRUE, spacing = "s")
  })
}

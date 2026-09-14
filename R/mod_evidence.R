mod_evidence_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Evidence"),
    bslib::card_body(
      shiny::tableOutput(ns("hashes")),
      shiny::tableOutput(ns("checks"))
    )
  )
}

mod_evidence_server <- function(id, current_revision) {
  shiny::moduleServer(id, function(input, output, session) {
    output$hashes <- shiny::renderTable({
      state <- current_revision()
      if (is.null(state$revision)) return(data.frame())
      data.frame(
        item = c("Specification", "Code", "Image", "Analytical output"),
        hash = c(
          state$revision$spec_hash,
          state$revision$code_hash,
          state$revision$image_hash,
          state$revision$analytical_hash
        ),
        stringsAsFactors = FALSE
      )
    }, striped = TRUE, spacing = "s")

    output$checks <- shiny::renderTable({
      state <- current_revision()
      if (is.null(state$verification)) return(data.frame())
      checks <- state$verification$checks
      data.frame(
        check = names(checks),
        passed = unname(unlist(checks)),
        stringsAsFactors = FALSE
      )
    }, striped = TRUE, spacing = "s")
  })
}

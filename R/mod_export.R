mod_export_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Controlled export"),
    bslib::card_body(
      shiny::selectInput(
        ns("actor_id"),
        "Actor",
        choices = c(
          "Creator" = "creator",
          "Statistical programmer" = "stat-programmer",
          "Biostatistician" = "biostatistician"
        )
      ),
      shiny::textInput(ns("destination_id"), "Destination", value = "local"),
      shiny::actionButton(ns("export"), "Export image and code"),
      shiny::verbatimTextOutput(ns("message")),
      shiny::tableOutput(ns("receipts"))
    )
  )
}

mod_export_server <- function(id, current_revision, workspace_provider) {
  shiny::moduleServer(id, function(input, output, session) {
    message <- shiny::reactiveVal("No export attempted.")

    shiny::observeEvent(input$export, {
      state <- current_revision()
      tryCatch(
        {
          if (is.null(state$revision) || is.null(state$repository)) {
            cli::cli_abort("Create a revision before export")
          }
          if (is.null(state$identity_provider)) {
            cli::cli_abort("Export requires an identity provider")
          }
          service <- new_export_service(
            state$repository,
            state$repository$artifact_store,
            workspace_provider,
            state$identity_provider
          )
          receipt <- service$export_revision(
            revision_id = state$revision$revision_id,
            actor_id = input$actor_id,
            destination_id = input$destination_id,
            expected_version = as.integer(state$revision$version),
            idempotency_key = paste(
              "app-export",
              state$revision$revision_id,
              input$actor_id,
              input$destination_id,
              sep = ":"
            )
          )
          message(paste("Exported", receipt$receipt_id, receipt$revision_id))
        },
        error = function(error) {
          message(conditionMessage(error))
        }
      )
    }, ignoreInit = TRUE)

    output$message <- shiny::renderText(message())
    output$receipts <- shiny::renderTable({
      state <- current_revision()
      if (is.null(state$revision) || is.null(state$repository)) {
        return(data.frame())
      }
      state$repository$list_export_receipts(state$revision$revision_id)
    }, striped = TRUE, spacing = "s")
  })
}

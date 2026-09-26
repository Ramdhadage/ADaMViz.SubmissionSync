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
      shiny::downloadButton(ns("download_zip"), "Download image and code ZIP"),
      shiny::verbatimTextOutput(ns("message")),
      shiny::tableOutput(ns("receipts"))
    )
  )
}

mod_export_server <- function(id, current_revision, workspace_provider) {
  shiny::moduleServer(id, function(input, output, session) {
    message <- shiny::reactiveVal("No export attempted.")
    receipt_refresh <- shiny::reactiveVal(0L)
    last_export <- shiny::reactiveVal(NULL)

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
          last_export(receipt)
          receipt_refresh(receipt_refresh() + 1L)
        },
        error = function(error) {
          message(conditionMessage(error))
        }
      )
    }, ignoreInit = TRUE)

    output$message <- shiny::renderText(message())
    output$download_zip <- shiny::downloadHandler(
      filename = function() {
        state <- current_revision()
        if (is.null(state$revision)) {
          return("image-code.zip")
        }
        paste0(state$revision$revision_id, "-image-code.zip")
      },
      content = function(file) {
        .write_export_zip(last_export(), file)
      },
      contentType = "application/zip"
    )
    output$receipts <- shiny::renderTable({
      receipt_refresh()
      state <- current_revision()
      if (is.null(state$revision) || is.null(state$repository)) {
        return(data.frame())
      }
      state$repository$list_export_receipts(state$revision$revision_id)
    }, striped = TRUE, spacing = "s")
  })
}

.write_export_zip <- function(export, file) {
  if (is.null(export)) {
    cli::cli_abort("Export the revision before download")
  }

  root <- fs::dir_create(fs::file_temp("revision-download-"))
  fs::file_copy(export$code_path, fs::path(root, "script.R"))
  fs::file_copy(export$image_path, fs::path(root, "plot.png"))

  file <- fs::path_abs(file)
  old <- getwd()
  on.exit({
    setwd(old)
    fs::dir_delete(root)
  }, add = TRUE)
  setwd(root)
  status <- utils::zip(file, c("script.R", "plot.png"), flags = "-q")
  if (!identical(status, 0L) || !fs::file_exists(file)) {
    cli::cli_abort("Could not create ZIP download")
  }
  invisible(file)
}

mod_plot_preview_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Plot preview"),
    bslib::card_body(
      shiny::uiOutput(ns("plot")),
      tags$details(
        class = "f001-panel",
        tags$summary("Generated R script"),
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
    output$plot <- shiny::renderUI({
      state <- current_revision()
      image_hash <- state$revision$image_hash %||% NA_character_
      store <- state$repository$artifact_store
      if (!is.null(store) && checkmate::test_string(
        image_hash,
        pattern = "^[0-9a-f]{64}$"
      )) {
        shiny::imageOutput(session$ns("accepted_plot"), height = "520px")
      } else {
        shiny::plotOutput(session$ns("experimental_plot"), height = "520px")
      }
    })

    output$experimental_plot <- shiny::renderPlot(
      {
        state <- current_revision()
        shiny::validate(shiny::need(
          !is.null(state$artifact), "No plot artifact yet."
        ))
        state$artifact$combined
      },
      alt = function() {
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
      }
    )

    output$accepted_plot <- shiny::renderImage({
      state <- current_revision()
      image_hash <- state$revision$image_hash %||% NA_character_
      store <- state$repository$artifact_store
      shiny::validate(shiny::need(
        !is.null(store) && checkmate::test_string(
          image_hash,
          pattern = "^[0-9a-f]{64}$"
        ),
        "No accepted plot artifact yet."
      ))
      store$verify(image_hash)
      list(
        src = store$path(image_hash),
        contentType = "image/png",
        alt = paste(
          "Accepted longitudinal boxplot for",
          state$spec$fields$paramcd
        )
      )
    }, deleteFile = FALSE)

    output$code <- shiny::renderText({
      state <- current_revision()
      code_hash <- state$revision$code_hash %||% NA_character_
      store <- state$repository$artifact_store
      if (!is.null(store) && checkmate::test_string(
        code_hash,
        pattern = "^[0-9a-f]{64}$"
      )) {
        return(rawToChar(store$get(code_hash)))
      }
      shiny::validate(shiny::need(
        !is.null(state$script), "No executed R script yet."
      ))
      state$script
    })
  })
}

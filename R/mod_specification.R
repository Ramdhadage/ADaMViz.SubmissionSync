mod_specification_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Resolved Specification"),
    bslib::card_body(
      shiny::uiOutput(ns("summary")),
      shiny::tableOutput(ns("fields")),
      shiny::uiOutput(ns("controls")),
      shiny::uiOutput(ns("message"))
    )
  )
}

mod_specification_server <- function(id, current_revision, execute_revision = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    message <- shiny::reactiveVal(NULL)

    output$summary <- shiny::renderUI({
      state <- current_revision()
      if (is.null(state$spec)) {
        return(div(class = "text-body-secondary", "No confirmed specification yet."))
      }
      if (!is.null(state$pending)) {
        return(div(
          class = "assurance-summary",
          tags$strong("Specification pending confirmation")
        ))
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

    output$controls <- shiny::renderUI({
      state <- current_revision()
      if (is.null(state$pending)) return(NULL)
      choices <- state$pending$choices
      fields <- state$spec$fields
      treatment_variable <- input$treatment_variable %||%
        fields$treatment_variable %||% choices$treatment_variables[[1]]
      paramcd <- input$paramcd %||% fields$paramcd %||% choices$parameters[[1]]
      units <- choices$units[[paramcd]] %||% character()
      selected_unit <- if (!is.null(fields$unit) && fields$unit %in% units) {
        fields$unit
      } else if (length(units) == 1L) {
        units[[1]]
      } else {
        character()
      }
      treatment_levels <- choices$treatment_levels[[treatment_variable]]

      tags$div(
        class = "specification-controls",
        shiny::selectInput(session$ns("paramcd"), "Parameter", choices$parameters, selected = paramcd),
        shiny::selectInput(
          session$ns("y_variable"),
          "Y variable",
          choices$y_variables,
          selected = fields$y_variable %||% choices$y_variables[[1]]
        ),
        shiny::selectInput(session$ns("unit"), "Unit", units, selected = selected_unit),
        shiny::selectInput(
          session$ns("treatment_variable"),
          "Treatment facet",
          choices$treatment_variables,
          selected = treatment_variable
        ),
        shiny::checkboxGroupInput(
          session$ns("treatment_levels"),
          "Included treatment levels",
          treatment_levels,
          selected = fields$treatment_levels %||% treatment_levels
        ),
        shiny::checkboxGroupInput(
          session$ns("visits"),
          "Included visits",
          choices$visits,
          selected = fields$visits %||% choices$visits
        ),
        shiny::radioButtons(
          session$ns("scale_mode"),
          "Y scales",
          choices = c("Fixed" = "fixed", "Free" = "free"),
          selected = fields$scale_mode %||% "fixed",
          inline = TRUE
        ),
        shiny::checkboxInput(
          session$ns("confirm_free_scale"),
          "I understand free Y scales create an Experimental/Draft revision",
          value = FALSE
        ),
        .assurance_task_button(session$ns("execute"), "Execute confirmed specification", class = "btn-primary")
      )
    })

    output$message <- shiny::renderUI({
      text <- message()
      if (is.null(text)) return(NULL)
      div(class = "assurance-message", role = "status", text)
    })

    shiny::observeEvent(input$execute, {
      message(NULL)
      if (!is.function(execute_revision)) {
        message("Execution is unavailable in this context.")
        return()
      }
      if (identical(input$scale_mode, "free") && !isTRUE(input$confirm_free_scale)) {
        message("Free Y scales require confirmation before execution.")
        return()
      }
      tryCatch(
        execute_revision(.current_spec_input_fields(input, current_revision())),
        error = function(error) {
          message(conditionMessage(error))
        }
      )
    }, ignoreInit = TRUE)
  })
}

.current_spec_input_fields <- function(input, state) {
  choices <- state$pending$choices
  fields <- state$spec$fields
  treatment_variable <- input$treatment_variable %||%
    fields$treatment_variable %||% choices$treatment_variables[[1]]
  paramcd <- input$paramcd %||% fields$paramcd %||% choices$parameters[[1]]
  units <- choices$units[[paramcd]] %||% character()
  unit <- input$unit %||% fields$unit %||% if (length(units) == 1L) units[[1]] else NULL
  treatment_levels <- input$treatment_levels %||%
    fields$treatment_levels %||% choices$treatment_levels[[treatment_variable]]
  visits <- input$visits %||% fields$visits %||% choices$visits

  list(
    paramcd = paramcd,
    y_variable = input$y_variable %||% fields$y_variable %||% choices$y_variables[[1]],
    unit = unit,
    treatment_variable = treatment_variable,
    treatment_levels = treatment_levels,
    visits = visits,
    scale_mode = input$scale_mode %||% fields$scale_mode %||% "fixed"
  )
}

.display_value <- function(value) {
  if (is.null(value)) return("")
  paste(as.character(value), collapse = ", ")
}

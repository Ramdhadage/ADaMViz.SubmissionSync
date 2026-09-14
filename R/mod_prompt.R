mod_prompt_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Prompt and Dataset"),
    bslib::card_body(
      shiny::selectInput(ns("dataset_id"), "Synthetic BDS scenario", choices = character()),
      shiny::textAreaInput(
        ns("prompt"),
        "Plot request",
        value = "Create a boxplot of ALT AVAL by treatment over all visits.",
        width = "100%",
        rows = 4
      ),
      shiny::checkboxInput(
        ns("confirm_free_scale"),
        "I understand free Y scales create an Experimental/Draft revision",
        value = FALSE
      ),
      .assurance_task_button(ns("submit"), "Create revision", class = "btn-primary"),
      shiny::uiOutput(ns("message"))
    )
  )
}

mod_prompt_server <- function(id, catalog, create_revision) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observe({
      choices <- stats::setNames(catalog()$dataset_id, catalog()$purpose)
      shiny::updateSelectInput(session, "dataset_id", choices = choices)
    })

    message <- shiny::reactiveVal(NULL)
    output$message <- shiny::renderUI({
      text <- message()
      if (is.null(text)) return(NULL)
      div(class = "assurance-message", role = "status", text)
    })

    shiny::observeEvent(input$submit, {
      message(NULL)
      tryCatch(
        create_revision(
          dataset_id = input$dataset_id,
          prompt = input$prompt,
          confirm_free_scale = isTRUE(input$confirm_free_scale)
        ),
        error = function(error) {
          message(conditionMessage(error))
        }
      )
    }, ignoreInit = TRUE)
  })
}

.assurance_task_button <- function(input_id, label, ...) {
  task_button <- get0(
    "input_task_button",
    envir = asNamespace("bslib"),
    inherits = FALSE
  )
  if (is.function(task_button)) {
    return(task_button(input_id, label, ...))
  }
  shiny::actionButton(input_id, label, ...)
}

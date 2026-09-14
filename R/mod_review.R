mod_review_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "assurance-panel",
    bslib::card_header("Two-Person Review"),
    bslib::card_body(
      shiny::selectInput(
        ns("actor_id"),
        "Reviewer identity",
        choices = c(
          "Statistical programmer" = "stat-programmer",
          "Biostatistician" = "biostatistician",
          "Creator" = "creator"
        )
      ),
      shiny::selectInput(
        ns("role"),
        "Review role",
        choices = c(
          "Statistical programmer" = "statistical_programmer",
          "Biostatistician" = "biostatistician"
        )
      ),
      shiny::textAreaInput(ns("comment"), "Comment or rejection rationale", rows = 3),
      div(
        class = "review-actions",
        shiny::actionButton(ns("approve"), "Approve", class = "btn-success"),
        shiny::actionButton(ns("reject"), "Reject", class = "btn-outline-danger")
      ),
      shiny::uiOutput(ns("message")),
      shiny::tableOutput(ns("decisions"))
    )
  )
}

mod_review_server <- function(id, current_revision, set_current_revision) {
  shiny::moduleServer(id, function(input, output, session) {
    message <- shiny::reactiveVal(NULL)

    output$message <- shiny::renderUI({
      text <- message()
      if (is.null(text)) return(NULL)
      div(class = "assurance-message", role = "status", text)
    })

    decide <- function(decision) {
      state <- current_revision()
      if (is.null(state$review_service) || is.null(state$revision)) {
        cli::cli_abort("Create and verify a revision before review")
      }
      current <- state$repository$get_revision(state$revision$revision_id)
      key <- paste(
        decision,
        current$revision_id,
        input$actor_id,
        current$version,
        sep = ":"
      )
      if (identical(decision, "approved")) {
        revision <- state$review_service$approve(
          current$revision_id,
          input$actor_id,
          as.integer(current$version),
          key,
          comment = input$comment,
          role = input$role
        )
      } else {
        revision <- state$review_service$reject(
          current$revision_id,
          input$actor_id,
          as.integer(current$version),
          key,
          rationale = input$comment,
          role = input$role
        )
      }
      state$revision <- revision
      set_current_revision(state)
      message(paste("Recorded", decision, "decision."))
    }

    shiny::observeEvent(input$approve, {
      tryCatch(decide("approved"), error = function(error) message(conditionMessage(error)))
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$reject, {
      tryCatch(decide("rejected"), error = function(error) message(conditionMessage(error)))
    }, ignoreInit = TRUE)

    output$decisions <- shiny::renderTable({
      state <- current_revision()
      if (is.null(state$repository) || is.null(state$revision)) return(data.frame())
      decisions <- state$repository$list_review_decisions(state$revision$revision_id)
      if (!nrow(decisions)) return(data.frame())
      decisions[, c("actor_id", "role", "decision", "created_at"), drop = FALSE]
    }, striped = TRUE, spacing = "s")
  })
}

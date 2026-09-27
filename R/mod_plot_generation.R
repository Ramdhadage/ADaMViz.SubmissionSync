mod_plot_generation_ui <- function(id) {
  ns <- shiny::NS(id)

  tags$div(
    waiter::use_waiter(),
    tags$style(shiny::HTML("\
      .f001-screen { position: relative; min-width: 0; min-height: 385px; border: 1px solid #aebbc5; border-radius: .5rem; background: white; overflow: hidden; }
      .f001-appbar { height: 45px; padding: .5rem .75rem; border-bottom: 1px solid #c7d1d9; display: flex; align-items: center; justify-content: space-between; background: white; }
      .f001-brand { font-weight: 700; }
      .f001-stepmark { color: #344754; font-size: .78rem; }
      .f001-step-status { color: #344754; font-size: .78rem; }
      .f001-workbench { position: relative; padding: 12px 14px 13px 40px; }
      .f001-steps { display: grid; grid-template-columns: repeat(5, 1fr); gap: 5px; margin-bottom: 11px; }
      .f001-stepmark { padding: 6px 5px; border: 1px solid #c7d1d9; border-radius: 4px; background: #f7f9fa; text-align: center; color: #52616d; font-size: .75rem; }
      .f001-stepmark.current { border-color: #7492a6; background: #edf4f8; color: #173f59; font-weight: 700; }
      .f001-stepmark.done { color: #245b46; }
      .f001-data-drawer { position: static; }
      .f001-data-drawer > summary { position: absolute; z-index: 5; top: 57px; left: 0; display: flex; flex-direction: column; width: 28px; height: 148px; padding: 9px 5px; align-items: center; justify-content: space-between; border: 1px solid #8fa2b0; border-left: 0; border-radius: 0 6px 6px 0; background: white; color: #1c4259; cursor: pointer; list-style: none; box-shadow: 1px 2px 5px #18293612; }
      .f001-data-drawer > summary::-webkit-details-marker, .f001-panel > summary::-webkit-details-marker { display: none; }
      .f001-trigger-label { writing-mode: vertical-rl; transform: rotate(180deg); font-size: .75rem; font-weight: 650; white-space: nowrap; }
      .f001-drawer-grip { color: #688091; font-size: 1rem; line-height: 1; letter-spacing: -2px; }
      .f001-data-drawer[open] > summary { left: 250px; border-left: 1px solid #8fa2b0; border-radius: 6px 0 0 6px; background: #edf3f6; box-shadow: none; }
      .f001-drawer-body { position: absolute; z-index: 4; top: 45px; bottom: 0; left: 0; width: 250px; padding: 15px 14px; border-right: 1px solid #8fa2b0; background: white; box-shadow: 4px 0 14px #18293616; }
      .f001-drawer-body h3 { margin: 0 0 3px; font-size: 1rem; }
      .f001-drawer-body p { margin: 0 0 12px; color: #52616d; font-size: .82rem; }
      .f001-drawer-section { padding: 10px 0; border-top: 1px solid #e0e6ea; }
      .f001-drawer-section b { display: block; }
      .f001-drawer-tag { display: inline-block; padding: 2px 7px; border: 1px solid #a6b6c0; border-radius: 12px; background: #f4f7f8; color: #334b5a; font-size: .72rem; }
      .f001-screen h2 { margin: 0; font-size: 1.05rem; }
      .f001-panel { margin-bottom: 8px; border: 1px solid #c7d1d9; border-radius: 5px; background: white; }
      .f001-panel > summary { display: flex; align-items: center; justify-content: space-between; padding: .5rem .65rem; cursor: pointer; font-weight: 650; list-style: none; }
      .f001-panel > summary::after { content: '+'; color: #31556b; font-weight: 500; }
      .f001-panel[open] > summary::after { content: '−'; }
      .f001-panel-body { padding: 0 .65rem .65rem; }
      .f001-caption { margin-top: .75rem; color: #52616d; font-size: .9rem; }
      .f001-page-title { display: flex; align-items: center; justify-content: space-between; gap: .75rem; margin: 0 0 8px; }
      .f001-page-title > span { color: #52616d; font-size: .78rem; }
      .f001-required { display: inline-block; margin-left: 5px; padding: 1px 5px; border: 1px solid #e1c38a; border-radius: 3px; background: #fff4df; color: #6d4400; font-size: .7rem; font-weight: 700; }
      .f001-drop { margin-top: 8px; padding: 13px 10px; border: 1px dashed #91a1ac; border-radius: 4px; background: #fbfcfd; }
      .f001-drop .shiny-input-container { width: 100%; margin: 0; }
      .f001-drop .form-group { margin: 0; }
      .f001-drop input[type=file] { width: 100%; }
      .f001-drop-caption { color: #52616d; font-size: .8rem; }
      .f001-upload-status { margin-top: .5rem; font-size: .82rem; }
      .f001-footer-action { display: flex; align-items: center; justify-content: space-between; gap: .75rem; margin-top: 9px; }
      .f001-footer-action > span { font-size: .8rem; }
      .f001-footer-action .btn { margin: 0; }
      .f001-review-info { width: 1.5rem; height: 1.5rem; margin-left: .35rem; border: 1px solid #96a8b3; border-radius: 50%; background: white; color: #23485f; }
      .f001-result-content { position: relative; }
      .f001-screen-caption { padding: 7px 12px 8px 40px; border-top: 1px solid #e3e8eb; background: #fafbfc; color: #50606a; font-size: .78rem; }
      @media (max-width: 575.98px) { .f001-workbench { padding-right: 10px; } .f001-stepmark { padding: .35rem .1rem; font-size: .75rem; } }
    ")),
    tags$div(
      class = "f001-screen",
      tags$div(
        class = "f001-appbar",
        tags$span(class = "f001-brand", "Create plot"),
        shiny::uiOutput(ns("step_mark"))
      ),
      tags$div(
        style = "display: none;",
        shiny::textInput(ns("step_signal"), NULL, value = "data")
      ),
      tags$details(
        id = ns("data_drawer"),
        class = "f001-data-drawer",
        tags$summary(
          tags$span(class = "f001-trigger-label", "Data & profile"),
          tags$span(class = "f001-drawer-grip", "•••"),
          `aria-label` = "Open active data and profile drawer"
        ),
        tags$div(class = "f001-drawer-body", shiny::uiOutput(ns("data_profile")))
      ),
      tags$div(
        class = "f001-workbench",
        shiny::uiOutput(ns("stepper")),
      shiny::conditionalPanel(
        sprintf("input['%s'] === 'data'", ns("step_signal")),
        tags$section(
          `aria-labelledby` = ns("data-heading"),
          tags$div(
            class = "f001-page-title",
            tags$h2(id = ns("data-heading"), "Start with your data"),
            tags$span("Upload is required to continue")
          ),
          tags$details(
            class = "f001-panel",
            open = NA,
            tags$summary("Upload a dataset ", tags$span(class = "f001-required", "Required")),
            tags$div(
              class = "f001-panel-body",
              tags$div(class = "f001-drop-caption", "Choose a supported CSV or Excel file."),
              tags$div(
                class = "f001-drop",
                shiny::fileInput(
                  ns("data_file"),
                  NULL,
                  accept = c(".csv", ".xls", ".xlsx"),
                  multiple = FALSE,
                  buttonLabel = "Choose file",
                  placeholder = "or drag and drop it here"
                ),
                tags$div(class = "f001-drop-caption", "CSV or Excel")
              ),
              tags$div(class = "f001-upload-status", shiny::uiOutput(ns("upload_status")))
            )
          ),
          tags$div(
            class = "f001-footer-action",
            tags$span(class = "text-body-secondary", "Next: describe the visualization question"),
            shiny::uiOutput(ns("continue_data"))
          )
        )
      ),
      shiny::conditionalPanel(
        sprintf("input['%s'] === 'ask'", ns("step_signal")),
        tags$section(
          `aria-labelledby` = ns("ask-heading"),
          tags$h2(id = ns("ask-heading"), "What would you like to see?"),
          tags$p("Describe one visualization question in your words."),
          tags$details(
            class = "f001-panel",
            open = NA,
            tags$summary("Your visualization question · Required"),
            tags$div(
              class = "f001-panel-body",
              shiny::textAreaInput(
                ns("question"),
                "Question",
                value = "Create a boxplot of ALT AVAL by visit, split by treatment. Include all visits and treatment groups, show the number of subjects below each box, and connect the medians.",
                width = "100%",
                rows = 3
              ),
              shiny::uiOutput(ns("question_validation"))
            )
          ),
          tags$div(
            class = "d-flex justify-content-between",
            shiny::actionButton(ns("back_to_data"), "Back to data", class = "btn-outline-secondary"),
            shiny::actionButton(ns("to_confirm"), "Continue to review choices", class = "btn-primary")
          )
        )
      ),
      shiny::conditionalPanel(
        sprintf("input['%s'] === 'confirm'", ns("step_signal")),
        tags$section(
          `aria-labelledby` = ns("confirm-heading"),
          tags$h2(id = ns("confirm-heading"), "Review the proposed plot"),
          shiny::uiOutput(ns("confirm_guidance")),
          mod_specification_ui(ns("specification")),
          tags$div(
            class = "d-flex justify-content-between",
            shiny::uiOutput(ns("back_to_ask")),
            shiny::uiOutput(ns("confirm_message"))
          ),
          tags$p(class = "f001-caption", "The selected BDS records are validated before the deterministic R script is generated or executed.")
        )
      ),
      shiny::conditionalPanel(
        sprintf("input['%s'] === 'result'", ns("step_signal")),
        tags$section(
          `aria-labelledby` = ns("result-heading"),
          tags$div(
            class = "f001-page-title",
            tags$h2(id = ns("result-heading"), "Plot result"),
            tags$div(shiny::uiOutput(ns("review_status")))
          ),
          tags$div(
            id = ns("result-body"),
            class = "f001-result-content",
            mod_run_status_ui(ns("run_status")),
            mod_plot_preview_ui(ns("plot_preview")),
            tags$details(
              class = "f001-panel",
              tags$summary("Optional: view automated checks"),
              tags$div(class = "f001-panel-body", mod_evidence_ui(ns("evidence")))
            )
          ),
          tags$div(
            class = "d-flex justify-content-between",
            shiny::actionButton(ns("back_to_confirm"), "Back to confirm", class = "btn-outline-secondary"),
            shiny::actionButton(ns("to_export"), "Continue to export", class = "btn-primary")
          )
        )
      ),
      shiny::conditionalPanel(
        sprintf("input['%s'] === 'export'", ns("step_signal")),
        tags$section(
          `aria-labelledby` = ns("export-heading"),
          tags$h2(id = ns("export-heading"), "Export"),
          tags$details(
            class = "f001-panel",
            open = NA,
            tags$summary("Traceability, review, and export"),
            tags$div(
              class = "f001-panel-body",
              mod_revision_history_ui(ns("revision_history")),
              mod_review_ui(ns("review")),
              mod_export_ui(ns("export"))
            )
          ),
          tags$div(
            class = "d-flex justify-content-start",
            shiny::actionButton(ns("back_to_result"), "Back to result", class = "btn-outline-secondary")
          ),
          tags$p(class = "f001-caption", "Review decisions are pending until both independent reviewers approve. The exact R script and check evidence remain linked to this revision.")
        )
      ),
      shiny::conditionalPanel(
        sprintf("input['%s'] === 'data'", ns("step_signal")),
        tags$div(class = "f001-screen-caption", "Data comes first. Continue becomes available when a permitted CSV or Excel file is ready.")
      )
    ),
    tags$script(shiny::HTML(sprintf("\
      (() => {
        const drawer = document.getElementById('%s');
        const handle = drawer && drawer.querySelector('summary');
        if (!handle) return;
        let startX = 0;
        let dragged = false;
        handle.addEventListener('pointerdown', (event) => {
          startX = event.clientX;
          dragged = false;
          handle.setPointerCapture(event.pointerId);
        });
        handle.addEventListener('pointermove', (event) => {
          if (event.buttons && event.clientX - startX > 48) {
            drawer.open = true;
            dragged = true;
          }
        });
        handle.addEventListener('click', (event) => {
          if (dragged) {
            event.preventDefault();
            dragged = false;
          }
        });
      })();\n", ns("data_drawer")))
    )
    )
  )
}

mod_plot_generation_server <- function(
  id,
  current_revision,
  execute_revision,
  create_correction,
  execution_status,
  workspace_provider
) {
  shiny::moduleServer(id, function(input, output, session) {
    step_ids <- c("data", "ask", "confirm", "result", "export")
    step_labels <- c("Data", "Ask", "Confirm", "Result", "Export")
    active_step <- shiny::reactiveVal("data")
    loaded_file <- shiny::reactiveVal(NULL)
    upload_error <- shiny::reactiveVal(NULL)
    question_attempted <- shiny::reactiveVal(FALSE)
    confirm_message <- shiny::reactiveVal(NULL)

    question_is_valid <- function() {
      is.character(input$question) && length(input$question) == 1L &&
        !is.na(input$question) && nzchar(trimws(input$question))
    }

    upload_inputs_valid <- function() {
      file <- input$data_file
      is.data.frame(file) && nrow(file) == 1L &&
        all(c("name", "datapath") %in% names(file)) &&
        checkmate::test_string(file$name[[1]], min.chars = 1L) &&
        tolower(tools::file_ext(file$name[[1]])) %in% c("csv", "xls", "xlsx") &&
        checkmate::test_file_exists(file$datapath[[1]], access = "r")
    }

    is_current_upload <- shiny::reactive({
      loaded <- loaded_file()
      file <- input$data_file
      !is.null(loaded) && is.data.frame(file) && nrow(file) == 1L &&
        identical(loaded$path, file$datapath[[1]])
    })

    output$stepper <- shiny::renderUI({
      current <- active_step()
      current_index <- match(current, step_ids)
      tags$div(
        class = "f001-steps",
        lapply(seq_along(step_ids), function(index) {
          class <- if (index == current_index) {
            "f001-stepmark current"
          } else if (index < current_index) {
            "f001-stepmark done"
          } else {
            "f001-stepmark"
          }
          label <- if (index < current_index) {
            paste("✓", "·", step_labels[[index]])
          } else {
            paste(index, "·", step_labels[[index]])
          }
          tags$div(class = class, label)
        })
      )
    })
    output$step_mark <- shiny::renderUI({
      tags$span(
        class = "f001-step-status",
        paste("Step", match(active_step(), step_ids), "of", length(step_ids))
      )
    })

    output$data_profile <- shiny::renderUI({
      loaded <- loaded_file()
      tags$div(
        tags$h3("Active data"),
        tags$p(
          if (is.null(loaded)) "No dataset uploaded" else loaded$file_name,
          if (!is.null(loaded)) tags$span(class = "f001-drawer-tag", "Ready")
        ),
        tags$div(
          class = "f001-drawer-section",
          tags$b("Data profile"),
          tags$span(
            class = "text-body-secondary",
            if (is.null(loaded)) "Available after upload" else paste(loaded$rows, "rows ×", loaded$columns, "columns")
          )
        ),
        tags$div(
          class = "f001-drawer-section",
          tags$b("File check"),
          tags$span(
            class = "f001-drawer-tag",
            if (!is.null(loaded)) "Passed" else if (!is.null(upload_error())) "Needs attention" else "Waiting for file"
          )
        ),
        if (is.null(loaded)) tags$p(class = "text-body-secondary", "Drawer starts closed. Click the tab or drag it to open.")
      )
    })

    output$upload_status <- shiny::renderUI({
      if (!is.null(upload_error())) {
        return(tags$div(class = "text-danger", role = "alert", upload_error()))
      }
      if (is_current_upload()) {
        return(tags$div(class = "text-success", role = "status", "File ready"))
      }
      NULL
    })

    output$continue_data <- shiny::renderUI({
      shiny::actionButton(
        session$ns("to_ask"),
        "Continue",
        class = "btn-primary",
        disabled = !is_current_upload()
      )
    })

    output$question_validation <- shiny::renderUI({
      if (!question_attempted()) return(NULL)
      shiny::validate(
        shiny::need(question_is_valid(), "Enter a visualization question before continuing.")
      )
      NULL
    })

    output$confirm_guidance <- shiny::renderUI({
      state <- current_revision()
      if (!is.null(state$revision) && is.null(state$pending)) {
        return(tags$p(class = "text-body-secondary", "This generated revision is immutable. Its specification is shown for review."))
      }
      NULL
    })

    output$back_to_ask <- shiny::renderUI({
      state <- current_revision()
      shiny::actionButton(
        session$ns("back_to_ask"),
        "Back to question",
        class = "btn-outline-secondary",
        disabled = !is.null(state$revision) && is.null(state$pending)
      )
    })

    output$confirm_message <- shiny::renderUI({
      message <- confirm_message()
      if (is.null(message)) return(NULL)
      tags$div(class = "alert alert-danger mb-0", role = "alert", message)
    })

    output$review_status <- shiny::renderUI({
      state <- current_revision()
      if (identical(execution_status(), "running")) {
        return(tags$span(class = "status-badge status-draft", "Generating plot"))
      }
      if (is.null(state$revision)) {
        return(tags$span(class = "status-badge status-draft", "No result yet"))
      }
      revision <- state$revision
      decisions <- state$repository$list_review_decisions(revision$revision_id)
      status <- revision$status
      label <- if (status %in% c("Draft", "Verified") && !nrow(decisions)) {
        paste(status, "· not reviewed")
      } else if (status %in% c("Draft", "Verified")) {
        paste(status, "· review pending")
      } else {
        status
      }
      tags$span(
        tags$span(class = paste("status-badge", .status_class(status)), label),
        tags$button(
          type = "button",
          class = "f001-review-info",
          title = "Both independent approvals are required for post-approval export eligibility.",
          `aria-label` = "Review status: both independent approvals are required for post-approval export eligibility.",
          "i"
        )
      )
    })

    set_step <- function(next_step) {
      if (identical(active_step(), next_step)) return(invisible(next_step))
      active_step(next_step)
      shiny::updateTextInput(session, "step_signal", value = next_step)
      invisible(next_step)
    }

    shiny::observeEvent(input$data_file, {
      upload_error(NULL)
      loaded_file(NULL)
      if (!upload_inputs_valid()) {
        if (!is.null(input$data_file)) upload_error("Choose one readable CSV or Excel file.")
        return()
      }
      file <- input$data_file
      loaded <- tryCatch(
        {
          provider <- .uploaded_study_data_provider(file)
          snapshot <- pin_study_snapshot(provider, provider$manifest$scenarios[[1]]$dataset_id)
          snapshot$source_metadata <- provider$source_metadata
          data <- snapshot$data
          list(
            path = file$datapath[[1]],
            file_name = provider$source_metadata$file_name,
            rows = nrow(data),
            columns = ncol(data),
            provider = provider,
            snapshot = snapshot
          )
        },
        error = function(error) {
          upload_error(trimws(cli::ansi_strip(conditionMessage(error))))
          NULL
        }
      )
      if (is.null(loaded)) return()
      loaded_file(loaded)
      current_revision(.empty_assurance_state())
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$to_ask, {
      if (!is_current_upload()) return()
      set_step("ask")
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$to_confirm, {
      if (!is_current_upload()) return()
      question_attempted(TRUE)
      if (!question_is_valid()) return()
      state <- current_revision()
      if (is.null(state$pending) || !identical(state$prompt, input$question)) {
        loaded <- loaded_file()
        state <- .create_assurance_candidate(
          provider = loaded$provider,
          dataset_id = loaded$snapshot$dataset_id,
          prompt = input$question
        )
        current_revision(state)
      }
      set_step("confirm")
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$back_to_data, set_step("data"), ignoreInit = TRUE)
    shiny::observeEvent(input$back_to_ask, set_step("ask"), ignoreInit = TRUE)
    shiny::observeEvent(input$back_to_confirm, set_step("confirm"), ignoreInit = TRUE)
    shiny::observeEvent(input$to_export, set_step("export"), ignoreInit = TRUE)
    shiny::observeEvent(input$back_to_result, set_step("result"), ignoreInit = TRUE)

    run_revision <- function(fields, correction = FALSE, rationale = NULL, provenance = NULL) {
      state <- current_revision()
      snapshot <- if (isTRUE(correction)) state$snapshot else state$pending$snapshot
      can_run <- if (isTRUE(correction)) {
        .can_create_correction(state)
      } else {
        !is.null(state$pending)
      }
      if (!can_run || is.null(snapshot)) {
        confirm_message("Create a new question and confirm its plot choices before execution.")
        return(invisible(NULL))
      }
      spec <- tryCatch(
        .confirmed_spec_from_fields(snapshot$dataset_id, fields),
        error = function(error) {
          confirm_message(conditionMessage(error))
          NULL
        }
      )
      if (is.null(spec)) return(invisible(NULL))
      profile <- validate_bds_profile(
        snapshot,
        spec$fields[setdiff(.plot_spec_fields, c("dataset_id", "scale_mode"))]
      )
      if (profile$blocked) {
        diagnostic <- profile$blocking_diagnostics[[1]]
        confirm_message(paste(diagnostic$code, diagnostic$message, sep = ": "))
        return(invisible(NULL))
      }
      confirm_message(NULL)
      set_step("result")
      tryCatch(
        if (isTRUE(correction)) {
          create_correction(fields, rationale, provenance)
        } else {
          execute_revision(fields)
        },
        error = function(error) {
          set_step("confirm")
          confirm_message(conditionMessage(error))
        }
      )
    }

    execute_current <- function(fields) run_revision(fields)
    correct_current <- function(fields, rationale, provenance) {
      run_revision(
        fields,
        correction = TRUE,
        rationale = rationale,
        provenance = provenance
      )
    }

    mod_specification_server(
      "specification",
      current_revision,
      execute_current,
      correct_current
    )
    mod_run_status_server("run_status", current_revision)
    mod_plot_preview_server("plot_preview", current_revision, execution_status)
    mod_evidence_server("evidence", current_revision)
    mod_revision_history_server("revision_history", current_revision)
    mod_export_server("export", current_revision, workspace_provider)
    mod_review_server("review", current_revision, current_revision)

    shiny::observeEvent(execution_status(), {
      if (identical(execution_status(), "error")) {
        confirm_message("Plot generation failed. Review the run status and try again.")
        set_step("confirm")
      }
    }, ignoreInit = TRUE)

  })
}

.uploaded_study_data_provider <- function(file) {
  if (!checkmate::test_data_frame(file, min.rows = 1L) || nrow(file) != 1L ||
      !checkmate::test_string(file$name[[1]], min.chars = 1L) ||
      !checkmate::test_file_exists(file$datapath[[1]], access = "r")) {
    cli::cli_abort("Choose one readable CSV or Excel file")
  }

  file_name <- basename(file$name[[1]])
  file_type <- tolower(tools::file_ext(file_name))
  sheet_name <- NULL
  data <- if (identical(file_type, "csv")) {
    utils::read.csv(file$datapath[[1]], check.names = FALSE, stringsAsFactors = FALSE)
  } else if (file_type %in% c("xls", "xlsx")) {
    sheets <- readxl::excel_sheets(file$datapath[[1]])
    if (!length(sheets)) cli::cli_abort("The Excel workbook contains no worksheet")
    sheet_name <- sheets[[1]]
    as.data.frame(
      readxl::read_excel(file$datapath[[1]], sheet = sheet_name, .name_repair = "minimal"),
      optional = TRUE
    )
  } else {
    cli::cli_abort("Choose a CSV or Excel file")
  }

  if (!checkmate::test_data_frame(data, min.rows = 1L, min.cols = 1L) ||
      anyNA(names(data)) || any(!nzchar(trimws(names(data)))) || anyDuplicated(names(data))) {
    cli::cli_abort("The selected file must contain records and unique, non-empty column names")
  }
  required <- c("USUBJID", "PARAMCD", "PARAM", "AVISIT", "AVISITN", "AVAL", "AVALU")
  missing <- setdiff(required, names(data))
  if (length(missing)) {
    cli::cli_abort(paste(
      "This file does not match the supported upload format. Upload long-format clinical data",
      "with one row per subject and visit.",
      "Missing columns:", paste0(paste(missing, collapse = ", "), "."),
      "If visits are separate columns (for example, Baseline, Week 4, and Week 8),",
      "reshape them into rows, with visit labels in AVISIT, numeric visit order in AVISITN,",
      "and measurements in AVAL. Include PARAMCD (parameter code), PARAM (name),",
      "and AVALU (unit) as columns too."
    ))
  }
  treatment_variables <- grep("^TRT(A|P|[0-9]+[AP])$", names(data), value = TRUE)
  if (!length(treatment_variables)) {
    cli::cli_abort("The selected worksheet needs a supported planned or actual treatment variable")
  }
  if (!is.numeric(data$AVAL) || !is.numeric(data$AVISITN)) {
    cli::cli_abort("AVAL and AVISITN must be numeric in the selected worksheet")
  }
  if (!any(!is.na(data$PARAMCD) & nzchar(as.character(data$PARAMCD))) ||
      !any(!is.na(data$PARAM) & nzchar(as.character(data$PARAM))) ||
      !any(!is.na(data$AVALU) & nzchar(as.character(data$AVALU))) ||
      !any(!is.na(data$AVISIT) & nzchar(as.character(data$AVISIT)) & is.finite(data$AVISITN)) ||
      !any(vapply(treatment_variables, function(variable) {
        any(!is.na(data[[variable]]) & nzchar(as.character(data[[variable]])))
      }, logical(1)))) {
    cli::cli_abort("The selected worksheet must contain selectable parameters, units, visits, and treatment levels")
  }

  content_hash <- study_data_content_hash(data)
  source_hash <- digest::digest(file = file$datapath[[1]], algo = "sha256")
  snapshot_key <- canonical_hash(list(
    content_hash = content_hash,
    source_file_hash = source_hash
  ))
  source_metadata <- list(
    source = "direct_upload",
    file_name = file_name,
    file_type = file_type,
    sheet_name = sheet_name,
    source_file_hash = source_hash
  )
  dataset_id <- paste0("upload-", substr(snapshot_key, 1L, 16L))
  metadata <- list(
    dataset_id = dataset_id,
    adam_designation = "BDS",
    declared_keys = as.list(c("USUBJID", "PARAMCD", "AVISIT")),
    metadata_version = "uploaded-bds-v1",
    content_hash = content_hash,
    snapshot_id = paste0("snapshot-", substr(snapshot_key, 1L, 16L)),
    permitted_treatment_variables = as.list(treatment_variables)
  )
  structure(
    list(
      manifest = list(scenarios = list(metadata)),
      read_data = \(metadata) data,
      source_metadata = source_metadata
    ),
    class = "study_data_provider"
  )
}

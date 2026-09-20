mod_plot_generation_ui <- function(id) {
  ns <- shiny::NS(id)
  steps <- c("Data", "Ask", "Confirm", "Result")

  tags$div(
    waiter::use_waiter(),
    waiter::use_waitress(),
    tags$style(shiny::HTML("\
      .f001-workbench { position: relative; padding-left: 2.5rem; }
      .f001-steps { display: grid; grid-template-columns: repeat(4, 1fr); gap: .4rem; margin-bottom: 1rem; }
      .f001-stepmark { padding: .45rem; border: 1px solid #c7d1d9; border-radius: .3rem; background: #f7f9fa; text-align: center; color: #52616d; }
      .f001-stepmark.current { border-color: #7492a6; background: #edf4f8; color: #173f59; font-weight: 700; }
      .f001-stepmark.done { color: #245b46; }
      .f001-data-drawer { --drawer-width: min(18rem, calc(100vw - 4rem)); position: absolute; z-index: 10; top: 7.5rem; left: 0; }
      .f001-data-drawer > summary { display: flex; width: 2rem; height: 9rem; padding: .6rem .35rem; align-items: center; justify-content: space-between; border: 1px solid #8fa2b0; border-radius: 0 .4rem .4rem 0; background: white; color: #1c4259; cursor: pointer; list-style: none; writing-mode: vertical-rl; transform: rotate(180deg); }
      .f001-data-drawer > summary::-webkit-details-marker, .f001-panel > summary::-webkit-details-marker { display: none; }
      .f001-data-drawer[open] > summary { position: absolute; top: 0; left: var(--drawer-width); border-radius: .4rem 0 0 .4rem; background: #edf3f6; }
      .f001-drawer-body { display: none; width: var(--drawer-width); min-height: 9rem; padding: 1rem; border: 1px solid #8fa2b0; border-radius: 0 .4rem .4rem 0; background: white; box-shadow: 4px 0 14px #18293616; }
      .f001-data-drawer[open] .f001-drawer-body { display: block; }
      .f001-profile-hash { overflow-wrap: anywhere; }
      .f001-panel { margin-bottom: .75rem; border: 1px solid #c7d1d9; border-radius: .35rem; background: white; }
      .f001-panel > summary { padding: .65rem .8rem; cursor: pointer; font-weight: 650; }
      .f001-panel-body { padding: 0 .8rem .8rem; }
      .f001-caption { margin-top: .75rem; color: #52616d; font-size: .9rem; }
      .f001-page-title { display: flex; align-items: center; justify-content: space-between; gap: .75rem; }
      .f001-review-info { width: 1.5rem; height: 1.5rem; margin-left: .35rem; border: 1px solid #96a8b3; border-radius: 50%; background: white; color: #23485f; }
      .f001-result-content { position: relative; }
      @media (max-width: 575.98px) { .f001-workbench { padding-left: 2.25rem; } .f001-stepmark { padding: .35rem .1rem; font-size: .75rem; } }
    ")),
    tags$div(
      style = "display: none;",
      shiny::textInput(ns("step_signal"), NULL, value = "data")
    ),
    shiny::uiOutput(ns("stepper")),
    tags$details(
      class = "f001-data-drawer",
      tags$summary("Data & profile", `aria-label` = "Open active data and profile"),
      tags$div(class = "f001-drawer-body", shiny::uiOutput(ns("data_profile")))
    ),
    tags$div(
      class = "f001-workbench",
      tags$div(id = ns("wizard-progress"), class = "f001-progress-line"),
      shiny::conditionalPanel(
        sprintf("input['%s'] === 'data'", ns("step_signal")),
        tags$section(
          `aria-labelledby` = ns("data-heading"),
          tags$h2(id = ns("data-heading"), "Start with your data"),
          tags$p("Upload is required before the plot question."),
          tags$details(
            class = "f001-panel",
            open = NA,
            tags$summary("Upload a dataset · Required"),
            tags$div(
              class = "f001-panel-body",
              tags$p("Only synthetic or properly de-identified data may be uploaded. This prototype does not detect or remove identifiers."),
              shiny::selectInput(
                ns("classification"),
                "Data classification",
                choices = c("Select classification" = "", "Synthetic" = "synthetic", "De-identified" = "deidentified"),
                selected = ""
              ),
              shiny::checkboxInput(
                ns("permitted_data"),
                "I confirm this file is permitted for the POC and contains no confidential or directly identifying information.",
                value = FALSE
              ),
              shiny::fileInput(
                ns("data_file"),
                "CSV or Excel file",
                accept = c(".csv", ".xls", ".xlsx"),
                multiple = FALSE
              ),
              tags$p(class = "text-body-secondary", "For Excel workbooks, the first worksheet is used."),
              shiny::actionButton(ns("load_data"), "Validate and load data", class = "btn-primary"),
              shiny::uiOutput(ns("upload_status"))
            )
          ),
          tags$div(class = "d-flex justify-content-end", shiny::uiOutput(ns("continue_data"))),
          tags$p(class = "f001-caption", "Continue becomes available after the selected file passes the supported BDS structure check and the data boundary is confirmed.")
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
                value = "How does mean change from baseline vary by visit and treatment arm?",
                width = "100%",
                rows = 3
              ),
              shiny::uiOutput(ns("question_validation")),
              shiny::actionButton(ns("suggest"), "Suggest plot", class = "btn-outline-primary"),
              shiny::uiOutput(ns("suggestion"))
            )
          ),
          tags$div(
            class = "d-flex justify-content-between",
            shiny::actionButton(ns("back_to_data"), "Back to data", class = "btn-outline-secondary"),
            shiny::actionButton(ns("to_confirm"), "Continue to review choices", class = "btn-primary")
          ),
          tags$p(class = "f001-caption", "Plot suggestion is optional. You can continue and choose the supported plot settings yourself.")
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
            ),
            tags$details(
              class = "f001-panel",
              tags$summary("Traceability, review, and export"),
              tags$div(
                class = "f001-panel-body",
                mod_revision_history_ui(ns("revision_history")),
                mod_review_ui(ns("review")),
                mod_export_ui(ns("export"))
              )
            )
          ),
          tags$div(class = "d-flex justify-content-start", shiny::actionButton(ns("back_to_confirm"), "Back to confirm", class = "btn-outline-secondary")),
          tags$p(class = "f001-caption", "Review decisions are pending until both independent reviewers approve. The exact R script and check evidence remain linked to this revision.")
        )
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
    step_ids <- c("data", "ask", "confirm", "result")
    step_labels <- c("Data", "Ask", "Confirm", "Result")
    active_step <- shiny::reactiveVal("data")
    loaded_file <- shiny::reactiveVal(NULL)
    upload_error <- shiny::reactiveVal(NULL)
    question_attempted <- shiny::reactiveVal(FALSE)
    confirm_message <- shiny::reactiveVal(NULL)

    progress <- waiter::Waitress$new(
      selector = paste0("#", session$ns("wizard-progress")),
      theme = "line",
      min = 0,
      max = length(step_ids)
    )
    progress$start()
    progress$set(1)
    result_waiter <- waiter::Waiter$new(
      id = session$ns("result-body"),
      html = waiter::spin_fading_circles(),
      color = "rgba(255, 255, 255, 0.85)"
    )

    upload_inputs_valid <- function() {
      file <- input$data_file
      is.data.frame(file) && nrow(file) == 1L &&
        all(c("name", "datapath") %in% names(file)) &&
        !is.na(file$name[[1]]) &&
        tolower(tools::file_ext(file$name[[1]])) %in% c("csv", "xls", "xlsx") &&
        (identical(input$classification, "synthetic") ||
          identical(input$classification, "deidentified")) &&
        isTRUE(input$permitted_data)
    }
    question_is_valid <- function() {
      is.character(input$question) && length(input$question) == 1L &&
        !is.na(input$question) && nzchar(trimws(input$question))
    }

    is_current_upload <- shiny::reactive({
      loaded <- loaded_file()
      file <- input$data_file
      !is.null(loaded) && !is.null(file) &&
        identical(loaded$path, file$datapath[[1]]) &&
        identical(loaded$classification, input$classification) &&
        isTRUE(input$permitted_data)
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
          tags$div(class = class, paste(index, "·", step_labels[[index]]))
        })
      )
    })
    output$data_profile <- shiny::renderUI({
      loaded <- loaded_file()
      shiny::validate(
        shiny::need(!is.null(loaded), upload_error() %||% "No permitted file has been validated yet."),
        shiny::need(is_current_upload(), "The file or classification changed. Validate the selected file again."),
        shiny::need(isTRUE(input$permitted_data), "Confirm the permitted-data boundary to view this profile.")
      )
      tags$dl(
        tags$dt("Active data"), tags$dd(loaded$file_name),
        tags$dt("Classification"), tags$dd(loaded$classification_label),
        tags$dt("Data profile"), tags$dd(paste(loaded$rows, "rows ×", loaded$columns, "columns")),
        tags$dt("Supported structure"), tags$dd("Visit-based numeric BDS"),
        tags$dt("Worksheet"), tags$dd(loaded$sheet_name %||% "Not applicable"),
        tags$dt("Source-file hash"), tags$dd(tags$code(class = "f001-profile-hash", loaded$source_file_hash)),
        tags$dt("Content hash"), tags$dd(tags$code(class = "f001-profile-hash", loaded$content_hash))
      )
    })

    output$upload_status <- shiny::renderUI({
      if (!is.null(upload_error())) {
        return(tags$div(class = "alert alert-danger mt-2", role = "alert", upload_error()))
      }
      if (is_current_upload()) {
        return(tags$div(class = "alert alert-success mt-2", role = "status", "Passed: supported BDS structure and permitted-data attestation recorded."))
      }
      if (isTRUE(input$load_data > 0)) {
        file <- input$data_file
        has_one_file <- is.data.frame(file) && nrow(file) == 1L &&
          all(c("name", "datapath") %in% names(file)) && !is.na(file$name[[1]])
        file_type <- if (has_one_file) tolower(tools::file_ext(file$name[[1]])) else ""
        shiny::validate(
          shiny::need(has_one_file, "Choose one CSV or Excel file."),
          shiny::need(file_type %in% c("csv", "xls", "xlsx"), "Choose a CSV or Excel file."),
          shiny::need(
            identical(input$classification, "synthetic") ||
              identical(input$classification, "deidentified"),
            "Choose Synthetic or De-identified."
          ),
          shiny::need(isTRUE(input$permitted_data), "Confirm the permitted-data boundary before loading the file.")
        )
      }
      tags$p(class = "text-body-secondary mt-2", "Choose a file, classify it, confirm the data boundary, then validate it.")
    })

    output$question_validation <- shiny::renderUI({
      if (!question_attempted()) return(NULL)
      shiny::validate(
        shiny::need(question_is_valid(), "Enter a visualization question before continuing.")
      )
      NULL
    })

    output$continue_data <- shiny::renderUI({
      shiny::actionButton(
        session$ns("to_ask"),
        "Continue to ask",
        class = "btn-primary",
        disabled = !is_current_upload()
      )
    })

    output$suggestion <- shiny::renderUI({
      state <- current_revision()
      interpretation <- state$pending$interpretation %||% NULL
      if (is.null(interpretation)) return(NULL)
      if (is.null(interpretation$candidate)) {
        return(tags$p(class = "text-body-secondary mt-2", "No automatic suggestion is available for this question. Continue to choose the supported settings manually."))
      }
      fields <- interpretation$candidate$fields
      tags$div(
        class = "alert alert-info mt-2",
        tags$strong("Suggested starting point: "),
        paste(
          fields$paramcd %||% "parameter to choose",
          fields$y_variable %||% "outcome to choose",
          "by treatment and visit"
        ),
        tags$div(class = "small mt-1", "Review and confirm every choice on the next step.")
      )
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
      progress$set(match(next_step, step_ids))
      progress$notify(
        html = tags$span(paste("Step", match(next_step, step_ids), "of 4 ·", step_labels[[match(next_step, step_ids)]])),
        background_color = "#edf4f8",
        text_color = "#173f59",
        position = "tr"
      )
      invisible(next_step)
    }

    shiny::observeEvent(input$load_data, {
      upload_error(NULL)
      if (!upload_inputs_valid()) return()
      file <- input$data_file
      loaded <- tryCatch(
        {
          provider <- .uploaded_study_data_provider(file, input$classification)
          snapshot <- pin_study_snapshot(provider, provider$manifest$scenarios[[1]]$dataset_id)
          snapshot$source_metadata <- provider$source_metadata
          data <- snapshot$data
          list(
            path = file$datapath[[1]],
            file_name = provider$source_metadata$file_name,
            source_file_hash = provider$source_metadata$source_file_hash,
            classification = input$classification,
            classification_label = if (identical(input$classification, "synthetic")) "Synthetic" else "De-identified",
            sheet_name = provider$source_metadata$sheet_name,
            content_hash = snapshot$content_hash,
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
      shiny::showNotification("File validated for the supported BDS profile.", type = "message")
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$to_ask, {
      if (!is_current_upload()) return()
      set_step("ask")
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$suggest, {
      question_attempted(TRUE)
      if (!question_is_valid()) return()
      loaded <- loaded_file()
      state <- tryCatch(
        .create_assurance_candidate(
          provider = loaded$provider,
          dataset_id = loaded$snapshot$dataset_id,
          prompt = input$question,
          suggest = TRUE
        ),
        error = function(error) {
          shiny::showNotification(conditionMessage(error), type = "error")
          NULL
        }
      )
      if (!is.null(state)) current_revision(state)
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$to_confirm, {
      question_attempted(TRUE)
      if (!question_is_valid()) return()
      state <- current_revision()
      if (is.null(state$pending) || !identical(state$prompt, input$question)) {
        loaded <- loaded_file()
        state <- .create_assurance_candidate(
          provider = loaded$provider,
          dataset_id = loaded$snapshot$dataset_id,
          prompt = input$question,
          suggest = FALSE
        )
        current_revision(state)
      }
      set_step("confirm")
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$back_to_data, set_step("data"), ignoreInit = TRUE)
    shiny::observeEvent(input$back_to_ask, set_step("ask"), ignoreInit = TRUE)
    shiny::observeEvent(input$back_to_confirm, set_step("confirm"), ignoreInit = TRUE)

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
      result_waiter$show()
      set_step("result")
      tryCatch(
        if (isTRUE(correction)) {
          create_correction(fields, rationale, provenance)
        } else {
          execute_revision(fields)
        },
        error = function(error) {
          result_waiter$hide()
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
    mod_plot_preview_server("plot_preview", current_revision)
    mod_evidence_server("evidence", current_revision)
    mod_revision_history_server("revision_history", current_revision)
    mod_export_server("export", current_revision, workspace_provider)
    mod_review_server("review", current_revision, current_revision)

    shiny::observeEvent(execution_status(), {
      if (identical(execution_status(), "error")) {
        result_waiter$hide()
        confirm_message("Plot generation failed. Review the run status and try again.")
        set_step("confirm")
      }
    }, ignoreInit = TRUE)

    shiny::observe({
      state <- current_revision()
      if (identical(execution_status(), "success") &&
          !is.null(state$revision) && is.null(state$pending)) {
        result_waiter$hide()
      }
    })
  })
}

.uploaded_study_data_provider <- function(file, classification) {
  if (!checkmate::test_choice(classification, c("synthetic", "deidentified"))) {
    cli::cli_abort("Select Synthetic or De-identified before loading data")
  }
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
    as.data.frame(readxl::read_excel(file$datapath[[1]], sheet = sheet_name, .name_repair = "minimal"), optional = TRUE)
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
    classification = classification,
    content_hash = content_hash,
    source_file_hash = source_hash
  ))
  source_metadata <- list(
    file_name = file_name,
    file_type = file_type,
    sheet_name = sheet_name,
    source_file_hash = source_hash
  )
  dataset_id <- paste0("upload-", substr(snapshot_key, 1L, 16L))
  metadata <- list(
    dataset_id = dataset_id,
    classification = classification,
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

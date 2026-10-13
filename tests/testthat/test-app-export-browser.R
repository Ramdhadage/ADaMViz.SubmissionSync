local_export_browser_fixture <- function(root = NULL) {
  local_artifact_store <- getFromNamespace(
    "local_artifact_store", "ADaMViz.SubmissionSync"
  )
  sqlite_evidence_repository <- getFromNamespace(
    "sqlite_evidence_repository", "ADaMViz.SubmissionSync"
  )
  local_identity_provider <- getFromNamespace(
    "local_identity_provider", "ADaMViz.SubmissionSync"
  )
  new_actor <- getFromNamespace("new_actor", "ADaMViz.SubmissionSync")
  local_workspace_provider <- getFromNamespace(
    "local_workspace_provider", "ADaMViz.SubmissionSync"
  )
  new_review_service <- getFromNamespace(
    "new_review_service", "ADaMViz.SubmissionSync"
  )
  if (is.null(root)) {
    root <- fs::file_temp("export-browser-fixture-")
    fs::dir_create(root)
    withr::defer(fs::dir_delete(root), envir = parent.frame())
  }
  store <- local_artifact_store(fs::path(root, "artifacts"))
  code <- "plot(1)\n"
  image <- charToRaw("png bytes")
  code_hash <- store$put(charToRaw(code))
  image_hash <- store$put(image)
  repo <- sqlite_evidence_repository(
    fs::path(root, "evidence.sqlite"),
    fs::path(root, "chain-root.json"),
    store
  )
  repo$create_revision(
    "plot-1", "rev-1", 1L, "creator", "spec", code_hash,
    image_hash, "analysis", "create"
  )
  repo$accept_artifact_bundle(
    "bundle-1", "rev-1", code_hash, image_hash, "analysis", "bundle"
  )
  repo$record_attempt("attempt-1", "rev-1", "attempt")
  repo$record_evidence(
    "evidence-1", "rev-1", "execution_verification", "passed", "evidence",
    details = list(attempt_id = "attempt-1")
  )
  repo$complete_attempt("attempt-1", "succeeded", "complete")
  repo$mark_verified("rev-1", 1L, "verify")
  reviewers <- local_identity_provider(list(
    new_actor("sp", "statistical_programmer"),
    new_actor("bio", "biostatistician")
  ))
  review <- new_review_service(repo, reviewers)
  review$approve("rev-1", "sp", 2L, "sp-approval")
  review$approve("rev-1", "bio", 3L, "bio-approval")

  workspace_root <- fs::path(root, "workspace")
  fs::dir_create(workspace_root)
  list(
    repo = repo,
    store = store,
    identities = local_identity_provider(list(
      new_actor("creator", "clinical_scientist"),
      new_actor("viewer", "viewer")
    )),
    workspace = local_workspace_provider(c(controlled = workspace_root))
  )
}

local_export_browser_app <- function() {
  shiny::shinyApp(
    ui = shiny::fluidPage(
      shiny::h1("Controlled Export Browser Harness"),
      shiny::selectInput(
        "actor_id",
        "Actor",
        choices = c("Creator" = "creator", "Viewer" = "viewer")
      ),
      shiny::textInput("destination_id", "Destination", value = "controlled"),
      shiny::numericInput("expected_version", "Version", value = 4, min = 1),
      shiny::actionButton("export", "Export"),
      shiny::verbatimTextOutput("status"),
      shiny::verbatimTextOutput("exported_files"),
      shiny::tableOutput("receipts")
    ),
    server = function(input, output, session) {
      new_export_service <- getFromNamespace(
        "new_export_service", "ADaMViz.SubmissionSync"
      )
      root <- fs::file_temp("export-browser-fixture-")
      fs::dir_create(root)
      session$onSessionEnded(function() {
        if (fs::dir_exists(root)) fs::dir_delete(root)
      })
      fixture <- local_export_browser_fixture(root)
      service <- new_export_service(
        fixture$repo,
        fixture$store,
        fixture$workspace,
        fixture$identities
      )
      status <- shiny::reactiveVal("Ready")
      exported_files <- shiny::reactiveVal("")
      shiny::observeEvent(input$export,
        {
          tryCatch(
            {
              receipt <- service$export_revision(
                "rev-1",
                input$actor_id,
                input$destination_id,
                as.integer(input$expected_version),
                paste("browser-export", input$actor_id, input$destination_id,
                  sep = ":"
                )
              )
              status(paste("Exported", receipt$receipt_id, receipt$revision_id))
              exported_files(paste(
                sort(fs::path_file(fs::dir_ls(receipt$path))),
                collapse = ", "
              ))
            },
            error = function(error) {
              status(conditionMessage(error))
            }
          )
        },
        ignoreInit = TRUE
      )
      output$status <- shiny::renderText(status())
      output$exported_files <- shiny::renderText(exported_files())
      output$receipts <- shiny::renderTable({
        fixture$repo$list_export_receipts("rev-1")
      })
    }
  )
}

test_that("browser export journey publishes an eligible accepted bundle", {
  app <- local_browser_app(
    local_export_browser_app(),
    "controlled-export"
  )
  withr::defer(app$stop(), envir = parent.frame())

  app$click("export")
  app$wait_for_js(
    "document.getElementById('status').textContent.includes('Exported')"
  )
  body <- app$get_text(selector = "body")

  expect_match(body, "Exported receipt-", fixed = TRUE)
  expect_match(body, "plot.png, script.R", fixed = TRUE)
  expect_match(body, "rev-1", fixed = TRUE)
})

test_that("browser export blocks stale tokens and unauthorized actors", {
  app <- local_browser_app(
    local_export_browser_app(),
    "controlled-export-denial"
  )
  withr::defer(app$stop(), envir = parent.frame())

  app$set_inputs(expected_version = 99)
  app$click("export")
  app$wait_for_js(
    "document.getElementById('status').textContent.toLowerCase().includes('stale')"
  )
  expect_match(app$get_text(selector = "body"), "stale", ignore.case = TRUE)

  app$set_inputs(expected_version = 4, actor_id = "viewer")
  app$click("export")
  app$wait_for_js(
    paste0(
      "document.getElementById('status').textContent",
      ".includes('not authorized')"
    )
  )
  expect_match(
    app$get_text(selector = "body"),
    "not authorized",
    fixed = TRUE
  )
  expect_no_match(app$get_text(selector = "body"), "Exported receipt-",
    fixed = TRUE
  )
})

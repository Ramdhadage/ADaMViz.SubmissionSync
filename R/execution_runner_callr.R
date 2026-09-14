.execution_source_root <- function() {
  root <- normalizePath(".", winslash = "/", mustWork = FALSE)
  if (file.exists(file.path(root, "DESCRIPTION"))) root else NULL
}

run_execution_callr <- function(
  request,
  script,
  analysis_data,
  data_classification = "synthetic",
  work_dir = tempfile("execution-callr-"),
  timeout = 60,
  source_root = .execution_source_root()
) {
  if (!requireNamespace("callr", quietly = TRUE)) {
    cli::cli_abort("The callr execution runner requires the {.pkg callr} package")
  }
  checkmate::assert_number(timeout, lower = 1, finite = TRUE)
  worker <- function(
    request,
    script,
    analysis_data,
    data_classification,
    work_dir,
    source_root
  ) {
    if (!is.null(source_root)) {
      devtools::load_all(source_root, quiet = TRUE)
    }
    ADaMViz.SubmissionSync:::run_execution_locally(
      request = request,
      script = script,
      analysis_data = analysis_data,
      data_classification = data_classification,
      work_dir = work_dir
    )
  }
  tryCatch(
    callr::r(
      worker,
      args = list(
        request,
        script,
        analysis_data,
        data_classification,
        work_dir,
        source_root
      ),
      libpath = .libPaths(),
      cmdargs = "--vanilla",
      system_profile = FALSE,
      user_profile = FALSE,
      env = c(
        R_PROFILE_USER = "",
        R_ENVIRON_USER = "",
        ADAMVIZ_SECRET_CANARY = ""
      ),
      timeout = timeout
    ),
    error = function(error) {
      structure(
        list(
          status = "failed",
          manifest_version = "execution-runner-result-v1",
          diagnostics = list(stdout = "", stderr = conditionMessage(error))
        ),
        class = "execution_runner_result"
      )
    }
  )
}

new_callr_execution_runner <- function(timeout = 60, source_root = .execution_source_root()) {
  new_execution_runner(function(request, script, analysis_data, data_classification, work_dir) {
    run_execution_callr(
      request = request,
      script = script,
      analysis_data = analysis_data,
      data_classification = data_classification,
      work_dir = work_dir,
      timeout = timeout,
      source_root = source_root
    )
  })
}

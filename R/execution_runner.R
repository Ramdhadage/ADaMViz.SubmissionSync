.execution_hash_text <- function(value) {
  digest::digest(.execution_text_bytes(value), algo = "sha256", serialize = FALSE)
}

.execution_text_bytes <- function(value) {
  charToRaw(enc2utf8(paste(value, collapse = "\n")))
}

.execution_hash_file <- function(path) {
  digest::digest(file = path, algo = "sha256")
}

.bounded_text <- function(value, limit = 4000L) {
  value <- paste(value, collapse = "\n")
  if (nchar(value, type = "bytes") <= limit) return(value)
  paste0(substr(value, 1L, limit), "\n[truncated]")
}

.execution_environment_details <- function() {
  packages <- c(
    ADaMViz.SubmissionSync = utils::packageVersion("ADaMViz.SubmissionSync"),
    ggplot2 = utils::packageVersion("ggplot2"),
    patchwork = utils::packageVersion("patchwork")
  )
  list(
    version = "execution-environment-details-v1",
    r_version = as.character(getRversion()),
    platform = R.version$platform,
    os = Sys.info()[["sysname"]],
    release = Sys.info()[["release"]],
    packages = lapply(packages, as.character),
    graphics_device = "png",
    image_width = NA_integer_,
    image_height = NA_integer_
  )
}

.execution_environment_fingerprint <- function() {
  canonical_hash(.execution_environment_details())
}

.validate_execution_input <- function(request, script, analysis_data, data_classification) {
  if (!inherits(request, "execution_request")) {
    cli::cli_abort("{.arg request} must be an {.cls execution_request}")
  }
  if (!checkmate::test_string(script, min.chars = 1L)) {
    cli::cli_abort("{.arg script} must be a non-empty R script")
  }
  if (!is.data.frame(analysis_data)) {
    cli::cli_abort("{.arg analysis_data} must be a data frame")
  }
  if (!data_classification %in% c("synthetic", "deidentified")) {
    cli::cli_abort("The local POC runner accepts only synthetic or de-identified data")
  }
  script_hash <- .execution_hash_text(script)
  if (!identical(script_hash, request$script_hash)) {
    cli::cli_abort("Execution script hash does not match the immutable request")
  }
  snapshot_hash <- canonical_hash(analysis_data)
  if (!identical(snapshot_hash, request$snapshot_hash)) {
    cli::cli_abort("Execution data hash does not match the immutable request")
  }
  invisible(TRUE)
}

run_execution_locally <- function(
  request,
  script,
  analysis_data,
  data_classification = "synthetic",
  work_dir = tempfile("execution-run-"),
  image_width = 1200,
  image_height = 840,
  diagnostics_limit = 4000L
) {
  .validate_execution_input(request, script, analysis_data, data_classification)
  checkmate::assert_string(work_dir, min.chars = 1L)
  checkmate::assert_number(image_width, lower = 1, finite = TRUE)
  checkmate::assert_number(image_height, lower = 1, finite = TRUE)
  checkmate::assert_int(diagnostics_limit, lower = 256L)

  fs::dir_create(work_dir, recurse = TRUE)
  env <- new.env(parent = globalenv())
  env$analysis_data <- analysis_data
  script_path <- fs::path(work_dir, "script.R")
  image_path <- fs::path(work_dir, "plot.png")
  writeLines(enc2utf8(script), script_path, useBytes = TRUE)

  stdout <- character()
  result <- tryCatch(
    {
      stdout <- utils::capture.output(
        sys.source(script_path, envir = env, keep.source = FALSE),
        type = "output"
      )
      if (!inherits(env$boxplot_analysis, "boxplot_analysis") ||
          !inherits(env$boxplot_artifact, "boxplot_artifact")) {
        cli::cli_abort("Execution script did not create the governed runtime objects")
      }
      ggplot2::ggsave(
        filename = image_path,
        plot = env$boxplot_artifact$combined,
        device = function(...) grDevices::png(..., type = "cairo"),
        width = image_width / 100,
        height = image_height / 100,
        dpi = 100,
        units = "in"
      )
      if (!fs::file_exists(image_path) || fs::file_size(image_path) <= 0) {
        cli::cli_abort("Execution did not produce a non-empty PNG image")
      }
      list(error = NULL)
    },
    error = function(error) {
      list(error = conditionMessage(error))
    }
  )

  if (!is.null(result$error)) {
    return(structure(
      list(
        status = "failed",
        manifest_version = "execution-runner-result-v1",
        diagnostics = list(
          stdout = .bounded_text(stdout, diagnostics_limit),
          stderr = .bounded_text(result$error, diagnostics_limit)
        )
      ),
      class = "execution_runner_result"
    ))
  }

  analytical_hash <- canonical_hash(env$boxplot_analysis)
  image_hash <- .execution_hash_file(image_path)
  environment <- .execution_environment_details()
  environment$image_width <- image_width
  environment$image_height <- image_height
  environment_fingerprint <- canonical_hash(environment)
  manifest <- new_execution_result(
    request,
    analytical_hash = analytical_hash,
    image_hash = image_hash,
    environment_fingerprint = environment_fingerprint
  )
  structure(
    list(
      status = "succeeded",
      manifest_version = "execution-runner-result-v1",
      result = manifest,
      analytical_output = env$boxplot_analysis,
      image_path = image_path,
      code_hash = request$script_hash,
      environment = environment,
      diagnostics = list(
        stdout = .bounded_text(stdout, diagnostics_limit),
        stderr = ""
      )
    ),
    class = "execution_runner_result"
  )
}

new_execution_runner <- function(run = run_execution_locally) {
  if (!is.function(run)) cli::cli_abort("{.arg run} must be a function")
  structure(list(run = run), class = "execution_runner")
}

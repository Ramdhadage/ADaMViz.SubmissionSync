# Run from the repository root: Rscript dev/check-environment.R [report.json].
check_environment <- function(project = ".", report = NULL) {
  project <- normalizePath(project, winslash = "/", mustWork = TRUE)
  if (!is.null(report) && file.exists(report)) {
    stop("Report already exists; choose a new path: ", report, call. = FALSE)
  }
  for (package in c("renv", "jsonlite")) {
    if (!requireNamespace(package, quietly = TRUE)) {
      stop("Missing package: ", package, ". Open the project with its renv library restored.", call. = FALSE)
    }
  }

  lockfile <- file.path(project, "renv.lock")
  lock <- jsonlite::read_json(lockfile)
  r_version <- as.character(getRversion())
  status_output <- capture.output(
    status <- renv::status(project = project, library = .libPaths())
  )
  installed <- utils::installed.packages(noCache = TRUE)
  installed <- installed[!duplicated(installed[, "Package"]), c("Package", "Version", "LibPath"), drop = FALSE]
  details <- list(
    schema_version = "development-environment-v1",
    recorded_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    expected = list(
      r_version = lock$R$Version,
      packages = lapply(lock$Packages, function(package) package$Version),
      lockfile_md5 = unname(tools::md5sum(lockfile))
    ),
    observed = list(
      r_version = r_version,
      platform = R.version$platform,
      os = Sys.info()[["sysname"]],
      os_release = Sys.info()[["release"]],
      locale = Sys.getlocale(),
      timezone = Sys.timezone(),
      library_paths = .libPaths(),
      packages = as.data.frame(installed, stringsAsFactors = FALSE),
      external_libraries = as.list(extSoftVersion()),
      tool_paths = as.list(Sys.which(c("git", "make", "gcc", "g++", "pandoc", "quarto")))
    ),
    checks = list(
      r_version = identical(r_version, lock$R$Version),
      packages = isTRUE(status$synchronized)
    ),
    package_diagnostics = status_output
  )

  cat("R required:", lock$R$Version, "| running:", r_version, "\n")
  cat(paste(status_output, collapse = "\n"), "\n")
  if (!is.null(report)) {
    jsonlite::write_json(details, report, pretty = TRUE, auto_unbox = TRUE, na = "null", null = "null")
    cat("Report saved:", report, "\n")
  }
  if (!all(unlist(details$checks))) {
    stop("Environment check failed. Resolve the reported mismatches and rerun the check.", call. = FALSE)
  }
  cat("Environment check passed.\n")
  invisible(details)
}

if (sys.nframe() == 0L) {
  arguments <- commandArgs(trailingOnly = TRUE)
  if (length(arguments) > 1L) {
    stop("Usage: Rscript dev/check-environment.R [report.json]", call. = FALSE)
  }
  check_environment(report = if (length(arguments)) arguments[[1L]] else NULL)
}

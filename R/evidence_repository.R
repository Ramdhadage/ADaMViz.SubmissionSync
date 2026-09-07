.utc_timestamp <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC")
}

.validate_identifier <- function(value, name) {
  if (!checkmate::test_string(value, min.chars = 1, pattern = "^[A-Za-z0-9._:-]+$")) {
    cli::cli_abort("{.arg {name}} must be a non-empty stable identifier")
  }
  invisible(value)
}

.validate_evidence_repository <- function(repository, capabilities) {
  available <- is.list(repository) && all(vapply(
    capabilities,
    \(capability) is.function(repository[[capability]]),
    logical(1)
  ))
  if (!available) {
    cli::cli_abort(
      "Evidence repository must implement {.fn {capabilities}}"
    )
  }
  invisible(repository)
}

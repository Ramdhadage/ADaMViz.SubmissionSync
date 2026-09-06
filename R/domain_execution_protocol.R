new_execution_request <- function(spec, script_hash, snapshot_id, snapshot_hash, harness_version) {
  .validate_plot_spec(spec)
  values <- list(script_hash, snapshot_id, snapshot_hash, harness_version)
  if (!all(vapply(values, checkmate::test_string, logical(1), min.chars = 1))) {
    cli::cli_abort("Execution requests require non-empty script, snapshot, and harness identifiers")
  }
  structure(
    list(
      manifest_version = "execution-request-v1",
      spec_hash = spec$hash,
      script_hash = script_hash,
      snapshot_id = snapshot_id,
      snapshot_hash = snapshot_hash,
      harness_version = harness_version
    ),
    class = "execution_request"
  )
}

new_execution_result <- function(request, analytical_hash, image_hash, environment_fingerprint) {
  if (!inherits(request, "execution_request")) {
    cli::cli_abort("{.arg request} must be an {.cls execution_request}")
  }
  values <- list(analytical_hash, image_hash, environment_fingerprint)
  if (!all(vapply(values, checkmate::test_string, logical(1), min.chars = 1))) {
    cli::cli_abort("Execution results require analytical, image, and environment identifiers")
  }
  manifest <- unclass(request)
  manifest$manifest_version <- "execution-result-v1"
  structure(
    c(manifest, list(
      analytical_hash = analytical_hash,
      image_hash = image_hash,
      environment_fingerprint = environment_fingerprint
    )),
    class = "execution_result"
  )
}

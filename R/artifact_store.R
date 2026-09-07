.validate_artifact_hash <- function(hash) {
  if (!checkmate::test_string(hash, pattern = "^[0-9a-f]{64}$")) {
    cli::cli_abort("Artifact hash must be a lowercase SHA-256 value")
  }
  invisible(hash)
}

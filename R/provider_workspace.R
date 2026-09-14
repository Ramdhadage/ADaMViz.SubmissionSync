.validate_workspace_provider <- function(provider) {
  capabilities <- c(
    "list_destinations", "stage_bundle", "publish_staged",
    "inspect_published", "quarantine_staged", "reconcile"
  )
  if (!is.list(provider) || !all(vapply(
    capabilities,
    \(capability) is.function(provider[[capability]]),
    logical(1)
  ))) {
    cli::cli_abort(
      "Workspace provider must implement {.fn {capabilities}}"
    )
  }
  invisible(provider)
}

.validate_workspace_token <- function(value, name = "workspace token") {
  reserved <- c(
    "CON", "PRN", "AUX", "NUL",
    paste0("COM", 1:9), paste0("LPT", 1:9)
  )
  if (!checkmate::test_string(value, min.chars = 1L) ||
      !grepl("^[A-Za-z0-9._-]+$", value) ||
      value %in% c(".", "..") ||
      toupper(tools::file_path_sans_ext(value)) %in% reserved) {
    cli::cli_abort("{.arg {name}} must be a safe logical identifier")
  }
  invisible(value)
}

.workspace_pair_hashes <- function(path) {
  code_path <- fs::path(path, "script.R")
  image_path <- fs::path(path, "plot.png")
  if (!fs::file_exists(code_path) || !fs::file_exists(image_path)) {
    return(NULL)
  }
  list(
    code_hash = digest::digest(file = code_path, algo = "sha256"),
    image_hash = digest::digest(file = image_path, algo = "sha256")
  )
}

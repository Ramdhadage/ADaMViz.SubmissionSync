#' Create the injected runtime configuration provider.
#'
#' Runtime configuration contains provider identifiers and logical references,
#' never secret values. Secret material is resolved only through the injected
#' provider when a domain service explicitly requests it.
#'
#' @param profile Runtime profile: `local`, `test`, or `production`.
#' @param prompt_provider Logical prompt-provider identifier.
#' @param workspace Logical workspace identifier.
#' @param secret_provider Function accepting a secret reference and returning
#'   its value, or `NULL` when unavailable.
#' @param required_secret_references Character vector of required references.
#' @return An object of class `submission_sync_runtime_config`.
#' @export
new_runtime_config <- function(
  profile = Sys.getenv("ADAMVIZ_PROFILE", "local"),
  prompt_provider = Sys.getenv("ADAMVIZ_PROMPT_PROVIDER", "mock"),
  workspace = Sys.getenv("ADAMVIZ_WORKSPACE", "local"),
  secret_provider = NULL,
  required_secret_references = character()
) {
  profile <- match.arg(profile, c("local", "test", "production"))
  if (!is.character(prompt_provider) || length(prompt_provider) != 1L ||
      !nzchar(prompt_provider)) {
    stop("prompt_provider must be one non-empty identifier", call. = FALSE)
  }
  if (!is.character(workspace) || length(workspace) != 1L || !nzchar(workspace)) {
    stop("workspace must be one non-empty identifier", call. = FALSE)
  }
  if (profile != "production" && identical(prompt_provider, "production")) {
    stop("A production provider cannot be selected outside the production profile", call. = FALSE)
  }
  if (!is.null(secret_provider) && !is.function(secret_provider)) {
    stop("secret_provider must be a function or NULL", call. = FALSE)
  }
  if (!is.character(required_secret_references) || anyNA(required_secret_references)) {
    stop("required_secret_references must be character values", call. = FALSE)
  }

  config <- structure(
    list(
      profile = profile,
      prompt_provider = prompt_provider,
      workspace = workspace,
      required_secret_references = unique(required_secret_references),
      secret_provider = secret_provider
    ),
    class = "submission_sync_runtime_config"
  )

  for (reference in config$required_secret_references) {
    if (is.null(config$secret_provider)) {
      stop(sprintf("Secret reference '%s' is not configured", reference), call. = FALSE)
    }
    value <- config$secret_provider(reference)
    if (is.null(value) || length(value) != 1L || !nzchar(value)) {
      stop(sprintf("Secret reference '%s' is not configured", reference), call. = FALSE)
    }
  }

  config
}

#' Resolve one runtime secret through the injected provider.
#'
#' @param runtime_config A `submission_sync_runtime_config` object.
#' @param reference Logical secret reference.
#' @return The resolved secret value.
#' @export
resolve_runtime_secret <- function(runtime_config, reference) {
  if (!inherits(runtime_config, "submission_sync_runtime_config")) {
    stop("runtime_config must be a submission_sync_runtime_config", call. = FALSE)
  }
  if (!is.character(reference) || length(reference) != 1L || !nzchar(reference)) {
    stop("reference must be one non-empty identifier", call. = FALSE)
  }
  if (is.null(runtime_config$secret_provider)) {
    stop(sprintf("Secret reference '%s' is not configured", reference), call. = FALSE)
  }
  value <- runtime_config$secret_provider(reference)
  if (is.null(value) || length(value) != 1L || !nzchar(value)) {
    stop(sprintf("Secret reference '%s' is not configured", reference), call. = FALSE)
  }
  value
}

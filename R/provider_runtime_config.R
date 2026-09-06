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
#' @importFrom cli cli_abort
#' @export
new_runtime_config <- function(
  profile = Sys.getenv("ADAMVIZ_PROFILE", "local"),
  prompt_provider = Sys.getenv("ADAMVIZ_PROMPT_PROVIDER", "mock"),
  workspace = Sys.getenv("ADAMVIZ_WORKSPACE", "local"),
  secret_provider = NULL,
  required_secret_references = character()
) {
  profiles <- c("local", "test", "production")
  if (!checkmate::test_choice(profile, choices = profiles)) {
    cli::cli_abort("{.arg profile} must be one of {.val {profiles}}")
  }
  if (!checkmate::test_string(prompt_provider, min.chars = 1)) {
    cli::cli_abort("{.arg prompt_provider} must be one non-empty identifier")
  }
  if (!checkmate::test_string(workspace, min.chars = 1)) {
    cli::cli_abort("{.arg workspace} must be one non-empty identifier")
  }
  if (profile != "production" && identical(prompt_provider, "production")) {
    cli::cli_abort(c(
      "A production provider cannot be selected outside the production profile",
      "i" = "Use {.val mock} for local and test profiles."
    ))
  }
  if (!checkmate::test_null(secret_provider) &&
      !checkmate::test_function(secret_provider)) {
    cli::cli_abort("{.arg secret_provider} must be a function or {.val NULL}")
  }
  if (!checkmate::test_character(required_secret_references, any.missing = FALSE)) {
    cli::cli_abort("{.arg required_secret_references} must contain character values")
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
      cli::cli_abort("Secret reference {.val {reference}} is not configured")
    }
    value <- config$secret_provider(reference)
    if (is.null(value) || length(value) != 1L || !nzchar(value)) {
      cli::cli_abort("Secret reference {.val {reference}} is not configured")
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
  if (!checkmate::test_class(runtime_config, classes = "submission_sync_runtime_config")) {
    cli::cli_abort("{.arg runtime_config} must be a {.cls submission_sync_runtime_config}")
  }
  if (!checkmate::test_string(reference, min.chars = 1)) {
    cli::cli_abort("{.arg reference} must be one non-empty identifier")
  }
  if (is.null(runtime_config$secret_provider)) {
    cli::cli_abort("Secret reference {.val {reference}} is not configured")
  }
  value <- runtime_config$secret_provider(reference)
  if (is.null(value) || length(value) != 1L || !nzchar(value)) {
    cli::cli_abort("Secret reference {.val {reference}} is not configured")
  }
  value
}

.validate_identity_provider <- function(provider) {
  if (!is.list(provider) || !is.function(provider$get_actor)) {
    cli::cli_abort("Identity provider must implement {.fn get_actor}")
  }
  invisible(provider)
}

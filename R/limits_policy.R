new_limits_policy <- function(max_prompt_chars = 4000L, max_levels = 50L, max_visits = 100L) {
  values <- c(max_prompt_chars, max_levels, max_visits)
  if (!all(vapply(values, checkmate::test_int, logical(1), lower = 1L))) {
    cli::cli_abort("All content limits must be positive integers")
  }
  structure(list(
    version = "limits-v1",
    max_prompt_chars = max_prompt_chars,
    max_levels = max_levels,
    max_visits = max_visits
  ), class = "limits_policy")
}

enforce_limit <- function(value, limit, field) {
  if (nchar(value, type = "chars") > limit) {
    cli::cli_abort("{.field {field}} exceeds its configured limit")
  }
  invisible(value)
}

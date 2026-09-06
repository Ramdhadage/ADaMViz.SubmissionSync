new_prompt_context <- function(dataset_id, labels = list(), aggregate_profile = list()) {
  if (!checkmate::test_string(dataset_id, min.chars = 1) ||
      !checkmate::test_list(labels) || !checkmate::test_list(aggregate_profile)) {
    cli::cli_abort("Prompt context requires an opaque dataset identifier and list inputs")
  }
  blocked <- c("USUBJID", "patient", "secret", "workspace", "path", "url")
  content <- paste(unlist(c(labels, aggregate_profile), use.names = FALSE), collapse = " ")
  if (any(grepl(paste(blocked, collapse = "|"), content, ignore.case = TRUE))) {
    cli::cli_abort("Prompt context contains prohibited content")
  }
  structure(list(
    version = "prompt-context-v1",
    dataset_id = dataset_id,
    labels = labels,
    aggregate_profile = aggregate_profile
  ), class = "prompt_context")
}

.prompt_context_blocked_terms <- c(
  "USUBJID", "patient", "secret", "credential", "workspace", "path", "url",
  "file", "directory", "comment", "diagnostic"
)

new_prompt_context <- function(dataset_id, labels = list(), aggregate_profile = list()) {
  if (!checkmate::test_string(dataset_id, min.chars = 1) ||
      !checkmate::test_list(labels) || !checkmate::test_list(aggregate_profile)) {
    cli::cli_abort("Prompt context requires an opaque dataset identifier and list inputs")
  }
  if (!.assert_prompt_context_content(list(labels = labels, aggregate_profile = aggregate_profile))) {
    cli::cli_abort("Prompt context contains prohibited content")
  }
  payload <- list(
    version = "prompt-context-v1",
    dataset_id = dataset_id,
    labels = labels,
    aggregate_profile = aggregate_profile
  )
  payload$hash <- canonical_hash(payload)
  structure(payload, class = "prompt_context")
}

.assert_prompt_context_content <- function(value) {
  content <- paste(unlist(value, use.names = TRUE), collapse = " ")
  pattern <- paste(c(.prompt_context_blocked_terms, "https?://"), collapse = "|")
  if (grepl(pattern, content, ignore.case = TRUE)) {
    return(FALSE)
  }
  TRUE
}

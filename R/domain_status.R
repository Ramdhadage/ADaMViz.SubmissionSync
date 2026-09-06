.workflow_transitions <- list(
  Draft = c("Verified", "Experimental/Draft"),
  "Experimental/Draft" = character(),
  Verified = c("Reviewed"),
  Reviewed = character(),
  Rejected = character()
)

transition_revision_status <- function(status, next_status) {
  if (!checkmate::test_choice(status, choices = names(.workflow_transitions))) {
    cli::cli_abort("Unknown revision status {.val {status}}")
  }
  if (!checkmate::test_choice(next_status, choices = names(.workflow_transitions))) {
    cli::cli_abort("Unknown next status {.val {next_status}}")
  }
  if (!checkmate::test_choice(next_status, choices = .workflow_transitions[[status]])) {
    cli::cli_abort("Cannot transition from {.val {status}} to {.val {next_status}}")
  }
  next_status
}

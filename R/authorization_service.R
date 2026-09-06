new_actor <- function(id, roles, active = TRUE) {
  if (!checkmate::test_string(id, min.chars = 1) ||
      !checkmate::test_character(roles, min.len = 1L, any.missing = FALSE) ||
      !checkmate::test_flag(active)) {
    cli::cli_abort("An actor requires an identifier, at least one role, and an active flag")
  }
  structure(list(id = id, roles = unique(roles), active = active), class = "submission_sync_actor")
}

authorize_revision_action <- function(actor, revision, action) {
  if (!inherits(actor, "submission_sync_actor") || !inherits(revision, "plot_revision")) {
    cli::cli_abort("Authorization requires an actor and plot revision")
  }
  if (!actor$active) {
    cli::cli_abort("The current actor is not active")
  }
  if (action %in% c("approve", "reject") && identical(actor$id, revision$creator_id)) {
    cli::cli_abort("A revision creator cannot review their own revision")
  }
  if (action == "approve" && !any(actor$roles %in% c("statistical_programmer", "biostatistician"))) {
    cli::cli_abort("The current actor is not eligible to approve a revision")
  }
  invisible(TRUE)
}

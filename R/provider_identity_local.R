local_identity_provider <- function(actors) {
  if (!is.list(actors) || !all(vapply(actors, inherits, logical(1), "submission_sync_actor"))) {
    cli::cli_abort("Local identities must be submission sync actors")
  }
  ids <- vapply(actors, `[[`, character(1), "id")
  if (anyDuplicated(ids)) cli::cli_abort("Local identity identifiers must be unique")

  get_actor <- function(actor_id) {
    if (!checkmate::test_string(actor_id, min.chars = 1)) {
      cli::cli_abort("Actor identifier is required")
    }
    match <- which(ids == actor_id)
    if (!length(match)) cli::cli_abort("Authenticated actor {.val {actor_id}} was not found")
    actors[[match]]
  }
  structure(list(get_actor = get_actor), class = "local_identity_provider")
}

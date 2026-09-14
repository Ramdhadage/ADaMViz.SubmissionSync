new_async_task_service <- function(max_active = 1L) {
  checkmate::assert_int(max_active, lower = 1L)
  tasks <- new.env(parent = emptyenv())

  submit <- function(task_id, fun, ...) {
    .validate_identifier(task_id, "task_id")
    if (!is.function(fun)) cli::cli_abort("{.arg fun} must be a function")
    active <- vapply(
      as.list(tasks),
      \(task) identical(task$status, "running"),
      logical(1)
    )
    if (sum(active) >= max_active) {
      cli::cli_abort("The async execution queue is full")
    }
    if (exists(task_id, envir = tasks, inherits = FALSE)) {
      return(get(task_id, envir = tasks, inherits = FALSE))
    }
    task <- list(status = "running", result = NULL, error = NULL)
    assign(task_id, task, envir = tasks)
    task <- tryCatch(
      list(status = "succeeded", result = fun(...), error = NULL),
      error = function(error) {
        list(status = "failed", result = NULL, error = conditionMessage(error))
      }
    )
    assign(task_id, task, envir = tasks)
    task
  }

  status <- function(task_id) {
    .validate_identifier(task_id, "task_id")
    if (!exists(task_id, envir = tasks, inherits = FALSE)) {
      cli::cli_abort("Async task {.val {task_id}} was not found")
    }
    get(task_id, envir = tasks, inherits = FALSE)
  }

  structure(
    list(submit = submit, status = status),
    class = "async_task_service"
  )
}

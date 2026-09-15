new_async_task_service <- function() {
  source_root <- .execution_source_root()
  shiny::ExtendedTask$new(function(args) {
    function_name <- args$function_name
    call_args <- args$args
    mirai::mirai(
      {
        if (!is.null(source_root)) {
          devtools::load_all(source_root, quiet = TRUE)
        }
        fun <- get(function_name, envir = asNamespace("ADaMViz.SubmissionSync"))
        do.call(fun, call_args)
      },
      function_name = function_name,
      call_args = call_args,
      source_root = source_root
    )
  })
}

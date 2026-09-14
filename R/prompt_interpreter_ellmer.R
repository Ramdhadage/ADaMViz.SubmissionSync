#' Create the disabled ellmer prompt interpreter placeholder
#'
#' The real provider remains unavailable until its retention, training, region,
#' transport, and incident-handling terms are approved for the target use.
#'
#' @param ... Reserved for future provider-specific configuration.
#'
#' @return This function always aborts in the local POC.
#' @export
ellmer_prompt_interpreter <- function(...) {
  cli::cli_abort("The ellmer prompt interpreter is disabled until provider terms are approved")
}

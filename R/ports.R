new_provider_port <- function(name, capabilities) {
  if (!checkmate::test_string(name, min.chars = 1) ||
      !checkmate::test_character(capabilities, min.len = 1L, any.missing = FALSE)) {
    cli::cli_abort("A provider port needs a name and declared capabilities")
  }
  structure(list(name = name, capabilities = unique(capabilities)), class = "provider_port")
}

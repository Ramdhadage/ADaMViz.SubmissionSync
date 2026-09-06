new_plot_revision <- function(plot_id, creator_id, spec, version = 1L) {
  .validate_plot_spec(spec)
  if (!checkmate::test_string(plot_id, min.chars = 1) ||
      !checkmate::test_string(creator_id, min.chars = 1) ||
      !checkmate::test_int(version, lower = 1L)) {
    cli::cli_abort("A revision requires valid plot, creator, and version identifiers")
  }
  status <- if (identical(spec$fields$scale_mode, "free")) "Experimental/Draft" else "Draft"
  structure(
    list(
      revision_id = paste(plot_id, version, sep = "-r"),
      plot_id = plot_id,
      creator_id = creator_id,
      version = version,
      spec_hash = spec$hash,
      status = status
    ),
    class = "plot_revision"
  )
}

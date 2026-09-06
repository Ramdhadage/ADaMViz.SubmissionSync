.synthetic_data_root <- function() {
  installed <- system.file("extdata", "synthetic", package = "ADaMViz.SubmissionSync")
  if (nzchar(installed)) {
    return(installed)
  }
  candidates <- c(
    file.path("inst", "extdata", "synthetic"),
    file.path("..", "..", "inst", "extdata", "synthetic")
  )
  existing <- candidates[dir.exists(candidates)]
  if (length(existing)) normalizePath(existing[[1]], winslash = "/") else candidates[[1]]
}

#' Create the governed local study-data provider
#'
#' @param root Directory containing `scenario-manifest.json` and its pinned RDS
#'   snapshots. The default resolves package installation data and then the
#'   source-tree location.
#'
#' @return A local `study_data_provider`.
#' @export
local_study_data_provider <- function(root = .synthetic_data_root()) {
  if (!checkmate::test_directory_exists(root, access = "r")) {
    cli::cli_abort("The local synthetic study-data directory is unavailable")
  }
  manifest_path <- file.path(root, "scenario-manifest.json")
  if (!checkmate::test_file_exists(manifest_path, access = "r")) {
    cli::cli_abort("The governed synthetic scenario manifest is unavailable")
  }
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
  .validate_synthetic_manifest(manifest)

  structure(
    list(
      port = new_provider_port("study_data", c("list_catalog", "read_snapshot")),
      manifest = manifest,
      read_data = function(metadata) {
        file_name <- metadata$file
        if (!checkmate::test_string(file_name, pattern = "^adlb-[a-z0-9-]+\\.rds$")) {
          cli::cli_abort("The synthetic manifest contains an invalid snapshot file name")
        }
        readRDS(file.path(root, file_name))
      }
    ),
    class = "study_data_provider"
  )
}

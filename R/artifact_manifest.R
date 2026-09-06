#' Create the pre-execution boxplot artifact manifest
#'
#' Binds the exact specification, script, analytical result, and expected-result
#' contract. Runtime and image hashes remain unset until controlled execution.
#'
#' @param spec A confirmed `plot_spec`.
#' @param script The exact compiled R script.
#' @param analysis A `boxplot_analysis` object.
#' @param expected_contract A list containing the expected-result `version`,
#'   `fixture_hash`, and `review_status`.
#'
#' @return A `boxplot_artifact_manifest`.
#' @export
new_artifact_manifest <- function(
  spec,
  script,
  analysis,
  expected_contract
) {
  .validate_plot_spec(spec)
  required_contract_fields <- c("version", "fixture_hash", "review_status")
  if (!identical(spec$state, "confirmed") ||
      !checkmate::test_string(script, min.chars = 1L) ||
      !inherits(analysis, "boxplot_analysis") ||
      !is.list(expected_contract) ||
      !setequal(names(expected_contract), required_contract_fields) ||
      !all(vapply(expected_contract, checkmate::test_string, logical(1), min.chars = 1L))) {
    cli::cli_abort("The artifact manifest requires confirmed, complete U4 inputs")
  }
  structure(
    list(
      manifest_version = "boxplot-artifact-manifest-v1",
      status = .initial_revision_status(spec$fields$scale_mode),
      spec_hash = spec$hash,
      script_hash = canonical_hash(script),
      analytical_hash = canonical_hash(analysis),
      expected_contract_version = expected_contract$version,
      expected_contract_review_status = expected_contract$review_status,
      expected_contract_hash = canonical_hash(expected_contract),
      image_hash = NULL,
      runtime_artifact_hash = NULL
    ),
    class = "boxplot_artifact_manifest"
  )
}

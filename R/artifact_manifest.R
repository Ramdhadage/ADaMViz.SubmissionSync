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

  authentic_spec_hash <- canonical_hash(list(
    fields = spec$fields,
    provenance = spec$provenance
  ))
  if (!identical(spec$hash, authentic_spec_hash)) {
    cli::cli_abort("The confirmed plot specification hash does not match its contents")
  }

  analytical_metadata <- list(
    treatment_variable = spec$fields$treatment_variable,
    y_variable = spec$fields$y_variable,
    facet_levels = spec$fields$treatment_levels,
    visit_levels = spec$fields$visits
  )
  analytical_mismatch <- vapply(
    names(analytical_metadata),
    function(field) !identical(analysis[[field]], analytical_metadata[[field]]),
    logical(1)
  )
  if (any(analytical_mismatch)) {
    cli::cli_abort(
      "The analytical result does not match the confirmed specification for {.field {names(analytical_metadata)[analytical_mismatch]}}"
    )
  }

  expected_script <- compile_boxplot_script(spec, analysis$low_n_policy)
  if (!identical(script, expected_script)) {
    cli::cli_abort("The compiled script does not match the confirmed specification and analytical policy")
  }

  structure(
    list(
      manifest_version = "boxplot-artifact-manifest-v1",
      status = .initial_revision_status(spec$fields$scale_mode),
      spec_hash = spec$hash,
      script_hash = .execution_hash_text(script),
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

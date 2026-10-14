test_source_root <- function() {
  .execution_source_root()
}

test_subprocess_libpaths <- function() {
  # covr's instrumented package library can sit outside .libPaths().
  package_path <- getNamespaceInfo(
    asNamespace("ADaMViz.SubmissionSync"), "path"
  )
  unique(c(dirname(package_path), .libPaths()))
}

execution_spec <- function() {
  new_plot_spec(
    dataset_id = "fixture-adlb",
    paramcd = "ALT",
    y_variable = "AVAL",
    unit = "U/L",
    treatment_variable = "TRT01A",
    treatment_levels = c("Active", "Placebo"),
    visits = c("Baseline", "Week 4", "Week 8"),
    scale_mode = "fixed",
    provenance = stats::setNames(rep("user_confirmed", 8L), .plot_spec_fields),
    state = "confirmed"
  )
}

execution_fixture <- function() {
  profile <- validate_bds_profile(
    make_test_snapshot(), # nolint: object_usage_linter.
    default_profile_selections() # nolint: object_usage_linter.
  )
  spec <- execution_spec()
  script <- compile_boxplot_script(spec, profile$low_n_policy)
  request <- new_execution_request(
    spec = spec,
    script_hash = .execution_hash_text(script),
    snapshot_id = profile$snapshot_id,
    snapshot_hash = canonical_hash(profile$analysis_data),
    harness_version = "execution-harness-v1"
  )
  list(
    spec = spec,
    profile = profile,
    script = script,
    request = request
  )
}

skip_if_no_cairo_device <- function() {
  path <- tempfile(fileext = ".png")
  available <- tryCatch(
    {
      ggplot2::ggsave(
        filename = path,
        plot = ggplot2::ggplot() +
          ggplot2::theme_void(),
        device = function(...) grDevices::png(..., type = "cairo"),
        width = 1,
        height = 1,
        dpi = 72,
        units = "in"
      )
      TRUE
    },
    error = function(error) FALSE,
    finally = {
      if (grDevices::dev.cur() > 1L) grDevices::dev.off()
    }
  )
  testthat::skip_if_not(
    available,
    "graphics device is unavailable in this R environment"
  )
}

fake_success_runner_result <- function(fixture) {
  env <- new.env(parent = globalenv())
  env$analysis_data <- fixture$profile$analysis_data
  connection <- textConnection(fixture$script)
  withr::defer(close(connection), envir = parent.frame())
  source(connection, local = env, keep.source = FALSE)
  image_path <- tempfile(fileext = ".png")
  withr::defer(unlink(image_path), envir = parent.frame())
  writeBin(charToRaw("png bytes"), image_path)
  result <- new_execution_result(
    fixture$request,
    analytical_hash = canonical_hash(env$boxplot_analysis),
    image_hash = .execution_hash_file(image_path),
    environment_fingerprint =
      .environment_fingerprint() # nolint: object_usage_linter.
  )
  structure(
    list(
      status = "succeeded",
      manifest_version = "execution-runner-result-v1",
      result = result,
      analytical_output = env$boxplot_analysis,
      image_path = image_path,
      code_hash = fixture$request$script_hash,
      environment = .execution_environment_details(),
      diagnostics = list(stdout = "", stderr = "")
    ),
    class = "execution_runner_result"
  )
}
utils::globalVariables(c(
  "make_test_snapshot",
  "default_profile_selections",
  "x",
  "y"
))

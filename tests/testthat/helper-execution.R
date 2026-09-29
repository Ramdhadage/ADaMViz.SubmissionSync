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
    make_test_snapshot(),
    default_profile_selections()
  )
  spec <- execution_spec()
  script <- compile_boxplot_script(spec, profile$low_n_policy)
  request <- new_execution_request(
    spec = spec,
    script_hash = .execution_hash_text(script),
    snapshot_id = profile$snapshot_id,
    snapshot_hash = canonical_hash(profile$selected_data),
    harness_version = "execution-harness-v1"
  )
  list(
    spec = spec,
    profile = profile,
    script = script,
    request = request
  )
}

skip_if_graphics_device_unavailable <- function() {
  path <- tempfile(fileext = ".png")
  available <- tryCatch(
    {
      ggplot2::ggsave(
        filename = path,
        plot = ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y)) +
          ggplot2::geom_point(),
        device = grDevices::png,
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
  skip_if_not(available, "graphics device is unavailable in this R environment")
}

fake_successful_runner_result <- function(fixture, image_hash = paste(rep("a", 64L), collapse = "")) {
  env <- new.env(parent = globalenv())
  env$analysis_data <- fixture$profile$selected_data
  connection <- textConnection(fixture$script)
  withr::defer(close(connection), envir = parent.frame())
  source(connection, local = env, keep.source = FALSE)
  result <- new_execution_result(
    fixture$request,
    analytical_hash = canonical_hash(env$boxplot_analysis),
    image_hash = image_hash,
    environment_fingerprint = .execution_environment_fingerprint()
  )
  structure(
    list(
      status = "succeeded",
      manifest_version = "execution-runner-result-v1",
      result = result,
      analytical_output = env$boxplot_analysis,
      image_path = tempfile(fileext = ".png"),
      code_hash = fixture$request$script_hash,
      environment = .execution_environment_details(),
      diagnostics = list(stdout = "", stderr = "")
    ),
    class = "execution_runner_result"
  )
}

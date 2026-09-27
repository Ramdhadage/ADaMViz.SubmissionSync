test_that("plot preview exposes the exact compiled script", {
  profile <- validate_bds_profile(make_test_snapshot(), default_profile_selections())
  spec <- execution_spec()
  script <- compile_boxplot_script(spec, profile$low_n_policy)
  analysis <- calculate_boxplot_statistics(
    profile$display_data,
    treatment_variable = spec$fields$treatment_variable,
    y_variable = spec$fields$y_variable,
    facet_levels = profile$facet_levels,
    visit_levels = profile$visit_levels,
    low_n_policy = profile$low_n_policy
  )
  artifact <- assemble_boxplot(analysis, spec$fields$scale_mode, spec$fields$unit)
  current_revision <- shiny::reactiveVal(list(
    spec = spec,
    profile = profile,
    script = script,
    artifact = artifact
  ))

  shiny::testServer(
    mod_plot_preview_server,
    args = list(current_revision = current_revision),
    {
      expect_match(output$code, "calculate_boxplot_statistics", fixed = TRUE)
      expect_match(output$code, "assemble_boxplot", fixed = TRUE)
    }
  )
})

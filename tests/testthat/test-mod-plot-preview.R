test_that("plot preview exposes the exact compiled script", {
  profile <- validate_bds_profile(
    make_test_snapshot(),
    default_profile_selections()
  )
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
  artifact <- assemble_boxplot(
    analysis, spec$fields$scale_mode,
    spec$fields$unit
  )
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

test_that("governed preview uses accepted image and code artifacts", {
  root <- withr::local_tempdir()
  store <- local_artifact_store(fs::path(root, "artifacts"))
  accepted_script <- "accepted script\n"
  code_hash <- store$put(charToRaw(accepted_script))
  image_hash <- store$put(charToRaw("accepted png bytes"))
  current_revision <- shiny::reactiveVal(list(
    repository = list(artifact_store = store),
    revision = list(
      status = "Verified",
      code_hash = code_hash,
      image_hash = image_hash
    ),
    script = "different script",
    profile = list(),
    spec = execution_spec()
  ))

  shiny::testServer(
    mod_plot_preview_server,
    args = list(current_revision = current_revision),
    {
      expect_match(
        paste(as.character(output$plot), collapse = " "),
        "accepted_plot",
        fixed = TRUE
      )
      expect_identical(output$code, trimws(accepted_script))
      expect_match(
        output$accepted_plot$src,
        "^data:image/png;base64,"
      )
    }
  )
})

confirmed_boxplot_spec <- function(scale_mode = "fixed", visits = c("Baseline", "Week 4", "Week 8")) {
  new_plot_spec(
    dataset_id = "fixture-adlb",
    paramcd = "ALT",
    y_variable = "AVAL",
    unit = "U/L",
    treatment_variable = "TRT01A",
    treatment_levels = c("Active", "Placebo"),
    visits = visits,
    scale_mode = scale_mode,
    provenance = stats::setNames(rep("user_confirmed", 8L), .plot_spec_fields),
    state = "confirmed"
  )
}

expected_boxplot_contract <- function() {
  fixture <- utils::read.csv(
    testthat::test_path("fixtures", "expected-boxplot-statistics.csv"),
    stringsAsFactors = FALSE,
    strip.white = TRUE
  )
  list(
    version = "expected-boxplot-statistics-v1",
    fixture_hash = canonical_hash(fixture),
    review_status = unique(fixture$review_status)
  )
}

test_that("compiler emits stable parseable governed code", {
  spec <- confirmed_boxplot_spec()
  policy <- governed_low_n_policy()
  first <- compile_boxplot_script(spec, policy)
  second <- compile_boxplot_script(spec, policy)

  expect_identical(first, second)
  expect_no_error(parse(text = first))
  expect_false(grepl("eval\\s*\\(|parse\\s*\\(|install\\.packages|setwd\\s*\\(|[A-Za-z]:[/\\\\]", first))
  expect_match(first, "ADaMViz.SubmissionSync::calculate_boxplot_statistics", fixed = TRUE)
  expect_match(first, "ADaMViz.SubmissionSync::assemble_boxplot", fixed = TRUE)
})

test_that("compiled script reproduces the independent analytical result", {
  spec <- confirmed_boxplot_spec()
  profile <- validate_bds_profile(make_test_snapshot(), default_profile_selections())
  policy <- profile$low_n_policy
  expected_boxes <- data.frame(
    treatment = rep(c("Active", "Placebo"), each = 3L),
    visit = rep(c("Baseline", "Week 4", "Week 8"), 2L),
    visit_n = rep(c(0, 4, 8), 2L),
    n = c(3L, 1L, 3L, 3L, 3L, 3L),
    ymin = c(26, 29, 32, 20, 24, 26),
    lower = c(27, 29, 33, 21, 24.5, 27),
    middle = c(28, 29, 34, 22, 25, 28),
    upper = c(29, 29, 35, 23, 26, 29),
    ymax = c(30, 29, 36, 24, 27, 30),
    low_n = rep(TRUE, 6L),
    stringsAsFactors = FALSE
  )
  script <- compile_boxplot_script(spec, policy)
  environment <- new.env(parent = globalenv())
  environment$analysis_data <- profile$selected_data
  connection <- textConnection(script)
  withr::defer(close(connection))
  source(connection, local = environment)

  expect_identical(environment$boxplot_analysis$boxes, expected_boxes)
  expect_identical(nrow(environment$boxplot_analysis$outliers), 0L)
  expect_identical(environment$boxplot_analysis$low_n_policy, policy)
  expect_identical(
    environment$boxplot_artifact$analysis,
    environment$boxplot_analysis
  )
})

test_that("artifact manifest binds only U4 reproducibility evidence", {
  spec <- confirmed_boxplot_spec("free")
  profile <- validate_bds_profile(make_test_snapshot(), default_profile_selections())
  analysis <- calculate_boxplot_statistics(
    profile$selected_data,
    spec$fields$treatment_variable,
    spec$fields$y_variable,
    profile$facet_levels,
    profile$visit_levels,
    profile$low_n_policy
  )
  script <- compile_boxplot_script(spec, profile$low_n_policy)
  expected_contract <- expected_boxplot_contract()
  manifest <- new_artifact_manifest(spec, script, analysis, expected_contract)

  expect_identical(manifest$manifest_version, "boxplot-artifact-manifest-v1")
  expect_identical(manifest$status, "Experimental/Draft")
  expect_identical(manifest$spec_hash, spec$hash)
  expect_identical(manifest$script_hash, .execution_hash_text(script))
  expect_identical(manifest$analytical_hash, canonical_hash(analysis))
  expect_identical(manifest$expected_contract_hash, canonical_hash(expected_contract))
  expect_identical(manifest$expected_contract_review_status, "pending_human_review")
  expect_null(manifest$image_hash)
  expect_null(manifest$runtime_artifact_hash)
})

test_that("artifact manifest rejects inconsistent U4 inputs", {
  spec <- confirmed_boxplot_spec()
  profile <- validate_bds_profile(make_test_snapshot(), default_profile_selections())
  analysis <- calculate_boxplot_statistics(
    profile$selected_data,
    spec$fields$treatment_variable,
    spec$fields$y_variable,
    profile$facet_levels,
    profile$visit_levels,
    profile$low_n_policy
  )
  script <- compile_boxplot_script(spec, profile$low_n_policy)
  expected_contract <- expected_boxplot_contract()

  tampered_spec <- spec
  tampered_spec$hash <- paste0("tampered-", spec$hash)
  expect_error(
    new_artifact_manifest(tampered_spec, script, analysis, expected_contract),
    "specification hash does not match"
  )

  expect_error(
    new_artifact_manifest(spec, paste0(script, "# tampered\n"), analysis, expected_contract),
    "compiled script does not match"
  )

  tampered_analysis <- analysis
  tampered_analysis$y_variable <- "CHG"
  expect_error(
    new_artifact_manifest(spec, script, tampered_analysis, expected_contract),
    "analytical result does not match"
  )
})

test_that("compiler retains the exact approved low-N threshold", {
  policy <- governed_low_n_policy()
  policy$value <- 4.5
  script <- compile_boxplot_script(confirmed_boxplot_spec(), policy)

  expect_match(script, "value = 4.5", fixed = TRUE)
})

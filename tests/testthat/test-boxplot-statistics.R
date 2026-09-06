read_expected_boxplot_statistics <- function() {
  expected <- utils::read.csv(
    testthat::test_path("fixtures", "expected-boxplot-statistics.csv"),
    stringsAsFactors = FALSE,
    strip.white = TRUE
  )
  expected$value_list <- strsplit(expected$values, ";", fixed = TRUE) |>
    lapply(as.numeric)
  expected
}

make_oracle_input <- function(expected) {
  rows <- lapply(seq_len(nrow(expected)), function(index) {
    values <- expected$value_list[[index]]
    data.frame(
      USUBJID = sprintf("SUBJ-%s-%02d", expected$scenario[[index]], seq_along(values)),
      AVISIT = expected$scenario[[index]],
      AVISITN = index,
      TRT01A = "Active",
      AVAL = values,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

test_that("independent fixtures match explicit type-7 box statistics", {
  expected <- read_expected_boxplot_statistics()
  analysis <- calculate_boxplot_statistics(
    make_oracle_input(expected),
    treatment_variable = "TRT01A",
    y_variable = "AVAL",
    facet_levels = "Active",
    visit_levels = expected$scenario,
    low_n_policy = governed_low_n_policy()
  )

  observed <- analysis$boxes
  expect_equal(observed$n, expected$n)
  expect_equal(observed$lower, expected$q1)
  expect_equal(observed$middle, expected$median)
  expect_equal(observed$upper, expected$q3)
  expect_equal(observed$ymin, expected$lower_whisker)
  expect_equal(observed$ymax, expected$upper_whisker)
  expect_identical(observed$low_n, expected$low_n)

  observed_outliers <- split(analysis$outliers$value, analysis$outliers$visit)
  expected_outliers <- stats::setNames(
    lapply(as.character(expected$outliers), function(value) {
      if (is.na(value) || !nzchar(value)) numeric() else as.numeric(strsplit(value, ";", fixed = TRUE)[[1]])
    }),
    expected$scenario
  )
  expect_identical(observed_outliers[names(expected_outliers)[lengths(expected_outliers) > 0L]],
                   expected_outliers[lengths(expected_outliers) > 0L])
})

test_that("missing values and empty combinations create no analytical rows", {
  data <- synthetic_bds_fixture()
  data$AVAL[data$TRT01A == "Active" & data$AVISIT == "Week 4"] <- NA_real_
  profile <- validate_bds_profile(make_test_snapshot(data), default_profile_selections())
  analysis <- calculate_boxplot_statistics(
    profile$selected_data,
    "TRT01A",
    "AVAL",
    profile$facet_levels,
    profile$visit_levels,
    profile$low_n_policy
  )

  expect_false(any(analysis$boxes$treatment == "Active" & analysis$boxes$visit == "Week 4"))
  expect_false(any(analysis$medians$treatment == "Active" & analysis$medians$visit == "Week 4"))
  expect_false(any(analysis$n_strip$treatment == "Active" & analysis$n_strip$visit == "Week 4"))
  expect_identical(
    as.character(analysis$medians$visit[analysis$medians$treatment == "Active"]),
    c("Baseline", "Week 8")
  )
})

test_that("row order does not change the analytical object or hash", {
  data <- synthetic_bds_fixture()
  arguments <- list(
    treatment_variable = "TRT01A",
    y_variable = "CHG",
    facet_levels = c("Active", "Placebo"),
    visit_levels = c("Baseline", "Week 4", "Week 8"),
    low_n_policy = governed_low_n_policy()
  )
  first <- do.call(calculate_boxplot_statistics, c(list(data = data), arguments))
  second <- do.call(
    calculate_boxplot_statistics,
    c(list(data = data[rev(seq_len(nrow(data))), ]), arguments)
  )

  expect_identical(first, second)
  expect_identical(canonical_hash(first), canonical_hash(second))
})

test_that("treatment and visit values cannot collide as grouping keys", {
  separator <- intToUtf8(31L)
  data <- data.frame(
    USUBJID = c("SUBJ-01", "SUBJ-02"),
    AVISIT = c(paste0("B", separator, "C"), "C"),
    AVISITN = c(1, 2),
    TRT01A = c("A", paste0("A", separator, "B")),
    AVAL = c(1, 9),
    stringsAsFactors = FALSE
  )

  analysis <- calculate_boxplot_statistics(
    data,
    treatment_variable = "TRT01A",
    y_variable = "AVAL",
    facet_levels = c("A", paste0("A", separator, "B")),
    visit_levels = c(paste0("B", separator, "C"), "C"),
    low_n_policy = governed_low_n_policy()
  )

  expect_equal(nrow(analysis$boxes), 2L)
  expect_identical(analysis$boxes$treatment, c("A", paste0("A", separator, "B")))
  expect_identical(analysis$boxes$visit, c(paste0("B", separator, "C"), "C"))
  expect_identical(analysis$boxes$middle, c(1, 9))
})

test_that("selected non-finite Y values are rejected", {
  data <- synthetic_bds_fixture()
  data$AVAL[[1]] <- Inf

  expect_error(
    calculate_boxplot_statistics(
      data,
      treatment_variable = "TRT01A",
      y_variable = "AVAL",
      facet_levels = c("Active", "Placebo"),
      visit_levels = c("Baseline", "Week 4", "Week 8"),
      low_n_policy = governed_low_n_policy()
    ),
    "selected Y variable must contain only finite values"
  )
})

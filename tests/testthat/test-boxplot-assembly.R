test_that("plot layers use the oracle and the N strip remains aligned", {
  data <- synthetic_bds_fixture()
  visits <- c("Baseline", "Week 4", "Week 8")
  analysis <- calculate_boxplot_statistics(
    data,
    "TRT01A",
    "AVAL",
    c("Active", "Placebo"),
    visits,
    governed_low_n_policy()
  )
  artifact <- assemble_boxplot(analysis, scale_mode = "fixed", unit = "U/L")
  built <- ggplot2::ggplot_build(artifact$plot)

  expect_s3_class(artifact$plot, "ggplot")
  expect_s3_class(artifact$n_strip, "ggplot")
  expect_s3_class(artifact$combined, "patchwork")
  expect_equal(built$data[[1]]$lower, analysis$boxes$lower)
  expect_equal(built$data[[1]]$middle, analysis$boxes$middle)
  expect_equal(built$data[[1]]$upper, analysis$boxes$upper)
  expect_equal(built$data[[1]]$ymin, analysis$boxes$ymin)
  expect_equal(built$data[[1]]$ymax, analysis$boxes$ymax)
  expect_identical(levels(artifact$plot_data$boxes$visit), visits)
  expect_identical(levels(artifact$plot_data$n_strip$visit), visits)
  expect_match(artifact$plot_data$n_strip$label[artifact$plot_data$n_strip$low_n], "Low N")
})

test_that("free scales change status but not analytical values", {
  data <- synthetic_bds_fixture()
  analysis <- calculate_boxplot_statistics(
    data,
    "TRT01A",
    "PCHG",
    c("Active", "Placebo"),
    c("Baseline", "Week 4", "Week 8"),
    governed_low_n_policy()
  )
  fixed <- assemble_boxplot(analysis, "fixed", "%")
  free <- assemble_boxplot(analysis, "free", "%")

  expect_identical(fixed$analysis, free$analysis)
  expect_identical(fixed$status, "Draft")
  expect_identical(free$status, "Experimental/Draft")
  expect_match(free$warning, "cross-facet")
})

test_that("long visit labels render at the governed export dimensions", {
  data <- synthetic_bds_fixture()
  data$AVISIT <- paste0(data$AVISIT, " - Extended analysis visit label")
  visits <- unique(data[c("AVISIT", "AVISITN")])
  visits <- visits$AVISIT[order(visits$AVISITN)]
  analysis <- calculate_boxplot_statistics(
    data,
    "TRT01A",
    "AVAL",
    c("Active", "Placebo"),
    visits,
    governed_low_n_policy()
  )
  artifact <- assemble_boxplot(analysis, "fixed", "U/L")
  image_path <- withr::local_tempfile(fileext = ".png")

  ggplot2::ggsave(
    image_path,
    artifact$combined,
    device = grDevices::png,
    width = 10,
    height = 7,
    units = "in",
    dpi = 120
  )

  expect_gt(file.info(image_path)$size, 0)
  expect_identical(levels(artifact$plot_data$n_strip$visit), visits)
})

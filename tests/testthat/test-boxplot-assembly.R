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
  n_strip_built <- ggplot2::ggplot_build(artifact$n_strip)
  main_panels <- built$layout$layout[c("PANEL", "treatment")]
  n_strip_panels <- n_strip_built$layout$layout[c("PANEL", "treatment")]
  expected_n_strip <- artifact$plot_data$n_strip
  expected_panels <- match(expected_n_strip$treatment, analysis$facet_levels)
  expected_x <- match(expected_n_strip$visit, analysis$visit_levels)

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
  expect_identical(main_panels, n_strip_panels)
  expect_equal(n_strip_built$data[[1]]$label, expected_n_strip$label)
  expect_equal(as.integer(n_strip_built$data[[1]]$x), expected_x)
  expect_equal(as.integer(n_strip_built$data[[1]]$PANEL), expected_panels)
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
  fixed_built <- ggplot2::ggplot_build(fixed$plot)
  free_built <- ggplot2::ggplot_build(free$plot)
  fixed_y_ranges <- lapply(fixed_built$layout$panel_params, function(panel) panel$y.range)
  free_y_ranges <- lapply(free_built$layout$panel_params, function(panel) panel$y.range)

  expect_identical(fixed$analysis, free$analysis)
  expect_identical(fixed$status, "Draft")
  expect_identical(free$status, "Experimental/Draft")
  expect_match(free$warning, "cross-facet")
  expect_length(fixed_built$layout$panel_scales_y, 1L)
  expect_length(free_built$layout$panel_scales_y, length(analysis$facet_levels))
  expect_identical(fixed_y_ranges[[1]], fixed_y_ranges[[2]])
  expect_false(identical(free_y_ranges[[1]], free_y_ranges[[2]]))
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
  plot_built <- ggplot2::ggplot_build(artifact$plot)
  n_strip_built <- ggplot2::ggplot_build(artifact$n_strip)
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
  expect_identical(
    plot_built$layout$layout[c("PANEL", "treatment")],
    n_strip_built$layout$layout[c("PANEL", "treatment")]
  )
  expect_true(all(vapply(
    plot_built$layout$panel_params,
    function(panel) identical(panel$x$get_labels(), visits),
    logical(1)
  )))
  expect_true(all(vapply(
    n_strip_built$layout$panel_params,
    function(panel) identical(panel$x$get_labels(), visits),
    logical(1)
  )))

  connection <- file(image_path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = 16L)
  dimensions <- readBin(connection, what = integer(), n = 2L, size = 4L, endian = "big")
  expect_identical(dimensions, c(1200L, 840L))
})

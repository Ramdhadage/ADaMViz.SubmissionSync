# Run from the repository root: Rscript dev/test-environment.R.
source("dev/check-environment.R")

testthat::test_that("matching R and packages pass without changing the lockfile", {
  project <- withr::local_tempdir()
  library <- file.path(project, "library")
  dir.create(library)
  stopifnot(requireNamespace("renv", quietly = TRUE))
  stopifnot(requireNamespace("waldo", quietly = TRUE))
  stopifnot(file.copy(find.package(c("jsonlite", "renv")), library, recursive = TRUE))
  withr::local_libpaths(c(library, .Library), action = "replace")
  dir.create(file.path(project, "renv"))
  writeLines('{"snapshot.type":"explicit"}', file.path(project, "renv", "settings.json"))
  lockfile <- file.path(project, "renv.lock")
  jsonlite::write_json(
    list(
      R = list(Version = as.character(getRversion())),
      Packages = list(
        jsonlite = list(
          Package = "jsonlite", Version = as.character(utils::packageVersion("jsonlite")),
          Source = "Repository", Repository = "CRAN"
        ),
        renv = list(
          Package = "renv", Version = as.character(utils::packageVersion("renv")),
          Source = "Repository", Repository = "CRAN"
        )
      )
    ),
    lockfile, auto_unbox = TRUE
  )
  writeLines(
    c("Package: environmentfixture", "Version: 0.0.0", "Imports: jsonlite"),
    file.path(project, "DESCRIPTION")
  )
  before <- tools::md5sum(lockfile)
  result <- NULL
  testthat::expect_output(result <- check_environment(project), "Environment check passed")
  testthat::expect_true(result$checks$r_version)
  testthat::expect_true(result$checks$packages)
  testthat::expect_identical(tools::md5sum(lockfile), before)

  report <- file.path(project, "environment.json")
  testthat::expect_output(check_environment(project, report), "Environment check passed")
  saved <- jsonlite::read_json(report)
  testthat::expect_identical(saved$expected$r_version, as.character(getRversion()))
  testthat::expect_true(saved$checks$packages)
  testthat::expect_error(check_environment(project, report), "already exists")

  lock <- jsonlite::read_json(lockfile)
  lock$R$Version <- "0.0.0"
  jsonlite::write_json(lock, lockfile, auto_unbox = TRUE)
  failed_report <- file.path(project, "failed.json")
  testthat::expect_error(check_environment(project, failed_report), "Environment check failed")
  failed <- jsonlite::read_json(failed_report)
  testthat::expect_false(failed$checks$r_version)

  lock$R$Version <- as.character(getRversion())
  lock$Packages$jsonlite$Version <- "0.0.0"
  jsonlite::write_json(lock, lockfile, auto_unbox = TRUE)
  testthat::expect_error(check_environment(project), "Environment check failed")

  lock$Packages$jsonlite$Version <- as.character(utils::packageVersion("jsonlite"))
  lock$Packages$environmentfixturemissing <- list(
    Package = "environmentfixturemissing", Version = "0.0.0", Source = "Repository", Repository = "CRAN"
  )
  writeLines(
    c("Package: environmentfixture", "Version: 0.0.0", "Imports: jsonlite, environmentfixturemissing"),
    file.path(project, "DESCRIPTION")
  )
  jsonlite::write_json(lock, lockfile, auto_unbox = TRUE)
  testthat::expect_error(check_environment(project), "Environment check failed")
})

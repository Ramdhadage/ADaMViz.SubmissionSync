# Run from the repository root with Rscript --vanilla dev/check-ci-workflows.R.
# Exercise the actual embedded gates with controlled scanner outputs, without installs.
workflow_block <- function(file, step, key = "run") {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  selected <- which(startsWith(lines, paste0("      - name: ", step)))
  stopifnot(length(selected) == 1L)
  following <- which(grepl("^      - (name:|uses:)", lines) & seq_along(lines) > selected)
  last <- if (length(following)) min(following) - 1L else length(lines)
  block <- lines[seq.int(selected, last)]
  start <- which(block == paste0("        ", key, ": |"))
  if (!length(start)) start <- which(block == paste0("          ", key, ": |"))
  stopifnot(length(start) == 1L)
  indent <- if (key == "script") 12L else 10L
  body <- block[seq.int(start + 1L, length(block))]
  end <- which(nzchar(body) & !startsWith(body, strrep(" ", indent)))
  if (length(end)) body <- head(body, min(end) - 1L)
  paste(substring(body, indent + 1L), collapse = "\n")
}

scenario_count <- 0L
fixture <- function(label, code, bindings = list(), setup = function() NULL,
                    error = NULL, inspect = function() NULL) {
  previous <- getwd()
  directory <- tempfile("ci-gate-")
  dir.create(directory)
  on.exit(
    {
      setwd(previous)
      unlink(directory, recursive = TRUE)
    },
    add = TRUE
  )
  setwd(directory)
  setup()
  actual <- tryCatch(
    {
      eval(parse(text = code), list2env(bindings, parent = globalenv()))
      NULL
    },
    error = identity
  )
  if (is.null(error)) {
    if (inherits(actual, "error")) stop(label, ": ", conditionMessage(actual))
  } else {
    if (!inherits(actual, "error")) stop(label, ": expected error containing ", error, "; gate passed")
    if (!grepl(error, conditionMessage(actual), fixed = TRUE)) {
      stop(label, ": expected error containing ", error, "; observed: ", conditionMessage(actual))
    }
  }
  inspect()
  scenario_count <<- scenario_count + 1L
  cat("PASS:", label, "\n")
}

root <- getwd()
audit_file <- file.path(root, ".github/workflows/audit.yaml")
for (step in c("Run oysteR scan on dependencies", "Run oysteR scan on renv.lock")) {
  audit <- workflow_block(audit_file, step)
  audit <- gsub("oysteR::audit_description", "scan", audit, fixed = TRUE)
  audit <- gsub("oysteR::audit_renv_lock", "scan", audit, fixed = TRUE)
  audit_setup <- function() writeLines("{}", "renv.lock")
  for (allowed in c("false", "true")) {
    Sys.setenv(ALLOW_FINDINGS = allowed)
    fixture(paste(step, "scanner error", allowed), audit,
      list(scan = function(...) stop("scanner unavailable")), audit_setup,
      error = "scanner unavailable"
    )
    fixture(paste(step, "finding", allowed), audit,
      list(scan = function(...) data.frame(no_of_vulnerabilities = 1L)), audit_setup,
      error = if (allowed == "false") "Vulnerabilities found" else NULL
    )
  }
  fixture(
    paste(step, "clean"), audit,
    list(scan = function(...) data.frame(no_of_vulnerabilities = 0L)), audit_setup
  )
  fixture(paste(step, "incomplete"), audit,
    list(scan = function(...) data.frame(no_of_vulnerabilities = NA_integer_)),
    audit_setup,
    error = "incomplete vulnerability results"
  )
}
Sys.unsetenv("ALLOW_FINDINGS")

coverage <- workflow_block(file.path(root, ".github/workflows/test-coverage.yaml"), "Run coverage")
coverage <- gsub("${{ inputs.additional-env-vars }}", "", coverage, fixed = TRUE)
for (fun in c("package_coverage", "percent_coverage", "report", "to_cobertura")) {
  coverage <- gsub(paste0("covr::", fun), fun, coverage, fixed = TRUE)
}
coverage_bindings <- list(
  package_coverage = function(...) "instrumented coverage",
  percent_coverage = function(...) 90,
  report = function(x, file, ...) writeLines("<html>coverage</html>", file),
  to_cobertura = function(x, filename) writeLines("<coverage/>", filename)
)
broken <- coverage_bindings
broken$package_coverage <- function(...) stop("coverage worker failed")
fixture("coverage error suppresses all reports", coverage, broken,
  error = "coverage worker failed", inspect = function() {
    stopifnot(!any(file.exists(c("coverage.txt", "coverage.xml", "coverage-report.html"))))
  }
)
fixture("coverage emits three nonempty reports", coverage, coverage_bindings)
broken <- coverage_bindings
broken$report <- function(...) NULL
fixture("coverage missing HTML fails", coverage, broken, error = "all(file.exists(reports))")
broken <- coverage_bindings
broken$percent_coverage <- function(...) NA_real_
fixture("coverage invalid percentage fails", coverage, broken, error = "is.finite(p)")

licenses <- workflow_block(file.path(root, ".github/workflows/licenses.yaml"), "Generate license report")
licenses <- gsub("jsonlite::toJSON", "to_json", licenses, fixed = TRUE)
license_setup <- function() writeLines(c("Package: fixture", "Imports: fixtureA"), "DESCRIPTION")
metadata <- matrix(
  c(
    "fixtureA", "1.0", "MIT", NA, "fixtureB", NA,
    "fixtureB", "1.0", "BSD_3_clause", NA, NA, NA
  ),
  nrow = 2L, byrow = TRUE,
  dimnames = list(
    c("fixtureA", "fixtureB"),
    c("Package", "Version", "License", "Depends", "Imports", "LinkingTo")
  )
)
license_bindings <- list(
  installed.packages = function(...) metadata,
  to_json = function(...) "[]"
)
fixture("licenses allowed dependency closure emits reports", licenses, license_bindings, license_setup,
  inspect = function() {
    report <- utils::read.csv("license-report.csv")
    stopifnot(setequal(report$Package, c("fixtureA", "fixtureB")))
  }
)
broken <- license_bindings
broken$installed.packages <- function(...) {
  bad <- metadata
  bad["fixtureB", "License"] <- "AGPL (>= 3)"
  bad
}
fixture("licenses disallowed transitive dependency fails", licenses, broken, license_setup,
  error = "AGPL dependency licenses"
)
broken <- license_bindings
broken$installed.packages <- function(...) metadata["fixtureA", , drop = FALSE]
fixture("licenses missing transitive metadata fails", licenses, broken, license_setup,
  error = "License metadata unavailable"
)
broken <- license_bindings
broken$to_json <- function(...) stop("jsonlite unavailable")
fixture("licenses serializer failure propagates", licenses, broken, license_setup,
  error = "jsonlite unavailable"
)
bootstrap <- workflow_block(file.path(root, ".github/workflows/licenses.yaml"), "Restore scanner dependencies")
bootstrap <- gsub("renv::restore", "restore", bootstrap, fixed = TRUE)
fixture("licenses missing jsonlite fails bootstrap", bootstrap,
  list(restore = function(...) NULL, requireNamespace = function(...) FALSE),
  error = 'requireNamespace("jsonlite", quietly = TRUE)'
)

check <- workflow_block(
  file.path(root, ".github/workflows/build-check-install.yaml"),
  "Catch warnings in R CMD check output"
)
check <- gsub("${{ env.PKGNAME }}", "fixture", check, fixed = TRUE)
check <- gsub("${{ inputs.enforce-note-blocklist }}", "true", check, fixed = TRUE)
check <- gsub("${{ inputs.note-blocklist }}", "checking possible problems .* NOTE", check, fixed = TRUE)
failed_check <- gsub("${{ steps.r-cmd-check.outcome }}", "failure", check, fixed = TRUE)
check <- gsub("${{ steps.r-cmd-check.outcome }}", "success", check, fixed = TRUE)
fixture("early nonzero R CMD exit fails without log", failed_check,
  error = "R CMD check exited unsuccessfully"
)
fixture("successful exit without requested log fails", check,
  error = "did not produce 00check.log"
)
log_setup <- function(lines) {
  function() {
    dir.create("fixture.Rcheck")
    writeLines(lines, "fixture.Rcheck/00check.log")
  }
}
fixture("R CMD warning fails", check,
  setup = log_setup("Status: 1 WARNING"),
  error = "R CMD check has warnings"
)
fixture("R CMD blocked note fails", check,
  setup = log_setup(c("checking possible problems ... NOTE", "Status: 1 NOTE")),
  error = "NOTEs on the blocklist"
)
fixture("clean R CMD log passes", check, setup = log_setup("Status: OK"))

pkgdown <- workflow_block(file.path(root, ".github/workflows/pkgdown.yaml"), "Check documentation version")
pkgdown_setup <- function(heading) {
  function() {
    writeLines(c("Package: fixture", "Version: 1.2.3.9001"), "DESCRIPTION")
    writeLines(heading, "NEWS.md")
  }
}
pkgdown_bindings <- list(Sys.getenv = function(...) "github-output")
fixture("pkgdown matching version emits publication version", pkgdown, pkgdown_bindings,
  setup = pkgdown_setup("# fixture 1.2.3.9001"), inspect = function() {
    stopifnot(identical(readLines("github-output"), "version=1.2.3.9001"))
  }
)
fixture("pkgdown stale NEWS fails", pkgdown, pkgdown_bindings,
  setup = pkgdown_setup("# fixture 1.2.3.9000"), error = "NEWS version does not match DESCRIPTION"
)
fixture("pkgdown missing NEWS heading fails", pkgdown, pkgdown_bindings,
  setup = pkgdown_setup("No version heading"), error = "NEWS version does not match DESCRIPTION"
)
fixture("pkgdown missing NEWS fails", pkgdown, pkgdown_bindings,
  setup = function() writeLines(c("Package: fixture", "Version: 1.2.3.9001"), "DESCRIPTION"),
  error = "cannot open the connection"
)

# Python remains the authoritative implementation for NEWS; execute when available.
python <- unname(Sys.which("python"))
if (!nzchar(python)) python <- unname(Sys.which("python3"))
if (nzchar(python)) {
  emoji <- workflow_block(file.path(root, ".github/workflows/version.yaml"), "Check for emojis in NEWS.md")
  for (has_emoji in c(FALSE, TRUE)) {
    directory <- tempfile("news-gate-")
    dir.create(directory)
    previous <- getwd()
    setwd(directory)
    writeLines(emoji, "check.py")
    writeLines(c(if (has_emoji) "Early emoji \U0001F600" else "Plain NEWS", "Last line has no emoji"),
      "NEWS.md",
      useBytes = TRUE
    )
    status <- system2(python, "check.py")
    setwd(previous)
    unlink(directory, recursive = TRUE)
    stopifnot(identical(status, if (has_emoji) 1L else 0L))
  }
} else {
  cat("UNVERIFIED: NEWS Python behavior (Python unavailable).\n")
}
cat(scenario_count, "controlled scanner/gate scenarios passed.\n")
cat("Scanner fixtures prove propagation and policy; live analyzers and hosted publishers require CI.\n")

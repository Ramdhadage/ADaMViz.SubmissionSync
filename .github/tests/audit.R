# Run from the repository root: Rscript --vanilla .github/tests/audit.R [audit-artifact-dir]
workflow <- readLines(".github/workflows/audit.yaml", encoding = "UTF-8")
read_step <- function(name) {
  start <- grep(paste0("- name: ", name), workflow, fixed = TRUE)
  stopifnot(length(start) == 1L)
  lines <- workflow[seq.int(start + 1L, length(workflow))]
  run <- which(trimws(lines) == "run: |")[1L]
  shell <- which(trimws(lines) == "shell: Rscript {0}")[1L]
  paste(sub("^          ", "", lines[seq.int(run + 1L, shell - 1L)]), collapse = "\n")
}

reviewed <- c("CVE-2026-18924", "CVE-2026-3783", "CVE-2026-86410", "CVE-2026-87865",
              "CVE-2026-86414", "CVE-2026-87864")
fixture <- data.frame(
  package = "curl", version = "8.1.0", oss_package = "pkg:cran/curl@8.1.0",
  no_of_vulnerabilities = 6L
)
fixture$vulnerabilities <- list(lapply(reviewed, function(id) list(id = id)))
checks <- 0L
expect_result <- function(code, env, succeeds, label) {
  result <- tryCatch(
    {
      invisible(capture.output(suppressMessages(eval(parse(text = code), env))))
      TRUE
    },
    error = function(e) FALSE
  )
  if (!identical(result, succeeds)) stop(label, call. = FALSE)
  checks <<- checks + 1L
}

for (name in c("Run oysteR scan on dependencies", "Run oysteR scan on renv.lock")) {
  code <- read_step(name)
  code <- gsub("oysteR::audit_description", "get_scan", code, fixed = TRUE)
  code <- gsub("oysteR::audit_renv_lock", "get_scan", code, fixed = TRUE)
  run_scan <- function(scan, verified = "true", allow = "false", succeeds, label) {
    env <- new.env(parent = baseenv())
    env$get_scan <- function(...) scan
    env$file.exists <- function(...) TRUE
    env$saveRDS <- function(object, ...) env$saved <- object
    env$Sys.getenv <- function(x) {
      if (x == "ALLOW_FINDINGS") allow else if (x == "CURL_NOBLE_REVIEWED") verified else ""
    }
    expect_result(code, env, succeeds, paste(name, label))
    stopifnot(identical(env$saved, scan))
  }
  run_scan(fixture, succeeds = TRUE, label = "must accept reviewed Noble findings")
  run_scan(fixture, verified = "", succeeds = FALSE, label = "must require runtime verification")
  changed <- fixture
  changed$vulnerabilities[[1L]][[7L]] <- list(id = "CVE-2099-00001")
  changed$no_of_vulnerabilities <- 7L
  run_scan(changed, succeeds = FALSE, label = "must block new CVEs")
  changed$vulnerabilities[[1L]][[7L]] <- list()
  run_scan(changed, succeeds = FALSE, label = "must block missing CVE IDs")
  changed$no_of_vulnerabilities <- 6L
  run_scan(changed, succeeds = FALSE, label = "must block inconsistent vulnerability counts")
  changed <- fixture
  changed$oss_package <- "pkg:cran/other@8.1.0"
  run_scan(changed, succeeds = FALSE, label = "must block other packages")
  changed$oss_package <- "pkg:cran/curl@8.2.0"
  run_scan(changed, succeeds = FALSE, label = "must block unreviewed versions")
  changed <- fixture
  changed$no_of_vulnerabilities <- NA_integer_
  run_scan(changed, succeeds = FALSE, label = "must block incomplete results")
  run_scan(changed, allow = "true", succeeds = FALSE, label = "allow-failure must not hide scanner errors")
  run_scan(fixture[FALSE, ], succeeds = FALSE, label = "must block empty results")
  run_scan(fixture, verified = "", allow = "true", succeeds = TRUE, label = "must preserve explicit allow-failure")
  changed <- fixture
  changed$no_of_vulnerabilities <- 0L
  changed$vulnerabilities[[1L]] <- list()
  run_scan(changed, succeeds = TRUE, label = "must accept clean results")
  artifact_dir <- commandArgs(trailingOnly = TRUE)
  if (length(artifact_dir)) {
    artifact <- if (grepl("renv.lock", name, fixed = TRUE)) "audit-renv-lock.rds" else "audit-description.rds"
    run_scan(readRDS(file.path(artifact_dir[[1L]], artifact)),
      succeeds = TRUE,
      label = "must accept the actual reviewed audit artifact"
    )
  }
}

code <- gsub("curl::curl_version", "get_curl_version",
  read_step("Report linked libcurl and system package versions"),
  fixed = TRUE
)
run_runtime <- function(os = c("ID=ubuntu", "VERSION_CODENAME=noble"),
                        version = "8.5.0", ssh = "libssh/0.10.6/openssl/zlib",
                        linkage = "libcurl.so.4 => /usr/lib/libcurl.so.4 (0x123)",
                        owner = "libcurl4t64:amd64: /usr/lib/libcurl.so.4",
                        package_version = "8.5.0-2ubuntu10.16", succeeds, label) {
  marker <- tempfile()
  on.exit(unlink(marker))
  env <- new.env(parent = baseenv())
  env$packageVersion <- function(...) "8.1.0"
  env$get_curl_version <- function() list(version = version, libssh_version = ssh)
  env$getLoadedDLLs <- function() list(curl = list(path = "/R/curl.so"))
  env$readLines <- function(...) os
  env$normalizePath <- function(path, ...) path
  env$Sys.getenv <- function(...) marker
  env$system2 <- function(command, args, ...) {
    if (command == "ldd") {
      return(linkage)
    }
    if (identical(args[[1L]], "-S")) {
      return(owner)
    }
    if (identical(args[[1L]], "-W")) {
      return(package_version)
    }
    if (identical(args[[1L]], "--compare-versions")) {
      stopifnot(identical(args[[4L]], "8.5.0-2ubuntu10.16"))
      return(if (package_version %in% c("8.5.0-2ubuntu10.14", "8.5.0-2ubuntu10.15")) 1L else 0L)
    }
    stop("Unexpected command")
  }
  expect_result(code, env, succeeds, label)
  stopifnot(identical(file.exists(marker), succeeds))
  if (succeeds) stopifnot("CURL_NOBLE_REVIEWED=true" %in% readLines(marker))
}
run_runtime(succeeds = TRUE, label = "verified runtime must enable the exception")
run_runtime(os = c("ID=ubuntu", "VERSION_CODENAME=jammy"), succeeds = FALSE, label = "must require Noble")
run_runtime(os = c("ID=debian", "VERSION_CODENAME=noble"), succeeds = FALSE, label = "must require Ubuntu")
run_runtime(version = "8.6.0", succeeds = FALSE, label = "must require reviewed libcurl version")
run_runtime(ssh = "libssh2/1.11.0", succeeds = FALSE, label = "must reject libssh2")
run_runtime(ssh = character(), succeeds = FALSE, label = "must require a reported SSH backend")
run_runtime(linkage = "statically linked", succeeds = FALSE, label = "must reject static linkage")
run_runtime(owner = "custom-libcurl: /usr/lib/libcurl.so.4", succeeds = FALSE, label = "must require Ubuntu library ownership")
run_runtime(package_version = "8.5.0-2ubuntu10.14", succeeds = FALSE, label = "must reject unpatched library")
run_runtime(package_version = "8.5.0-2ubuntu10.15", succeeds = FALSE, label = "must reject library missing proxy and IMAP fixes")
run_runtime(package_version = "9.0.0-custom", succeeds = FALSE, label = "must reject non-Noble package versions")
cat(checks, "audit workflow checks passed\n")

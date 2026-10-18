# Verification and CI

Repository-wide authorization remains in [AGENTS.md](../../AGENTS.md). Implementation rules are in [R/AGENTS.md](../../R/AGENTS.md); test design and test layers are in [tests/AGENTS.md](../../tests/AGENTS.md).

## Completion gate

Before reporting a change complete, run the full local sequence below on the final changes and inspect its actual results. Add the checks required by the changed scope. Instructions in Markdown guide agent behavior; they do not install a terminal hook or execute commands by themselves.

| Changed scope | Required verification before claiming completion |
| --- | --- |
| R implementation, package metadata, or tests | Focused tests for changed behavior, then the full local sequence below |
| Documentation or guidance only | Full local sequence, local links, applicable documentation lint, and syntax checks for changed code examples |
| CI workflows | Full local sequence, the existing workflow fixture checks below, applicable workflow lint, and hosted CI when claiming CI success |
| UI or browser behavior | Full local sequence plus Chrome DevTools MCP verification of affected UI/browser flows; package checks alone do not prove browser behavior |

Run local R and Git commands in the existing **VS Code integrated terminal** at the repository root with the project's `renv` environment. Do not open RStudio or additional terminal windows. If the agent cannot access that terminal or run a required check, provide the exact commands and report **verification pending**. Do not substitute a different execution surface without the user's authorization. Browser interaction uses Chrome DevTools MCP as described below.

Do not say a check passed because it was configured, a command was suggested, an earlier revision passed, or another check succeeded. Report commands executed, their results, and failed/skipped/unavailable checks. After fixing a failure or changing relevant files, rerun the affected checks before claiming success.

Before any commit, run the full local sequence even for documentation changes. Lint findings, spelling findings, test failures, and package-check warnings/errors block verification. Report the results and ask for explicit commit approval only after the sequence passes. Requested manual-testing handoffs remain pending until the user supplies results.

## UI and browser verification

- Use Chrome DevTools MCP to inspect the running app and exercise the affected user flows before claiming UI/browser behavior verified. Use `ce-test-browser` for the browser-testing workflow, with Chrome DevTools MCP as the interaction tool.
- Inspect rendered states and relevant browser console/network errors; verify the affected interactions and responsive layouts where applicable. Use synthetic or permitted test data and preserve existing browser state unrelated to the task.
- Report the tested URL/environment, revision when known, interactions exercised, observed results, and relevant snapshots/screenshots. Confirm the running app contains the changed revision; deployed behavior does not verify unpublished local edits.
- If the app or MCP connection is unavailable, report browser verification pending. Static inspection, package tests, and skipped `shinytest2` tests do not substitute for observed browser behavior; retain any explicitly requested manual-testing handoff.

## Full local verification

Run this in the existing VS Code PowerShell terminal from the repository root. The executable path below is the R installation available in this checkout's environment; use the configured project R executable if its location changes. Normal startup loads the project `renv` environment; do not use `--vanilla` for package verification.

```powershell
@'
styler::style_pkg()
roxygen2::roxygenise()
findings <- spelling::spell_check_package()
print(findings)
stopifnot(nrow(findings) == 0L)
lints <- lintr::lint_package()
print(lints)
stopifnot(length(lints) == 0L)
testthat::test_local(reporter = "summary")
devtools::check(error_on = "warning")
'@ | & 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' -
if ($LASTEXITCODE -ne 0) { throw "Local package verification failed" }
git diff --check
if ($LASTEXITCODE -ne 0) { throw "Whitespace verification failed" }
```

- Formatting: `styler::style_pkg()` modifies files. CI uses `styler::style_file()` on changed R/source-document files and can auto-update eligible PRs. Review formatter changes.
- Documentation generation: `roxygen2::roxygenise()` can change `DESCRIPTION`, `NAMESPACE`, and `man/`. Review generated changes; the separate Roxygen CI job also rejects generation warnings/errors.
- Lint: the package is `lintr`, not `linter`. Printing findings alone does not fail an automated command; the sequence asserts zero findings.
- Tests: `testthat::test_local(reporter = "summary")` matches the core CI job; `devtools::test()` remains the development alternative. Report skipped browser tests separately.
- Package check: the pre-commit command is `devtools::check(error_on = "warning")`. Core CI uses `rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "warning")`; these are different invocations.
- Spelling dictionary: use `spelling::update_wordlist()` for legitimate project terms, review `inst/WORDLIST`, and rerun the spelling check. Fix actual misspellings rather than adding them to the dictionary. Updating the dictionary is not verification.

The sequence covers local R checks; it does not reproduce every hosted CI job.

## Additional CI checks

Additional checks used by the reusable CI workflows:

- CRAN/non-CRAN builds: [build-check-install.yaml](../../.github/workflows/build-check-install.yaml) runs `R CMD build`, `R CMD check`, and `R CMD INSTALL` on the built package. The CRAN call adds `--as-cran`, `TESTING_DEPTH=5`, `_R_CHECK_CRAN_INCOMING_REMOTE_=false`, and `_R_CHECK_EXAMPLE_TIMING_THRESHOLD_=6`; the non-CRAN call sets `NOT_CRAN=true` and the same timing threshold. Both reject errors, warnings, missing check logs, and the NOTE patterns listed in [check.yaml](../../.github/workflows/check.yaml). A local `devtools::check()` pass does not prove these container jobs pass. R CMD check supplies R code analysis; no separate static type-check command is configured.
- Spelling check: `findings <- spelling::spell_check_package(); print(findings); stopifnot(nrow(findings) == 0L)` is a local preflight; rerun it after updating the word list. [spelling.yaml](../../.github/workflows/spelling.yaml) additionally uses the spellcheck action with `inst/extdata/*` excluded and updates/checks `inst/WORDLIST` on pushes.
- URLs: [links.yaml](../../.github/workflows/links.yaml) runs the following R check, including one retry, and fails on remaining findings:

  ```r
  bad_urls <- urlchecker::url_check(".", parallel = FALSE, fail = FALSE)
  if (nrow(bad_urls) > 0L) {
    Sys.sleep(5)
    bad_urls <- urlchecker::url_check(".", parallel = FALSE, fail = FALSE)
  }
  print(bad_urls)
  stopifnot(nrow(bad_urls) == 0L)
  ```

- Coverage: `covr::package_coverage(clean = FALSE, quiet = FALSE)`; [test-coverage.yaml](../../.github/workflows/test-coverage.yaml) also requires a finite percentage in `[0, 100]`, nonempty HTML/XML/text reports, and successful report publication. Its 80% reporting threshold has `fail: false`; it is not a minimum-coverage gate.
- Other hosted checks: [audit.yaml](../../.github/workflows/audit.yaml) audits `DESCRIPTION` and `renv.lock` with oysteR under the configured Ubuntu security policy; [gitleaks.yaml](../../.github/workflows/gitleaks.yaml) scans secrets; [licenses.yaml](../../.github/workflows/licenses.yaml) requires complete dependency-license metadata and rejects AGPL licenses pending review; [version.yaml](../../.github/workflows/version.yaml) checks NEWS/DESCRIPTION version consistency and rejects NEWS emojis; [linter.yaml](../../.github/workflows/linter.yaml) checks Bash, Dockerfiles, Markdown, and YAML with SuperLinter. These checks are not covered by the local R sequence.
- When changing CI workflows, also run `Rscript --vanilla dev/check-ci-workflows.R` and `Rscript --vanilla .github/tests/audit.R` in the terminal. These existing fixture checks test workflow failure propagation/policy; they do not run live scanners or hosted publishers and are not themselves jobs in `check.yaml`.

Full CI verification means **Required CI results** succeeds in [Package CI](../../.github/workflows/check.yaml) for the revision being reviewed. It requires `check`, `audit`, `r-cmd`, `r-cmd-non-cran`, `coverage`, `linter`, `roxygen`, `gitleaks`, `spelling`, `links`, `version`, `licenses`, and `style` to succeed.

Main pushes additionally require `vbump` and `generated-check`; the latter records and rechecks the final generated revision, including an unchanged `DESCRIPTION`/`NAMESPACE`/`man/` after roxygen. Lychee, Covtracer, and PII scanning are intentionally inactive in this configuration. Documentation publication and app deployment are downstream main-push jobs, not checks required by this aggregate. There is no single local `make check` equivalent, and this workflow does not establish branch-protection settings or formal validation.

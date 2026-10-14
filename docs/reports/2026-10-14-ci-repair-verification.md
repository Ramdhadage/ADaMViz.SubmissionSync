# CI repair implementation and verification

Date: 2026-10-14 (Asia/Calcutta).

Plan: [Repair CI failures and skips](../plans/2026-10-14-1537-fix-ci-skips-and-failures-plan.md).
Checkout: `.worktrees/ci-workflow-repair`; branch: `docs/ci-workflow-repair-plan`.

Implementation is local and uncommitted. Three implementation agents used disjoint
file ownership; a fourth agent independently reviewed the integrated changes.
No remaining concrete review finding was reported. Hosted verification is pending.

## Changes

- U1/U2: restore locked version tools, preserve eligible development-version increments
  and release NEWS history, and accept five valid architecture terms in WORDLIST.
- U3/U5: run required checks on PR/main events, fail missing or skipped required
  results, fix scoped R lint findings, and use immutable read-only PR checkouts.
- U4/U8/U9: propagate audit/coverage/license errors, require real coverage reports,
  preserve AGPL license policy, enforce R CMD outcomes/logs, and check every NEWS line.
- U7: require actual source files before subprocess source loading and pass the
  active namespace library to instrumented concurrency workers. Existing backup,
  write serialization, integrity and review assertions remain intact.
- U6 local portion: sequence main writers, validate the final generated revision,
  guard PR writes, retry report publication on current branch state, pin runtime
  images, and document the required/optional event matrix in
  [UPSTREAM.md](../../.github/workflows/UPSTREAM.md).

## Observed checks

| Check | Result |
| --- | --- |
| actionlint 1.7.12 | Pass across all 14 workflow YAML files |
| Local reusable targets | Pass: all 13 calls resolve |
| Scanner and R CMD gate fixtures | Pass: 26 scenarios executing extracted workflow code |
| Required-result JavaScript fixtures | Pass: 7 scenarios, including failed/skipped/missing required results |
| Live PR write-target JavaScript fixtures | Pass: 10 scenarios covering open/closed/fork/stale/no-token targets |
| Version/NEWS transformation fixtures | Pass: 3 scenarios for release, existing development version, and release-history preservation |
| R parsing | Pass: 107 source/test/check scripts |
| git diff --check | Pass after corrections |
| Independent connected-code review | Three findings corrected; no remaining concrete finding |

Scanners, desc and GitHub API responses were supplied by controlled fixtures.
These results establish local gate behavior; they do not establish live scanner,
container, subprocess coverage, branch-write or publication success.

Testing began after integration. Failed syntax/whitespace checks and fixture
environment errors were corrected and only affected checks were repeated.
No package dependencies were installed. The main checkout's existing workflow,
manifest and deployment changes were preserved.

## Chrome DevTools

The [existing main run](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/actions/runs/38525234711)
at `5ab97c1` renders Failure, with Spell Check and Version Bump failed. The browser
session is signed out, so job logs are unavailable there.

The [published coverage page](https://ramdhadage.github.io/ADaMViz.SubmissionSync/coverage-report/)
renders `No coverage report.` Both pages recorded a resource 404 in the console.
Screenshots were saved in the local temporary directory as
`submissionsync-ci-baseline.png` and `submissionsync-coverage-baseline.png`.
These are baseline observations, not browser verification of the unpublished repair.

## Remaining verification

- Local `devtools`, `testthat`, `covr`, `lintr`, `styler`, and `spelling` could not
  be loaded from the available R libraries. Ordinary tests, instrumented coverage,
  lint/style/spelling and the RStudio package checkpoint remain blocked.
- Python was unavailable. The NEWS emoji implementation was inspected but its
  early-line negative fixture could not execute.
- Container compatibility, real audit/license results, live PR lifecycle,
  concurrent branch writes and report preservation require hosted CI.
- U6 remains open until the repair has a passing PR run and the subsequent main
  push has passing required checks, final generated SHA and actual coverage reports.
- Nothing was committed, pushed, published or merged.

When the existing R environment is available, run the ordinary suite and
`covr::package_coverage()` once from this worktree, then perform the required
RStudio Console checkpoint: `styler::style_pkg()`, `lintr::lint_package()`,
and `devtools::check(error_on = "warning")`. Commit approval and hosted delivery
remain separate steps.

The dependency-free regression check can be repeated from this worktree with
`Rscript --vanilla dev/check-ci-workflows.R`.

---
title: Teal-Style Package Checks - Plan
type: ci
date: 2026-10-13
topic: teal-style-package-checks
artifact_contract: ce-unified-plan/v1
product_contract_source: ce-plan-bootstrap
execution: code
---

## Goal Capsule

**Objective:** Run teal's complete package quality workflow for ADaMViz SubmissionSync while retaining this repository's approved package check.

**Means:** Replace `R-CMD-check.yaml` with a workflow that calls local copies of teal's thirteen reusable jobs and retains the existing warning-failing R package job. Migrate the repository default branch from `master` to `main`, which teal's write jobs require.

**Success signal:** All applicable jobs run on a pull request and the post-merge `main` push; the existing lint, tests, and R CMD check still fail on findings or warnings. The version, spelling, update, coverage, and publication jobs complete with the intended writes.

**Authority:** The user selected all teal jobs, including automatic commits, report publication, and PR comments, and selected migration to `main`. The [teal workflow](https://github.com/insightsengineering/teal/blob/main/.github/workflows/check.yaml) supplies the job set; repository rules supply the existing verification gate.

**Stop conditions:** Do not claim a green workflow from static inspection. The RStudio pre-commit checkpoint and live GitHub Actions run remain required before delivery. Do not migrate or merge before GitHub authentication is restored and repository rules can be inspected.

## Product Contract

### Requirements

- R1. Include teal's audit, CRAN and non-CRAN R CMD checks, coverage, linter, roxygen, gitleaks, spelling, links, version bump, version, licenses, and style jobs using vendored YAML files in `.github/workflows/`.
- R2. Preserve teal's automatic roxygen/style/WORDLIST/version commits, coverage and test report publication, and PR comments, with the permissions they require.
- R3. Preserve the current `renv`-based document, fatal lint, test, and warning-failing R CMD check job as a separate gate.
- R4. Move the default branch to `main`; target PRs and pushes to `main` so teal's write jobs act on the intended branch.
- R5. Bring the `NEWS.md` version and spelling wordlist prerequisites into line with the called workflows.
- R6. Keep generated reports separate from the existing pkgdown source files and preserve unrelated local work.

### Acceptance Examples

- AE1. A pull request runs the applicable checks; lint findings, test failures, and package warnings fail the retained package job.
- AE2. A `main` push runs version bump and spelling update against `main`, with any generated commits visible in Git history.
- AE3. The version job reads matching version headings in `DESCRIPTION` and `NEWS.md` before the first version bump.
- AE4. Coverage and test reports publish without deleting the pkgdown site.

## Planning Contract

Copy the twelve required reusable YAML files from `insightsengineering/r.pkg.template` into `.github/workflows/` and call them by local path. Record the upstream revision and Apache 2.0 attribution, remove their standalone event triggers, and review internal local references before treating them as portable. Keep the existing package job in the same new workflow because teal's shared R setup does not restore this repository's dependencies or enforce the same lint/test/warning policy. `pkgdown.yaml` remains a separate workflow.

The caller must grant write permissions for the auto-update and report jobs. Prefer the repository's `REPO_GITHUB_TOKEN` when configured, with the job-scoped `GITHUB_TOKEN` fallback described by the reusable workflows. The Project, branch protection, secret availability, and hosted runner behavior cannot be verified from this checkout.

## Implementation Units

### U1. Prepare version and spelling inputs

**Execution: test-first.** Verify the current mismatch and missing file, then align `NEWS.md` with `DESCRIPTION` and add `inst/WORDLIST` for the spelling workflow. Do not change package code or the declared version.

### U2. Replace package CI

**Execution: test-first.** Assert the thirteen teal job IDs and the retained package gate, then replace `.github/workflows/R-CMD-check.yaml` with `.github/workflows/check.yaml`. Download the twelve reusable workflow YAML files into `.github/workflows/` and point every job at its local file. Adapt `main` triggers, permissions, and report branding. Preserve the retained job's existing commands and system setup.

### U3. Update active references

Update `ARCHITECTURE.md` and the `pkgdown.yaml` branch trigger for the new default. Retain historical plan references. Revisit raw `master` links before retiring that branch.

### U4. Deliver through the repository workflow

Create and track the GitHub issue, use the numbered worktree branch, complete review and RStudio checks, then commit, push, open a PR, run hosted Actions, address feedback, merge, and move the Project item. Create and select `main` as default before the first merged run; verify branch rules and report-publication behavior.

## Verification Contract

Run a YAML-aware workflow validation across the caller and all twelve local reusable files, assert the job IDs, local references, triggers, permissions, preserved commands, version heading, and wordlist, and run `git diff --check`. Before committing, run `styler::style_pkg()`, `lintr::lint_package()`, then `devtools::check(error_on = "warning")` from the RStudio Console. Treat warnings and lint findings as failures. A GitHub Actions run must verify actual job and write behavior; local checks cannot prove it.

## Definition of Done

All fourteen jobs are configured, the old workflow is removed, the package checkpoint and independent review pass, `main` is the repository default, hosted checks and intended writes are observed, and the issue/Project/PR workflow is complete. Any failed gate leaves delivery open.

## Execution Status

- [Issue #26](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/issues/26) is open. The isolated worktree is on `ci/26-teal-check`.
- The workflow files are implemented and pass `actionlint` and `git diff --check`; independent review identified the roxygen push-branch defect, which is fixed.
- The user waived the RStudio Console checks for this change. GitHub Project steps, default-branch migration, commit, PR, hosted checks, and merge remain open.

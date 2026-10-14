---
title: Repair package CI failures and clarify skipped checks
type: fix
date: 2026-10-14
topic: package-ci-repair
artifact_contract: ce-unified-plan/v1
product_contract_source: ce-plan-bootstrap
execution: code
---

## Goal Capsule

**Objective:** A reviewer can trust the package CI checks, dependency and license scans, and published coverage report on both a pull request and a `main` push, and can tell which optional checks were deliberately not run.

**Means:** Repair the two reproducible `main` failures and three false-green checks, make event-specific checks and external dependencies explicit, then prove the PR and push paths separately (KTD1-KTD7).

**Authority:** The requester asked to identify failed and skipped workflows and copied Insights Engineering paths, then plan their repair. The earlier request selected all teal jobs, their write behavior, local reusable YAML files, and `main` as default. This plan preserves those decisions while correcting failures and misleading signals.

**Stop conditions:** Do not treat a green PR run as evidence for push-only jobs. Require a successful PR run before merge; declare the repair complete only after the merge push on `main` verifies push-only jobs. If that push fails, keep the repair open and follow with a focused fix. The repository's RStudio Console checkpoint applies unless the requester waives it for the repair itself; the previous waiver covered PR #27 only.

---

## Product Contract

### Summary and Problem Frame

PR #27 merged on 2026-10-13. Its final [PR check run](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/actions/runs/38443602194) was green, but coverage, dependency audit, and license checking each failed internally while their jobs reported success. The [latest `main` check run](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/actions/runs/38525234711) at `5ab97c1` failed: 13 jobs were marked successful, 7 skipped, and 2 failed. The same three false-green checks recur there. Coverage produced no percentage or XML, and `gh-pages/coverage-report/index.html` contains only `No coverage report.` Operators currently see a red aggregate result and many skips without an event matrix explaining them. A separate [merged PR #31 run](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/actions/runs/38524824518) exposed a lint failure and checkout failures after its source branch disappeared.

### Requirements

- R1. The version bump job must obtain its required `desc` package in this repository's `renv` environment and complete its intended `DESCRIPTION`/`NEWS.md` write path on `main`.
- R2. Spell Check must pass on current package text, including `vignettes/architecture.Rmd`, without adding indiscriminate dictionary exemptions; its subsequent WORDLIST update must be observable on `main`.
- R3. CI must distinguish required checks, event-specific checks, and optional disabled checks. A skipped required check must not masquerade as an overall green result for the event that requires it.
- R4. Keep all reusable workflow calls local to `.github/workflows/`. Inventory external Insights Engineering actions/images and remove or correct template-specific references that do not describe this repository.
- R5. A queued PR run must not fail solely because its source branch was deleted after merge. Actual lint findings from PR #31 must receive a separate owning fix or a documented scoped exception.
- R6. Preserve the approved strict `renv` check job and teal's requested update/report behavior, while making audit, coverage, and license-report failures visible rather than silently green.
- R7. Coverage must complete the package test suite under instrumentation, produce a real percentage and XML/HTML reports, and publish only a valid report.
- R8. License Check must execute its license scan in a usable R environment, emit an inspectable result, and fail if the scanner cannot run or finds a disallowed license.
- R9. The reusable R CMD job must fail on a nonzero check exit or missing check log; the NEWS emoji check must detect a match on any line.

### Scope Boundaries

The repair covers `.github/workflows/`, the five current spelling findings, and the three reported R lint findings. It does not change Shiny behavior, package public interfaces, clinical validation rules, or the default branch. Covtracer and PII scanning are optional inputs in the copied templates; enabling them is a policy and cost decision, not a prerequisite for fixing the present failures. Tag-only tarball uploads and alternate multiversion report publishers remain conditional because this repository currently runs ordinary `main`/PR events and a single-version pkgdown site.

### Acceptance Examples

- AE1. A PR run executes the strict package check, both reusable R CMD checks, coverage, SuperLinter, Style, URL Checker, spelling, roxygen, audit, gitleaks, version, and license jobs. A missing required result fails delivery.
- AE2. A `main` push completes version bump and spelling, and any generated commit is visible; report publication uses this repository's single-version `gh-pages` layout.
- AE3. PII, Covtracer, tag uploads, Lychee, and alternate report destinations show as intentionally skipped with their governing condition documented; an earlier failure never gets relabeled as intentional.
- AE4. A PR event already queued when its branch is removed still checks the event's immutable revision or exits cleanly by an explicit lifecycle rule. Lint findings remain failures until fixed.
- AE5. The audit and coverage jobs fail when their own analysis fails, even if report publishing is allowed to fail independently.
- AE6. A successful coverage run contains nonempty `coverage.xml`, numeric `coverage.txt`, and an HTML report with actual coverage; a failing test in the coverage subprocess makes the job fail and does not publish a placeholder.
- AE7. Audit Dependencies executes both `oysteR` scans, and License Check executes its license scan with an inspectable result; missing scanner dependencies fail both jobs.
- AE8. An early `R CMD check` failure without `00check.log` fails the reusable job; an emoji before the final line of `NEWS.md` fails Version Check.

---

## Planning Contract

### Observed failures and skips

| Evidence | Cause | Classification |
| --- | --- | --- |
| `main` Version Bump, latest run | `desc::desc_bump_version()` stops with `there is no package called 'desc'` after `renv` bootstrap. `desc` is in `renv.lock`, but the job does not restore/install it. | Current defect |
| `main` Spell Check, latest run | Five findings in `vignettes/architecture.Rmd`: `explainers`, `Invariants`, `linter`, `Observability`, `UX`. WORDLIST cleanup/commit steps then skip because the earlier step failed. | Current defect |
| PR #31 SuperLinter | `object_usage_linter` reports `canonical_hash`, `new_execution_result`, and `tags` in `R/execution_runner.R` and `R/mod_plot_generation.R`. | Merged lint defect; check against current code before editing |
| PR #31 nine checkout-dependent jobs | They fetch the source branch by name after it was deleted following merge. | PR lifecycle defect; not the cause of the current `main` failure |
| `main` Coverage job and published page | `covr::package_coverage()` ran 659 passing tests but failed three concurrent-process tests: `test-backup-restore.R`, `test-evidence-repository-sqlite.R`, and `test-review-service.R`. Their `callr` workers could not resolve `sqlite_evidence_repository` from the package namespace. `test-coverage.yaml` caught the error, made a one-line HTML placeholder, and published it without XML or a percentage. | Current false-green defect; actual percentage is unknown |
| PR #27 and `main` Audit Dependencies | Both `oysteR` steps log `there is no package called 'oysteR'`; their `tryCatch` handlers print the errors and return success. Neither scan ran. The default `allow-failure: false` also has inverted vulnerability-failure logic. | Current false-green defect; vulnerability status is unknown |
| PR #27 and `main` License Check | The container action logs `Error in library("jsonlite")`, then `Execution halted`, but its job concludes success. The action runs in its own container, so installing `jsonlite` only on the host runner would not prove a fix. | Current false-green defect; license status is unknown |
| `main` R CMD checks and JUnit publication | Both R CMD variants completed checks and published nonempty JUnit HTML artifacts. A branch-already-exists message during JUnit setup and missing `.*` glob during publication were harmless in this run; the report jobs pushed successfully. | Substantive success, with separate latent error-handling risks |
| `main` SuperLinter, Style, Check URLs | Caller `check.yaml` explicitly has `if: github.event_name != 'push'`. | Intentional today; leaves no push coverage for these checks |
| Covtracer, PII, tarball upload | Inputs default false or artifact upload is tag-only. | Intentional optional/event skips |
| PR Version Bump and PR report publication; `main` PR-only comments | Push-only or PR-only event conditions. The selected URL Checker runs while the Lychee alternative skips; single-version publishers run while multiversion/tag variants skip. | Intentional event skips |

The latest [pkgdown run](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/actions/runs/38525234640) and recent Pages builds succeed. An older pkgdown SSL reset is historical, not a current repair target. Earlier failed PR #27 runs were superseded by its passing final run.

### Key Technical Decisions

- KTD1. **Fix required push failures first.** Install/restore the locked `desc` dependency before running version bump, then observe its later write steps; do not merely suppress the job. Resolve the five spelling findings by correcting prose where appropriate and adding accepted domain words to `inst/WORDLIST`.
- KTD2. **Use a PR/push verification matrix.** Keep clearly conditional optional jobs conditional. Run SuperLinter, Style, and URL checks on `main` as read-only validation or explicitly designate PR checks as the required gate in branch protection; prefer running them on `main` because PR #31's lint findings otherwise become invisible after merge. Keep automatic style writes on PRs only to avoid an untested bot write loop on `main`.
- KTD3. **Treat copied YAML as local integration code.** All 13 caller jobs already use 12 local reusable workflows. Insights Engineering actions and `ghcr.io/insightsengineering/rstudio:latest` are external runtime dependencies, not paths to vendored YAML. Retain an external action/image only if its behavior is needed and tested here; pin mutable image versions or digests after compatibility checks. Remove irrelevant template URLs and messages.
- KTD4. **Do not hide analyzer failures.** The copied `audit.yaml` lacks `oysteR` in its job environment and has inverted `allow-failure` checks: default `false` does not fail on findings. `test-coverage.yaml` catches the observed test failure and publishes a placeholder. The containerized license action terminates because `jsonlite` is unavailable but reports success. Supply each scanner inside the environment where it runs, propagate errors, and require inspectable scan results and real coverage XML, numeric text, and HTML. Keep optional publication best effort only after valid analysis output exists.
- KTD5. **Use immutable PR identity for read-only jobs.** Checkout by the event's head revision rather than a mutable branch name where no write is needed. Write jobs need the live branch; gate their write path on branch existence/open PR, and avoid treating a merged/deleted branch as a check failure. Apply consistently across the 11 reusable files that reference `head_ref_branch`.
- KTD6. **Coordinate branch writers.** Roxygen, spelling, and version bump can all commit to `main` from one push. Order their write paths at the caller, make non-fast-forward/write failures visible, and verify the final branch SHA contains every intended change. Coordinate pkgdown with coverage/JUnit `gh-pages` publishers under one queued concurrency group or an equivalent retry strategy; the current separate groups allow stale pushes. [GitHub's concurrency documentation](https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency) says the default group keeps only one pending job, so use its queue mode if more than two publishers share a group. Decide whether the write token is the repository `GITHUB_TOKEN` or a separate token; [GitHub documents](https://docs.github.com/en/actions/concepts/security/github_token) that normal pushes made with `GITHUB_TOKEN` do not start new workflow runs, while another token may. If `GITHUB_TOKEN` suppresses follow-up CI, validate generated content within the originating run or dispatch a check for the final commit.
- KTD7. **Close latent green paths with focused negative tests.** `build-check-install.yaml` gives `R CMD check` `continue-on-error: true` and only parses the last line if `00check.log` exists; an early failure can report green. `version.yaml` tests only the final line's `matches` variable after its NEWS loop. These are code-path risks, not observed failures in the latest run. Keep the successful R CMD and JUnit paths intact while proving the negative cases.

### External reference inventory

`check.yaml` calls all 12 reusable YAML files via `./.github/workflows/`; it contains no call into `insightsengineering/r.pkg.template`. The remaining references fall into these exhaustive groups:

| Reference | Files | Interpretation |
| --- | --- | --- |
| `ghcr.io/insightsengineering/rstudio:latest` image | `audit.yaml`, `build-check-install.yaml`, `linter.yaml`, `roxygen.yaml`, `spelling.yaml`, `style.yaml`, `test-coverage.yaml` | External runtime image; retain only after compatibility and version pinning. |
| `insightsengineering/staged-dependencies-action@v2`, `setup-r-dependencies@v1` | `build-check-install.yaml`, `roxygen.yaml`, `test-coverage.yaml` | External dependency actions; the staged path currently skips because callers select `setup-r-dependencies`. Related input descriptions in build/check and roxygen name the same action. |
| `insightsengineering/coverage-action@v3`, `covtracer-action@v1` | `test-coverage.yaml` | External coverage/report actions; Covtracer is disabled by input. |
| `insightsengineering/r-spellcheck-action@v3`, `r-license-report@v1`, `pip-action@v2`, `presidio-action@v1`, `release-existence-action@v1` | `spelling.yaml`, `licenses.yaml`, `version.yaml`, `gitleaks.yaml`, `build-check-install.yaml`, respectively | External actions; PII and release paths are conditional. |
| `insightsengineering/junit-xml-diff` release binary | `build-check-install.yaml` | External executable download used by the JUnit comparison path; verify need, provenance, and pinning. |
| `insightsengineering/r-pkgdown-multiversion` marker | `build-check-install.yaml`, `test-coverage.yaml` | Upstream site-layout probe; this repo currently uses the single-version publication path. |
| `insightsengineering.github.io` exclusion; `tern.gee` help URL | `links.yaml`; `version.yaml` | Template-specific residue to remove or replace. |
| `insightsengineering.r-universe.dev` | `build-check-install.yaml` | Example input text, not active configuration. |

`${{ github.event.repository.name }}` resolves to this repository. `main`, `gh-pages`, `renv.lock`, `_pkgdown.yml`, and `inst/WORDLIST` are valid local concepts. Do not replace them just because they appear in copied YAML.

### Sequencing and impact

U1 and U2 remove the current red `main` causes. U3 makes skipped checks visible, U4 exposes audit/coverage failures, U7 fixes the coverage tests those failures reveal, and U8 restores license checking. U9 closes two additional latent green paths. U5 handles PR lifecycle failures and template residue. U6 proves both event paths and write behavior. Maintainers and reviewers need a compact skip matrix; pkgdown readers depend on reports not overwriting the site. Since write jobs can commit to `main`, verify permissions and branch rules before enabling additional writes.

---

## Implementation Units

### U1. Restore version-bump dependencies

**Goal:** Complete the version bump and its intended commit path on `main` (R1).

**Dependencies:** None.

**Files:** `.github/workflows/version-bump.yaml`; `renv.lock` only if the locked dependency is actually absent; `DESCRIPTION` and `NEWS.md` are observed outputs, not files to pre-edit for this unit.

**Approach:** Add the smallest locked-dependency setup before the first `desc` call. Check both `DESCRIPTION` and `NEWS.md` transformations, the pre-commit branch, token permissions, and the auto-commit result; do not use `continue-on-error` to mask a failed required write. Coordinate this writer with Roxygen and spelling per KTD6.

**Test scenarios:** Locked `desc` resolves under the job's `renv` bootstrap; first `main` push produces the expected development version/NEWS state; a later bot commit does not create an infinite bump loop; absent write permission yields a visible failure.

**Verification:** The push job succeeds and Git history contains the intended change, or the job explicitly reports no change when already at the target version.

### U2. Resolve spelling findings and its write path

**Goal:** Pass current spell checking and preserve WORDLIST maintenance (R2).

**Dependencies:** None.

**Files:** `vignettes/architecture.Rmd`, `inst/WORDLIST`, `.github/workflows/spelling.yaml` only if its follow-on update path proves defective.

**Approach:** Review the five reported words in context. Correct genuine typos and add accepted terminology to the wordlist. Keep the package's existing `inst/extdata/*` exclusion focused; its directory-removal warning did not cause the failure.

**Test scenarios:** The current vignette yields zero spelling findings; a deliberately new misspelling fails; a push with a stale WORDLIST reaches cleanup and records only intended changes.

**Verification:** Spell Check passes in PR and push runs, and push-only update steps execute or report no change.

### U3. Make required checks visible on each event

**Goal:** Make skipped required checks visible and fix the merged lint findings (R3, R5).

**Dependencies:** U1, U2 for the first all-green push target.

**Files:** `.github/workflows/check.yaml`, `.github/workflows/linter.yaml`, `.github/workflows/style.yaml`, `.github/workflows/links.yaml`, `R/execution_runner.R`, `R/mod_plot_generation.R` if current lint reproduces.

**Approach:** Establish one expected-job matrix for PR and `main`; make SuperLinter, Style, and URL checks run on both where their permissions and write behavior allow. Decide whether main SuperLinter should lint all files or only changed files; the current `lint-all-files` input defaults to false. Keep Style's auto-update enabled only where writes were approved and tested. Fix actual R lint findings at their owning code or document a narrow justified linter exception.

**Test scenarios:** PR and push each produce a required result for all active checks; known lint/style/link violations fail, including a violation outside the latest changed-files set if full-baseline lint is selected; optional Covtracer/PII and tag-only jobs remain identified as skipped; `main` Style does not make an unplanned commit.

**Verification:** Both event summaries match the matrix, with no unexplained required-job skip.

### U4. Correct analyzer failure propagation

**Goal:** A green audit or coverage result means its analysis completed (R6).

**Dependencies:** None.

**Files:** `.github/workflows/audit.yaml`, `.github/workflows/test-coverage.yaml`.

**Approach:** Provide `oysteR` to the audit job using a reproducible CI dependency setup, correct `allow-failure` polarity, and let errors from both scans propagate instead of being printed as success. Let a coverage computation error fail coverage and suppress placeholder creation/publication. Preserve optional report posting as best effort only after valid analysis output exists.

**Test scenarios:** Both `oysteR` functions actually run and produce inspectable results; missing `oysteR` and a simulated finding each fail by default; an allowed finding passes only when explicitly configured; thrown errors in either scan fail the audit job; a thrown coverage error fails the coverage job and suppresses publication; a successful coverage run publishes real XML/text/HTML reports.

**Verification:** Failure injection is reflected in job conclusions. The audit's normal scan stays green; coverage is expected to fail visibly until U7 resolves the observed test errors.

### U7. Make instrumented coverage tests pass

**Goal:** Produce real, reproducible coverage results (R7).

**Dependencies:** U4, so a coverage test failure is visible during diagnosis.

**Files:** `tests/testthat/test-backup-restore.R`, `tests/testthat/test-evidence-repository-sqlite.R`, `tests/testthat/test-review-service.R`, and the narrowest shared test helper if the three files need the same correction; `.github/workflows/test-coverage.yaml` only if its test environment must change.

**Approach:** Reproduce the three `callr::r_bg` failures under `covr::package_coverage()`. Inspect the worker's library paths, source root, and namespace loading before changing tests or package code. Repair the shared subprocess lookup/environment assumption while keeping the concurrent write, backup, integrity, and review assertions intact. Do not skip the tests under coverage.

**Test scenarios:** The three previously failing tests pass under both ordinary `testthat` and instrumented `covr`; a deliberate worker failure still fails the test; coverage produces numeric percentage, nonempty XML, and a real HTML report; the published page is no longer the placeholder.

**Verification:** Coverage job succeeds with 0 test failures and the expected artifacts; the report publisher reads those artifacts and serves a real report.

### U8. Restore fail-closed license checking

**Goal:** A green License Check means the license scan actually ran (R8).

**Dependencies:** None.

**Files:** `.github/workflows/licenses.yaml`; replace or fix the external `r-license-report` action only if its container cannot be made reliable without a fork.

**Approach:** Reproduce the container's `jsonlite` failure and determine whether the repository's `renv` autoloader masks the action's installed library. Fix the scanner inside its container or use a small local scan with explicit dependencies. Require the scanner's exit status and an inspectable result; do not rely solely on the outer Docker action's conclusion.

**Test scenarios:** Missing `jsonlite` fails; a disallowed license fails; an allowed dependency set emits a report and passes; PR and `main` both exercise the check.

**Verification:** The hosted job log contains actual scanned packages and a result, with no `Execution halted`; a negative case concludes failure.

### U9. Harden remaining green gates

**Goal:** Early package-check failures and NEWS emoji matches cannot pass silently (R9).

**Dependencies:** None.

**Files:** `.github/workflows/build-check-install.yaml`, `.github/workflows/version.yaml`.

**Approach:** Make the R CMD exit status authoritative while retaining explicit warning/note policy and JUnit reporting; require `00check.log` when a check was requested. Accumulate emoji matches across all NEWS lines or exit when one is found.

**Test scenarios:** Nonzero R CMD exit before log creation fails; a warning and a blocked note still fail; clean CRAN and non-CRAN checks pass with JUnit artifacts; an emoji on an early NEWS line fails; emoji-free NEWS passes.

**Verification:** Focused negative cases have failed job conclusions, and both hosted R CMD variants plus Version Check still perform their intended checks.

### U5. Remove PR lifecycle and upstream-template assumptions

**Goal:** Queued PR checks survive branch deletion and user-facing references point to this repository (R4, R5).

**Dependencies:** U3 for the settled event matrix.

**Files:** The 11 reusable workflows under `.github/workflows/` that use `head_ref_branch`; `.github/workflows/links.yaml`, `version.yaml`, `build-check-install.yaml`, `test-coverage.yaml`, and `UPSTREAM.md`.

**Approach:** Separate read-only checkout from write-target checkout. Use immutable PR revision for the former; only attempt branch writes while the PR branch is available. Remove the irrelevant Insights Engineering URL exclusion/help link. Keep or replace the pkgdown marker and JUnit binary only after confirming their branches are exercised and report paths are needed. Record any retained external actions/images and their pinned versions.

**Test scenarios:** A queued PR run survives branch deletion after merge; a normal open same-repo PR retains approved auto-updates; fork PR cannot gain write authority; links for this repo are checked; single-version reports publish without the upstream marker.

**Verification:** No checkout job fails solely because the named branch disappeared; static references and the UPSTREAM inventory agree with runtime use.

### U6. Verify delivery and document intentional skips

**Goal:** Prove the repaired CI on both event types and make its skip semantics reviewable (R1-R9).

**Dependencies:** U1-U5 and U7-U9.

**Files:** `.github/workflows/check.yaml`, `.github/workflows/pkgdown.yaml`, `.github/workflows/roxygen.yaml`, `.github/workflows/spelling.yaml`, `.github/workflows/version-bump.yaml`, `.github/workflows/UPSTREAM.md`, `ARCHITECTURE.md` only if its CI description changes.

**Approach:** Run workflow syntax checks and focused local R checks, then the repository's RStudio Console checkpoint or record its explicit waiver for this repair. Order or serialize the `main` writers and coordinate all `gh-pages` publishers per KTD6. Use a PR run before merge and observe the resulting `main` push for version/spelling/report writes. Record job URLs, expected skips, final generated commit SHA, and report locations. Review the repair diff independently before delivery.

**Test scenarios:** PR gate and push gate both pass; output lists each optional/event skip with its condition; concurrent main writers preserve every expected change or fail visibly; a bot commit does not start an uncontrolled loop; concurrent reports and pkgdown keep both sets of files on `gh-pages`; an induced required-job failure blocks completion.

**Verification:** The final PR and post-merge `main` run have no unexplained skips or failed required jobs, and the Project/issue/PR tracker reflects the observed result.

---

## Verification Contract

| Gate | Evidence required |
| --- | --- |
| Static workflow integrity | `actionlint` across caller and reusable YAMLs; local `uses:` targets exist; `git diff --check`; external reference inventory reviewed. |
| R package checkpoint | From RStudio Console at the repair worktree root: `styler::style_pkg()`, `lintr::lint_package()`, then `devtools::check(error_on = "warning")`; lint findings, warnings, and errors fail unless this repair receives an explicit waiver. |
| PR event | Required checks run and pass, including SuperLinter, Style, URL Checker, both R CMD variants, spelling, coverage, audit, roxygen, gitleaks, version, license, and the strict `check` job. Confirm approved PR comments/updates and real coverage artifacts. |
| `main` push | Required checks run and pass, including Version Bump and Spell Check; inspect their generated commits and JUnit/coverage reports on `gh-pages`. Check that bot commits do not create an uncontrolled loop. |
| Negative proof | Force representative audit/coverage/license/spelling/lint failures, early R CMD failure, and early NEWS emoji in a disposable branch or safe test fixture; confirm each expected job conclusion. Never inject a finding on `main`. |

---

## Definition of Done

The two reported `main` failures and three false-green jobs are resolved; PR #31's lint findings and deleted-branch checkout failures have owning resolutions; early R CMD and NEWS negative cases fail as intended; every required event has a passing observed result; optional skips are explained; copied upstream references are classified or corrected; analyzer failures cannot report green; real coverage artifacts and write-job/report destinations are observed; and the repair has independent review. Until both PR and `main` runs pass with real coverage, audit, and license results, the CI migration is not verified end to end.

# Progress

Updated: 2026-10-18 22:46 IST
Task: Implement one Export and download ZIP action after both approvals.
Branch: `fix/export-approval-controls`
HEAD at checkpoint start: `351e8fb0e594f944752b1cb97d63ddd68ab31d1b`
Plan / issue: User-reported error and requested disabled controls; no issue supplied.

## Done

- Reconciled the previous checkpoint with a clean worktree at the current HEAD. Earlier dependency repairs are committed; do not repeat them.
- Reproduced `Export the revision before download`. The UI permitted downloads with no export receipt; the export service already enforced Reviewed-only eligibility.
- Replaced the two actions with one Export and download ZIP control, disabled until Reviewed. Its download handler runs the existing controlled export service, refreshes the receipt table, then writes the ZIP; service/ZIP failures display a message and cancel the download silently.
- Updated module tests for one-action publication/download, approval gates, revision changes, receipt reuse, authorization denials, and ZIP-failure retry. Updated the existing browser export journey and its launcher to build the app from current source inside the subprocess.
- Independent read-only correctness review found no concrete defects. Chrome verification resolved its disabled-selectize interaction question.

## In progress

- Single-button Chrome flow, focused module/browser tests, and full source suite passed. Final package build/check is running. Documentation now reflects one combined action; spelling is being rechecked after those prose edits.

## Blocked

- None. Sandbox access to the existing renv cache required escalation; checks run with the user's authorization in background PowerShell.

## Decisions and constraints

- Keep the existing two-reviewer approval and Reviewed-only service policy.
- No new dependencies or changes to service/public interfaces. User approved the combined action. Owned paths: R/mod_export.R, tests/testthat/test-mod-export.R, tests/testthat/test-app-browser.R, PROGRESS.md, vignettes/ADaMViz.SubmissionSync.Rmd, vignettes/articles/11-controlled-export.Rmd, docs/features/11-controlled-export.md, and docs/ux/F001-plot-generation-prototype.html. Preserve concurrent unowned edits to AGENTS.md, docs/development/workflow.md, and docs/development/agent-state/.
- The user authorized background PowerShell checks for this task. No additional terminal windows, commits, push, or publication.
- Preserve earlier unresolved documentation-lint verification from the progress-guidance task. The known installed roxygen2 8.1.0 versus recorded 8.1.1 diagnostic is unchanged.

## Verification

- Focused export-module tests passed after reproducing failure before implementation.
- Formatting, documentation generation, spelling, lint, and full `testthat::test_local(reporter = "summary")` passed. Reverted the formatter's unrelated line wrap in `test-revision-evidence.R` to preserve scope.
- Chrome DevTools verified the source app at `http://127.0.0.1:42016/`, launched with `print(source("dev/run_dev.R")$value)`, using the repository's synthetic `adlb-standard.csv`.
- Browser: zero/one approval disables controls; both approvals enable Export while Download remains disabled; export enables Download; download returns HTTP 200, application/zip, ZIP bytes, and an attachment filename for the current revision. Shiny stays connected. No browser console warnings/errors; upload/download network requests returned 200.
- Disabled Actor selectize input cannot open or take keyboard focus. Destination and Export match native disabled state; Download has disabled styling, aria-disabled, and tabindex -1.
- `devtools::check(error_on = "warning")` passed: 0 errors, 0 warnings, 0 notes, including installed-package tests and vignette rebuilding. `git diff --check` passed.
- Earlier two-button verification log: `C:/Users/admin/AppData/Local/Temp/submission-sync-export-approval-check.log`. The single-action final verification log is `C:/Users/admin/AppData/Local/Temp/submission-sync-single-export-final-check.log`; the initial single-action run exposed the stale browser-test launcher and was stopped.

## Next action

1. The user approved the single-button workflow. Finish focused tests, Chrome verification, and the full package sequence; preserve controlled publication and receipt creation before download.
2. Restart the user's existing app with `source("dev/run_dev.R")` to load the fix.
3. Leave changes uncommitted; commit or publication requires an explicit request.

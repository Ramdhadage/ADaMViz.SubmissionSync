# ACID guidance checkpoint

Updated: 2026-10-18 22:40 IST
Task: Persist the user-approved ACID agent-state contract while keeping root AGENTS.md a map.
Owner: This session; documentation writes only.
Branch: `fix/export-approval-controls`
HEAD at checkpoint start: `351e8fb0e594f944752b1cb97d63ddd68ab31d1b`
Plan / issue: Approved contract in this conversation; routine guidance change, no issue required.
Owned paths: `AGENTS.md`, `docs/development/workflow.md`, and this checkpoint.
Baseline: `PROGRESS.md`, `R/mod_export.R`, and `tests/testthat/test-mod-export.R` were already modified. They are excluded from this operation.

## Done

- Added a short root guidance pointer and the detailed Atomicity, Consistency, Isolation, and Durability contract in the workflow guide.
- Kept all procedures outside root AGENTS.md and made its map-only purpose explicit.
- Detected concurrent updates to root PROGRESS.md and the export implementation/tests. A checkpoint patch failed its context check without changing that file; this session uses its own checkpoint to avoid competing with the export task's coordinator.

## In progress

- Guidance edits and static review are finished; full verification is pending.

## Blocked

- The available tools cannot access the existing VS Code integrated terminal required by the verification guide. The full local sequence has not been run for these changes. Do not run mutating package-wide checks concurrently with the export task.
- Markdown lint is not installed in the checked command paths or the usual local npm cache. Applicable Markdown lint remains pending; no dependencies were installed.

## Decisions and constraints

- Guidance only: no application logic, tests, dependencies, hooks, locks, or automatic commits.
- Preserve concurrent export work and leave root PROGRESS.md to its current coordinator.
- No commits or publication are authorized. These files are uncommitted and not yet durable in Git history.
- Verification predicates: changed documentation links and anchors resolve, whitespace checks pass, applicable Markdown lint has zero findings, and the full local sequence passes under `docs/development/verification.md`.

## Verification

- 2026-10-18 22:39 IST: inline Node.js assertions, executed through PowerShell with `node -`, passed structural checks for all three owned files and resolved all 19 local links/anchors in the two guides. Assertions also confirmed all four ACID sections, the root map-only rule, one H1 per file, and the CI Markdown line-length limit. These checks are not Markdown lint.
- Checked uncommitted guide identities (SHA256): `AGENTS.md` = `63fd348e33bdceac0555f406ad0a4e55b43d2f186bc685da2058428de41e97ca`; `docs/development/workflow.md` = `d03917aef543a59bb7bb367e810260f0d771a6ad52e8f7ca23fd5dae64aa0766`. Branch and HEAD are recorded above.
- `git diff --check -- AGENTS.md docs/development/workflow.md` passed. Final inline Node.js assertions passed for all three owned files: final newline present, no trailing whitespace, and no line exceeding 800 characters. A prior no-index comparison returned 1 for the new file with only an LF-to-CRLF advisory; the direct assertions subsequently verified its whitespace.
- Diff review: root guidance adds one ACID link and clarifies its map-only purpose; the workflow guide adds the contract and coordinator ownership. This session has written only its three owned documentation files. Concurrent export changes now also include `tests/testthat/test-app-browser.R`; they are not part of this operation.
- No tests added: this operation changes process documentation only. Document checks and the repository's existing full local sequence provide verification.
- Prior export verification recorded in root PROGRESS.md is evidence for that task, not this operation.

## Next action

1. Keep the operation marked verification pending until the remaining checks pass.
2. When shared resources are available, run applicable Markdown lint and the exact full local sequence in `docs/development/verification.md#full-local-verification` in the existing VS Code integrated terminal. Record fresh evidence before calling this operation verified.
3. The coordinator should link this checkpoint from root PROGRESS.md when integrating it. Include new continuity files in the explicitly approved commit; keep the separate export task's changes outside this operation.

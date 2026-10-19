# Repository Process Rules

## System Anchors

- Follow the clock-in and clock-out routines below. Long tasks must maintain [PROGRESS.md](PROGRESS.md) under [Progress tracking](docs/development/workflow.md#progress-tracking).
- For product or code work, read [CODEX_CONTEXT.md](CODEX_CONTEXT.md) before planning or changing implementation.
- Read [ARCHITECTURE.md](ARCHITECTURE.md) for the implementation map, enforcement boundaries, known gaps, and task-specific document pointers.
- Treat [docs/product/STRATEGY.md](docs/product/STRATEGY.md) as the source of truth for scope, terminology, boundaries, and metrics.
- Consult [docs/solutions/](docs/solutions/) for reusable technical learnings and [CONCEPTS.md](CONCEPTS.md) for project vocabulary. The solutions store is organized by category and searchable through YAML frontmatter such as `module`, `tags`, and `problem_type` when implementing or debugging a documented area.
- Before editing implementation or tests, read [R/AGENTS.md](R/AGENTS.md) or [tests/AGENTS.md](tests/AGENTS.md), respectively; nested guidance supplements this root contract.
- Read [Verification](docs/development/verification.md) for completion gates, VS Code commands, and CI requirements.
- Read [Development workflow](docs/development/workflow.md) before selecting a process tier or using Compound Engineering.

## At session start (clock in)

1. Read [PROGRESS.md](PROGRESS.md) and reconcile it with the current branch, HEAD, working tree, and verification evidence.
2. Read [DECISIONS.md](DECISIONS.md) for accepted decisions and reasons; follow linked task-specific sources as needed.
3. Run the [required verification](docs/development/verification.md) in the existing VS Code integrated terminal to establish the baseline. Record failures or unavailable checks as verification pending; do not infer a passing baseline.
4. Continue from PROGRESS.md's `Next action` section unless the user's current request redirects the work. Preserve unresolved tasks when switching scope.

## Before session end (clock out)

1. Update [PROGRESS.md](PROGRESS.md) with current state, verification results, blockers, and the next action. Record newly accepted important choices and reasons in [DECISIONS.md](DECISIONS.md).
2. Run the [required verification](docs/development/verification.md) on the final tree in the existing VS Code integrated terminal. Record the actual results or missing checks in PROGRESS.md before handoff.
3. Commit completed work only after the full local verification sequence passes and the user explicitly approves the commit. Otherwise leave it identified as uncommitted, with a concrete next action.

These routines are agent instructions, not automatic startup or shutdown hooks. Compound Engineering roles and decision-recording rules are in the [development guide](docs/development/workflow.md#decision-records).

## Working Contract

- Within platform, safety, and security constraints, the user's current explicit request overrides repository and skill guidance.
- Make small, focused changes. Preserve unrelated work and all uncommitted changes.
- Manage agent state under the [ACID contract](docs/development/workflow.md#agent-state-acid-contract).
- Stop and ask before changing requirements, business logic, public interfaces, target environments, dependencies, or error-handling policy.
- Preserve approved verification checkpoints and manual-testing handoffs.
- Launch the application for local development and browser verification with `source("dev/run_dev.R")` from the repository root; do not use root `app.R` for these runs.
- Report files changed, checks run, observed results, and anything unverified. Keep static checks, R execution, browser behavior, statistical review, and formal validation distinct.
- For complex features that need long-form package documentation, use `usethis::use_vignette("feature_name")`. Ask the user for explicit permission before running the command or creating any vignette files.
- Before claiming implementation is complete, run the applicable checks in [Verification](docs/development/verification.md) in the existing VS Code integrated terminal. If required checks fail or cannot run, report verification pending, with the missing checks; do not claim completion.
- Before committing, complete the full local verification sequence, report the results, and obtain explicit commit approval. Commit, publish, or merge only when requested.
- Write user-facing reports through `ce-noslop`. Keep this file a map, not a manual; put detailed workflow instructions in the linked development guide.

# Repository Process Rules

## System Anchors

- At session start, read
  [PROGRESS.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/PROGRESS.md)
  if present and reconcile it with current repository state. Long tasks
  must maintain it under [Progress
  tracking](https://ramdhadage.github.io/ADaMViz.SubmissionSync/docs/development/workflow.html#progress-tracking).
- For product or code work, read
  [CODEX_CONTEXT.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/CODEX_CONTEXT.md)
  before planning or changing implementation.
- Read
  [ARCHITECTURE.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/ARCHITECTURE.md)
  for the implementation map, enforcement boundaries, known gaps, and
  task-specific document pointers.
- Treat
  [docs/product/STRATEGY.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/docs/product/STRATEGY.md)
  as the source of truth for scope, terminology, boundaries, and
  metrics.
- Consult
  [docs/solutions/](https://ramdhadage.github.io/ADaMViz.SubmissionSync/docs/solutions/)
  for reusable technical learnings and
  [CONCEPTS.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/CONCEPTS.md)
  for project vocabulary. The solutions store is organized by category
  and searchable through YAML frontmatter such as `module`, `tags`, and
  `problem_type` when implementing or debugging a documented area.
- Before editing implementation or tests, read
  [R/AGENTS.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/R/AGENTS.md)
  or
  [tests/AGENTS.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/tests/AGENTS.md),
  respectively; nested guidance supplements this root contract.
- Read
  [Verification](https://ramdhadage.github.io/ADaMViz.SubmissionSync/docs/development/verification.md)
  for completion gates, VS Code commands, and CI requirements.
- Read [Development
  workflow](https://ramdhadage.github.io/ADaMViz.SubmissionSync/docs/development/workflow.md)
  before selecting a process tier or using Compound Engineering.

## Working Contract

- Within platform, safety, and security constraints, the user’s current
  explicit request overrides repository and skill guidance.
- Make small, focused changes. Preserve unrelated work and all
  uncommitted changes.
- Manage agent state under the [ACID
  contract](https://ramdhadage.github.io/ADaMViz.SubmissionSync/docs/development/workflow.html#agent-state-acid-contract).
- Stop and ask before changing requirements, business logic, public
  interfaces, target environments, dependencies, or error-handling
  policy.
- Preserve approved verification checkpoints and manual-testing
  handoffs.
- Launch the application for local development and browser verification
  with `source("dev/run_dev.R")` from the repository root; do not use
  root `app.R` for these runs.
- Report files changed, checks run, observed results, and anything
  unverified. Keep static checks, R execution, browser behavior,
  statistical review, and formal validation distinct.
- For complex features that need long-form package documentation, use
  `usethis::use_vignette("feature_name")`. Ask the user for explicit
  permission before running the command or creating any vignette files.
- Before claiming implementation is complete, run the applicable checks
  in
  [Verification](https://ramdhadage.github.io/ADaMViz.SubmissionSync/docs/development/verification.md)
  in the existing VS Code integrated terminal. If required checks fail
  or cannot run, report verification pending, with the missing checks;
  do not claim completion.
- Before committing, complete the full local verification sequence,
  report the results, and obtain explicit commit approval. Commit,
  publish, or merge only when requested.
- Write user-facing reports through `ce-noslop`. Keep this file a map,
  not a manual; put detailed workflow instructions in the linked
  development guide.

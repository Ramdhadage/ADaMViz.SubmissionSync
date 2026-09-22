# Repository Process Rules

## System Anchors

- For product or code work, read [CODEX_CONTEXT.md](CODEX_CONTEXT.md) before planning or changing implementation.
- Treat [docs/product/STRATEGY.md](docs/product/STRATEGY.md) as the source of truth for scope, terminology, boundaries, and metrics.
- Consult [docs/solutions/](docs/solutions/) for reusable technical learnings and [CONCEPTS.md](CONCEPTS.md) for project vocabulary.
- More specific nested `AGENTS.md` files govern work in their directories.

## Working Contract

- Within platform, safety, and security constraints, the user's current explicit request overrides repository and skill guidance.
- Make small, focused changes. Preserve unrelated work and all uncommitted changes.
- Stop and ask before changing requirements, business logic, public interfaces, target environments, dependencies, or error-handling policy.
- Preserve approved verification checkpoints and manual-testing handoffs.
- Report files changed, checks run, observed results, and anything unverified. Keep static checks, R execution, browser behavior, statistical review, and formal validation distinct.

## Compound Engineering Workflow

- Read the selected skill's `SKILL.md` and use only capabilities available in the current session. Plugin workflows do not broaden authorization, and small explicit edits do not require a full workflow.
- Match the skill to the task: `ce-brainstorm` for unclear requirements, `ce-plan` for implementation planning, and `ce-work` for an agreed plan or concrete work prompt.
- Use `ce-debug` for failures, `ce-explain` for evidence-based explanations, and `ce-pov` for evaluating approaches. Search relevant `docs/solutions/` before planning or debugging.
- For substantial code changes, run `ce-simplify-code` before `ce-code-review`. Use `ce-doc-review` for plans and `ce-test-browser` for requested browser verification; review findings are not test evidence.
- Use `ce-compound` only after a verified, non-obvious solution that is not already explained by the diff or existing documentation.
- Commit or publish only when requested, using `ce-commit` or `ce-commit-push-pr`. Use `lfg` only when the user explicitly authorizes autonomous delivery.

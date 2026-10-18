# Development Workflow

Read [root AGENTS.md](../../AGENTS.md) first. This guide contains the detailed process referenced by the root map; [Verification](verification.md) defines VS Code execution and completion requirements.

## Compound Engineering Workflow

- Read the selected skill's `SKILL.md` and use only capabilities available in the current session. Plugin workflows do not broaden authorization.
- Use the GitHub MCP for GitHub Project, issue, pull-request, review, status, linking, and merge operations when the required capability is available; do not substitute manual GitHub UI steps.
- The complete workflow is:

  ```text
  [GitHub MCP: create an issue and add it to the GitHub Project]
    -> ce-brainstorm -> ce-plan
    -> ce-worktree (branch: <type>/<issue-number>-<slug>)
    -> GitHub MCP: move the project item to In Progress
    -> ce-work (commits reference #<issue-number>)
    -> ce-test-browser
    -> ce-code-review
    -> ce-commit-push-pr (PR body includes "Closes #<issue-number>")
    -> GitHub MCP: link the PR and move the project item to In Review
    -> ce-resolve-pr-feedback
    -> [GitHub MCP: merge the PR and move the project item to Done]
    -> ce-compound (writes to docs/solutions/)
  ```

- Apply only the steps required by the change's blast radius:

  | Tier | Examples | Required process |
  | --- | --- | --- |
  | Routine | Copy or documentation edits; CSS-only spacing, typography, or icon changes; lint or formatting fixes; small UI changes that reuse an approved `bslib` or Shiny pattern without changing behavior | Run `ce-work` directly with a bare prompt; `ce-code-review` is optional. Do not create an issue. |
  | Standard | A new Shiny module within the approved workflow; a read-only data-profile panel; a new plot control using an existing supported `ggplot2` pattern; an internal refactor that preserves public interfaces, validation rules, and review status | Run `ce-plan` -> `ce-work` -> `ce-code-review` -> `ce-commit-push-pr`. Create an issue. |
  | Safety-critical | Changes to permitted-data or BDS validation boundaries; LLM prompts or tools that can expose study data; generated-code execution or automated statistical checks; revision evidence, audit trail, review status, export eligibility, authentication, authorization, privacy controls, or persistent-data migrations | Run `ce-brainstorm` -> `ce-plan` (every unit has `Execution: test-first`) -> `ce-work` -> `ce-code-review` -> `ce-commit-push-pr` -> `ce-compound`. Create an issue. |

- If less than 95% confident in the tier classification, ask the user before proceeding.
- Use `ce-debug` for failures, `ce-explain` for evidence-based explanations, and `ce-pov` for evaluating approaches. Search relevant `docs/solutions/` before planning or debugging.
- For substantial code changes, run `ce-simplify-code` before `ce-code-review`. Use `ce-doc-review` for plans and `ce-test-browser` with Chrome DevTools MCP for affected UI/browser verification; review findings are not test evidence.
- Use `ce-compound` only after a verified, non-obvious solution that is not already explained by the diff or existing documentation.
- After a solved, verified problem, automatically invoke the `ce-compound` skill with `mode:non-interactive` at the completion checkpoint only when the work produced durable project reasoning that is not readily recoverable from the final code, tests, types, comments, or existing documentation, and losing it would plausibly cause recurrence, material risk, or substantial rediscovery. Apply this counterfactual: if the learning document disappeared, would a future engineer reading the final implementation still be likely to repeat the mistake or redo substantial investigation? If not, do not invoke it. Completion, effort, and diff size alone are not enough. Capture at the checkpoint so a qualifying learning can ship in the PR that produced it, and only
  where the repository treats captured learnings as tracked, committed knowledge.
- Write every report, summary, or handoff to the user through the `ce-noslop` skill. This applies when you are the top-level agent writing to the user, not when you are a subagent reporting to its caller. Do not apply it to code, config, verbatim quotes, or text the user asked to post as written.
- Commit, publish, or merge only when requested. Use `lfg` only when the user explicitly authorizes autonomous delivery.

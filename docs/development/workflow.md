# Development Workflow

Read [root AGENTS.md](../../AGENTS.md) first. This guide contains the detailed process referenced by the root map; [Verification](verification.md) defines VS Code execution and completion requirements.

## Progress tracking

- The coordinating agent owns root `PROGRESS.md`. Concurrent workers use separate progress files under the [ACID contract](#agent-state-acid-contract); they report results to the coordinator instead of editing the shared checkpoint.
- Long tasks that span multiple steps or sessions must maintain root [PROGRESS.md](../../PROGRESS.md). At session start, read it if present and reconcile the checkpoint with the current branch, working tree, relevant artifacts, and verification evidence before acting. Resolve mismatches from current evidence; do not repeat completed work solely because a checkpoint is stale.
- Record the task, update time with timezone, branch and HEAD, and plan or issue links when applicable. Keep `Done`, `In progress`, `Blocked`, `Decisions and constraints`, `Verification`, and `Next action` sections. Use `None` when a section has no entries. Name what remains in partial work and what would resolve each blocker; make the next action concrete.
- Update the checkpoint after meaningful milestones, decisions, verification results, or blockers, before switching tasks, and before ending a session with an active long task. Update during execution because an interruption may prevent a final write. When changing tasks, retain unresolved work with its task or artifact pointer so it is not lost.
- Use the host task tracker during execution when available; checkpoint its useful state into `PROGRESS.md` even when no tracker is available. Keep approved requirements and design in their authoritative plans and lasting choices with their reasons in [DECISIONS.md](../../DECISIONS.md); link to them rather than copying them or using plan checkboxes as execution state.
- Distinguish implementation finished from verification passed. Record observed checks with their results and revision or scope, plus pending checks and manual handoffs. A checkpoint is context, not proof of completion or new authorization; existing verification and commit/publish approval gates still apply. Keep secrets and patient-level or confidential data out of the file.
- Keep the checkpoint concise. Use `ce-handoff` when a transfer needs more context, link the handoff from the checkpoint, and choose a durable destination accessible to the receiving session. Do not rely on its default temporary storage for permanent continuity. These are agent instructions; they do not install startup or shutdown hooks.

## Decision records

- Follow root AGENTS.md's [clock-in](../../AGENTS.md#at-session-start-clock-in) and [clock-out](../../AGENTS.md#before-session-end-clock-out) routines. This repository uses the [verification sequence](verification.md#full-local-verification); it has no `make check` equivalent. Markdown instructions do not execute checks automatically.
- Keep [DECISIONS.md](../../DECISIONS.md) as the concise record of important accepted choices: what, why, and when. Include rejected alternatives and constraints only when relevant. Link authoritative plans, requirements, or architecture evidence; the log does not grant approval or change product requirements.
- During `ce-brainstorm` and `ce-plan`, keep proposed choices and open questions in the working artifact. Record important choices in DECISIONS.md when accepted. During `ce-work`, consult the log and capture any newly approved decisions; ask before changing an approved requirement or interface under the root contract.
- Use [PROGRESS.md](../../PROGRESS.md) for current execution state, verification, blockers, and next actions. Its `Decisions and constraints` section should link lasting decisions rather than become a second decision history.
- Use `ce-compound` for verified, non-obvious lessons that meet its durability threshold, saved in `docs/solutions/`. It is not required for every decision. Use `ce-handoff` when a session transfer needs more context, linking the durable handoff from PROGRESS.md.
- Add a new dated entry when a decision changes and link the superseded entry; preserve the earlier reason. Do not invent historical decision dates or backfill choices without supporting evidence.

## Agent state: ACID contract

Apply this contract to agent work and its recorded state. These instructions define process requirements; they do not install transaction machinery, locks, or automatic verification.

### Atomicity

- Before editing, record the logical operation's goal, owned paths, starting branch and HEAD, pre-existing changes, and verification predicates in the task checkpoint. Include affected callers, tests, fixtures, configuration, and generated documentation in the same operation when needed.
- Complete and verify the whole operation before committing or merging any of it. Commit only the operation's changes, with the user's explicit approval under the [verification gate](verification.md#completion-gate). Uncommitted work awaiting approval remains identified as such.
- Discard failed or abandoned attempts only when their changes can be attributed to the operation. Preserve existing user work and other agents' changes; never use a blanket reset or clean. If ownership is uncertain, retain the changes and record the blocker. A failed attempt must not enter a commit or merge as a partial result.
- After interruption, reconcile the checkpoint with the actual files and Git state before resuming or retrying. Retained partial work is recovery state, not an accepted operation.

### Consistency

- Define the predicates before starting: approved requirements still hold, all required tests pass, lint and spelling have zero findings, package checks have no errors or warnings, and scope-specific checks pass as required by [Verification](verification.md). Record pre-existing failures separately; they remain blockers to the applicable completion gate.
- Run the applicable verification after each logical operation and again after integration on the combined tree. Record exact commands, observed results, time with timezone, checked paths, branch and HEAD, and a diff identity or file hashes for uncommitted changes. Evidence for an older or different tree does not verify the current operation.
- Failed, skipped, unavailable, or pending required checks mean **verification pending**. Do not commit, merge, report completion, or start work that depends on that operation until the required checks pass. After a relevant change, rerun the affected checks.
- Distinguish implementation finished, verification passed, and committed. Keep static checks, R execution, browser behavior, statistical review, and formal validation evidence separate. Use the execution surface required by the verification guide; do not substitute another terminal without authorization.

### Isolation

- Before concurrent work, assign each agent exclusive file ownership and a unique progress file, such as `docs/development/agent-state/<task>-<agent>.md`. Create these files only when needed and use the root checkpoint's fields. Only the coordinator updates root `PROGRESS.md`, integrates results, writes the shared Git index, or makes canonical commits.
- Use separate worktrees and branches when agents need overlapping files or independent Git operations. Different branch names in one working directory do not provide isolation. If isolation is unavailable, serialize the conflicting work.
- In a shared worktree, allow concurrency only for disjoint writes, including progress files, generated files, caches, fixtures, and configuration. Serialize formatters, documentation generation, package checks, and other commands that mutate shared state. Give shared runtime resources, such as the app, browser session, or database, one owner at a time.
- Before integration, compare each result with its recorded baseline and current tree. Reconcile stale or conflicting results, then verify the combined operation. Stop integration on unexpected or unowned writes; preserve them for reconciliation rather than overwriting them.

### Durability

- Keep critical decisions, constraints, approved requirements, recovery instructions, and verification evidence in git-tracked project files. Use `DECISIONS.md` for lasting choices and reasons, authoritative plans for approved requirements, `docs/solutions/` for reusable lessons, and `PROGRESS.md` for current execution state; link to existing sources instead of duplicating them. New continuity files must be included in the approved commit, not left only in temporary storage or session memory.
- Write checkpoints after meaningful milestones and before handoff or task switching. Link any worker progress files or durable handoffs from the root checkpoint. Retain unresolved work and its next action when changing tasks.
- A durable verification record contains the result and enough context to identify the checked tree; a temporary log path alone is insufficient. Keep secrets and patient-level or confidential data out of all state and knowledge files.
- Changes saved on disk but not committed are explicitly **uncommitted**. Git-history durability requires the user's commit approval; remote durability requires separately authorized publication. This contract grants neither automatically.

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

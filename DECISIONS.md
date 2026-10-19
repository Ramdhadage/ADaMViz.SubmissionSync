# Design Decisions

Record important accepted decisions as a dated heading stating the choice and a short reason. Add rejected alternatives, constraints, and source links when relevant; omit fields that do not apply. Keep implementation detail in the linked plan or architecture document.

Use the decision date when known. For an older decision with an unknown date, label the entry's date as the recording date. When a decision changes, add a new entry and link the superseded entry so its reasoning remains available. Proposed choices and open questions stay in the plan until accepted.

```markdown
## YYYY-MM-DD: Decision

- Reason: Why this choice fits the problem.
- Rejected alternative: Alternative considered and why it was rejected.
- Constraint: Limit that must hold.
- Source: Link to the approving request, plan, or other evidence.
```

## 2026-10-19: Keep a concise decision log and explicit session routines

- Reason: Future sessions need the accepted choices and their reasons without reading detailed design documents or recovering chat history.
- Constraint: Keep current work and next actions in [PROGRESS.md](PROGRESS.md), record lasting choices here, and link existing authoritative documents instead of duplicating them. Session routines retain the existing verification and explicit commit-approval gates.
- Source: User request on 2026-10-19; [session routines](AGENTS.md#at-session-start-clock-in) and [development workflow](docs/development/workflow.md#decision-records).

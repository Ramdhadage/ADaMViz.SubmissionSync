# Design Decisions

Record important accepted decisions as a dated heading stating the
choice and a short reason. Add rejected alternatives, constraints, and
source links when relevant; omit fields that do not apply. Keep
implementation detail in the linked plan or architecture document.

Use the decision date when known. For an older decision with an unknown
date, label the entry’s date as the recording date. When a decision
changes, add a new entry and link the superseded entry so its reasoning
remains available. Proposed choices and open questions stay in the plan
until accepted.

``` markdown
## YYYY-MM-DD: Decision

- Reason: Why this choice fits the problem.
- Rejected alternative: Alternative considered and why it was rejected.
- Constraint: Limit that must hold.
- Source: Link to the approving request, plan, or other evidence.
```

## 2026-10-19: Keep a concise decision log and explicit session routines

- Reason: Future sessions need the accepted choices and their reasons
  without reading detailed design documents or recovering chat history.
- Constraint: Keep current work and next actions in
  [PROGRESS.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/PROGRESS.md),
  record lasting choices here, and link existing authoritative documents
  instead of duplicating them. Session routines retain the existing
  verification and explicit commit-approval gates.
- Source: User request on 2026-10-19; [session
  routines](https://ramdhadage.github.io/ADaMViz.SubmissionSync/AGENTS.html#at-session-start-clock-in)
  and [development
  workflow](https://ramdhadage.github.io/ADaMViz.SubmissionSync/docs/development/workflow.html#decision-records).

## 2026-10-19: Interpret revised plot questions before confirmation

- Reason: Changing ALT AVAL to ALT CHG in the question previously left
  the confirmation form at its AVAL default because candidate
  construction did not interpret the question.
- Choice: Reuse the existing local deterministic interpreter to propose
  fields, with manual selection when no candidate is returned. Keep
  explicit confirmation and the existing validation before generation.
- Constraint: No external model calls, new dependencies, or changes to
  execution and review policy. The interpreter supports its existing
  rule set, not unrestricted natural-language requests.
- Source: User approval to implement in the current conversation;
  [candidate
  construction](https://ramdhadage.github.io/ADaMViz.SubmissionSync/R/app_server.R),
  [architecture
  map](https://ramdhadage.github.io/ADaMViz.SubmissionSync/ARCHITECTURE.md).

## 2026-10-21: Require Noble curl security revision .16 for reviewed audit findings

- Reason: The dependency audit now reports CVE-2026-86414 and
  CVE-2026-87864 in addition to the four previously reviewed curl
  findings. Ubuntu reports both fixed in `8.5.0-2ubuntu10.16`; require
  that revision before applying the existing runtime-specific review
  mechanism.
- Constraint: Keep raw scan artifacts, runtime linkage and
  package-ownership checks, and failure on unreviewed findings. This
  review covers the pinned Ubuntu CI environment, not other deployments
  or Windows libraries.
- Source: [Ubuntu proxy
  advisory](https://ubuntu.com/security/CVE-2026-86414), [Ubuntu IMAP
  advisory](https://ubuntu.com/security/CVE-2026-87864), accessed
  2026-10-21; user request to repair both CI failures.
- Choice: Keep development version `0.1.0.9021` and its expected CRAN
  incoming NOTE, as selected by the user on 2026-10-21. Exclude
  DECISIONS.md from the source package and close the test browser at
  suite teardown to address the other NOTES without weakening the check
  gate.

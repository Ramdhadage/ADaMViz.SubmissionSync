# Execution plan tracking

This directory tracks execution state for project work. The canonical product
strategy remains in [`../../product/STRATEGY.md`](../../product/STRATEGY.md), the
implementation map remains in [`../../../ARCHITECTURE.md`](../../../ARCHITECTURE.md),
and approved plan documents remain alongside this directory in `docs/plans/`.

- `active/` contains links or concise execution notes for work that is underway.
- `completed/` contains completion records after the agreed verification evidence
  is available. Keep canonical plans in `docs/plans/`; do not copy or move them.
- [`tech-debt-tracker.md`](tech-debt-tracker.md) records known gaps and deferred
  work grounded in the current repository documentation.

Use the existing status terms from project records where applicable: `Planned`,
`Development evidence in progress`, and `Deferred`. Do not mark an item complete
from implementation presence alone; record the evidence and date used to close
it.

# Correction revisions and traceability to earlier results

A correction creates a new revision linked to a closed result. The
earlier revision remains `Reviewed` or `Rejected`, with its existing
evidence and decisions. The successor receives its own specification,
script, artifacts, execution evidence, and review decisions. Approval of
the parent does not approve the correction.

[![Rendered correction lifecycle
diagram](diagrams/10-correction-revision-traceability.png)](https://htmlpreview.github.io/?https://raw.githubusercontent.com/Ramdhadage/ADaMViz.SubmissionSync/master/vignettes/articles/diagrams/10-correction-revision-traceability.html)

[View in Full
Screen](https://htmlpreview.github.io/?https://raw.githubusercontent.com/Ramdhadage/ADaMViz.SubmissionSync/master/vignettes/articles/diagrams/10-correction-revision-traceability.html)

## Starting a correction

The confirmation module offers **Create correction revision** when the
current state contains a `Reviewed` or `Rejected` revision and
specification choices. The user changes the plotting selections and
supplies both a correction rationale and correction provenance.
Rationale explains why the result needs a successor; provenance records
the source of the requested change. These are required strings. The code
does not validate the accuracy of their content or require a structured
change-request reference.

`mod_specification_server()` requires explicit confirmation when the new
specification uses free Y scales. It passes the selected fields and
correction text to the coordinator. Errors are shown as messages in the
module. `Draft`, `Verified`, and `Experimental/Draft` revisions cannot
be correction parents through this path.

The coordinator rereads the parent from the repository before creating
the correction. `.execute_correction_revision()` requires a repository,
revision, and snapshot; it rejects parents whose current repository
status is not `Reviewed` or `Rejected`. It then confirms the new
specification and validates the selected records against the BDS
plotting envelope. A blocking diagnostic stops the operation before
successor creation.

## Inputs and defaults

A correction uses `state$snapshot` and the fields collected for the
current operation. It does not retrieve and replay the parent’s retained
input evidence automatically. In the usual session this snapshot is the
input associated with the current result, but the parent link alone does
not establish input equality.

`.current_spec_input_fields()` prefers control values, then the current
specification, then available choices. Parameter, analysis variable,
unit, treatment variable, treatment levels, visits, and scale mode are
therefore explicit parts of the successor specification. Default
selection is a convenience for confirmation, not evidence that the
correction must preserve every earlier choice. The coordinator
recomputes the profile and script from the new confirmed fields.

## Stored relationship and identities

`new_lifecycle_service()$create_correction()` assigns the next number as
the maximum revision number for the plot plus one. The successor belongs
to the parent’s `plot_id`; its `parent_revision_id` identifies the
particular earlier revision being corrected. Numbering is plot-wide, so
a successor’s number need not immediately follow its parent’s number if
other successors already exist.

The SQLite repository independently checks that the parent belongs to
the same plot, has a closed status, and has both correction fields. It
also rejects correction text without a parent. The schema supplies a
parent foreign key and a unique `(plot_id, revision_number)` pair.
Creation writes the successor, its initial status projection, and a
`revision_created` lifecycle event within the repository command
transaction. Idempotency keys bind repeated commands to their payloads.

The revision record contains creator identity, specification and code
hashes, artifact identities when available, initial status, creation
time, parent identity, rationale, and provenance. The application
coordinator currently supplies the literal creator ID `creator`. The
lower-level lifecycle service accepts a supplied creator ID; it does not
resolve an authenticated correction author or apply reviewer-role
authorization. Review role checks happen in the separate review service.
See [human
review](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/09-human-review-decisions.md).

## Execution and status of the successor

A fixed-scale correction starts as `Draft`.
`.materialize_correction_revision()` compiles and stores a new script,
creates the linked successor with image and analytical hashes pending,
then submits a new governed execution attempt using the selected data.
Passing verification and artifact acceptance can promote this successor
to `Verified`. A failed verification completes a failed attempt and
leaves the successor `Draft`; it does not reopen or reject the parent.

A free-scale correction starts as `Experimental/Draft`. The coordinator
builds its script and in-process preview without submitting the governed
worker attempt. It cannot inherit the parent’s verification or review
status. See [scale
paths](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/05-fixed-free-y-scales.md)
and [verification
evidence](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/07-verification-revision-evidence.md).

The application updates its reactive current revision after the
correction function returns. Successor creation occurs before execution
and preview assembly finish. If a later operation throws an error,
repository records may already contain the child while the UI still
holds the parent. The entire correction workflow is not one database
transaction.

## Inspecting history and limits

`mod_revision_history_server()` lists all revisions for the plot and
rereads each current status. The table shows revision ID, number,
initial status, current status, and creation time. It does not show the
parent link, rationale, provenance, or a field-level difference between
specifications. Inspect repository records and revision evidence to
establish those relationships; adjacent rows alone do not prove direct
ancestry.

Tests inspected cover rejection followed by correction, preservation of
a reviewed parent, rejection of open parents, repository correction
constraints, governed execution of an application correction, and
display of parent/child statuses. The application correction test uses a
fake runner, so its assertions are not subprocess or browser proof. No R
tests or browser checks were run for this documentation change.

## Implementation references

- [Lifecycle
  service](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/lifecycle_service.R):
  `create_correction()`.
- [Application
  coordinator](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/app_server.R):
  `.execute_correction_revision()`,
  `.materialize_correction_revision()`.
- [Specification
  controls](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/mod_specification.R):
  `.can_create_correction()`, `.current_spec_input_fields()`.
- [Repository](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/evidence_repository_sqlite.R)
  and
  [schema](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/inst/sql/schema.sql):
  revision relationships and creation transaction.
- [History
  module](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/mod_revision_history.R),
  [lifecycle
  tests](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-lifecycle-service.R),
  [application correction
  test](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-app-server-correction.R),
  [repository contract
  tests](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-evidence-repository-contract.R),
  and [history
  test](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-mod-revision-history.R).

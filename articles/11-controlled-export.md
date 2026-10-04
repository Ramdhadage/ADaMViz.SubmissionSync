# Controlled export of plot images and R scripts

Controlled export publishes the accepted `plot.png` and `script.R` pair
to a registered workspace destination and retains a receipt inside the
evidence repository. The current implementation permits `Draft`,
`Verified`, and `Reviewed` revisions with an accepted artifact bundle.
Human approval is not a service prerequisite. The local workspace
provider is explicitly development-only.

[Open the export
diagram](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/diagrams/11-controlled-export.md).
It separates workspace publication, internal receipt recording, and the
later ZIP download. This page describes inspected implementation at
`5e2fa6a`; it does not establish target-environment qualification.

## User actions and eligibility

The Export step contains revision history, review, and controlled
export, following the [five-step
workflow](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/docs/solutions/four-step-wizard-flow.md).
`mod_export_ui()` offers an actor selector, a logical destination field,
**Export image and code**, and **Download image and code ZIP**.
`mod_export_server()` sends the current revision identifier and version
to `new_export_service()`, then displays the result and receipt table.
Service errors appear as messages.

For a new export command, `.authorize_export_actor()` requires an active
`submission_sync_actor` with at least one of `clinical_scientist`,
`statistical_programmer`, `biostatistician`, or `export_publisher`. A
creator can export; the independent-reviewer restriction does not apply
here. Local actor selection does not authenticate a person, despite the
authorization error referring to an authenticated actor.

`.assert_exportable_revision()` compares the expected version with the
stored version and allows only `Draft`, `Verified`, or `Reviewed`. It
excludes `Rejected` and `Experimental/Draft`.
`repository$get_artifact_bundle()` must find an accepted bundle; status
alone is insufficient. A normal failed execution without acceptance
therefore has no exportable pair. See
[execution](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/06-script-generation-execution.md)
and [human
review](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/09-human-review-decisions.md)
for their separate boundaries.

## Publication and retained records

`export_revision()` in
[export_service.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/export_service.R)
performs these operations:

1.  Validate identifiers and derive a receipt identifier from the
    idempotency key. If that receipt already exists for the revision,
    return it immediately.
2.  Authorize the actor, check status and version, and obtain the
    accepted script and image hashes. Read their bytes through the
    artifact store. `local_artifact_store()$get()` verifies content
    hashes before returning bytes.
3.  Inspect the destination for an already-published pair. Otherwise
    stage the bytes through `workspace_provider$stage_bundle()`.
4.  After staging, retrieve and authorize the actor again, reread the
    revision, and recheck status and version. If revision hashes differ
    from the accepted bundle, quarantine the stage as `stale-revision`
    and abort.
5.  Publish the stage, compare final hashes with the accepted bundle,
    and record the internal receipt.

[local_workspace_provider()](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/provider_workspace_local.R)
writes `script.R`, `plot.png`, and a temporary `manifest.json` beneath
`.staging/<export_id>`. `publish_staged()` hashes both staged files
again. Changed bytes cause quarantine and failure. It removes the
manifest, moves the directory to its final location, and checks the
published hashes. Only the script and PNG remain in the published
directory.

`record_export_receipt()` in
[evidence_repository_sqlite.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/evidence_repository_sqlite.R)
checks receipt hashes against the immutable revision and writes the
receipt identifier, revision identifier, logical destination,
script/image hashes, timestamp, and idempotency key. This record stays
internal; no receipt, selected input data, review decisions, or
environment record accompanies the detached files.

## Retries, recovery, and downloads

The receipt lookup makes repeated successful commands return the stored
receipt without republishing. That early return precedes fresh actor
authorization, revision-version checks, and destination inspection. It
is not proof that the files remain present or unchanged. The returned
database row also lacks the `code_path` and `image_path` supplied by a
first publication. The module stores that row in `last_export`, so a
repeated successful command can leave ZIP creation without the paths it
expects.

Publication precedes receipt recording. If receipt recording fails after
publication, a retry can inspect the existing pair, compare hashes, and
record the receipt.
[reconcile_workspace_exports()](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/export_reconciliation.R)
separately quarantines leftover staging directories; it does not
complete their publication or create receipts. It is not wired into
automatic application startup.

`.write_export_zip()` in
[mod_export.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/mod_export.R)
copies the last successful export’s two files and invokes
[`utils::zip()`](https://rdrr.io/r/utils/zip.html). Download is a
separate operation: it does not rerun actor, status, version, or hash
checks. `last_export` is not reset when the current revision changes,
while the ZIP filename uses the current revision identifier. After
navigation or a failed later export, filename and packaged revision can
differ. The ZIP is therefore not a new controlled-publication decision.

## Policy differences and operating limits

Strategy requires unreviewed output to remain labeled `Draft`, and the
[draft-status design
learning](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/docs/solutions/draft-status-badge.md)
describes dual approval for post-approval export. Current detached files
have no export-added review label, and service eligibility includes
unreviewed revisions. These differences require a policy decision; this
documentation does not resolve them.

The pair is also not a complete reproduction package.
[compile_boxplot_script()](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/boxplot_compiler.R)
includes package-installation code and an absolute synthetic-example CSV
fallback path. Export copies that script unchanged. Omission of retained
input records does not remove this internal path or ensure another
machine reproduces the accepted plot.

Logical tokens reject traversal syntax and Windows reserved names;
destinations must be registered existing roots. The provider checks the
root for links/reparse points but does not establish qualified
descendant-path, filesystem-race, access-control, or custody guarantees.
[app_server()](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/app_server.R)
creates the workspace under temporary storage. See [integrity and
lifecycle](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/12-integrity-lifecycle-backup.md)
for retained-evidence controls.

## Inspected coverage

Tests inspected:
[service](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-export-service.R),
[workspace
contract](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-provider-workspace-contract.R),
[module and
ZIP](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-mod-export.R),
[reconciliation](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-export-reconciliation.R),
and [browser
harness](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-app-export-browser.R).
They cover publication, receipts, repeated commands,
actor/version/destination denials, experimental exclusion, missing
bundles, ZIP contents, and orphan staging. No R tests or browser
journeys were run for this documentation change; coverage inspection is
not a passing result.

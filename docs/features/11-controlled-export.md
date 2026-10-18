# Controlled export of plot images and R scripts

Controlled export publishes the accepted `plot.png` and `script.R` pair to a registered workspace destination and retains a receipt inside the evidence repository. The current implementation permits only `Reviewed` revisions with an accepted artifact bundle. The local workspace provider is explicitly development-only.

[Open the export diagram](diagrams/11-controlled-export.html). The historical diagram separates workspace publication, internal receipt recording, and ZIP creation; its labels show the earlier two-button interface. The publication details were originally inspected at `5e2fa6a`; the interface and download description include the combined action. This guide does not establish target-environment qualification.

## User actions and eligibility

The Export step contains revision history, review, and controlled export, following the [five-step workflow](../solutions/four-step-wizard-flow.md). `mod_export_ui()` offers an actor selector, a logical destination field, and one **Export and download ZIP** action, disabled until both approvals are recorded. `mod_export_server()` sends the current revision identifier and version to `new_export_service()`, then creates the ZIP and displays the result and receipt table. Export or ZIP errors appear as messages.

For a new export command, `.authorize_export_actor()` requires an active `submission_sync_actor` with at least one of `clinical_scientist`, `statistical_programmer`, `biostatistician`, or `export_publisher`. A creator can export; the independent-reviewer restriction does not apply here. Local actor selection does not authenticate a person, despite the authorization error referring to an authenticated actor.

`.assert_exportable_revision()` compares the expected version with the stored version and allows only `Reviewed`. `repository$get_artifact_bundle()` must find an accepted bundle; status alone is insufficient. A normal failed execution without acceptance therefore has no exportable pair. See [execution](06-script-generation-execution.md) and [human review](09-human-review-decisions.md) for their separate boundaries.

## Publication and retained records

`export_revision()` in [export_service.R](../../R/export_service.R) performs these operations:

1. Validate identifiers and derive a receipt identifier from the idempotency key.
2. Authorize the actor and require the current revision version to be `Reviewed`. If the matching receipt already exists, return it. Otherwise, obtain the accepted script and image hashes. Read their bytes through the artifact store. `local_artifact_store()$get()` verifies content hashes before returning bytes.
3. Inspect the destination for an already-published pair. Otherwise stage the bytes through `workspace_provider$stage_bundle()`.
4. After staging, retrieve and authorize the actor again, reread the revision, and recheck status and version. If revision hashes differ from the accepted bundle, quarantine the stage as `stale-revision` and abort.
5. Publish the stage, compare final hashes with the accepted bundle, and record the internal receipt.

[local_workspace_provider()](../../R/provider_workspace_local.R) writes `script.R`, `plot.png`, and a temporary `manifest.json` beneath `.staging/<export_id>`. `publish_staged()` hashes both staged files again. Changed bytes cause quarantine and failure. It removes the manifest, moves the directory to its final location, and checks the published hashes. Only the script and PNG remain in the published directory.

`record_export_receipt()` in [evidence_repository_sqlite.R](../../R/evidence_repository_sqlite.R) checks receipt hashes against the immutable revision and writes the receipt identifier, revision identifier, logical destination, script/image hashes, timestamp, and idempotency key. This record stays internal; no receipt, selected input data, review decisions, or environment record accompanies the detached files.

## Retries, recovery, and downloads

The receipt lookup makes repeated successful commands inspect and hash-check the previously published pair, then return the same complete path-bearing result without republishing after fresh actor, status, and revision-version checks. Reusing the idempotency key for another destination is rejected.

Publication precedes receipt recording. If receipt recording fails after publication, a retry can inspect the existing pair, compare hashes, and record the receipt. [reconcile_workspace_exports()](../../R/export_reconciliation.R) separately quarantines leftover staging directories; it does not complete their publication or create receipts. It is not wired into automatic application startup.

`.write_export_zip()` in [mod_export.R](../../R/mod_export.R) verifies that the export returned by the service belongs to the current revision, copies its two files, and invokes `utils::zip()`. Every download first calls the export service, which rechecks the actor, status, version, and hashes. A successful retry reuses the existing receipt and published pair.

## Policy differences and operating limits

Strategy and the [draft-status design learning](../solutions/draft-status-badge.md) require both independent approvals before export. The service enforces this by accepting only `Reviewed` revisions.

The pair is not a complete reproduction package. [compile_boxplot_script()](../../R/boxplot_compiler.R) requires callers to supply `analysis_data` and the controlled package environment. Export does not include retained input records or an environment lockfile, so the pair alone does not ensure another machine reproduces the accepted plot.

Logical tokens reject traversal syntax and Windows reserved names; destinations must be registered existing roots. The provider checks the root for links/reparse points but does not establish qualified descendant-path, filesystem-race, access-control, or custody guarantees. [app_server()](../../R/app_server.R) creates the workspace under temporary storage. See [integrity and lifecycle](12-integrity-lifecycle-backup.md) for retained-evidence controls.

## Inspected coverage

Tests: [service](../../tests/testthat/test-export-service.R), [workspace contract](../../tests/testthat/test-provider-workspace-contract.R), [module and ZIP](../../tests/testthat/test-mod-export.R), [reconciliation](../../tests/testthat/test-export-reconciliation.R), and [browser harness](../../tests/testthat/test-app-export-browser.R). They cover Reviewed-only eligibility, publication, receipts, repeated commands, actor/version/destination denials, missing bundles, ZIP contents, and orphan staging.

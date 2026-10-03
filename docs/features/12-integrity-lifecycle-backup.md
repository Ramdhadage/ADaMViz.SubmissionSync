# Evidence integrity, lifecycle history, and backup and restore

The local evidence repository retains revision history and checks relationships between records, lifecycle events, and stored artifacts. Its backup and restore functions operate on that local evidence package. These mechanisms detect several forms of local modification; they do not establish qualified audit-record custody or a durable study repository.

[Open the integrity and recovery diagram](diagrams/12-integrity-lifecycle-backup.html).

## Records and identity

[`sqlite_evidence_repository()`](../../R/evidence_repository_sqlite.R) stores plots, revisions, attempts and outcomes, evidence entries, accepted artifact bundles, reviewer decisions, export receipts, command keys, and a status/version projection. Numbered [SQL migrations](../../inst/sql/migrations/) apply in version order and record successful versions in `schema_migrations`. Foreign keys are enabled for each repository connection. SQL constraints enforce revision numbering, permitted status and decision values, unique command/event keys, and record relationships.

[`canonical_serialize()` and `canonical_hash()`](../../R/canonical_serialization.R) sort named list elements recursively and serialize compact JSON before hashing. Evidence details have a SHA-256 content hash. Reviewer decision records have a separate hash tied to a lifecycle event. These hashes serve different purposes; a lifecycle chain does not contain every repository row.

[`local_artifact_store()`](../../R/artifact_store_local.R) stores raw bytes at `<root>/<first-two-hash-characters>/<sha256>`. `put()` writes to a temporary file, checks its bytes, and moves it into place. Existing objects are verified before reuse. `get()` verifies an object's hash before returning its bytes. Code and image artifacts therefore have byte-level identity independent of their display filenames.

## Lifecycle writes and recovery

`.append_lifecycle_event()` creates a per-plot sequence spanning its revisions. Each event binds the plot and revision identifiers, sequence, event type, serialized payload, previous hash, and timestamp. The first event starts from a 64-character zero hash. A separate `chain-root.json` records the latest sequence and chain hash for each plot.

Repository commands use `.with_repository_lock()`: a companion SQLite `.lock` database holds a `BEGIN IMMEDIATE` transaction while the operation runs. Repository writes use database transactions. Lifecycle transitions compare `expected_version` with the current projection, so stale commands fail. Idempotency keys bind a canonical command hash: repeating the same command is tolerated, while reusing its key for different content fails.

The database transaction completes before the sidecar root is published. If publication fails, an exact replay of the previously registered command can reconcile the root. A new lifecycle command is blocked while roots disagree. Reconciliation refuses a root that is newer than the database or conflicts at the same sequence. This addresses a recoverable publication failure without silently accepting arbitrary rollback.

`rebuild_projections()` reconstructs revision status and version from initial statuses and ordered lifecycle payloads. It replaces the status projection; it does not reconstruct missing evidence, artifacts, attempts, reviewer decisions, or export receipts. Historical revision update and deletion methods explicitly reject those operations. Direct filesystem or SQL access remains outside these API restrictions.

## What integrity verification checks

`verify_integrity()` checks foreign keys; per-plot event order and chain hashes; sidecar roots and persisted plot membership; reconstructed status/version projections; evidence-detail hashes; accepted-bundle hashes against revision hashes; reviewer hashes, decision identifiers, and lifecycle bindings; and receipt code/image hashes against revision hashes. When an artifact store is attached, it also verifies referenced code and image bytes.

`require_artifacts = TRUE` rejects a nonempty revision repository without an artifact store. The default is `FALSE`. The verifier does not independently recalculate plotting statistics, authenticate reviewers, or compare exported workspace files with receipts. Its evidence-entry hash checks do not prove that every expected evidence record exists. Analytical hashes are checked as recorded relationships, rather than through a separate content-addressed analytical artifact check.

## Backup and restore sequence

`backup(destination)` requires an empty destination, holds the repository lock, and verifies source integrity with `require_artifacts = TRUE`. It stages a database copy using `RSQLite::sqliteCopyDatabase()`, copies or creates the sidecar root, and copies the artifact directory when attached. The staged repository is verified before publication.

`backup-manifest.json` records the database SHA-256, chain-root SHA-256, table row counts, and completion timestamp. It does not enumerate or hash every artifact file and does not sign the package. The staged directory moves into the destination after verification and manifest creation. A failed operation removes its staging directory.

`restore_evidence_repository(backup_path, destination)` checks the completion manifest, database/root hashes, and recorded row counts before copying into a new staging directory. It attaches an artifact store when the backup contains an `artifacts` directory, verifies the staged repository, and publishes to an empty destination only after success. It returns a repository pointing at the restored paths.

**Restore coverage gap:** restore calls `verify_integrity()` with its default argument. If the complete artifact directory is absent, no artifact store is attached and metadata verification can proceed. Corrupt referenced bytes in a present artifact directory are detected. The manifest therefore does not establish that a restored package contains all artifact bytes.

## Cleanup and operational limits

`cleanup_orphan_artifacts(minimum_age_seconds = 3600)` locks the repository and preserves code/image hashes referenced by revisions. Cleanup considers only files matching the two-level content-addressed layout and removes unreferenced files old enough to meet the threshold. It does not implement evidence retention or study deletion. Its reference scope is the attached repository; sharing an artifact root with another repository would not protect that other repository's references.

The [application coordinator](../../R/app_server.R) uses a temporary `assurance-session-` root unless `repository_root` is supplied. Backup, restore, cleanup, and recovery exist as callable operations; no automatic scheduled backup or cross-session discovery is established by this workflow. Persistent storage configuration, retention policy, access control, independently protected roots, and qualified target-environment custody remain unresolved.

## Inspected test coverage

[Repository tests](../../tests/testthat/test-evidence-repository-sqlite.R) cover chain corruption, event omission, root rollback, projection rebuilds, evidence/decision modification, publication retry, command reuse, migrations, serialized writes, and pending artifact-hash binding. [Artifact tests](../../tests/testthat/test-artifact-store-contract.R) cover corruption, reference-preserving cleanup, layout filtering, and resolved roots. [Backup/restore tests](../../tests/testthat/test-backup-restore.R) cover round trips, modified/incomplete backups, concurrent lifecycle writes, empty repositories, required artifact reconciliation during backup, and corrupt artifact bytes during restore. These tests were inspected, not executed for this documentation change.

Related: [execution evidence](07-verification-revision-evidence.md), [correction traceability](10-correction-revision-traceability.md), and [controlled export](11-controlled-export.md).

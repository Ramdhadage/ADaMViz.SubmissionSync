PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS schema_migrations(version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL);
INSERT OR IGNORE INTO schema_migrations(version, applied_at) VALUES (1, strftime('%Y-%m-%dT%H:%M:%fZ','now'));
CREATE TABLE IF NOT EXISTS plots(plot_id TEXT PRIMARY KEY NOT NULL, created_at TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS revisions(
 revision_id TEXT PRIMARY KEY NOT NULL, plot_id TEXT NOT NULL REFERENCES plots(plot_id),
 revision_number INTEGER NOT NULL CHECK(revision_number > 0), creator_id TEXT NOT NULL,
 parent_revision_id TEXT REFERENCES revisions(revision_id), correction_rationale TEXT,
 correction_provenance TEXT, spec_hash TEXT NOT NULL, code_hash TEXT NOT NULL,
 initial_status TEXT NOT NULL CHECK(initial_status IN ('Draft','Experimental/Draft')),
 created_at TEXT NOT NULL, image_hash TEXT, analytical_hash TEXT,
 UNIQUE(plot_id, revision_number)
);
CREATE TABLE IF NOT EXISTS lifecycle_events(
 event_id TEXT PRIMARY KEY NOT NULL, plot_id TEXT NOT NULL REFERENCES plots(plot_id),
 revision_id TEXT NOT NULL REFERENCES revisions(revision_id), event_sequence INTEGER NOT NULL,
 event_type TEXT NOT NULL, payload_json TEXT NOT NULL, previous_hash TEXT NOT NULL,
 chain_hash TEXT NOT NULL, created_at TEXT NOT NULL, idempotency_key TEXT NOT NULL UNIQUE,
 UNIQUE(plot_id, event_sequence)
);
CREATE TABLE IF NOT EXISTS revision_projection(
 revision_id TEXT PRIMARY KEY REFERENCES revisions(revision_id), status TEXT NOT NULL CHECK(status IN ('Draft','Experimental/Draft','Verified','Reviewed','Rejected')),
 version INTEGER NOT NULL CHECK(version > 0), updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS attempts(
 attempt_id TEXT PRIMARY KEY, revision_id TEXT NOT NULL REFERENCES revisions(revision_id),
 run_id TEXT NOT NULL, created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS attempt_outcomes(
 attempt_id TEXT PRIMARY KEY REFERENCES attempts(attempt_id), outcome TEXT NOT NULL CHECK(outcome IN ('succeeded','failed','cancelled','timed_out')),
 created_at TEXT NOT NULL, idempotency_key TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS evidence_entries(
 evidence_id TEXT PRIMARY KEY, revision_id TEXT NOT NULL REFERENCES revisions(revision_id),
 evidence_type TEXT NOT NULL, outcome TEXT NOT NULL, details_json TEXT NOT NULL,
 content_hash TEXT NOT NULL, created_at TEXT NOT NULL,
 idempotency_key TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS artifact_bundles(
 bundle_id TEXT PRIMARY KEY, revision_id TEXT NOT NULL UNIQUE REFERENCES revisions(revision_id),
 code_hash TEXT NOT NULL, image_hash TEXT NOT NULL, analytical_hash TEXT NOT NULL,
 accepted_at TEXT NOT NULL, idempotency_key TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS review_decisions(
 decision_id TEXT PRIMARY KEY, revision_id TEXT NOT NULL REFERENCES revisions(revision_id),
 actor_id TEXT NOT NULL, role TEXT NOT NULL CHECK(role IN ('statistical_programmer','biostatistician')),
 decision TEXT NOT NULL CHECK(decision IN ('approved','rejected')), authorization_json TEXT NOT NULL,
 comment TEXT,
 code_hash TEXT NOT NULL, image_hash TEXT NOT NULL, analytical_hash TEXT NOT NULL,
 created_at TEXT NOT NULL, idempotency_key TEXT NOT NULL UNIQUE, record_hash TEXT NOT NULL,
 UNIQUE(revision_id, actor_id)
);
CREATE TABLE IF NOT EXISTS export_receipts(
 receipt_id TEXT PRIMARY KEY, revision_id TEXT NOT NULL REFERENCES revisions(revision_id),
 destination_id TEXT NOT NULL, code_hash TEXT NOT NULL, image_hash TEXT NOT NULL,
 created_at TEXT NOT NULL, idempotency_key TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS command_keys(
 idempotency_key TEXT PRIMARY KEY, command_hash TEXT NOT NULL, created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_lifecycle_events_revision
 ON lifecycle_events(revision_id, event_sequence);
CREATE INDEX IF NOT EXISTS idx_attempts_revision
 ON attempts(revision_id, created_at, attempt_id);
CREATE INDEX IF NOT EXISTS idx_evidence_entries_revision
 ON evidence_entries(revision_id, created_at, evidence_id);
CREATE INDEX IF NOT EXISTS idx_export_receipts_revision
 ON export_receipts(revision_id, created_at, receipt_id);

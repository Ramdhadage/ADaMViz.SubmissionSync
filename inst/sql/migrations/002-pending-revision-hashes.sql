ALTER TABLE revisions RENAME COLUMN image_hash TO image_hash_required;
ALTER TABLE revisions RENAME COLUMN analytical_hash TO analytical_hash_required;
ALTER TABLE revisions ADD COLUMN image_hash TEXT;
ALTER TABLE revisions ADD COLUMN analytical_hash TEXT;
UPDATE revisions
SET image_hash = image_hash_required,
    analytical_hash = analytical_hash_required;
ALTER TABLE revisions DROP COLUMN image_hash_required;
ALTER TABLE revisions DROP COLUMN analytical_hash_required;

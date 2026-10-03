# Concepts

Shared domain vocabulary for this project — entities, named processes,
and status concepts with project-specific meaning. Seeded with core
domain vocabulary, then accretes as ce-compound and ce-compound-refresh
process learnings; direct edits are fine. Glossary only, not a spec or
catch-all.

## Plot generation

### Confirmed plot specification

The scientist-approved plot type, variables, and relevant settings from
which the application deterministically generates R code.

### Plot revision

An immutable review unit that links the permitted input, confirmed plot
specification, executed R code, resulting plot, validation evidence, and
reviewer decisions.

Each reviewer independently approves or rejects a revision, and both
approvals are required for post-approval export eligibility. The
complete status lifecycle, correction path, and relationship to
draft-only export remain open.

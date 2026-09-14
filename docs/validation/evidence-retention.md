# Evidence retention template

This template separates development evidence from sponsor-controlled validation
records. Local POC evidence does not establish intended-use validation.

| Evidence class | Example records | Retention owner | Current POC status |
| --- | --- | --- | --- |
| Development evidence | Unit tests, provider-contract tests, local static checks, local package checks | Product team | In progress |
| POC operational evidence | SQLite revisions, lifecycle events, artifact hashes, export receipts, local backups | Product team | Local only |
| Human review evidence | Statistical-programmer and biostatistician decisions against identical revision hashes | Sponsor quality system | Procedure required |
| Target-environment validation evidence | Approved protocol, qualified identity, controlled workspace ACLs, UAT, deviations, release authorization | Sponsor quality system | Not started |

## U9 retention notes

- Internal receipts retain revision identifier, destination identifier, code hash,
  image hash, timestamp, and idempotency key.
- Detached exports retain only the image and R script. They intentionally do not
  embed lifecycle status, reviewer identity, prompt text, scope, or internal
  paths.
- Retention periods, backup custody, access reviews, and release authorization
  remain sponsor-controlled procedures.

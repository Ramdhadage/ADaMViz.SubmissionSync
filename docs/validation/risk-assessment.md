# Initial risk assessment

This document is a development evidence scaffold for ADaMViz SubmissionSync.
It does not establish intended-use validation or target-environment
qualification.

| Risk | Initial control | Evidence owner |
| --- | --- | --- |
| Unresolved clinical plotting choices produce a misleading display | Closed specification, explicit confirmation, and blocking validation | Product and statistical programming |
| Sensitive values cross a provider boundary | Minimum-necessary context, injected providers, redaction, and synthetic-only POC data | Security and quality |
| Unreproducible output | Recorded specification, generated code, package versions, and environment fingerprint | Statistical programming |
| Local evidence is mistaken for validation | Separate development, POC operational, and validation evidence classifications | Sponsor quality system |
| Controlled export writes to an unapproved path or overwrites an artifact | Logical workspace identifiers, safe export tokens, registered roots, no overwrite, staged pair publication, final hash verification, and internal receipts | Product and security |
| A mismatched or partial export is treated as accepted | Accepted-bundle lookup, artifact-store hash verification, final file hash checks, receipt hash binding, and staged-export reconciliation | Product and statistical programming |
| `Experimental/Draft` output leaves the contained POC path | Export service blocks non-exportable statuses before staging or publication | Product |

## Residual U9 risks

- Local workspace roots are development evidence only. Sponsor-controlled ACLs,
  filesystem support, and target-environment identity must be qualified outside
  this POC.
- Reparse-point and volume identity checks are provider responsibilities in the
  qualified target. The local provider rejects symbolic-link roots and fails
  closed on unregistered destinations, unsafe identifiers, and collisions.
- Exported files are detached image and R-code artifacts. Status, review,
  prompt, scope, and internal evidence remain in repository receipts and are not
  embedded in the files.

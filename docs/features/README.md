# Feature documentation

These pages describe the implementation inspected at source commit `5e2fa6a` on 2026-10-04. They explain the active Shiny workflow and separately callable services, including where those paths differ. They do not add requirements or establish clinical, regulatory, or target-environment validation.

Read the pages in order for the full input-to-export workflow, or open a feature directly.

| Feature | Documentation | Diagram |
| --- | --- | --- |
| 01 | [CSV and Excel uploads, data snapshots, and input identity](01-uploads-snapshots-input-identity.md) | [Open diagram](diagrams/01-uploads-snapshots-input-identity.html) |
| 02 | [BDS data profiling and plotting eligibility checks](02-bds-profiling-eligibility.md) | [Open diagram](diagrams/02-bds-profiling-eligibility.html) |
| 03 | [Confirming parameters, units, analysis values, visits, and treatments](03-confirming-analysis-selections.md) | [Open diagram](diagrams/03-confirming-analysis-selections.html) |
| 04 | [Longitudinal boxplots: statistical summaries and visual conventions](04-longitudinal-boxplot-statistics.md) | [Open diagram](diagrams/04-longitudinal-boxplot-statistics.html) |
| 05 | [Fixed and free Y scales: governed and experimental plotting paths](05-fixed-free-y-scales.md) | [Open diagram](diagrams/05-fixed-free-y-scales.html) |
| 06 | [Deterministic R script generation and subprocess execution](06-script-generation-execution.md) | [Open diagram](diagrams/06-script-generation-execution.html) |
| 07 | [Execution verification and revision evidence](07-verification-revision-evidence.md) | [Open diagram](diagrams/07-verification-revision-evidence.html) |
| 08 | [Reproducing plots from retained inputs and execution records](08-reproducing-retained-results.md) | [Open diagram](diagrams/08-reproducing-retained-results.html) |
| 09 | [Human review: reviewer roles, approvals, and rejections](09-human-review-decisions.md) | [Open diagram](diagrams/09-human-review-decisions.html) |
| 10 | [Correction revisions and traceability to earlier results](10-correction-revision-traceability.md) | [Open diagram](diagrams/10-correction-revision-traceability.html) |
| 11 | [Controlled export of plot images and R scripts](11-controlled-export.md) | [Open diagram](diagrams/11-controlled-export.html) |
| 12 | [Evidence integrity, lifecycle history, and backup and restore](12-integrity-lifecycle-backup.md) | [Open diagram](diagrams/12-integrity-lifecycle-backup.html) |

## Reading the evidence

The [documentation verification record](verification.md) lists the observed checks and the remaining RStudio commit checkpoint.

Each page links to implementation files and names the relevant functions. Test references describe inspected coverage; they are not evidence that those tests passed during this documentation work. Documented design intent is identified separately when it differs from code.

`Verified` means the execution service accepted its recorded checks. `Reviewed` requires the recorded human decisions. Replay is a separate service operation. Neither status establishes formal validation or regulatory approval.

The diagrams use the application's navy and slate colors and Inter font stack from [app_theme.R](../../R/app_theme.R), with technical labels in Geist Mono. Each HTML file includes its SVG and styles. Public Google Fonts stylesheets may supply the exact fonts; local fallbacks keep the diagrams readable offline. Diagrams retain their canvas width inside a horizontal scroller on narrow screens.

## Known boundaries across features

- Upload and profile checks establish supported structure and selected-record compatibility. They do not prove synthetic provenance or remove patient identifiers.
- Fixed-scale revisions use the governed subprocess path. Free-scale revisions remain `Experimental/Draft` and do not submit that governed attempt.
- The UI reconstructs its preview separately from the accepted worker PNG. Human review binds recorded artifact identities.
- Reviewer identities in the current UI come from a selectable local catalog. Production authentication and qualified record custody remain outside this implementation.
- The export service permits accepted bundles in `Draft`, `Verified`, or `Reviewed` status. Detached files do not carry an enforced draft status label.
- Local evidence integrity and backup mechanisms exist. The app's temporary storage, operational recovery, retention custody, and target-environment qualification still need explicit decisions.

The [architecture map](../../ARCHITECTURE.md) explains component boundaries and current gaps. [Strategy](../product/STRATEGY.md) remains the authority for product scope and terminology. When a page needs revision, inspect the linked implementation and tests together, then update its diagram and this source-baseline note.

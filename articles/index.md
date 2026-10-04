# Articles

### Getting started

- [Getting started: from data upload to plot
  export](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/ADaMViz.SubmissionSync.md):

### Feature documentation

Current implementation guides for the input-to-export workflow.

- [CSV and Excel uploads, data snapshots, and input
  identity](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/01-uploads-snapshots-input-identity.md):

  The Data step reads one CSV or Excel file into an in-memory study-data
  provider, checks the supported upload structure, and pins a
  content-verified snapshot. Later revisions retain the selected
  analysis records and input identities. These mechanisms identify what
  was read and executed; they do not establish synthetic provenance,
  de-identification, or full ADaM conformance.

- [BDS data profiling and plotting
  eligibility](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/02-bds-profiling-eligibility.md):

  The application checks whether selected records support its
  longitudinal numeric BDS boxplot before generating a result. Passing
  this check establishes compatibility with one plotting pattern. The
  result explicitly records `dataset_conformance = "not_assessed"`; it
  does not establish full ADaM conformance, data provenance, or
  statistical suitability for an intended clinical analysis.

- [Confirming analysis
  selections](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/03-confirming-analysis-selections.md):

  The Confirm step turns scientist-selected scope into a hashed plot
  specification. The active upload workflow retains the question but
  does not interpret it to choose a parameter, Y variable, unit, visit,
  or treatment. Its choices come from the pinned dataset, and the
  scientist confirms the settings before generation.

- [Longitudinal boxplots: statistical summaries and visual
  conventions](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/04-longitudinal-boxplot-statistics.md):

  The implemented figure summarizes one confirmed numeric analysis
  variable across ordered visits, with a separate facet for each
  selected treatment. Statistical calculations happen before rendering.
  The plot draws those calculated values directly, so `ggplot2` does not
  choose a second quartile or whisker definition.

- [Fixed and free Y
  scales](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/05-fixed-free-y-scales.md):

  Fixed Y scales use the governed execution path. Free Y scales require
  an explicit acknowledgement and create an `Experimental/Draft`
  revision with a generated script and an in-process preview. The
  free-scale revision does not receive a governed subprocess attempt,
  execution verification, human review, or controlled export.

- [Deterministic R script generation and subprocess
  execution](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/06-script-generation-execution.md):

  The fixed-scale plotting path compiles a confirmed specification into
  application-owned R code, then runs that code synchronously in a
  separate R process. The script, selected records, specification, and
  execution harness have recorded identities. A completed worker run
  supplies evidence for verification; it does not establish statistical
  approval or human review.

- [Execution verification and revision
  evidence](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/07-verification-revision-evidence.md):

  A governed fixed-scale revision becomes `Verified` when the execution
  service records passing checks, accepts its artifact bundle, completes
  the attempt, and promotes the revision. `Verified` describes automated
  execution evidence. Human approval and reproduction of a retained
  result are separate operations.

- [Reproducing plots from retained inputs and execution
  records](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/08-reproducing-retained-results.md):

  The separately callable reproducibility service reruns a revision’s
  retained R script against its retained selected records and compares
  the new result with stored identities. Replay does not run
  automatically during confirmation, human review, or export. It returns
  evidence for a caller to inspect; it does not promote a revision,
  replace its accepted artifacts, or approve a plot.

- [Human review: reviewer roles, approvals, and
  rejections](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/09-human-review-decisions.md):

  Human review binds decisions to one revision’s retained script, image,
  and analytical output. A revision reaches `Reviewed` only after
  approvals from distinct active non-creator actors covering both
  `statistical_programmer` and `biostatistician` roles. Successful
  execution alone produces `Verified`; it does not supply either human
  approval.

- [Correction revisions and traceability to earlier
  results](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/10-correction-revision-traceability.md):

  A correction creates a new revision linked to a closed result. The
  earlier revision remains `Reviewed` or `Rejected`, with its existing
  evidence and decisions. The successor receives its own specification,
  script, artifacts, execution evidence, and review decisions. Approval
  of the parent does not approve the correction.

- [Controlled export of plot images and R
  scripts](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/11-controlled-export.md):

  Controlled export publishes the accepted `plot.png` and `script.R`
  pair to a registered workspace destination and retains a receipt
  inside the evidence repository. The current implementation permits
  `Draft`, `Verified`, and `Reviewed` revisions with an accepted
  artifact bundle. Human approval is not a service prerequisite. The
  local workspace provider is explicitly development-only.

- [Evidence integrity, lifecycle history, and backup and
  restore](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/12-integrity-lifecycle-backup.md):

  The local evidence repository retains revision history and checks
  relationships between records, lifecycle events, and stored artifacts.
  Its backup and restore functions operate on that local evidence
  package. These mechanisms detect several forms of local modification;
  they do not establish qualified audit-record custody or a durable
  study repository.

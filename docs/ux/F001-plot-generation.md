# F001: Plot Generation

This document defines the first POC workflow and its behavior. It does not define screen layout, visual styling, or control placement. The workflow starts with data upload, as clarified during brainstorming. Product boundaries and metrics come from the [strategy](../product/STRATEGY.md) and [product contract](../product/product-contract.md).

## 1. User

- **Primary user:** Clinical scientist answering a regulatory or internal clinical question.
- **Supporting reviewers:** Statistical programmer and biostatistician.
- Additional user roles, permissions, and responsibilities are not defined in the product contract.

## 2. User Goal

Turn a clinical question into a statistically appropriate, inspectable, reproducible visualization and exact R script, with qualified human review and traceability across the prompt, permitted input data, executed code, visual output, review status, and validation evidence.

## 3. Preconditions

- The clinical scientist has data permitted for the POC: public, synthetic, or properly de-identified data.
- The application supports Excel and CSV uploads. ADaM and tabular data are in scope; the specific structures and plot patterns remain to be defined.
- The application uses user authentication, data validation checks, and de-identification guidance to establish whether uploaded data meet the permitted-data boundary.
- The scientist has a visualization question to ask after uploading the data.
- The application can receive the uploaded data and propose plotting choices.

Confidential patient-level data is outside the POC boundary until the product and outputs are validated, privacy and security controls are qualified, and the client approves its use.

## 4. Main User Flow

1. The clinical scientist uploads permitted ADaM or tabular data in Excel or CSV format. Upload is the first step in the workflow.
2. The scientist asks a visualization question about the uploaded data.
3. The application proposes plotting choices for that question.
4. The scientist reviews and confirms the plot type, variables, and relevant visualization parameters or settings. If a choice is ambiguous or needs refinement, the application provides feedback and the scientist adjusts the choices before proceeding.
5. The application validates the selected data. A record that does not conform to the expected structure, has missing or invalid values, or fails plot-generation validation is unsupported. Any unsupported record blocks the entire selected input before code generation and plot execution.
6. A deterministic compiler generates R code from the confirmed specification.
7. The exact generated script runs in a controlled process to produce the plot.
8. Automated checks assess code correctness, data integrity, result accuracy, and reproducibility. Domain experts will define specific checks and passing thresholds.
9. Independent reviewers decide whether to approve or reject the immutable revision. Both reviewers must approve for the revision to be eligible for the post-approval export.
10. After both approvals, an eligible revision can be exported with its exact R script for subsequent human review.

The strategy also allows unreviewed outputs to be exported as `Draft`. The relationship between this draft-only path and the post-approval export remains open; see [Open Questions](#13-open-questions).

## 5. Alternative Flows

- **Choices need revision:** The user can refine the question or proposed choices before confirming them. If a choice is ambiguous, the application provides feedback and allows adjustment. Whether a new proposal replaces or versions a prior proposal remains open.
- **Unsupported records:** If any record in the selected input is unsupported, the application blocks the entire input from code generation and plot execution.
- **Verification does not pass:** The failed check is retained. The revision status and the correction or retry path remain open.
- **Reviewer rejects:** The rejection and subsequent actions are retained. The user can address the feedback and make corrections; whether this creates a successor revision and the exact return path remain open.
- **Revision is not eligible for post-approval export:** The post-approval export is unavailable until both reviewers approve. The separate draft-only export path and its relationship to this gate remain open.

## 6. Error States

The workflow explicitly requires the entire selected input to stop before code generation and plot execution when any unsupported record is detected. Unsupported records include records that fail expected-structure, missing/invalid-value, or plot-specific validation checks.

Other failure points include:

- Upload data are unreadable or do not meet the permitted-data boundary.
- The question or proposed choices cannot be resolved for the selected data.
- Data validation, script compilation, or controlled execution fails.
- An automated check fails or a reproducibility rerun does not match.
- A reviewer rejects the revision.
- An export is attempted for a revision that is not eligible for the requested export path.

The application must not describe unsupported data as successfully processed. The precise user-facing explanations, recovery actions, and status effects for these failures remain to be defined.

## 7. Loading States

Potentially active operations include upload, plotting-choice proposal, data validation, compilation, controlled execution, automated checks, and export. Human review can remain pending while the reviewers act.

Wait limits will be set based on expected processing times. Cancellation should allow interruption of ongoing processes where applicable; how partially completed work is handled remains to be defined. Retry rules will specify eligible failure conditions, retry limits, and handling of errors during retries. Exact wait limits, cancellation behavior, retry conditions, and retry limits are still open.

## 8. Empty States

- **No data uploaded:** Initial workflow state; the first user task is to upload permitted data.
- **No question or confirmed choices:** No plot can proceed without a question and confirmed proposal. The exact prompt and recovery behavior are open.
- **No plot or verified revision:** No result is available until execution and checks complete.
- **No review decision:** Reviewer decisions have not yet been recorded for the revision.
- **No eligible revision:** No revision is available for the post-approval export unless both reviewers have approved it. A separate draft-only export may apply; its relationship to this state remains open.

Empty-state wording and visual presentation are not defined here.

## 9. Verification States

The product contract names `Draft`, `Experimental` or `draft`, and `Verified`. It associates `Verified` with a plot and reproducible R code, but does not define the full entry criteria or transitions. Unevaluated plot patterns must be labeled experimental or draft.

Automated verification covers code correctness, data integrity, result accuracy, and reproducibility. Domain experts will define the specific checks and passing thresholds. The status after a failed check and the criteria for entering `Verified` remain open. Do not infer that successful execution alone makes a revision `Verified`.

## 10. Review States

- The supporting reviewer roles are statistical programmer and biostatistician.
- Each reviewer independently approves or rejects the immutable revision, bringing their respective roles and expertise to the assessment.
- Both approvals are required for the revision to be eligible for export after review.
- After both approvals, export is for subsequent human review.
- A rejection is retained. The user can address reviewer feedback and make corrections; the precise lifecycle and successor-revision behavior remain open.
- The product contract does not define whether `Reviewed` means both reviewers approved, whether an `Approved` state exists, or how a rejection changes the revision lifecycle.
- Unreviewed exports, if available, must be labeled `Draft`. The exact relationship between that path and the export requiring both approvals remains open.

## 11. Traceability Information

The following information is retained and linked to the revision:

- User's visualization question and confirmed plotting choices.
- Identity and metadata for the permitted input data used by the run.
- Exact generated R script and evidence that this same script was executed.
- Plot and analytical results produced by that execution.
- Automated check outcomes and reproducibility evidence.
- Revision status and both reviewers' decisions.
- Package versions and execution environment details needed for reproducibility.
- Unique identifiers and metadata linking an exported script to its source revision.

The retention period will follow applicable regulatory requirements and organizational policies. The exact retention period, retained metadata fields, identifier scheme, and integrity mechanism remain to be defined.

## 12. Acceptance Criteria

### Confirmed by the workflow and product documents

- The primary flow begins with data upload, followed by the visualization question.
- Excel and CSV are supported upload formats; the supported ADaM/tabular structures and plot patterns remain to be defined.
- POC data are limited to public, synthetic, or properly de-identified data. User authentication, data validation checks, and de-identification guidance contribute to establishing this boundary.
- The scientist reviews and confirms the proposed plot type, variables, and relevant settings before validation and generation proceed.
- If any selected record fails expected-structure, missing/invalid-value, or plot-specific validation, the entire selected input is blocked before code generation and plot execution.
- R code is generated deterministically from the confirmed specification, and the exact generated script is executed in a controlled process.
- Automated checks cover code correctness, data integrity, result accuracy, and reproducibility; their evidence is linked to the run. Specific checks and pass thresholds remain open.
- Reviewers decide independently on an immutable revision. Both reviewers must approve before the revision is eligible for post-approval export.
- The post-approval export includes the exact R script used to produce the plot and is available for subsequent human review.
- If unreviewed outputs can be exported, they are labeled `Draft`; the relationship between this path and the post-approval export remains open.
- The question, input data, code, output, review status, and validation evidence remain traceable. The exported script is linked to its source revision by unique identifiers and metadata.
- Product-level targets remain those in the strategy: at least 80% first-pass reviewer acceptance, at least 80% exact reproducibility for `Reviewed` outputs, and median prompt-to-`Verified` time under one minute. Human-review turnaround is measured separately and has no target yet.

### Pending definition

Acceptance cannot be fully tested until the supported data and plot envelope, permitted-data checks, verification thresholds, status transitions, draft-only export relationship, detailed review lifecycle, and operational timing/retry rules are defined.

## 13. Open Questions

1. Which specific ADaM and tabular structures, columns, and plot patterns are supported beyond Excel and CSV as file formats?
2. Which authentication requirements, de-identification guidance, and data-validation criteria establish that an upload meets the permitted-data boundary?
3. What exact structure and plot-specific validation rules determine whether a record is unsupported, including which missing or invalid values block a run?
4. **Resolved (workflow behavior):** Refinement stays linear: going back and revising an earlier input replaces the current proposal in the flow; it does not create a separately versioned proposal. Audit-history and retention requirements remain open under Q9. See [the four-step wizard flow](../solutions/four-step-wizard-flow.md).
5. Which automated checks and measurable pass thresholds establish code correctness, data integrity, result accuracy, and reproducibility?
6. What are the exact meanings and transition criteria for `Draft`, `Experimental`, `Verified`, `Reviewed`, and approved outputs?
7. **Partially resolved:** The Plot result shows a `Draft · not reviewed` badge, and its info tooltip states that both independent approvals are required for post-approval export eligibility. This defines the review-status cue and approval gate only; whether unreviewed outputs can use a draft-only export path and how that path relates to post-approval export remain open. See [the draft status badge pattern](../solutions/draft-status-badge.md).
8. After rejection, what correction path applies, how is a successor immutable revision created, and what makes the reviewers independent for this workflow?
9. What is the retention period and exact metadata set, identifier scheme, and integrity mechanism for traceability?
10. What wait limits, cancellation behavior for partially completed work, retry conditions, and retry limits apply to each processing step?
11. What evaluation corpus, sample size, denominator, reviewer-calibration process, and criteria for a `material correction` will be used for the strategy's quality measures?

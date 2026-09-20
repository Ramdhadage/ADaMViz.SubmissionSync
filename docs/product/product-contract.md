# ADaMViz SubmissionSync Product Contract

**Source of truth:** [Product strategy](strategy.md)  
This contract extracts the strategy without adding requirements. Missing definitions are marked **Open question**.

## 1. Product goals

- Reduce the need for clinical scientists to move between general LLM chat and an R environment to execute, inspect, and refine plotting code.
- Reduce uncertainty about statistical appropriateness, reproducibility, and review readiness.
- Deliver statistically appropriate, inspectable, reproducible, Pharmaverse-aligned visualizations designed for qualified human review.
- Keep the prompt, permitted input data, executed R code, visual output, review status, and validation evidence aligned.
- Prioritize submission-oriented trust first, persistent study context second, and rapid iteration third. Introduce later priorities progressively without weakening traceability.

## 2. Users

- **Primary users:** Clinical scientists answering regulatory and internal clinical questions from ADaM data.
- **Supporting users:** Statistical programmers and biostatisticians who support the primary users and review outputs.
- The strategy refers to both a statistical programmer and a biostatistician as required reviewers for review-turnaround measurement.

**Open question:** The strategy does not specify additional user roles, permissions, or responsibilities.

## 3. Boundaries

- The proof of concept (POC) accepts only public, synthetic, or properly de-identified data.
- Confidential patient-level data remains prohibited until the product and outputs are validated, privacy and security controls are qualified, and the client approves its use.
- Unreviewed outputs may be exported only as drafts.
- Unevaluated plot patterns must be clearly labeled experimental or draft.
- Broader table, listing, and figure support is deferred until after the ggplot POC.
- Do not assume business logic or the target environment. Do not change requirements or existing interfaces, install packages, or add custom error handling without first asking the user.

## 4. Non-goals and deferred scope

- **Not implied by the product name:** Direct electronic submission to the FDA, FDA validation, or FDA approval.
- **Deferred until after the ggplot POC:** Broader table, listing, and figure support.
- The strategy does not identify other permanent non-goals.

**Open question:** The strategy does not define the exact ggplot POC pattern or its supported data and visualization envelope.

## 5. Quality metrics

| Metric | Target and measurement stated in the strategy |
| --- | --- |
| First-pass quality | At least 80% of outputs pass statistical-programmer and biostatistician review without material correction, measured with a versioned evaluation harness and recorded reviewer decisions. |
| Exact reproducibility | At least 80% of `Reviewed` outputs reproduce from recorded inputs, code, package versions, and execution environment through controlled re-execution. |
| Automated turnaround | Median prompt-submission-to-`Verified` plot and reproducible R code is under one minute, measured through application telemetry and automated-check completion timestamps. |
| Human-review turnaround | Measure median time from `Verified` to `Reviewed` separately using the recorded decisions and timestamps of both required reviewers. Set a target after the pilot establishes a defensible baseline. |

**Open questions:** The strategy does not define the evaluation corpus, denominators, sample size, reviewer calibration, or what qualifies as a “material correction.” It also does not define the exact reproducibility pass criteria or benchmark conditions beyond the stated inputs, code, package versions, environment, telemetry, and automated-check timestamps.

## 6. Product tracks

1. **Statistically Appropriate ggplot Generation:** Generate and conversationally refine safety and efficacy visualizations from ADaM and other permitted tabular data.
2. **Reproducible, Controlled R Execution:** Execute generated R code in a controlled environment and record inputs, code, dependencies, environment details, and outputs.
3. **Evaluation, Review, and Traceability:** Build the evaluation harness, reviewer workflow, status controls, and audit evidence needed to distinguish drafts, experimental outputs, and approved outputs.
4. **Persistent Study Context and Broader TLF Support:** After the POC, retain governed study context across conversations and expand to broader table, listing, and figure workflows.

## 7. Milestones

- **2026-09-07:** Demonstrate the ADaMViz SubmissionSync proof of concept.
- Client pilot, validation checkpoint, and regulatory-facing review dates are to be set after client discussion.

**Open questions:** The strategy does not record the status of the 2026-09-07 demonstration or provide dates for the pilot, validation checkpoint, or regulatory-facing review.

## 8. Product states

The strategy names these terms but does not define a complete state model:

- **Draft:** Unreviewed outputs may be exported only as drafts.
- **Experimental or draft:** Unevaluated plot patterns must carry one of these labels.
- **Verified:** The automated-turnaround metric ends when a plot and reproducible R code reach this state.
- **Reviewed:** The reproducibility metric applies to `Reviewed` outputs; the strategy measures elapsed time from `Verified` to `Reviewed`.
- **Approved outputs:** This phrase appears in the evaluation/review/traceability track as a category to distinguish, but the strategy does not define an `Approved` state.

**Open questions:** The strategy does not define state entry criteria, allowed transitions, whether `Reviewed` means approved, how `Experimental` relates to `Draft`, or what review decisions produce `Reviewed`.

## 9. Regulatory and trust constraints

- Position the product as designed for validated clinical submission workflows. Do not imply direct FDA electronic submission, FDA validation, or FDA approval.
- Protect submission-oriented trust through statistical appropriateness, inspectability, reproducibility, traceability, Pharmaverse alignment, and qualified human review.
- Preserve the POC data boundary and the stated conditions for any future use of confidential patient-level data.
- Resist changes that weaken reproducibility, traceability, qualified human review, the data-safety boundary, or an approved requirement or interface.

**Open question:** The strategy does not specify a target regulatory framework, intended-use validation protocol, or target-environment qualification criteria.

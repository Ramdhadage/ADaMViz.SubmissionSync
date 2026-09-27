---
title: How the Plot-Pattern Assurance Cell Will Work
date: 2026-09-06
input_shape: idea
subject: A step-by-step dummy ADLB boxplot journey through ADaMViz SubmissionSync
---

# How the Plot-Pattern Assurance Cell Will Work

## The short version

You are building a prompt-driven Shiny application for a narrow, governed plotting task. The user asks for a plot in ordinary language. The language model translates the request into a constrained plot specification, but it does not write or execute arbitrary R. Deterministic application code validates the specification and ADaM BDS data, generates the R script, executes that exact script, verifies the result, and presents the plot and code for human review.

The first supported pattern is a longitudinal boxplot:

- one `PARAMCD`;
- one selected `AVALU`;
- one Y variable: `AVAL`, `CHG`, or `PCHG`;
- `AVISIT` on X, ordered by `AVISITN`;
- treatment facets;
- native R type-7 quartiles and Tukey whiskers;
- visible outliers;
- connected median points;
- distinct-subject N below every displayed box; and
- a low-sample warning when N is below the configured threshold.

This document is a dummy walkthrough of the intended product. It is not evidence that the application has already been implemented or validated.

![Prompt-to-reviewed plot workflow showing the blocking validation branch and the governed path to controlled export](assets/plot-pattern-assurance-cell/prompt-to-reviewed-workflow.png)

## Meet the dummy user and data

Dr. Meera is a clinical scientist. She wants to compare alanine aminotransferase values over time between Placebo and Drug 100 mg.

For teaching purposes, the synthetic data are shown below in a compact wide view. The real ADLB-style input remains long: one record for each subject, parameter, and analysis visit.

| USUBJID | TRTA | Baseline | Week 4 | Week 8 |
|---|---|---:|---:|---:|
| P01 | Placebo | 20 | 22 | 23 |
| P02 | Placebo | 24 | 25 | 27 |
| P03 | Placebo | 28 | 29 | 31 |
| P04 | Placebo | 32 | 34 | 35 |
| P05 | Placebo | 36 | 38 | 40 |
| D01 | Drug 100 mg | 21 | 19 | 17 |
| D02 | Drug 100 mg | 25 | 22 | 20 |
| D03 | Drug 100 mg | 29 | 25 | 23 |
| D04 | Drug 100 mg | 33 | 28 | 26 |
| D05 | Drug 100 mg | 37 | 31 | missing |

The corresponding BDS records contain at least these variables:

| USUBJID | PARAMCD | AVALU | AVISIT | AVISITN | TRTA | AVAL |
|---|---|---|---|---:|---|---:|
| P01 | ALT | U/L | Baseline | 0 | Placebo | 20 |
| P01 | ALT | U/L | Week 4 | 4 | Placebo | 22 |
| P01 | ALT | U/L | Week 8 | 8 | Placebo | 23 |
| D05 | ALT | U/L | Baseline | 0 | Drug 100 mg | 37 |
| D05 | ALT | U/L | Week 4 | 4 | Drug 100 mg | 31 |
| D05 | ALT | U/L | Week 8 | 8 | Drug 100 mg | missing |

No population flag or `ANL01FL` filter is silently applied. The selected parameter records are used exactly according to the confirmed choices.

## Step 1 — Meera enters a prompt

Meera enters:

> Create a boxplot of ALT AVAL by visit, split by treatment. Include all visits and treatment groups, show the number of subjects below each box, and connect the medians.

At this point, the model is used as an intent interpreter. It may identify likely choices, but it cannot generate executable R, approve the result, change status, or select a filesystem destination.

## Step 2 — The app proposes an inspectable specification

The prompt interpreter returns a candidate object similar to this:

```yaml
pattern: longitudinal_tukey_boxplot
dataset: synthetic_adlb
parameter: ALT
y_variable: AVAL
unit: U/L
treatment_variable: TRTA
treatment_levels:
  - Placebo
  - Drug 100 mg
visits:
  - Baseline
  - Week 4
  - Week 8
visit_order_variable: AVISITN
y_scale: fixed
quantile_type: 7
show_outliers: true
connect_medians: true
show_subject_n: true
low_n_threshold: 5
```

The user sees these choices before execution. Each material field also carries provenance such as “from prompt,” “from dataset metadata,” “governed default,” or “confirmed by user.”

If the prompt said only “plot liver results,” the app would not guess the parameter. It would ask Meera to select one eligible `PARAMCD`.

If ALT had both `U/L` and `µkat/L`, the app would stop at this stage and ask Meera to select one `AVALU`.

## Step 3 — Meera confirms or changes the choices

The confirmation screen lets Meera:

- choose one eligible Y variable from `AVAL`, `CHG`, and `PCHG`;
- choose one unit when multiple units exist;
- choose the treatment variable;
- exclude treatment levels;
- exclude visits;
- keep the fixed Y scale or explicitly request free scales; and
- view the sponsor-approved low-N threshold.

The defaults are intentionally conservative: all eligible visits and treatment levels are included, values are plotted as stored, and scales are fixed across treatment facets.

A free-scale choice creates an `Experimental/Draft`. Arbitrary R transformation text is rejected because that capability is deferred.

## Step 4 — The app validates the selected ADaM BDS profile

After confirmation, deterministic validation runs before R code or a plot is produced.

For the dummy data, the app checks:

| Check | Dummy result |
|---|---|
| Required columns exist | Pass |
| Exactly one `PARAMCD` is selected | Pass: ALT |
| Exactly one applicable `AVALU` is selected | Pass: U/L |
| Selected Y is numeric | Pass: AVAL |
| Visit labels have a deterministic `AVISITN` order | Pass: 0, 4, 8 |
| At most one record per subject, parameter, and visit | Pass |
| At least one non-missing selected Y value remains | Pass |
| Missing selected Y values are excluded from statistics and N | Pass |

The result is a structured validation report, not only a green checkmark. Blocking failures and nonblocking warnings remain separate.

## Step 5 — A duplicate demonstrates the stop behavior

Suppose the source also contains a second ALT Week 4 record for subject D03 after the user's selections are applied.

The app identifies the duplicate key:

```text
USUBJID = D03
PARAMCD = ALT
AVISIT = Week 4
```

It then stops before compilation and shows a message such as:

> This selection has more than one record for the same subject, parameter, and analysis visit. This record structure is unsupported by the current plot cell. Resolve the record-selection rule or use another supported pattern.

No R code, plot, execution attempt, or `Verified` status is created. The message does not claim that the entire ADaM dataset is nonconforming; it says only that this plot cell cannot safely interpret the selected structure.

For the remainder of the walkthrough, assume the duplicate is not present.

## Step 6 — The deterministic compiler generates R

The confirmed specification, not the original prompt, enters the compiler. The compiler fills an owned R template. The model never supplies executable code.

The generated script will explicitly encode the selected dataset fields, parameter, unit, treatments, visits, type-7 statistics, missing-value rule, N definition, low-N threshold, and layout. A simplified fragment would resemble:

```r
selected_data <- analysis_data |>
  dplyr::filter(
    PARAMCD == "ALT",
    AVALU == "U/L",
    TRTA %in% c("Placebo", "Drug 100 mg"),
    AVISIT %in% c("Baseline", "Week 4", "Week 8")
  ) |>
  dplyr::mutate(
    AVISIT = factor(
      AVISIT,
      levels = c("Baseline", "Week 4", "Week 8")
    )
  )

plot_stats <- selected_data |>
  dplyr::filter(!is.na(AVAL)) |>
  dplyr::group_by(TRTA, AVISIT) |>
  dplyr::summarise(
    n = dplyr::n_distinct(USUBJID),
    q1 = stats::quantile(AVAL, 0.25, type = 7),
    median = stats::median(AVAL),
    q3 = stats::quantile(AVAL, 0.75, type = 7),
    .groups = "drop"
  )
```

This fragment is explanatory rather than the finished production template. The implemented script must be self-contained, must compute whiskers and visible outliers consistently, and must be byte-identical to the script executed and exported.

## Step 7 — The exact script runs in a controlled process

The application pins the authorized input snapshot and creates an execution request containing the specification hash, script hash, snapshot identity and hash, renderer settings, and environment version.

The exact script runs synchronously in a clean R subprocess. The subprocess returns results to the application service; it does not write directly to lifecycle or evidence storage.

For the POC, this is a reliability boundary, not a hostile-code sandbox. Only public, synthetic, or properly de-identified data are permitted. Approved clinical data require a separately qualified worker boundary with least-privilege access and network, filesystem, and resource controls.

## Step 8 — The app calculates the visible result

The dummy statistics are:

| Treatment | Visit | N | Q1 | Median | Q3 | Low-N warning |
|---|---|---:|---:|---:|---:|---|
| Placebo | Baseline | 5 | 24.00 | 28.00 | 32.00 | No |
| Placebo | Week 4 | 5 | 25.00 | 29.00 | 34.00 | No |
| Placebo | Week 8 | 5 | 27.00 | 31.00 | 35.00 | No |
| Drug 100 mg | Baseline | 5 | 25.00 | 29.00 | 33.00 | No |
| Drug 100 mg | Week 4 | 5 | 22.00 | 25.00 | 28.00 | No |
| Drug 100 mg | Week 8 | 4 | 19.25 | 21.50 | 23.75 | Yes: N < 5 |

The displayed result has two treatment facets. Each facet contains three Tukey boxes. A point marks each median, and a line connects the three displayed medians within that treatment. The lower aligned strip shows N values of `5, 5, 5` for Placebo and `5, 5, 4` for Drug 100 mg. The Drug Week 8 box remains visible and receives a low-N warning; it is not suppressed.

The fixed Y scale lets the user compare the two treatment distributions on the same visual range.

## Step 9 — Automated checks decide whether the revision becomes Verified

The generated result first exists as a `Draft`. The application then checks that:

- the executed script matches the stored script;
- the input snapshot matches its recorded hash;
- N, quartiles, medians, whiskers, and outliers match an independent analytical result;
- the ggplot layer data match those expected values;
- the PNG was created successfully;
- the execution environment is recorded; and
- clean re-execution reproduces the specification, code, and analytical results.

If every mandatory check passes, the same immutable revision becomes `Verified — checks passed, awaiting human approval`.

`Verified` means automated checks passed for that revision. It does not mean that the plot is human-approved, that the application is validated for intended use, or that a regulator approved anything.

## Step 10 — The statistical programmer and biostatistician review it

Two distinct authenticated people review the same immutable revision and artifact hashes:

1. A statistical programmer reviews the record selection, ADaM interpretation, missing-value handling, N, type-7 calculations, generated R, and reproducibility evidence.
2. A biostatistician reviews the statistical and clinical appropriateness of the display and interpretation.

Neither reviewer may be the creator. Two eligible approvals move the revision to `Reviewed`.

If either person rejects it, the rejected revision is closed and preserved. The creator documents the correction and creates a new Draft successor. The new revision repeats automated verification and both reviews; the old evidence is never overwritten.

![Plot revision lifecycle from Draft through automated verification and two-person review, including rejection, correction, and Experimental Draft](assets/plot-pattern-assurance-cell/revision-lifecycle.png)

## Step 11 — Reviewed code is locked

Once the revision is `Reviewed`, its specification, generated code, plot, input identity, evidence, and approvals are immutable.

Meera can still ask:

> Exclude Week 4 and regenerate the plot.

The app does not edit the Reviewed code. It creates a new Draft revision linked to the Reviewed parent. The previous Reviewed result remains available in the version history.

## Step 12 — Export is intentionally narrow

An authorized user selects a registered controlled-workspace name, not an arbitrary path. The application publishes an exact pair:

- one PNG plot image; and
- the exact UTF-8 R script used to generate it.

The files do not contain lifecycle status, reviewer identity, approval scope, prompt text, or internal evidence. Those remain linked internally to the source revision and export receipt.

`Experimental/Draft` cannot be exported. The Product Contract intends eligible `Draft`, `Verified`, and `Reviewed` revisions with complete artifact bundles to be exportable, although the implementation plan still has an open design decision about accepting a Draft bundle independently of verification promotion.

## What the user sees versus what happens behind the screen

| User-facing experience | Deterministic product behavior |
|---|---|
| Enter a natural-language plotting request | Build a constrained candidate specification |
| Confirm parameter, Y, unit, treatment, and visits | Validate choices against authorized metadata |
| See a blocking message or warning | Run BDS profile checks and structured diagnostics |
| View the plot and R code | Compile and execute one exact governed script |
| See Draft or Verified | Record revision-specific automated evidence |
| Approve or reject | Enforce identity, role, independence, and immutable-hash rules |
| Export plot and code | Publish only an authorized image/code pair to a controlled workspace |

## What the language model controls—and what it does not

| The model may | The model may not |
|---|---|
| Interpret the prompt into known specification fields | Generate executable R for this governed path |
| Identify unresolved choices | Invent parameters, treatments, visits, or units |
| Ask the user to clarify a material choice | Silently choose a clinically material option |
| Recognize a supported free-scale request | Execute arbitrary transformation text |
| Fall back to manual selection on failure | Approve, reject, set status, or choose an export path |

This division is the core product idea: use the model for language understanding and use deterministic, testable R/application logic for clinical and statistical behavior.

## Local POC versus a validated deployment

![Architecture showing the same Shiny application using local POC providers or qualified target providers](assets/plot-pattern-assurance-cell/poc-vs-qualified-architecture.png)

The POC proves that the workflow and contracts can work. It does not prove that production identity, storage, execution, retention, access controls, or the intended-use environment are qualified. Those require separate sponsor-controlled validation evidence.

## Important choices still open in the reviewed plan

The overall workflow is clear, but the latest document review identified several decisions that should be settled before or during implementation:

- whether the September 7 demonstration should be a thin synthetic vertical slice before the complete assurance workflow;
- what should happen if the user excludes every treatment or visit;
- how unitless parameters and missing treatment values are handled;
- whether `Experimental/Draft` results enter any formal review path;
- how users submit a result for review and how reviewers find pending work;
- when benchmark datasets and the one-minute latency budget are fixed;
- how long an immutable input snapshot must remain available;
- how much event-chain integrity infrastructure belongs in the POC; and
- what desktop viewport range the first UI supports.

These open choices do not change the central model shown above. They refine edge behavior, milestone sequencing, and the boundary between the POC and later validated deployment.

## A practical way to remember the application

Think of the product as six connected responsibilities:

1. **Understand:** Translate the prompt into known plotting choices.
2. **Confirm:** Let the user inspect and resolve every material choice.
3. **Protect:** Stop unsupported data structures before code runs.
4. **Produce:** Generate and execute deterministic R for one approved pattern.
5. **Prove:** Record checks, reproducibility evidence, and immutable versions.
6. **Approve:** Require independent statistical and biostatistical review before calling the result Reviewed.

## Source documents

- `STRATEGY.md`
- `docs/ideation/2026-09-05-adamviz-submissionsync-validation-ready-product-ideation.md`
- `docs/plans/2026-09-06-0014-feat-plot-pattern-assurance-cell-plan.md`

## Check yourself

1. Why does the language model produce a specification rather than executable R?
2. What happens when two selected records have the same subject, parameter, and analysis visit?
3. Why is a result not yet human-approved when it becomes Verified?
4. What happens when someone changes a Reviewed plot?

**Answers**

1. The specification constrains the model to known, inspectable choices; deterministic product code owns validation and R generation. An answer that says only “for reproducibility” misses the safety boundary between language interpretation and executable behavior.
2. The application identifies the duplicate key and stops before compilation or execution. An answer that proposes averaging or choosing one record adds an unapproved analysis rule.
3. Verified records only that mandatory automated checks passed for one immutable revision. Human approval requires two distinct eligible non-creator reviewers; confusing these states would weaken the review lifecycle.
4. The Reviewed revision remains locked. The change creates a linked Draft successor that must repeat verification and both reviews; editing the original would destroy its evidence linkage.

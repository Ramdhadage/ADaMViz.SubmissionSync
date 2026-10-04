# Confirming analysis selections

The Confirm step turns scientist-selected scope into a hashed plot
specification. The active upload workflow retains the question but does
not interpret it to choose a parameter, Y variable, unit, visit, or
treatment. Its choices come from the pinned dataset, and the scientist
confirms the settings before generation.

[Open the confirmation flow
diagram](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/diagrams/03-confirming-analysis-selections.md).
The diagram shows the selection and field gates; detailed BDS
eligibility checks are described in [BDS data
profiling](https://ramdhadage.github.io/ADaMViz.SubmissionSync/articles/02-bds-profiling-eligibility.md).

## From question to selectable choices

In
[mod_plot_generation.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/mod_plot_generation.R),
`to_confirm` requires the current upload and a valid question. It calls
`.create_assurance_candidate()` in
[app_server.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/app_server.R)
when there is no pending candidate or the question has changed. That
function pins the snapshot, retains the question, builds aggregate
context, and creates a candidate with `dataset_id` set and
`scale_mode = "fixed"`. The remaining plot fields initially contain
`NULL`.

[`build_prompt_context()`](https://ramdhadage.github.io/ADaMViz.SubmissionSync/reference/build_prompt_context.md)
in
[prompt_context.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/prompt_context.R)
derives the following choices:

| Choice | Dataset source and ordering |
|----|----|
| Parameter | `PARAMCD`, with `PARAM` supplying the aggregate label; parameter rows sort by code. |
| Unit | Distinct non-missing `AVALU` values for each parameter, sorted with radix ordering. |
| Y variable | Existing columns from `AVAL`, `CHG`, and `PCHG`, in that order. |
| Treatment facet | Snapshot `permitted_treatment_variables`; each variable has sorted distinct non-missing levels. |
| Visit | Distinct non-missing `AVISIT`/`AVISITN` pairs, ordered by `AVISITN`, then label. |

`.spec_choices_from_context()` converts this context to UI choices. The
parameter control displays codes, and the visit control displays labels.
Treatment and visit choices are initially dataset-wide; selecting a
parameter does not rebuild them from that parameter’s records. The later
profile gate checks whether the selected combination exists.

The context contains aggregate choices rather than patient records.
[prompt_context_policy.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/prompt_context_policy.R)
rejects specified prohibited terms and URL patterns in labels and
aggregate content. This lexical check does not qualify uploaded data
provenance or establish de-identification. A separate
`.create_assurance_revision()` helper invokes a mock interpreter, but
the active upload candidate path does not call it.

## What the scientist confirms

[mod_specification.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/mod_specification.R),
through `mod_specification_server()`, presents the supported
longitudinal numeric BDS boxplot and its controls. Parameter, Y
variable, and treatment facet fall back to the first available choice
when the specification has no value. Visits and treatment levels
initially include all available choices. Fixed Y scales are the default.

Units depend on the selected parameter. The control preserves an
available current unit, selects the sole available unit, or supplies an
empty selection when there are several units and no valid current
choice. `.current_spec_input_fields()` assembles the current inputs with
specification and choice fallbacks. The server validates the submitted
values; the controls alone are not the enforcement boundary.

Selecting `AVAL`, `CHG`, or `PCHG` chooses a stored column. Confirmation
does not calculate change or percent change, convert units, derive
treatment assignments, or silently apply analysis flags. Visit order
comes from `AVISITN`, rather than the order in which the scientist
checks labels. Free Y scales require the explicit acknowledgement
checkbox before either generation or correction can proceed.

## Specification, provenance, and profile gate

`.confirmed_spec_from_fields()` requires one non-empty parameter,
supported Y variable, non-empty unit, and treatment variable. Treatment
levels and visits must each contain at least one unique non-missing
character value. It records `dataset_id` provenance as `metadata` and
all seven remaining field sources as `user_confirmed`, including
defaults accepted by the scientist.

[domain_plot_spec.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/domain_plot_spec.R)
defines eight specification fields: `dataset_id`, `paramcd`,
`y_variable`, `unit`, `treatment_variable`, `treatment_levels`,
`visits`, and `scale_mode`. `new_plot_spec()` records schema version
`plot-spec-v1` and hashes the fields together with provenance.
`confirm_plot_spec()` requires non-NULL fields and provenance for every
field, then changes the state to `confirmed`. Confirmation itself does
not change that hash.

The domain constructor accepts provenance labels `prompt`, `metadata`,
`default`, and `user_confirmed`. Those labels describe the recorded
source; they are not signatures or authenticated proof of a person’s
decision. The active field builder imposes stronger shape checks than
`confirm_plot_spec()` alone.

The workflow then calls
[`validate_bds_profile()`](https://ramdhadage.github.io/ADaMViz.SubmissionSync/reference/validate_bds_profile.md)
in
[bds_profile.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/R/bds_profile.R).
This gate checks selected parameter and unit availability, permitted
treatment, numeric Y, treatment levels, visit availability and mappings,
and the supported record keys. A blocked profile remains on Confirm with
a diagnostic and prevents materialization. Field completeness therefore
does not imply plotting eligibility, full ADaM conformance, successful
execution, or human approval.

## Revisiting choices and implementation evidence

Generated settings are read-only when there is no pending candidate and
the revision is not eligible for correction. Result can return to
Confirm and then back to Result. For `Rejected` or `Reviewed` revisions
with retained choices, the module offers a correction action requiring
rationale and provenance; it creates a successor rather than editing the
previous revision.

Inspected tests cover field/provenance display, read-only controls,
user-selected units and visits, free-scale acknowledgement, and
correction requests in
[test-mod-specification.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-mod-specification.R).
[test-domain-plot-spec.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-domain-plot-spec.R)
covers complete and incomplete specifications, supported Y variables,
and unknown provenance fields.
[test-prompt-context.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-prompt-context.R)
covers aggregate context and prohibited content.
[test-bds-profile.R](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/blob/master/tests/testthat/test-bds-profile.R)
covers explicit units, exclusions, numeric Y, and deterministic visit
mappings.

These are inspected coverage references. This documentation task did not
run R tests, browser journeys, statistical review, or formal validation.

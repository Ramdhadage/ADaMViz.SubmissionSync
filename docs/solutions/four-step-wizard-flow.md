---
title: "Use a linear four-step plot workflow"
date: 2026-09-20
category: design-patterns
module: F001 Plot Generation workflow
problem_type: design_pattern
component: frontend
severity: low
applies_when:
  - "Plot workflows share data upload, question entry, choice confirmation, and a result."
tags:
  - clinical-ux
  - plot-generation
  - multi-step-wizard
  - navigation
---

# Use a linear four-step plot workflow

## Context

F001 fixes the main sequence as Data → Ask → Confirm → Result. The design also sets how users return to earlier work, refine choices, and proceed after data validation. These are target interaction rules; the current static prototype shows Back links on Ask and Confirm but not on Result, and its disabled Continue only illustrates the Step 1 gate.

## Guidance

- Keep the sequence Data → Ask → Confirm → Result.
- Provide Back navigation from every step with a predecessor: Ask to Data, Confirm to Ask, and Result to Confirm. Data is the entry step.
- Keep Continue on Data disabled until file validation passes.
- Keep refinement linear: return to an earlier step, revise the input or choices, then continue forward. Do not create in-page branches for refinement.

## Why This Matters

A stable sequence keeps users oriented, and returning to a prior step gives them a direct way to refine their work without creating alternate routes. The validation gate makes the data prerequisite explicit before the user proceeds.

## When to Apply

- Reuse this flow for F002, F003, and future plot-generation workflows with the same stages.
- Use backtracking when refinement should revisit an earlier step rather than branch within the current step.

## Examples

In the [F001 prototype](../ux/F001-plot-generation-prototype.html), Ask links back to Data and Confirm links back to Ask. Add a Result-to-Confirm Back action to meet the navigation rule. The Data screen shows Continue disabled until a permitted file is ready; the design rule gates it on file validation passing. Within the workflow, refining an earlier input replaces the current proposal instead of creating a separately versioned proposal; this interaction rule does not define audit history or retention. Exact validation criteria and audit-history requirements remain open in the [F001 workflow spec](../ux/F001-plot-generation.md).

## Related

- [Data and profile side drawer](data-profile-side-drawer.md)
- [Task-first layout for clinical plot generation](design-patterns/task-first-clinical-plot-workbench.md)

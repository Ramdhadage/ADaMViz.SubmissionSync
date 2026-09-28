---
title: "Use a linear five-step plot workflow"
date: 2026-09-20
category: design-patterns
module: F001 Plot Generation workflow
problem_type: design_pattern
component: frontend
severity: low
applies_when:
  - "Plot workflows share data upload, question entry, choice confirmation, a result, and export actions."
tags:
  - clinical-ux
  - plot-generation
  - multi-step-wizard
  - navigation
---

# Use a linear five-step plot workflow

## Context

F001 uses the main sequence Data → Ask → Confirm → Result → Export. The design also sets how users return to earlier work, refine choices, and proceed after data validation. The static prototype and implemented workflow both show Export as the final step so traceability, independent review, and controlled export remain separate from the generated result.

## Guidance

- Keep the sequence Data → Ask → Confirm → Result → Export.
- Provide Back navigation from every step with a predecessor: Ask to Data, Confirm to Ask, Result to Confirm, and Export to Result. Data is the entry step.
- Keep Continue on Data disabled until file validation passes.
- Keep plot output and automated checks on Result; keep revision history, review, and controlled export on Export.
- Keep refinement linear: return to an earlier step, revise the input or choices, then continue forward. Do not create in-page branches for refinement.

## Why This Matters

A stable sequence keeps users oriented, and returning to a prior step gives them a direct way to refine their work without creating alternate routes. The validation gate makes the data prerequisite explicit before the user proceeds.

## When to Apply

- Reuse this flow for F002, F003, and future plot-generation workflows with the same stages.
- Use backtracking when refinement should revisit an earlier step rather than branch within the current step.

## Examples

In the implemented F001 workflow, each step after Data links back to its predecessor, Result continues to Export, and Export contains the existing traceability, review, and export panel. The Data screen keeps Continue disabled until a permitted file is ready. Within the workflow, refining an earlier input replaces the current proposal instead of creating a separately versioned proposal; this interaction rule does not define audit history or retention. Exact validation criteria and audit-history requirements remain governed by the [F001 workflow spec](../ux/F001-plot-generation.md).

## Related

- [Data and profile side drawer](data-profile-side-drawer.md)
- [Task-first layout for clinical plot generation](design-patterns/task-first-clinical-plot-workbench.md)

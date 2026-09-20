---
title: "Keep plot suggestion optional before confirmation"
date: 2026-09-20
category: design-patterns
module: F001 Plot Generation workflow
problem_type: design_pattern
component: frontend
severity: low
applies_when:
  - "A workflow offers a system suggestion while users may already know the specification they want."
tags:
  - clinical-ux
  - plot-generation
  - plot-suggestion
  - human-control
---

# Keep plot suggestion optional before confirmation

## Context

F001 separates asking a visualization question from reviewing and confirming plot choices. The design makes plot suggestion optional so a scientist can ask for help or enter a known specification directly. The current static [prototype](../ux/F001-plot-generation-prototype.html) shows Suggest plot and Continue as separate Step 2 controls, but it does not show an inline suggestion result or a distinct manual-specification path.

## Guidance

- Make Suggest plot an optional soft action that displays a suggestion inline and stays on Step 2.
- Make Continue to review choices the hard action that advances to Step 3.
- Let the scientist enter their own specification on Step 2 and continue without requesting a suggestion.
- Keep Step 3 review and confirmation in the flow regardless of whether the scientist used a suggestion.

## Why This Matters

Clinical scientists may already know the plot type they need. An optional suggestion supports them when useful without forcing AI into the workflow or blocking direct specification.

## When to Apply

- Use when a system suggestion is available alongside a direct user-authored path.
- Keep the suggestion optional when users can provide a suitable specification themselves.

## Examples

On Step 2, the scientist can request an inline suggestion or enter their own specification. In either case, Continue to review choices advances to Step 3. The existing prototype places proposed choices on Step 3 and does not depict the inline result or manual path; this note records the target interaction, not implemented behavior. See the [F001 workflow spec](../ux/F001-plot-generation.md).

## Related

- [Use a linear four-step plot workflow](four-step-wizard-flow.md)
- [Task-first layout for clinical plot generation](design-patterns/task-first-clinical-plot-workbench.md)

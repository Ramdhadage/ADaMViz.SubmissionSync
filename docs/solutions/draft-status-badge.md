---
title: "Show draft review status beside the plot result title"
date: 2026-09-20
category: design-patterns
module: F001 Plot Generation workflow
problem_type: design_pattern
component: frontend
severity: low
applies_when:
  - "An output requires dual review before it is eligible for post-approval export."
tags:
  - clinical-ux
  - plot-generation
  - review-status
  - dual-approval
---

# Show draft review status beside the plot result title

## Context

F001 displays review status on the Plot result page. The design places a `Draft · not reviewed` badge at the top-right of the title row and explains the two-approval requirement in an adjacent information tooltip. This is a display pattern; it does not define the status lifecycle or export policy, which remain open in the [F001 workflow spec](../ux/F001-plot-generation.md).

## Guidance

- Place the `Draft · not reviewed` badge at the top-right of the Plot result title row.
- Use an adjacent information tooltip to explain that both independent approvals are required for post-approval export eligibility.
- Reuse this display pattern for outputs that require dual review before post-approval export.
- Do not infer status transitions, the full meaning of `Draft`, or draft-only export availability from the badge and tooltip.

## Why This Matters

The badge makes the current review state visible where the output is presented. The tooltip explains the approval condition without implying that the badge defines the full review lifecycle or export policy.

## When to Apply

- Use when an output needs two independent approvals before becoming eligible for post-approval export.
- Keep the status cue beside the output title and the explanation available on demand.

## Examples

In the [F001 prototype](../ux/F001-plot-generation-prototype.html), the Plot result title row shows `Draft · not reviewed` at the right, with an information tooltip explaining the dual-approval requirement. The badge does not define what happens after approval, rejection, or a failed check, and it does not settle whether unreviewed output can be exported as Draft.

## Related

- [F001: Plot Generation](../ux/F001-plot-generation.md)
- [Task-first layout for clinical plot generation](design-patterns/task-first-clinical-plot-workbench.md)

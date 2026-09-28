---
title: "Keep data and profile context in a collapsible side drawer"
date: 2026-09-20
category: design-patterns
module: F001 Plot Generation workflow
problem_type: design_pattern
component: frontend
severity: low
applies_when:
  - "A multi-step wizard needs input data to remain accessible while the current task stays in focus."
tags:
  - clinical-ux
  - data-profile
  - side-drawer
  - multi-step-wizard
---

# Keep data and profile context in a collapsible side drawer

## Context

F001 begins with a Data upload step, then moves through the plot tasks. The design keeps dataset and profile context available during those later steps without a separate screen for revisiting it or a panel that stays open beside each task.

## Guidance

Use a collapsible Data & Profile drawer on each workflow step. It starts closed. Keep its edge tab discoverable; open it by clicking the tab or dragging it to the right. The [F001 prototype](../ux/F001-plot-generation-prototype.html) shows this trigger on each step.

## Why This Matters

The scientist can stay focused on the current task without losing access to input-data context or navigating away from the step.

## When to Apply

- Use this pattern in a multi-step wizard when input data should remain accessible across steps.
- Keep required inputs and blocking statuses visible in the task canvas; the drawer is for supporting context.

## Examples

The [F001 plot-generation prototype](../ux/F001-plot-generation-prototype.html) places the drawer on each of its five step screens and shows it hidden by default. The broader [task-first plot workbench pattern](design-patterns/task-first-clinical-plot-workbench.md) describes how this fits the clinical workflow.

## Related

- [F001: Plot Generation](../ux/F001-plot-generation.md)
- [Task-first layout for clinical plot generation](design-patterns/task-first-clinical-plot-workbench.md)

---
title: "Use task-specific defaults for collapsible panels"
date: 2026-09-20
category: design-patterns
module: F001 Plot Generation workflow
problem_type: design_pattern
component: frontend
severity: low
applies_when:
  - "A multi-step workflow has primary task content and supporting details that should be available on demand."
tags:
  - clinical-ux
  - plot-generation
  - collapsible-panels
  - progressive-disclosure
---

# Use task-specific defaults for collapsible panels

## Context

F001 uses collapsible panels to keep each step's main task prominent while preserving access to supporting details. The [prototype](../ux/F001-plot-generation-prototype.html) shows the intended default states and a caption below each screen. The automated-check panel is optional to open; F001 still requires the checks and linked evidence.

## Guidance

- Make Upload, Question, Plot type, Variables and settings, Plot preview, Exact R code, and Automated checks collapsible.
- Default open: Upload on Step 1, Question on Step 2, Plot type and Variables on Step 3, and Plot preview on Step 4.
- Default closed: Exact R code and Automated checks. Users may open these panels to inspect their contents.
- Use the screen caption below each task canvas to explain its rule or constraint.
- Keep required checks and blocking conditions effective regardless of whether their detail panels are open.

## Why This Matters

Opening the panel needed for the current task makes the next action easier to find. Keeping supporting details closed reduces screen density while preserving access. Panel visibility must not change whether required checks run or whether their evidence is retained.

## When to Apply

- Use in a multi-step workflow with one primary task per screen and secondary details users can inspect on demand.
- Keep required actions, blocking conditions, and required checks visible or clearly explained regardless of panel state.

## Examples

The [F001 prototype](../ux/F001-plot-generation-prototype.html) opens Upload, Question, Plot type, Variables and settings, and Plot preview by default. Exact R code and automated-check details start closed. Its Step 4 caption currently says “Automated checks are optional,” which can imply the checks themselves are optional. Keep the panel optional to open while all required checks run and their evidence is linked to the run. The captions explain the rule or constraint for each step.

## Related

- [F001: Plot Generation](../ux/F001-plot-generation.md)
- [Task-first layout for clinical plot generation](design-patterns/task-first-clinical-plot-workbench.md)

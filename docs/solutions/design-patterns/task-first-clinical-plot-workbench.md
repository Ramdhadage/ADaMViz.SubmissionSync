---
title: "Task-first layout for clinical plot generation"
date: 2026-09-20
category: design-patterns
module: F001 Plot Generation workflow
problem_type: design_pattern
component: frontend
severity: low
applies_when:
  - "A clinical scientist moves through data upload, a visualization question, proposal confirmation, and results."
  - "Dataset and profile context must stay accessible while the current task remains the focus."
tags:
  - clinical-ux
  - plot-generation
  - progressive-flow
  - contextual-help
  - review-traceability
---

# Task-first layout for clinical plot generation

## Context

F001 defines the data-to-plot workflow and its clinical controls, but leaves screen layout and control placement open. The final wireframe resolves that gap for clinical scientists who need to scan the current task while retaining access to dataset context. See the [F001 workflow](../../ux/F001-plot-generation.md) and the [final wireframe](../../ux/F001-plot-generation-prototype.html).

## Guidance

- Keep the four stages visible in order: Data, Ask, Confirm, Result. Give each stage one primary task canvas and make the next action clear.
- Keep dataset and profile context in a side drawer that is closed initially and can be opened directly. Do not repeat an active-dataset card in the main task canvas.
- Make each content panel collapsible, while keeping the current task and primary action easy to find.
- Put required-input cues beside the inputs. Use contextual tooltips for secondary explanations, such as the question and proposed choices or the meaning of review status.
- Show automated-check details on demand. This changes their visibility only; required checks still run and their evidence remains linked to the revision. Specific checks and pass thresholds remain to be defined.
- Keep blocking validation results, required actions, and clinical boundaries visible when they matter. A compact layout must not obscure a stop condition or imply that an unchecked result is approved.

## Why This Matters

This layout aims to keep the current task prominent while preserving direct access to dataset context. The visible step order supports scanning and forward movement; collapsible secondary panels and contextual help keep supporting information close without making every screen dense. Separating disclosure from workflow rules avoids weakening required validation or review controls for visual simplicity.

## When to Apply

- Use this pattern for a bounded, multi-step clinical workflow with one clear primary action per step.
- Keep context in a drawer only when opening it is immediate and the handle remains discoverable; never hide a required input or blocking status there.
- Use tooltips for supplemental explanations, not the only place where required input instructions or blocking decisions appear.

## Examples

The F001 wireframe shows Data → Ask → Confirm → Result, keeps dataset/profile context in a hidden-by-default side drawer, removes the duplicate active-dataset card, and uses collapsible panels. It places help for proposed choices and review status in tooltips and makes automated-check details optional to open. The underlying workflow still blocks the full selected input before code generation and execution if any selected record is unsupported, and still performs automated checks. See [F001 workflow requirements](../../ux/F001-plot-generation.md) and the [wireframe](../../ux/F001-plot-generation-prototype.html).

## Related

- [F001: Plot Generation](../../ux/F001-plot-generation.md)
- [Product strategy](../../product/STRATEGY.md)
- [Product contract](../../product/product-contract.md)

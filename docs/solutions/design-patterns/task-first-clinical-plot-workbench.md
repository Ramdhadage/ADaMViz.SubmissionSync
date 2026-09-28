---
title: "Task-first layout for clinical plot generation"
date: 2026-09-21
category: design-patterns
module: F001 Plot Generation workflow
problem_type: design_pattern
component: frontend
severity: low
applies_when:
  - "Implementing or revising the F001 clinical plot-generation workbench."
tags:
  - clinical-ux
  - plot-generation
  - progressive-flow
  - contextual-help
  - review-traceability
---

# Task-first layout for clinical plot generation

## Context

The user-designated final prototype is the source of truth for F001 screen content and interactions. It shows the five-step Data → Ask → Confirm → Result → Export flow, a CSV/Excel upload on Data, and a closed-by-default Data & Profile drawer attached to the screen edge. The user also clarified that this POC uses synthetic data only. The workflow prose and older implementation notes provide context, but do not override the prototype where they differ.

## Guidance

- Keep the four stages visible in order: Data, Ask, Confirm, Result. Give each stage one primary task canvas and make the next action clear.
- Keep dataset and profile context in a side drawer that is closed initially and can be opened directly. Do not repeat an active-dataset card in the main task canvas.
- Make each content panel collapsible, while keeping the current task and primary action easy to find.
- Put required-input cues beside the inputs. Use contextual tooltips for secondary explanations, such as the question and proposed choices or the meaning of review status.
- Show automated-check details on demand. This changes their visibility only; required checks still run and their evidence remains linked to the revision. Specific checks and pass thresholds remain to be defined.
- Keep blocking validation results, required actions, and clinical boundaries visible when they matter. A compact layout must not obscure a stop condition or imply that an unchecked result is approved.
- Keep the prototype's CSV/Excel upload and file-readiness gate when removing the classification dropdown, consent checkbox, and upload warning. Removing those controls does not mean disabling the upload path.
- Keep the synthetic-only POC boundary without storing an uploaded-file classification. Format and BDS checks establish file compatibility, not synthetic provenance or identifier removal.
- Match the prototype's attached drawer: closed initially, with an edge tab users can click or drag to open.

## Why This Matters

This layout aims to keep the current task prominent while preserving direct access to dataset context. The visible step order supports scanning and forward movement; collapsible secondary panels and contextual help keep supporting information close without making every screen dense. Separating disclosure from workflow rules avoids weakening required validation or review controls for visual simplicity.

## When to Apply

- Use this pattern for a bounded, multi-step clinical workflow with one clear primary action per step.
- Keep context in a drawer only when opening it is immediate and the handle remains discoverable; never hide a required input or blocking status there.
- Use tooltips for supplemental explanations, not the only place where required input instructions or blocking decisions appear.

## Examples

The F001 wireframe shows Data → Ask → Confirm → Result, keeps dataset/profile context in a hidden-by-default side drawer, removes the duplicate active-dataset card, and uses collapsible panels. It places help for proposed choices and review status in tooltips and makes automated-check details optional to open. The underlying workflow still blocks the full selected input before code generation and execution if any selected record is unsupported, and still performs automated checks. See [F001 workflow requirements](../../ux/F001-plot-generation.md) and the [wireframe](../../ux/F001-plot-generation-prototype.html).

In the current implementation, [`R/mod_plot_generation.R`](../../../R/mod_plot_generation.R) retains CSV/Excel parsing and supported BDS checks without putting a classification on uploaded snapshots. [`R/bds_profile.R`](../../../R/bds_profile.R) permits this classless direct-upload path while still enforcing BDS structure and selected-record checks. Execution uses the synthetic-only POC default; revision input evidence omits the classification field for uploads. None of these checks verifies data provenance or removes identifiers.

## Related

- [F001: Plot Generation](../../ux/F001-plot-generation.md)
- [Product strategy](../../product/STRATEGY.md)
- [Product contract](../../product/product-contract.md)

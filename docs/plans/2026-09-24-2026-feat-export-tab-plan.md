---
title: "Export Workflow Tab - Plan"
type: feat
date: 2026-09-24
artifact_contract: ce-unified-plan/v1
product_contract_source: ce-plan-bootstrap
execution: code
---

# Export Workflow Tab - Plan

## Goal Capsule

- **Objective:** Give traceability, independent review, and controlled export a dedicated fifth workflow step without changing their governed behavior.
- **Means:** Extend the existing linear Shiny stepper and relocate the current panel intact.
- **Authority:** The user-approved five-step layout and the existing review/export contracts.
- **Execution profile:** Test-first, isolated branch, browser verification required.
- **Stop conditions:** Stop if the change requires new dependencies, module IDs, lifecycle rules, export eligibility changes, or edits to the user's uncommitted main-checkout work.

---

## Product Contract

### Summary

The plot-generation workflow becomes Data -> Ask -> Confirm -> Result -> Export. Result remains focused on the generated plot and automated evidence; Export contains the existing traceability, review, and controlled-export panel.

### Problem Frame

The current Result step combines the generated result with revision history, two-person review, and controlled export. A dedicated Export step separates those downstream actions while retaining the existing governed controls and visual language.

### Requirements

- R1. Show five ordered workflow steps: Data, Ask, Confirm, Result, and Export.
- R2. Keep plot status, run status, plot preview, and optional automated checks on Result.
- R3. Move the complete existing "Traceability, review, and export" panel to Export, including revision history, review controls, and controlled export.
- R4. Provide forward navigation from Result to Export and back navigation from Export to Result.
- R5. Preserve existing Shiny module IDs, server wiring, review rules, export eligibility, data drawer, styling, and accessibility semantics.
- R6. Keep lifecycle status and review context visible on Result; moving the action panel must not imply a policy or status transition.
- R7. Keep Export reachable whenever Result is active so the relocated modules retain their existing empty, running, and completed states.

### Scope Boundaries

- No change to review, revision, lifecycle, evidence, authorization, or export services.
- No dependency, public-interface, persistence, identity, or controlled-workspace changes.
- No redesign of the four existing step surfaces beyond the added navigation controls and five-column stepper.

### Acceptance Examples

- AE1. Given the workflow UI, the stepper renders five ordered labels and reports the active step as "Step 5 of 5" on Export.
- AE2. Given a generated result, when the user continues from Result, Export displays the relocated traceability, review, and export panel.
- AE3. Given Export is active, when the user selects Back to result, Result returns with the plot and automated checks still available.
- AE4. Existing review and export controls retain their namespaced IDs and behavior after relocation.

---

## Planning Contract

### Key Technical Decisions

- KTD1. Reuse the existing `active_step`, `step_ids`, `step_labels`, `set_step()`, `conditionalPanel()`, and Bootstrap classes. Do not introduce a tab library or navigation abstraction.
- KTD2. Keep `mod_revision_history_server()`, `mod_review_server()`, and `mod_export_server()` wired exactly once in `mod_plot_generation_server()`; only their UI placement changes.
- KTD3. Update the existing wizard solution note after verification so it records the five-step workflow and retains its linear forward/back navigation rule.

### Existing Patterns

- `R/mod_plot_generation.R` owns the current stepper, conditional step surfaces, and navigation events.
- `docs/solutions/four-step-wizard-flow.md` supplies the linear predecessor-navigation pattern.
- `docs/solutions/collapsible-panel-pattern.md` supplies the existing disclosure-panel styling.
- `tests/testthat/helper-app-browser.R` and `tests/testthat/test-app-browser.R` provide browser-test conventions.

### Sequencing

Add the failing structural/navigation proof first, make the smallest UI/server change that passes it, then run focused and browser verification. Do not alter domain services.

---

## Implementation Units

### U1. Five-step Export workflow

- **Execution note:** Test-first.
- **Goal:** Add Export as the fifth step and relocate the existing panel without changing governed behavior.
- **Files:** `tests/testthat/test-mod-plot-generation.R`, `R/mod_plot_generation.R`, and only if necessary `tests/testthat/test-app-browser.R`.
- **Approach:** First add a focused UI/navigation test for R1-R5. Then change the step grid to five columns, append `export`/`Export` to the existing step vectors, derive the total step count from those vectors, add Result-to-Export and Export-to-Result controls, and move the existing panel markup intact into an Export conditional section.
- **Test scenarios:** Five labels appear in order; Export is guarded by the Export step condition; the panel appears exactly once under Export; Result retains preview and automated checks; navigation handlers move Result -> Export -> Result while execution is running or complete; module IDs remain unchanged.
- **Verification:** Run the focused test file, relevant existing module tests, `git diff --check`, and the browser journey in the real Shiny app.

### U2. Five-step workflow guidance

- **Execution note:** Update after U1 verification.
- **Goal:** Keep the reusable workflow guidance aligned with the verified five-step implementation.
- **Files:** `docs/solutions/four-step-wizard-flow.md`.
- **Approach:** Replace four-step-specific F001 guidance with Data -> Ask -> Confirm -> Result -> Export and add the Result/Export predecessor navigation while preserving validation and refinement rules.
- **Test scenarios:** The guidance names all five steps in order, assigns Back navigation for every step with a predecessor, and no longer instructs future F001 work to stop at Result.
- **Verification:** Read the updated guidance against the verified UI and run `git diff --check`.

---

## Verification Contract

- **Focused R tests:** `testthat::test_file("tests/testthat/test-mod-plot-generation.R")` plus existing review/export module tests.
- **Configured suite:** `testthat::test_local(reporter = "summary")` when focused tests pass.
- **Static checks:** Parse changed R files and run `git diff --check`.
- **Browser proof:** Verify five-step rendering, Result -> Export -> Result navigation, and that review/export controls operate from Export.
- **Evidence boundary:** Static and server-side checks do not count as browser, statistical, or formal validation evidence.

---

## Definition of Done

- The visible workflow is Data -> Ask -> Confirm -> Result -> Export.
- The complete traceability/review/export panel exists only on Export.
- Result retains its plot, status, and optional automated checks.
- Existing review and controlled-export behavior is unchanged and verified by relevant tests.
- Browser verification confirms the fifth-step layout and bidirectional navigation.
- The main checkout's pre-existing uncommitted changes remain untouched.

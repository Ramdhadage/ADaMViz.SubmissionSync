---
title: Repository Audit Findings - Plan
type: fix
date: 2026-10-11
topic: repository-audit-findings
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready-with-policy-blockers
product_contract_source: ce-brainstorm
execution: code
---

# Repository Audit Findings - Plan

## Goal Capsule

**Objective:** Close the whole-repository audit findings without weakening the POC's clinical-data, evidence, review, or export boundaries.

**Means:** Repair the broken evidence SQL, minimize retained analytical data, bind verification to the submitted request and accepted artifacts, serve the accepted image, remove non-portable generated-script behavior, require evidence-backed lifecycle promotion, persist one configured evidence store per app instance, and align CI with repository checks. Resolve the three documented product-policy gaps before changing upload classification, production identity, or unreviewed export behavior.

**Success signal:** Focused regression tests pass for every changed boundary, the package test suite passes, and package check reports no warnings or errors. Browser rendering, target-environment qualification, and formal validation remain separate evidence.

**Authority:** [Product strategy](../product/STRATEGY.md), [architecture](../../ARCHITECTURE.md), and the current repository behavior define the boundary. The user's whole-repository audit and request to fix all findings authorize implementation, but do not settle contradictory product-policy records.

**Stop conditions:** Do not infer upload provenance from file shape, trust browser-supplied identity, or silently choose between Reviewed-only and draft-labelled unreviewed exports. Do not commit, push, publish, or merge without explicit authorization.

## Product Contract

### Summary

Make the existing assurance workflow fail closed at its trust boundaries and ensure that durable evidence, displayed artifacts, verification, lifecycle promotion, generated scripts, persistence, and CI all describe the same executed revision.

### Requirements

- R1. Revision creation writes valid SQL and remains covered by a repository regression test.
- R2. Durable revision evidence contains only the minimum pseudonymous analytical records needed for exact replay; it excludes raw subject identifiers, unrelated uploaded columns, and original filenames.
- R3. Governed previews and displayed code come from the accepted artifact bundle; experimental previews remain explicitly local and Draft.
- R4. Generated scripts require caller-supplied analysis data and the installed locked environment; they neither install packages nor contain checkout-specific fallback paths.
- R5. Verification rejects a result whose manifest fields do not match the submitted execution request or whose returned image identity cannot be independently confirmed.
- R6. A revision reaches Verified only through evidence-backed lifecycle promotion tied to its passing attempt and accepted bundle.
- R7. One configured durable evidence root is created per app instance and reused across sessions and revisions.
- R8. CI runs lint and fails package check on warnings as required by repository policy.
- R9. Direct uploads fail closed unless an approved, attributable classification mechanism supplies provenance; no synthetic default is permitted.
- R10. Production creator, reviewer, and exporter identity is server-derived; client controls cannot select or spoof the acting identity.
- R11. Export policy follows the user's selected resolution of the current conflict: Reviewed-only, or visibly and durably Draft-labelled unreviewed exports.

### Scope Boundaries

- No new dependencies, plot patterns, statistical rules, authentication platform, or qualified deployment claims.
- No alteration to accepted plot statistics or review-role separation.
- No commit, push, pull request, or merge in this run.
- Upload classification, production identity claims, and unreviewed export semantics remain blocked until the user selects their documented alternatives.

### Acceptance Examples

- AE1. Creating a revision succeeds in SQLite and the stored row can be read back.
- AE2. A source row containing a raw `USUBJID`, original filename, and unrelated canary column produces replay-capable evidence containing none of those values.
- AE3. A governed result page serves the accepted PNG and code hashes, while a missing or tampered artifact is rejected rather than reconstructed.
- AE4. A generated script run without injected `analysis_data` fails clearly and contains no package-install or checkout-path fallback.
- AE5. Verification rejects a runner response with a mismatched request identifier, snapshot identity, script identity, harness version, or image digest.
- AE6. Direct repository promotion without a passing attempt and accepted bundle fails.
- AE7. Two revisions created by the same app instance use the same configured repository root and remain discoverable after a new session.
- AE8. CI invokes lint and uses `devtools::check(error_on = "warning")`.

### Open Policy Decisions

- Which upload policy applies: governed synthetic fixtures only, or authenticated uploader attestation for public/synthetic/de-identified data?
- Which production identity source and claims map the authenticated subject and roles?
- Are exports Reviewed-only, or are Draft/Verified exports retained with a durable visible Draft label?

## Planning Contract

### Key Technical Decisions

- Reuse the existing provider, repository, artifact-store, execution-request, and Shiny-module boundaries; add no parallel framework.
- Persist only pseudonymous `analysis_data`; keep raw selected/display data in session memory.
- Verify returned execution fields against the submitted request before accepting artifacts.
- Use `shiny::renderImage(deleteFile = FALSE)` for accepted PNGs and the artifact store for displayed code.
- Configure persistence at the application composition root, not inside revision creation.

### Implementation Units

#### U1. Repair revision SQL

**Execution: test-first.** Add a focused create/read regression, then close the SQL column list in `R/evidence_repository_sqlite.R`.

**Files:** `R/evidence_repository_sqlite.R`, `tests/testthat/test-evidence-repository-contract.R`.

#### U2. Minimize durable analytical evidence

**Execution: test-first.** Add pseudonymization/minimization assertions, then create stable `analysis_data`, use it for execution hashing/input, and persist only whitelisted source metadata.

**Files:** `R/bds_profile.R`, `R/revision_evidence.R`, `R/app_server.R`, focused BDS/evidence/replay tests.

#### U3. Bind preview and code to accepted artifacts

**Execution: test-first.** Prove governed output reads accepted hashes, then serve the artifact-store PNG/code; preserve the local preview only for `Experimental/Draft`.

**Files:** `R/mod_plot_preview.R`, `R/app_server.R`, focused module/app tests.

#### U4. Remove generated-script side effects and local paths

**Execution: test-first.** Assert generated text contains neither installation code nor checkout paths and requires injected data, then simplify the compiler template.

**Files:** `R/boxplot_compiler.R`, compiler tests.

#### U5. Strengthen execution verification and lifecycle promotion

**Execution: test-first.** Add mismatch and bypass regressions, then compare request/result fields, independently validate image bytes, and require a passing attempt plus accepted bundle before Verified promotion.

**Files:** `R/verification_service.R`, `R/domain_execution_protocol.R`, `R/evidence_repository_sqlite.R`, `R/lifecycle_service.R`, helpers and focused tests.

#### U6. Persist the application evidence repository

**Execution: test-first.** Prove root reuse across revisions/sessions, then add an optional validated evidence root to runtime configuration and construct it once per app instance.

**Files:** `R/provider_runtime_config.R`, `R/run_app.R`, `R/app_server.R`, runtime/app tests.

#### U7. Align CI checks

**Execution: test-first.** Statistically assert the workflow contract, then run lint and make warnings fatal in package check.

**Files:** `.github/workflows/R-CMD-check.yaml`, focused workflow test if an existing pattern exists.

#### U8. Enforce upload classification

**Execution: test-first.** After the upload-policy decision, remove synthetic defaults, bind attributable classification into the immutable execution contract, and make missing provenance fail closed.

**Blocked by:** upload-policy decision.

#### U9. Make acting identity server-authoritative

**Execution: test-first.** After the identity-source decision, bind creator/reviewer/exporter to the session actor, remove client actor selectors, and fail closed in production when no authenticated actor is available.

**Blocked by:** production identity-source and claim-mapping decision.

#### U10. Resolve unreviewed export semantics

**Execution: test-first.** Implement the selected Reviewed-only or durable Draft-labelled behavior consistently across service, provider, ZIP, receipt, UI, tests, and contract documents.

**Blocked by:** export-policy decision.

### Verification Contract

1. Run the narrowest test files after each unit.
2. Run `devtools::test()` after integration.
3. Run `styler::style_pkg()`, `lintr::lint_package()`, and `devtools::check(error_on = "warning")` from the repository root.
4. Treat browser behavior as unverified unless `ce-test-browser` or an equivalent real-browser run succeeds.
5. Treat production authentication, regulated validation, and qualified target-environment behavior as unverified.

### Definition of Done

- Every unblocked audit finding has a passing regression and an integrated fix.
- The three policy-blocked findings are implemented after explicit decisions or reported as unresolved blockers, never silently defaulted.
- No raw subject identifier or original upload filename is stored in new revision context evidence.
- No generated script installs dependencies or references the developer checkout.
- Verification, accepted artifacts, preview, lifecycle status, and export all bind to the same immutable revision.
- Repository status and all checks are reported without committing or publishing changes.

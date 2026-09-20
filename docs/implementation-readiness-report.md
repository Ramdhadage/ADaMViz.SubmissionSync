# Implementation-readiness report

**Snapshot:** 2026-09-20  
**Scope:** Static repository and strategy review; no application code or requirements changed.

## Readiness

The repository is a functioning package-oriented R/Shiny foundation, not a greenfield project. It contains domain and service code, Shiny modules, injected local providers, synthetic fixtures, SQL/schema assets, and a substantial `testthat` suite. The existing plot-pattern plan and architecture explainer define a detailed first-cell scope. The repository is ready for a narrowly selected continuation of that approved scope, but not for an unspecified new feature or a claim of release/validation readiness.

## Strategy in force

- First priority is submission-oriented trust, followed by persistent study context and rapid iteration.
- The POC uses public, synthetic, or properly de-identified data. Draft and experimental outputs retain their stated limits; broader TLF support and persistent study context are post-POC.
- Current strategy targets are at least 80% first-pass review acceptance, at least 80% reproducibility, and median prompt-to-`Verified` under one minute. `Verified`-to-`Reviewed` is tracked separately, with a target deferred until pilot data exist.
- The strategy's demonstration date, 2026-09-07, has passed. Pilot and validation dates remain unset.

## Current structure

```text
root: DESCRIPTION, NAMESPACE, renv.lock, app.R, README.md, STRATEGY.md, AGENTS.md
R/: app composition, Shiny modules, domain objects, services, providers, execution
inst/: app assets and schemas, SQL schema/migrations, synthetic ADaM fixtures
tests/testthat/: unit, contract, service, module, smoke, and browser tests
docs/: plans, explainers, ideation, references, validation evidence/templates
.github/workflows/: R CMD check CI
```

This organization is suitable for the first POC; no structural refactor is needed before the next bounded slice. Preserve the current package-first shape and naming groups.

## Compound Engineering configuration

- The repository has no populated project-local `.codex` configuration and no `.agents` directory.
- The Plot-Pattern Assurance Cell plan uses `ce-unified-plan/v1` and contains implementation units, verification gates, and a Definition of Done.
- The user-level Compound Engineering plugin is installed, but no repository-specific agent or skill overrides were found.

## Documentation to reconcile before the next implementation slice

1. **Current execution state and next unit:** The plan still says “Greenfield” and `implementation-ready`; the traceability matrix labels some areas `Planned` or `Development evidence in progress`, despite corresponding code and tests now being present. Record which U1–U9 requirements are implemented, what evidence is actually available, and which single unit is next.
2. **Open product choices:** The September 6 explainer lists unresolved behavior for empty selections, unitless parameters/missing treatment values, review of `Experimental/Draft`, review submission/discovery, snapshot retention, event-chain scope, and supported viewport. Reconcile each relevant item against current code and approved decisions before extending that flow.
3. **Evaluation and metric protocol:** The strategy names an evaluation harness, but the repository does not expose a dedicated metric protocol/harness. Define the evaluated corpus and versioning, denominators, reviewer calibration, “material correction,” reproducibility pass criteria, and benchmark environment before reporting the 80% or one-minute metrics. The plan also sets 100% exact replay for `Reviewed` outputs; clarify how that per-output gate relates to the strategy's 80% aggregate target.
4. **Strategy milestone:** Replace or disposition the passed demonstration date and state the next agreed milestone before using the strategy as a schedule.

The target-environment and evidence-retention documents are explicitly templates. Their sponsor-owned approvals, qualified identity/storage/execution controls, and target-environment results are prerequisites for qualified deployment, not for continued synthetic local-POC work.

## Assumptions to clarify

- Which specific U1–U9 unit or requirement is the next task? The current request does not select one.
- Does the next slice remain within the first supported longitudinal ADaM BDS safety boxplot, or is a broader pattern/domain being proposed? The first-cell plan is narrower than the strategy's eventual safety-and-efficacy direction.
- For any provider-related change, is the intended scope still local/mock POC behavior, or has a target runtime/provider been approved? The strategy prohibits assuming a target environment.
- Are the explainer's open choices still open, already decided in implementation, or deferred? Do not infer their answers from current behavior alone.

## Proposed initial project structure

Retain the current package-oriented layout: keep `app.R` as a thin composition root; group implementation through the existing `app_*`, `mod_*`, `domain_*`, service, provider, and runner naming; keep schemas, SQL/migrations, and synthetic fixtures under `inst/`; and keep focused tests under `tests/testthat/`. Continue separating strategy, implementation plans, explainers, and validation evidence under `docs/`. Add decision records or operator guides only when an approved change creates a decision or operational procedure that needs a durable home.

## Review limits

No tests, package checks, app launch, browser flow, or target-environment verification were run. Existing uncommitted work was preserved.

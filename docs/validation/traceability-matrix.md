# Initial requirement traceability

This matrix is seeded by U1 and must be completed as requirements are
implemented. A local test or package check is development evidence only.

| Requirement area | Planned unit | Objective evidence | Status |
| --- | --- | --- | --- |
| R1-R8 prompt and specification | U2, U7, U8 | Schema, prompt, clarification, and UI tests | Planned |
| R9-R15 BDS envelope | U3, U6, U8 | Governed fixtures, blocking diagnostics, no-hidden-filter assertions, missing-value display exclusions | Development evidence in progress |
| R16-R24 statistics and display | U4, U8 | Independent oracle and plot-layer tests | Planned |
| R25-R28 experimental and deferred behavior | U2, U4, U7, U8 | Free-scale downgrade tests, arbitrary-transformation deferral, compiler allowlist, no-verification guard | Development evidence in progress |
| R29-R35 lifecycle and review | U2, U5, U8 | Transition, authorization, immutability, correction-successor, and review-flow tests | Development evidence in progress |
| R36-R40 evidence and export | U2, U5, U9 | Hash, persistence, export, and reconciliation tests | Development evidence in progress |

## U3 development evidence checkpoint

| Requirement or example | Control or implementation surface | Development evidence |
| --- | --- | --- |
| R9 permitted BDS source and required variables | `pin_study_snapshot()` hash-verified catalog metadata; `validate_bds_profile()` source metadata and required-column gates | `test-provider-study-data.R`; `test-bds-profile.R` |
| R10 no silent analysis-flag filtering | Explicit parameter, unit, treatment-level, and visit selections are the only profile filters before display-time missing-Y removal | `test-bds-profile.R` |
| R11-R12 duplicate subject-parameter-visit stop | Duplicate selected `USUBJID`/`PARAMCD`/visit keys return blocking diagnostics and no display rows; authorized duplicate detail is kept out of durable diagnostics | `test-bds-profile.R`; `test-synthetic-scenarios.R` |
| R13 deterministic visit order | Invalid, missing, conflicting, or reused `AVISIT`/`AVISITN` mappings block before plot generation | `test-bds-profile.R`; `test-synthetic-scenarios.R` |
| R14 missing selected Y exclusion | `display_data` and distinct-subject `N` exclude missing selected Y values while `selected_data` retains the stored selected records | `test-bds-profile.R`; downstream `test-boxplot-statistics.R` |
| R15 empty treatment-visit display omission | Empty treatment-visit combinations produce no box, median, or N row and are retained as structured warnings | `test-bds-profile.R`; `test-synthetic-scenarios.R` |

## R25-R28 development evidence checkpoint

| Requirement or example | Control or implementation surface | Development evidence |
| --- | --- | --- |
| R25 free-scale downgrade | Free-scale prompt interpretation requires confirmation; unconfirmed UI execution is blocked; confirmed free-scale artifacts and manifests are `Experimental/Draft` with reduced-comparability warning | `test-prompt-interpreter-mock.R`; `test-mod-specification.R`; `test-boxplot-assembly.R`; `test-boxplot-compiler.R` |
| R26 arbitrary transformations deferred | Prompt guard blocks code-generation and transformation intents before provider calls and returns no candidate or executable code | `test-prompt-interpreter-contract.R` |
| R27 governed operations only | The compiler emits only the canonical boxplot statistics and assembly calls and rejects executable/path-like generated code surfaces | `test-boxplot-compiler.R` |
| R28 future sandbox boundary | No arbitrary transformation path is accepted; `Experimental/Draft` revisions cannot be submitted for governed verification | `test-prompt-interpreter-contract.R`; `test-execution-service.R` |

## R29-R35 development evidence checkpoint

| Requirement or example | Control or implementation surface | Development evidence |
| --- | --- | --- |
| R29 initial revision identity | `create_revision()` stores one logical plot record, immutable revision identifier, revision number, creator, hashes, and initial `Draft` or `Experimental/Draft` status | `test-evidence-repository-contract.R`; `test-lifecycle-service.R` |
| R30 verification promotion | `new_execution_service()` and `mark_verified()` promote only eligible `Draft` revisions after complete execution verification; experimental drafts remain unverified | `test-execution-service.R`; `test-lifecycle-service.R` |
| R31 two independent approvals | `new_review_service()` requires active, distinct, non-creator reviewers with statistical-programmer and biostatistician roles before `Reviewed` | `test-review-service.R`; `test-mod-review.R`; `test-app-browser.R` |
| R32 reviewer decision evidence | Review decisions retain actor, role, timestamp, revision, decision, comment or rationale, authorization snapshot, immutable hashes, and record hash | `test-review-service.R`; `test-evidence-repository-sqlite.R` |
| R33 rejection and correction | Rejection appends an immutable decision, closes the revision, blocks competing review, and permits a documented child correction revision | `test-review-service.R`; `test-lifecycle-service.R`; `test-app-server-correction.R` |
| R34 reviewed immutability | Reviewed revisions reject further review edits; correction/refinement creates a separate child revision instead of mutating reviewed code or specification | `test-lifecycle-service.R`; `test-app-browser.R`; `test-app-server-correction.R` |
| R35 append-only logical history | Repository history disables update/delete, keeps parent and child revisions under one plot, rebuilds projections from events, and verifies event-chain integrity | `test-evidence-repository-contract.R`; `test-evidence-repository-sqlite.R`; `test-mod-revision-history.R` |

## U9 development evidence checkpoint

| Requirement or example | Control or implementation surface | Development evidence |
| --- | --- | --- |
| R36 retained internal evidence | App-created revisions record prompt, resolved specification, input snapshot identity and selected-data evidence, generated UTF-8 R code, execution result, environment details, checks, rendered-output hashes, warnings, lifecycle events, and review/export records | `test-revision-evidence.R`; `test-evidence-repository-sqlite.R`; `test-review-service.R`; `test-export-service.R` |
| R37 layered reproducibility | `new_reproducibility_service()` reruns retained revision context, verifies specification/code/analytical identity exactly, and treats image-byte equality as environment-fingerprint bound | `test-revision-evidence.R`; `test-execution-service.R`; `test-execution-runner-contract.R` |
| R38 export eligibility | `new_export_service()` and `mod_export_server()` block missing bundles, stale tokens, inactive or unauthorized actors, unknown destinations, and `Experimental/Draft` revisions | `test-export-service.R`; `test-mod-export.R` |
| R39 detached export files | Local workspace provider and app export module publish only `plot.png` and UTF-8 `script.R` in the visible export pair | `test-provider-workspace-contract.R`; `test-mod-export.R` |
| R40 internal linkage retained | Repository receipt records revision, destination, code hash, and image hash after final hash verification while internal evidence remains linked to the source revision | `test-export-service.R`; `test-mod-export.R`; existing backup/restore receipt checks |
| AE11 controlled export boundary | Registered logical destinations, safe export identifiers, no overwrite, final hash comparison, idempotent receipt replay, app export authorization, and staged-export quarantine | `test-export-service.R`; `test-provider-workspace-contract.R`; `test-export-reconciliation.R`; `test-mod-export.R` |

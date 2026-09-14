# Initial requirement traceability

This matrix is seeded by U1 and must be completed as requirements are
implemented. A local test or package check is development evidence only.

| Requirement area | Planned unit | Objective evidence | Status |
| --- | --- | --- | --- |
| R1-R8 prompt and specification | U2, U7, U8 | Schema, prompt, clarification, and UI tests | Planned |
| R9-R15 BDS envelope | U3, U6, U8 | Governed fixtures and blocking diagnostics | Planned |
| R16-R24 statistics and display | U4, U8 | Independent oracle and plot-layer tests | Planned |
| R29-R35 lifecycle and review | U2, U5, U8 | Transition, authorization, and immutability tests | Planned |
| R36-R40 evidence and export | U2, U5, U9 | Hash, persistence, export, and reconciliation tests | Development evidence in progress |

## U9 development evidence checkpoint

| Requirement or example | Control or implementation surface | Development evidence |
| --- | --- | --- |
| R36-R37 retained evidence and reproducibility | SQLite revision hashes, accepted artifact bundles, artifact-store hash verification, export receipts, integrity checks | `test-export-service.R`; existing repository integrity tests |
| R38 export eligibility | `new_export_service()` blocks missing bundles, stale tokens, inactive or unauthorized actors, unknown destinations, and `Experimental/Draft` revisions | `test-export-service.R` |
| R39 detached export files | Local workspace provider publishes only `plot.png` and `script.R` in the visible export pair | `test-provider-workspace-contract.R` |
| R40 internal linkage retained | Repository receipt records revision, destination, code hash, and image hash after final hash verification | `test-export-service.R`; existing backup/restore receipt checks |
| AE11 controlled export boundary | Registered logical destinations, safe export identifiers, no overwrite, final hash comparison, idempotent receipt replay, and staged-export quarantine | `test-export-service.R`; `test-provider-workspace-contract.R`; `test-export-reconciliation.R` |

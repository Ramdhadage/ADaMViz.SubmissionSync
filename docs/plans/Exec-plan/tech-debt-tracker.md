# Technical debt and project progress

**Last reviewed:** 2026-10-05  
**Scope:** Repository-documented implementation gaps and progress that still
needs evidence reconciliation. This tracker does not establish qualification,
release readiness, or new product requirements.

## Status convention

Preserve the status terms already used in the project: `Planned`,
`Development evidence in progress`, and `Deferred`. A row may be closed only
when its stated evidence is recorded. `Active` and `Completed` are folder
locations, not substitutes for requirement or validation status.

## Progress snapshot

| Work area | Available status | Current record | Next step |
| --- | --- | --- | --- |
| [Plot-Pattern Assurance Cell](../2026-09-06-0014-feat-plot-pattern-assurance-cell-plan.md) | Development evidence in progress | The consolidated plan now records the implementation inventory, evidence limits, and five-step Export workflow. Focused tests could not run because the local `testthat` package is incomplete and dependency bootstrap could not reach its repository. | Re-run focused, package, and browser checks in the restored project environment; reconcile U1-U9 and R1-R40 and record results. |
| [First POC workflow](../2026-09-20-1315-feat-first-poc-workflow-plan.md) | Development evidence in progress | The architecture describes the current Data → Ask → Confirm → Result → Export workflow. Plan-level acceptance and evidence have not been reconciled in the current readiness report. | Compare each acceptance criterion with the current workflow and its verification evidence; then record completion or remaining work. |
| Strategy evaluation metrics | Planned | The strategy defines first-pass quality, exact reproducibility, and automated turnaround targets. The readiness report says no dedicated metric protocol or harness is documented. | Define the evaluated corpus, denominators, reviewer calibration, pass criteria, and benchmark environment before reporting metric results. |
| Target-environment qualification and pilot dates | Deferred | Sponsor-owned approvals, qualified controls, UAT, and target-environment results remain prerequisites for qualified deployment; pilot and validation dates are unset. | Set dates and owners through the approved project process; retain the work as deferred until then. |

The progress entries above summarize existing documentation; they are not new
verification results. The latest implementation-readiness report is dated
2026-09-20 and explicitly says it did not run tests, package checks, app launch,
browser flows, or target-environment verification.

## Open technical debt

| ID | Gap | Available status | Evidence or impact | Closure evidence |
| --- | --- | --- | --- | --- |
| TD-01 | Requirement-to-implementation traceability is stale. | Development evidence in progress | The readiness report identifies an unresolved U1-U9 progress record; the traceability matrix still contains `Planned` and `Development evidence in progress` entries despite implementation being present in areas. | Requirement-by-requirement mapping to current implementation and recorded tests/checks; identify one next unit. |
| TD-02 | Upload format/profile checks do not prove data provenance or de-identification. | Development evidence in progress | Architecture notes that direct uploads carry no classification and format checks cannot establish synthetic provenance or de-identification. The permitted-data boundary remains a policy and workflow gap. | Approved provenance/attestation behavior and evidence that the implemented boundary enforces it. |
| TD-03 | UI review identities are local selectable actors rather than authenticated identities. | Deferred | Architecture describes local identities and lists production authentication as incomplete. | Approved identity integration and authorization evidence in the target environment. |
| TD-04 | The workspace export provider is development-only and lacks qualified target controls. | Deferred | Architecture lists filesystem/access-control guarantees as deferred; the traceability matrix records AE11 as having no qualifying evidence. | Qualified provider implementation plus target-environment evidence for the required controls. |
| TD-05 | Evidence is stored under temporary directories; durable retention and cross-session discovery are unsettled. | Deferred | Architecture identifies retention custody, cross-session discovery, automatic recovery, and production monitoring as open operational concerns. | Approved retention and recovery design with operational evidence for the selected deployment. |
| TD-06 | The displayed preview is reconstructed in the application process instead of showing the accepted worker PNG. | Development evidence in progress | Architecture records the difference between the preview and the worker-accepted artifact. | A resolved display decision and implementation/evidence showing the displayed artifact has the intended identity. |
| TD-07 | Replay is separately callable and is not a normal review/export prerequisite. | Deferred | Architecture documents a replay service but no automatic replay gate in the standard path. | Approved replay policy and evidence for its intended place in review/export, or a recorded decision to keep it separate. |
| TD-08 | Strategy metrics lack a documented evaluation protocol and dedicated harness. | Planned | The readiness report says the 80% and one-minute targets cannot yet be reported from a documented corpus, denominator, review definition, and benchmark environment. | Versioned protocol and harness results with the defined measurement context. |

## References

- [Implementation-readiness report](../../implementation-readiness-report.md)
- [Architecture and known gaps](../../../ARCHITECTURE.md)
- [Product strategy and metrics](../../product/STRATEGY.md)
- [Initial requirement traceability](../../validation/traceability-matrix.md)
- [Plan directory](..)

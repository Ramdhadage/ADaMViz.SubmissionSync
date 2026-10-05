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
| [Plot-Pattern Assurance Cell](../2026-09-06-0014-feat-plot-pattern-assurance-cell-plan.md) | Development evidence in progress | The consolidated plan incorporates the First POC workflow. Its 2026-10-05 inventory records U1-U9 implementation and evidence limits; focused tests did not run because local `testthat` was incomplete and `renv` could not reach its repository. CSV and Excel input support is retained by user decision; the older plan's four-step sequence differs from current five-step behavior and remains open. Upload attestation is absent and revision evidence retains selected rows including `USUBJID`. Earlier focused passes are not current gate results. | Restore the project environment, run focused/full/package/browser gates, and resolve the sequence, provenance, and identifier-retention gaps recorded in the canonical plan. |
| Strategy evaluation metrics | Planned | The strategy defines first-pass quality, exact reproducibility, and automated turnaround targets. The readiness report says no dedicated metric protocol or harness is documented. | Define the evaluated corpus, denominators, reviewer calibration, pass criteria, and benchmark environment before reporting metric results. |
| Target-environment qualification and pilot dates | Deferred | Sponsor-owned approvals, qualified controls, UAT, and target-environment results remain prerequisites for qualified deployment; pilot and validation dates are unset. | Set dates and owners through the approved project process; retain the work as deferred until then. |

These entries summarize inspected source and recorded evidence; this tracker
update did not run tests. The 2026-10-05 Plot-Pattern status inventory notes that
the focused test was blocked by incomplete local `testthat` and unreachable
dependency bootstrap. Earlier focused passes are dated 2026-09-14 in the test
evidence record. No first-POC browser, full-suite, or target-environment result
is recorded.

## Open technical debt

| ID | Gap | Available status | Evidence or impact | Closure evidence |
| --- | --- | --- | --- | --- |
| TD-01 | Requirement-to-implementation traceability is stale. | Development evidence in progress | The Plot-Pattern plan now has a U1-U9 inventory, but the matrix still marks R1-R8 and R16-R24 `Planned`; the First POC acceptance criteria are not fully reconciled. | Update requirement rows against current source, tests, and recorded results; select the next unit only after the mapping is complete. |
| TD-02 | Uploads lack proven provenance/de-identification, and persisted revision evidence includes raw subject IDs. | Development evidence in progress | Direct uploads carry no verified classification; the runner defaults unclassified inputs to synthetic. `revision_evidence` retains selected rows including `USUBJID`, while the First POC plan forbids raw identifiers in durable evidence. | Resolve the approved data boundary and evidence representation; record tests proving only permitted data and allowed identifiers reach retained evidence. |
| TD-03 | UI review identities are local selectable actors rather than authenticated identities. | Deferred | Architecture describes local identities and lists production authentication as incomplete. | Approved identity integration and authorization evidence in the target environment. |
| TD-04 | The workspace export provider is development-only and lacks qualified target controls. | Deferred | Architecture lists filesystem/access-control guarantees as deferred; the traceability matrix records AE11 as having no qualifying evidence. | Qualified provider implementation plus target-environment evidence for the required controls. |
| TD-05 | Evidence is stored under temporary directories; durable retention and cross-session discovery are unsettled. | Deferred | Architecture identifies retention custody, cross-session discovery, automatic recovery, and production monitoring as open operational concerns. | Approved retention and recovery design with operational evidence for the selected deployment. |
| TD-06 | The displayed preview is reconstructed in the application process instead of showing the accepted worker PNG. | Development evidence in progress | Architecture records the difference between the preview and the worker-accepted artifact. | A resolved display decision and implementation/evidence showing the displayed artifact has the intended identity. |
| TD-07 | `Verified` checks identity/completeness but does not itself prove independent statistical correctness or replay. | Development evidence in progress | `verification_service` validates request/data hashes, runner success, result manifest, analytical hash consistency, and image/environment hash shape. Replay is callable separately and is not a normal review/export prerequisite. | Align the `Verified` claim with the agreed per-revision checks and record oracle/replay evidence at the required boundary. |
| TD-08 | Export policy and reproducibility targets conflict across the plan and strategy. | Development evidence in progress | The 2026-10-05 plan records that R38 permits unreviewed export while strategy requires unreviewed outputs to be drafts; detached files omit status. The plan also retains 100% exact replay for Reviewed outputs while strategy targets 80%. | Keep both decisions open until reconciled; record the authorized policy and compatible measurement definitions before changing behavior. |
| TD-09 | Prompt interpretation is not part of the active upload workflow. | Development evidence in progress | The active path builds choices from the uploaded profile and user selections; the mock interpreter and disabled real-provider adapter are separate. The 2026-10-05 Plot-Pattern plan explicitly records this as incomplete. | Decide and deliver the provider integration/evaluation path, or keep it explicitly deferred and align the plan's goal/status. |
| TD-10 | Strategy metrics lack a documented evaluation protocol and dedicated harness. | Planned | The readiness report says the 80% and one-minute targets lack a defined corpus, denominator, review definition, and benchmark environment. | Version and approve the protocol/harness, then record results with the measurement context. |

## References

- [Implementation-readiness report](../../implementation-readiness-report.md)
- [Architecture and known gaps](../../../ARCHITECTURE.md)
- [Product strategy and metrics](../../product/STRATEGY.md)
- [Initial requirement traceability](../../validation/traceability-matrix.md)
- [Plan directory](..)

# Initial data-flow and threat model

The U1 boundary is intentionally provider-neutral:

1. A server session supplies the actor and runtime profile.
2. The Shiny composition root injects logical provider and workspace identifiers.
3. Domain services will receive permitted data and bounded prompt context.
4. Secret values are resolved only by an injected runtime provider and are not
   copied into configuration objects, browser state, logs, prompts, or scripts.

The local proof of concept accepts only public, synthetic, or properly
de-identified data. Production providers and controlled workspaces remain
disabled until their privacy, isolation, authorization, and target-environment
controls are separately qualified.

## Controlled export flow

1. The server-session actor is resolved through the injected identity provider.
2. The export service reads the immutable revision, expected version token, and
   accepted artifact bundle from the repository.
3. The artifact store returns the exact code and image bytes by hash.
4. The workspace provider accepts only a registered logical destination and a
   generated safe export identifier.
5. The provider stages `script.R` and `plot.png`, verifies hashes, removes the
   staging manifest, and publishes the pair without overwriting an existing
   export.
6. The export service rechecks authorization, version, revision hashes, final
   file hashes, and then records the internal receipt.

## Export threat checks

| Threat | Control |
| --- | --- |
| Prompt or UI supplies a path | Only logical destination identifiers are accepted by the export service and provider |
| Path traversal or reserved Windows name | Destination and export identifiers must pass the safe-token policy |
| Destination collision | Existing visible or staged exports are rejected; no overwrite is attempted |
| Partial staged pair after interruption | Reconciliation quarantines leftover staging directories |
| Metadata leakage in detached files | Visible exports contain only `script.R` and `plot.png`; status, scope, reviewer, prompt, and receipt data stay internal |

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

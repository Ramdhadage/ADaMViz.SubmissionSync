# ADaMViz SubmissionSync Architecture Context

## Product Scope and Audience

- **Product:** An R-first Shiny proof of concept for review-ready
  `ggplot2` visualizations and reproducible R code from permitted ADaM
  or tabular data.
- **Primary user:** Clinical scientists who are not developers.
- **Supporting reviewers:** Statistical programmers and
  biostatisticians.
- Plans and explainers describe intent; they are not implementation or
  validation evidence.
- The current UX specification is
  [docs/ux/F001-plot-generation.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/docs/ux/F001-plot-generation.md).

## Architecture Boundaries

- Keep the POC inside the approved `ggplot2` visualization scope unless
  the user approves expansion.
- Use R packages only for AI and LLM implementation unless the user
  explicitly changes this requirement.
- Maintain a production-oriented `golem` package structure with a
  readable `app.R` composition root and focused code under `R/`.
- Use `bslib` and Bootstrap 5 for the Shiny interface. Centralize
  branding and keep plots visually consistent with the application
  theme.
- Detailed implementation rules are scoped in
  [R/AGENTS.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/R/AGENTS.md);
  test and verification rules are scoped in
  [tests/AGENTS.md](https://ramdhadage.github.io/ADaMViz.SubmissionSync/tests/AGENTS.md).

## Clinical and UX Context

- Design for pharmaverse and GxP-compliant clinical-trial workflows
  where traceability, reproducibility, audit readiness, and human review
  are required.
- Follow the UX sequence: Define → Research → Analysis → Design →
  Prototype → Test → Launch → Iterate.
- Treat submission-oriented trust, persistent study context, and rapid
  iteration as the product priorities, in that order.
- “Fine-tuning” means conversational refinement of a plot, not
  model-weight training.

## Clinical and Security Boundaries

- Use only public, synthetic, or properly de-identified data in the POC.
- Never send patient-level or confidential data through general-purpose
  plugins, MCP servers, prompts, logs, or external services.
- Keep unreviewed outputs labeled `Draft`; label unevaluated plot
  patterns `Experimental` or `Draft`.
- Never describe the product as FDA validated or FDA approved. Use:
  **designed for validated clinical submission workflows**. Intended-use
  validation belongs to the regulated organization.
- Record permitted inputs, executed R code, package versions, outputs,
  review status, and relevant evaluation evidence for traceability and
  reproducibility.

## Research and Evidence

- Use official OpenAI documentation for OpenAI product or API claims.
- For requested clinical or regulatory research, prefer authoritative
  primary sources such as FDA, EMA, ICH, CDISC, peer-reviewed
  literature, and trial registries.

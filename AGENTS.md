# Repository Guidelines

## Scope and Authority

- Build **ADaMViz SubmissionSync** as an R-first Shiny proof of concept for review-ready `ggplot2` visualizations and reproducible R code from permitted ADaM or tabular data.
- Treat `STRATEGY.md` as the source of truth for scope, terminology, boundaries, and metrics. Plans and explainers describe intent; they are not implementation or validation evidence.
- Within platform, safety, and security constraints, the user's current explicit request overrides this file and skill guidance. More specific nested `AGENTS.md` guidance overrides broader repository guidance.
- Make small, focused changes; preserve unrelated and uncommitted work. Ask before changing requirements, business logic, interfaces, target environments, dependencies, or error-handling policy.

## UX Context

- UX stack: R/Shiny, pharmaverse, and clinical-trial workflows.
- Primary user: clinical scientist (non-developer); supporting reviewers: statistical programmer and biostatistician.
- Design for GxP-compliant workflows with required traceability; do not use patient-level data in the POC.
- UX spec: `docs/ux/F001-plot-generation.md` (current repository path).
- Follow the eight-step UX process: Define → Research → Analysis → Design → Prototype → Test → Launch → Iterate.

## R Engineering

- Use only R packages for AI and LLM implementation unless the user explicitly changes this requirement. Prefer `ellmer` for model interaction, `vitals` for evaluation, `ragnar` for retrieval-augmented generation, `shinychat` for chat UI, and `mcptools` for Model Context Protocol integration.
- Use modern R and tidyverse style: native `|>`, snake_case names, clear reactive boundaries, small functions, and namespace-qualified calls where ambiguity or background execution matters.
- Use `checkmate` for function-parameter and structured-spec validation. Use `cli` for user-facing errors, warnings, status messages, and progress.
- Use `golem` for production-grade Shiny application structure. Keep package code under `R/`, tests under `tests/testthat/`, and the `app.R` composition root readable; move substantial UI, server, plotting, validation, and LLM logic into focused functions or Shiny modules.
- Build the UI with `bslib` and Bootstrap 5 components. Centralize branding in a reusable `bs_theme()` or `_brand.yml`, minimize custom CSS, verify contrast and accessibility, and make plots visually consistent with the application theme.
- Use `mirai` only for work that would otherwise block Shiny or benefits materially from parallelism. Pass dependencies explicitly, namespace-qualify package calls on daemons, apply backpressure where needed, and clean up daemon pools.
- Apply the relevant installed skills: `tidy-r`, `cli`, `r-package-development`, `testing-r-packages`, `shiny-bslib`, `shiny-bslib-theming`, `mirai`, `cran-extrachecks`, and `openai-docs`.

## Testing and Verification

- Use `testthat` for function-level unit tests, `shiny::testServer()` for reactive and module server tests, and `shinytest2` for critical end-to-end browser flows.
- Keep tests deterministic, self-contained, behavior-focused, and independent of live LLM or external services. Use synthetic fixtures, mocks, temporary files, and explicit cleanup.
- Run targeted tests first, then the broader configured suite. Use `devtools::check()` for package-level verification; apply `cran-extrachecks` only when CRAN preparation is explicitly in scope.
- Do not invent commands or claim checks that the repository does not yet configure. Distinguish static checks, R execution, Shiny/browser behavior, statistical review, and formal validation.

## Clinical and Security Boundaries

- Use only public, synthetic, or properly de-identified data in the POC. Never send patient-level or confidential data through general-purpose plugins, MCP servers, prompts, logs, or external services.
- Keep unreviewed outputs labeled as drafts and unevaluated plot patterns labeled experimental or draft. Do not expand beyond the approved ggplot POC without permission.
- Never call the product FDA validated or FDA approved. Say it is **designed for validated clinical submission workflows**; intended-use validation belongs to the regulated organization.
- Record the permitted inputs, executed R code, package versions, outputs, review status, and relevant evaluation evidence needed for traceability and reproducibility.

## Reporting

- Report the files changed, checks run, results observed, and anything unverified. Use official OpenAI documentation for OpenAI product or API claims and authoritative primary sources for requested clinical or regulatory research.

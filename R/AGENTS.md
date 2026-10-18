# R and Shiny Engineering Rules

These rules apply to implementation files under `R/`. Read [root AGENTS.md](../AGENTS.md) for repository-wide process and authorization, and [CODEX_CONTEXT.md](../CODEX_CONTEXT.md) for product and safety boundaries.

## Stack and Structure

- Prefer `ellmer` for model interaction, `vitals` for evaluation, `ragnar` for retrieval-augmented generation, `shinychat` for chat UI, and `mcptools` for Model Context Protocol integration when those capabilities are in approved scope.
- Use modern R and tidyverse style: native `|>`, snake_case names, small functions, clear reactive boundaries, and namespace-qualified calls where ambiguity or background execution matters.
- Use `checkmate` for function-parameter and structured-spec validation. Use `cli` for user-facing errors, warnings, status messages, and progress.
- Keep substantial UI, server, plotting, validation, and LLM logic in focused functions or Shiny modules. Preserve `app.R` as a readable composition root.

## Shiny UI

- Build with `bslib` and Bootstrap 5 components. Reuse the centralized theme, minimize custom CSS, verify contrast and accessibility, and keep plots aligned with the application theme.
- For Shiny work, use the installed `shiny-for-r` skill: read its index and only the linked references relevant to the task.
- Apply other installed skills when relevant, including `tidy-r`, `cli`, `r-package-development`, `testing-r-packages`, `shiny-bslib`, `shiny-bslib-theming`, `cran-extrachecks`, and `openai-docs`.

## Local Verification

- Run focused tests for changed behavior before broader checks; follow [`../tests/AGENTS.md`](../tests/AGENTS.md) when changing tests.
- Before claiming R/package implementation complete, follow the [verification completion gate and full local sequence](../docs/development/verification.md) in the existing VS Code integrated terminal. Report verification pending if a required check fails or cannot run.
- Before running `app.R`, restart any R session with the package namespace loaded and run `devtools::install()` using the project R installation from the existing VS Code integrated terminal. The root script calls `ADaMViz.SubmissionSync::run_app()` from the installed namespace.

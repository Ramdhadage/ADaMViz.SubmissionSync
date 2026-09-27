# R and Shiny Engineering Rules

These rules apply to implementation files under `R/`. Repository-wide product and safety boundaries remain in [`../CODEX_CONTEXT.md`](../CODEX_CONTEXT.md).

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
- After package development is complete, restart R if the namespace is loaded, then run `devtools::install()` from the RStudio Console at the repository root before running `app.R`. The root script calls `ADaMViz.SubmissionSync::run_app()` from the installed namespace.

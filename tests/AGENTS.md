# R Package Test Rules

These rules apply to tests under `tests/`. Repository-wide product and safety boundaries remain in [`../CODEX_CONTEXT.md`](../CODEX_CONTEXT.md).

## Test Layers

- Use `testthat` for function-level unit tests, `shiny::testServer()` for reactive and module server tests, and `shinytest2` for critical end-to-end browser flows.
- Keep tests deterministic, self-contained, and behavior-focused. Avoid live LLMs and external services; use synthetic fixtures, mocks, temporary files, and explicit cleanup.
- Add or update the narrowest test that proves changed behavior. Do not duplicate coverage that belongs in an existing test.

## Verification Order

- During development, run focused tests first, then `devtools::test()`.
- Run `covr::package_coverage()` periodically to identify untested code. Treat coverage as diagnostic evidence, not proof of test quality or formal validation.
- Use `devtools::check()` for package-level verification. Apply `cran-extrachecks` only when CRAN preparation is explicitly in scope.
- Use `ce-test-browser` when browser verification is requested. A static or server-side check is not browser evidence.
- Do not invent commands or claim checks the repository does not configure. Report focused tests, package checks, browser checks, statistical review, and formal validation separately.

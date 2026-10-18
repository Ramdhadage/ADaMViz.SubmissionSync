# R Package Test Rules

These rules apply to tests under `tests/`. Read [root AGENTS.md](../AGENTS.md) for repository-wide process and authorization, and [CODEX_CONTEXT.md](../CODEX_CONTEXT.md) for product and safety boundaries.

## Test Layers

- Use `testthat` for function-level unit tests, `shiny::testServer()` for reactive and module server tests, and `shinytest2` for critical end-to-end browser flows.
- Keep tests deterministic, self-contained, and behavior-focused. Avoid live LLMs and external services; use synthetic fixtures, mocks, temporary files, and explicit cleanup.
- Add or update the narrowest test that proves changed behavior. Do not duplicate coverage that belongs in an existing test.

## Verification Order

- During development, run focused tests first, then `devtools::test()`.
- Run `covr::package_coverage()` periodically to identify untested code. Treat coverage as diagnostic evidence, not proof of test quality or formal validation.
- Before claiming test/package work complete, follow the [verification completion gate and full local sequence](../docs/development/verification.md) in the existing VS Code integrated terminal. This includes `devtools::check(error_on = "warning")`; report verification pending if a required check fails or cannot run. Apply `cran-extrachecks` only when CRAN preparation is explicitly in scope.
- Use `ce-test-browser` with Chrome DevTools MCP to verify affected UI/browser behavior; follow the [browser verification requirements](../docs/development/verification.md#ui-and-browser-verification). If the app or MCP connection is unavailable, report browser verification pending. A static or server-side check is not browser evidence.
- Do not invent commands or claim checks the repository does not configure. Report focused tests, package checks, browser checks, statistical review, and formal validation separately.

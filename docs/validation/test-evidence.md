# Test evidence template

Record local and target-environment results separately. Do not promote local
development results to validation evidence.

| Date | Environment | Command or protocol | Scope | Result | Evidence location |
| --- | --- | --- | --- | --- | --- |
| 2026-09-14 | Local Windows R 4.6.0 | `testthat::test_file()` focused U3 files | R9-R15 BDS envelope, governed synthetic scenarios, local study-data provider | Passed locally | Console output |
| 2026-09-14 | Local Windows R 4.6.0 | `testthat::test_file()` focused R25-R28 files | Free-scale downgrade, arbitrary-transformation deferral, governed compiler surface, no-verification guard | Passed locally | Console output |
| 2026-09-14 | Local Windows R 4.6.0 | `testthat::test_file()` focused U9 files | Revision evidence, reproducibility rerun, export service, app export module, development-only workspace mechanics, reconciliation | Passed locally; not AE11 qualification evidence | Console output |

## Focused U3 commands

```r
devtools::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-provider-study-data.R")
testthat::test_file("tests/testthat/test-bds-profile.R")
testthat::test_file("tests/testthat/test-synthetic-scenarios.R")
```

## Focused R25-R28 commands

```r
devtools::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-prompt-interpreter-contract.R")
testthat::test_file("tests/testthat/test-prompt-interpreter-mock.R")
testthat::test_file("tests/testthat/test-mod-specification.R")
testthat::test_file("tests/testthat/test-boxplot-assembly.R")
testthat::test_file("tests/testthat/test-boxplot-compiler.R")
testthat::test_file("tests/testthat/test-execution-service.R")
```

## Focused U9 commands

```r
devtools::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-provider-workspace-contract.R")
testthat::test_file("tests/testthat/test-revision-evidence.R")
testthat::test_file("tests/testthat/test-mod-export.R")
testthat::test_file("tests/testthat/test-export-service.R")
testthat::test_file("tests/testthat/test-export-reconciliation.R")
```

## Required later evidence

- Full `devtools::test()` and `devtools::check(error_on = "warning")` results.
- Browser export workflow evidence when Chromote is available for
  `test-app-export-browser.R`.
- Target-environment protocol execution with qualified identity, storage, ACLs,
  backup, and recovery controls.

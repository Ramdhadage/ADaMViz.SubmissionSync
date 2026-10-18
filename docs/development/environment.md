# Development environment

The standalone environment check compares the running R session with
[`renv.lock`](../../renv.lock). It requires exactly the recorded R version and
uses `renv::status()` to check the active library against the lockfile and project
dependencies. A mismatch raises an R error and gives a nonzero exit status when
run with `Rscript`. The check never installs packages, updates the lockfile, or
changes application configuration. CI and application startup do not invoke it.

## Sources of truth

| Artifact | Responsibility |
| --- | --- |
| [`DESCRIPTION`](../../DESCRIPTION) | Package dependency declarations and minimum supported R version; this is not an exact environment pin |
| [`renv.lock`](../../renv.lock) | Exact package versions, package sources, repositories, and the R version required by this check |
| [`.Rprofile`](../../.Rprofile), [`renv/activate.R`](../../renv/activate.R), [`renv/settings.json`](../../renv/settings.json) | Activate and configure the project library |
| [`.Renviron.example`](../../.Renviron.example) | Existing optional configuration variables and local defaults |
| [`dev/check-environment.R`](../../dev/check-environment.R) | Check the current environment and optionally save its observed state |
| [`verification.md`](verification.md) | Required package verification and CI boundaries |

Read the exact R version directly from `renv.lock`; do not maintain another copy
in this document. `renv` records R but does not install or switch the R runtime.

## Recreate the package environment

1. Read the `R.Version` value in `renv.lock` and install or select that exact R
   version in your editor.
2. Open the repository root. Normal R startup sources `.Rprofile` and activates
   the project library. Do not use `--vanilla` for the standalone check.
3. From the project R session, explicitly restore the approved lockfile:

   ```r
   renv::restore(prompt = FALSE)
   ```

4. Run the check below before installing or launching the application. The
   [README](../../README.md#run-locally) describes package installation and launch.

Project startup may bootstrap a missing `renv` installation, and an explicit
restore may download packages. Those are setup actions, separate from the check.
If startup fails, or reports missing package `DESCRIPTION` files, diagnose the
library/cache before making changes; do not assume that another restore is safe.
Never snapshot a mismatched environment merely to make this check pass.

## Run the standalone check

In the existing VS Code integrated PowerShell terminal, at the repository root:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' dev/check-environment.R
if ($LASTEXITCODE -ne 0) { throw "Environment check failed" }
```

The executable path above is the current local installation. If the approved
lockfile changes, select the matching executable before running the check.

To keep a JSON report, supply a new output path:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' dev/check-environment.R environment-report.json
if ($LASTEXITCODE -ne 0) { throw "Environment check failed; inspect the report if written" }
```

From an R session already using the project environment:

```r
source("dev/check-environment.R")
check_environment()
check_environment(report = "environment-report.json")
```

The report is written before an R/package mismatch raises an error, so it can
describe a failed check. A missing prerequisite, unreadable lockfile, or other
error before report generation can prevent it being written. Existing report
files are never overwritten; choose a new name for another run. Root-level
`environment-report*.json` files are ignored by Git and excluded from package
builds, as are local `.Renviron` files.

The report records the lockfile checksum, expected package versions, observed
installed package versions and library paths, R/platform/OS details, locale,
timezone, external libraries reported by R, and discoverable tool paths. The
checksum identifies the lockfile used; it is not an integrity attestation.
It does not dump environment variables, credentials, patient data, or host/user
names. Library and tool paths can still contain local user names; review the
report before sharing it.

## System requirements and configuration

Windows is the current local development platform. The core package CI job uses
Ubuntu 24.04 and selects R `release`; it is not pinned to `renv.lock` by this
change. Other jobs have their own environments. See
[`check.yaml`](../../.github/workflows/check.yaml) and
[`build-check-install.yaml`](../../.github/workflows/build-check-install.yaml).
These configurations do not establish production qualification.

| Component | When it is needed |
| --- | --- |
| R | The standalone check requires the exact lockfile version |
| R packages | Restore the lockfile, including development/check dependencies needed for the intended task |
| Windows build tools | Use Rtools matching the selected R release when compiling packages from source |
| Linux system libraries | Follow the relevant CI image/workflow and package system requirements when building on Linux |
| Pandoc | Needed to render R Markdown documentation; installing `rmarkdown` alone does not pin Pandoc |
| Chrome/Chromium | Needed for browser tests; see the verification guide |
| Fonts and graphics libraries | Affect rendering; matching package versions alone does not guarantee identical plot images |
| Git | Needed for repository development |

Tool paths, OS, external libraries, locale, and timezone are observations, not
additional pass/fail requirements. This change introduces no new supported OS,
font, compiler, or external-tool version policy. Quarto is reported when found
on `PATH` but is not required by this check. Tools bundled with an editor may
exist even when they are absent from `PATH`.

All variables in `.Renviron.example` are optional for the local mock workflow.
Copy the template to an untracked `.Renviron` only when overrides are needed,
then restart R. Leave optional paths unset to keep existing application defaults.
Provider identifiers select configuration; they do not authenticate a user or
configure a working external model integration. Actual credentials remain outside
source, logs, generated scripts, and execution evidence.

## Verification and limits

Run the focused checker tests from the repository root:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' dev/test-environment.R
if ($LASTEXITCODE -ne 0) { throw "Environment checker tests failed" }
```

The check supplements the [full local verification sequence](verification.md).
It does not run package tests, verify browser behavior, establish statistical
correctness, or qualify a regulated environment. Its development JSON report is
separate from the application's revision evidence and environment fingerprint.
It does not prove package binary identity, repository availability, system-library
equivalence, or reproducibility across operating systems. A container or retained
machine image would require a separate approved environment decision.

## References

Official documentation accessed 2026-10-18:

- [renv introduction and caveats](https://rstudio.github.io/renv/articles/renv.html#caveats)
- [renv status checks and return value](https://rstudio.github.io/renv/reference/status.html)
- [renv with Docker](https://rstudio.github.io/renv/articles/docker.html)

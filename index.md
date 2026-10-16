# ADaMViz SubmissionSync

[![R CMD
check](https://img.shields.io/github/actions/workflow/status/Ramdhadage/ADaMViz.SubmissionSync/check.yaml?branch=main&label=R%20CMD%20check)](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/actions/workflows/check.yaml)
[![Documentation
build](https://img.shields.io/github/actions/workflow/status/Ramdhadage/ADaMViz.SubmissionSync/pkgdown.yaml?branch=main&label=docs)](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/actions/workflows/pkgdown.yaml)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://ramdhadage.github.io/ADaMViz.SubmissionSync/LICENSE)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Commits per
month](https://img.shields.io/github/commit-activity/m/Ramdhadage/ADaMViz.SubmissionSync)](https://github.com/Ramdhadage/ADaMViz.SubmissionSync/commits/main/)
[![Test
coverage](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Framdhadage.github.io%2FADaMViz.SubmissionSync%2Fcoverage-report%2Fcoverage.xml&query=round%28100%20%2A%20%2Fcoverage%2F%40line-rate%29&suffix=%25&label=coverage&color=blue)](https://ramdhadage.github.io/ADaMViz.SubmissionSync/coverage-report/)

ADaMViz SubmissionSync is an R-first Shiny proof of concept for
review-ready clinical visualizations and reproducible R code from
permitted ADaM or tabular data. It is designed for validated clinical
submission workflows; it is not FDA validated or FDA approved.

**Live app:** [Open ADaMViz
SubmissionSync](https://ramnath-dhadage.shinyapps.io/ADaMViz-SubmissionSync/)

**Prototype preview:**

[![Rendered F001 plot-generation
prototype](inst/app/www/wireframe.png)](https://htmlpreview.github.io/?https://raw.githubusercontent.com/Ramdhadage/ADaMViz.SubmissionSync/main/docs/ux/F001-plot-generation-prototype.html)

[View in Full
Screen](https://htmlpreview.github.io/?https://raw.githubusercontent.com/Ramdhadage/ADaMViz.SubmissionSync/main/docs/ux/F001-plot-generation-prototype.html)

## Development status

The application follows **Data → Ask → Confirm → Result → Export**. Its
shared frame follows the F001 prototype: a blue **ADaMViz
SubmissionSync** header with a GitHub link, a white **Create plot** bar
showing the current step out of five, and a footer crediting Ramnath
Dhadage with **Source Code** and **Report Issues** links.

See the [F001 UX
documentation](https://ramdhadage.github.io/ADaMViz.SubmissionSync/docs/ux/F001-plot-generation.html#application-frame)
for the frame’s source files. The preview image above is a static
prototype; the hosted app may differ until the updated package is
deployed.

The first Plot-Pattern Assurance Cell is being implemented
incrementally. The current application shell uses injected local
providers for runtime configuration, study data, identity, evidence
storage, artifacts, and controlled workspace export. Only public,
synthetic, or properly de-identified data may be used during this proof
of concept.

## Run locally

The package is intended to run from a locked `renv` environment:

``` r

renv::restore(prompt = FALSE)
devtools::install()
ADaMViz.SubmissionSync::run_app()
```

After changing application source or CSS, restart R and run
[`devtools::install()`](https://devtools.r-lib.org/reference/install.html)
from the RStudio Console at the repository root before launching
`app.R`. The launcher uses the installed package.

Provider credentials and secret values must remain outside source files,
prompts, logs, generated scripts, and retained evidence.

Controlled exports are addressed by logical workspace identifiers. A
local POC workspace export writes a detached `plot.png` and `script.R`
pair only after the accepted artifact hashes, acting user, revision
token, destination, and final file hashes are rechecked. The receipt
stays inside the internal evidence store.

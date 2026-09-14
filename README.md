# ADaMViz SubmissionSync

ADaMViz SubmissionSync is an R-first Shiny proof of concept for review-ready
clinical visualizations and reproducible R code from permitted ADaM or tabular
data. It is designed for validated clinical submission workflows; it is not
FDA validated or FDA approved.

## Development status

The first Plot-Pattern Assurance Cell is being implemented incrementally. The
current application shell uses injected local providers for runtime
configuration, study data, identity, evidence storage, artifacts, and controlled
workspace export. Only public, synthetic, or properly de-identified data may be
used during this proof of concept.

## Run locally

The package is intended to run from a locked `renv` environment:

```r
renv::restore(prompt = FALSE)
devtools::load_all()
ADaMViz.SubmissionSync::run_app()
```

Provider credentials and secret values must remain outside source files,
prompts, logs, generated scripts, and retained evidence.

Controlled exports are addressed by logical workspace identifiers. A local POC
workspace export writes a detached `plot.png` and `script.R` pair only after the
accepted artifact hashes, acting user, revision token, destination, and final
file hashes are rechecked. The receipt stays inside the internal evidence store.

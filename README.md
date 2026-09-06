# ADaMViz SubmissionSync

ADaMViz SubmissionSync is an R-first Shiny proof of concept for review-ready
clinical visualizations and reproducible R code from permitted ADaM or tabular
data. It is designed for validated clinical submission workflows; it is not
FDA validated or FDA approved.

## Development status

The first Plot-Pattern Assurance Cell is being implemented incrementally. The
current application shell uses an injected local runtime configuration and a
deterministic empty state. Only public, synthetic, or properly de-identified
data may be used during this proof of concept.

## Run locally

The package is intended to run from a locked `renv` environment:

```r
renv::restore(prompt = FALSE)
devtools::load_all()
ADaMViz.SubmissionSync::run_app()
```

Provider credentials and secret values must remain outside source files,
prompts, logs, generated scripts, and retained evidence.

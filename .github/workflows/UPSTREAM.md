# Vendored R package workflows

The following reusable workflows were copied from
[`insightsengineering/r.pkg.template` at `9a4999333bb39887c2600295739b1e592152cb21`](https://github.com/insightsengineering/r.pkg.template/tree/9a4999333bb39887c2600295739b1e592152cb21/.github/workflows):
`audit.yaml`, `build-check-install.yaml`, `gitleaks.yaml`, `licenses.yaml`,
`links.yaml`, `linter.yaml`, `roxygen.yaml`, `spelling.yaml`, `style.yaml`,
`test-coverage.yaml`, `version-bump.yaml`, and `version.yaml`.

The copied files are licensed under Apache License 2.0. Copyright 2022
F. Hoffmann-La Roche AG. The license text is in
[`LICENSE-APACHE-2.0.txt`](LICENSE-APACHE-2.0.txt).

Local changes remove each copied workflow's standalone push, pull request, and
manual triggers. `check.yaml` calls them through `workflow_call` so the checks
and write jobs run once per event. Further local fixes select the push branch
for roxygen auto-updates and correct invalid expressions and token references
in `test-coverage.yaml`. CI feedback also required renv-compatible package
setup in the R checks, coverage, roxygen, linter, style, and link jobs.
Repository-specific edits after this copy should be reviewed against the
upstream source before updating it.

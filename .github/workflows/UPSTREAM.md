# Vendored R package workflows

The following reusable workflows are stored in this [workflows](./) folder:
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
setup in the R checks, coverage, roxygen, linter, style, and link jobs. This
package's `.Rprofile` activates renv inside the template's pak subprocess and
hides pak from the library installed by its setup action; the affected jobs
disable that autoloader during setup. Other R tools are installed or restored
within the project library before use.
Repository-specific edits after this copy should be reviewed against the
upstream source before updating it.

## Local CI repair (2026-10-14)

Read-only checks use the immutable event PR head SHA or push SHA. Roxygen,
spelling and version bump run in that order; main writers checkout the current
main branch so previous generated commits are retained. Main writers use the
repository GITHUB_TOKEN. The final generated-check job validates the resulting
main revision with the same documentation, lint, tests and warning-failing
package check as the original strict check, and records its SHA.

Open same-repository PR updates require the configured REPO_GITHUB_TOKEN so
generated commits start their own required checks. Without that token, changes
must be applied manually; the job fails on unresolved generated differences.
Forks cannot write. Closed PRs keep immutable checks and report that generated
updates are not published. Stale write targets or failed pushes fail visibly.

| Required result | PR | main push |
| --- | --- | --- |
| Strict check, audit, both R CMD variants, coverage, full baseline lint, roxygen, gitleaks, spelling, URL Checker, version, licenses, style | Required | Required |
| Version bump and final generated revision check | Skipped | Required |
| Lychee, Covtracer, PII, tag-only release and multiversion report paths | Disabled or condition not met | Disabled or condition not met |

Style remains limited to changed R/source-document files; main is read-only.
The caller's Required CI results job fails for any missing, failed or skipped
required result. Report publishers retry against the latest gh-pages revision;
pkgdown keeps other report directories, disables force pushes, and permits five
rebase attempts. Concurrent writes that cannot be reconciled fail visibly.

Pkgdown is called only after Required CI results and the final generated revision
check pass on a main push. It checks out that job's recorded SHA, checks that the
first NEWS heading matches DESCRIPTION, and includes the version and source SHA
in its gh-pages commit message. Standalone push, PR, release and manual pkgdown
triggers are removed so they cannot bypass the publication gate.

### Retained external runtime references

The copied YAML remains local integration code. These images were resolved
from public registry manifests on 2026-10-14, preserving the then-current runtime:

- ghcr.io/insightsengineering/rstudio at sha256:b7fce5f56d0f979f33304b8d74ab878fd4f78db81278aeedc3a8ad6f22e86428
- docker.io/rocker/tidyverse at sha256:94a4cdb7be4d1214f9039bca4937e8919253d2ad90d8bed084e9a8af685a50c7

Digest identity is verified; container execution and hosted compatibility remain
part of the PR/main verification checkpoint. Action major-version tags remain
explicitly mutable, whereas existing SHA-pinned actions retain those pins.

| Reference | Local use |
| --- | --- |
| sonatype-nexus-community/oysteR at 8e25ba01fbc6b783bdc0fb5514442d6a8b6e1066 | Audit scanner restored reproducibly from upstream source |
| insightsengineering/staged-dependencies-action@v2 | Optional staged dependency setup, inactive for current callers |
| insightsengineering/setup-r-dependencies@v1 | Active dependency setup for package checks, roxygen and coverage |
| insightsengineering/coverage-action@v3 | Optional posting after validated real coverage output |
| insightsengineering/covtracer-action@v1 | Optional disabled Covtracer scan |
| insightsengineering/r-spellcheck-action@v3 | Active package spelling analysis |
| insightsengineering/pip-action@v2 | NEWS emoji-check dependency setup |
| insightsengineering/presidio-action@v1 | Optional disabled PII scan |
| insightsengineering/release-existence-action@v1 | Tag-only release path |
| insightsengineering/junit-xml-diff v0.4.0 | Active PR comparison of current and baseline JUnit XML; versioned executable download |
| insightsengineering/r-pkgdown-multiversion marker | Conditional site-layout detection; current repository publishes a single-version site |
| JamesIves/github-pages-deploy-action@v4.7.3 | pkgdown deployment; clean:false, force:false, attempt-limit:5 |
| zricethezav/gitleaks v8.18.1 release executable | Active secret scan |

The external r-license-report Docker action was replaced by a local locked
scanner. Report publication no longer uses peaceiris/actions-gh-pages or
ad-m/github-push-action; bounded latest-ref git retries preserve other report
destinations and separate CRAN/non-CRAN JUnit history.

The misleading Insights Engineering URL exclusion and tern.gee help link were
removed. Local uses targets, package-subdirectory, main, gh-pages, renv.lock,
_pkgdown.yml and inst/WORDLIST remain repository concepts. See each workflow for
the exact pins of other retained GitHub/R-lib, lint, artifact and comment actions.

Hosted evidence still required: PR and main run URLs, scanner outputs and failure
injection, final generated main SHA, live open/deleted/fork PR behavior, and
preservation of site plus real coverage/JUnit reports under concurrent publishing.

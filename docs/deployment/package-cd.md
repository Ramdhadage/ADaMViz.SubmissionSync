# Package CD

Package CI calls [Package CD](../../.github/workflows/deploy.yaml) after its
required results gate and final generated-revision check succeed for a push to
`main`. Pull requests, manual Package CI runs, failed checks, skipped required
checks, and cancelled runs cannot deploy.

## Setup

Set these repository Actions secrets before the first deployment:

- `SHINYAPPSIO_TOKEN`
- `SHINYAPPSIO_SECRET`

Use credentials for the existing `ramnath-dhadage` shinyapps.io account. Keep
their values out of source, issues, and workflow inputs. The tracked deployment
record selects app ID `18047061`, named `ADaMViz-SubmissionSync`, at
<https://ramnath-dhadage.shinyapps.io/ADaMViz-SubmissionSync/>.

## Deployment behavior

The three CI generators report only commits they created in the current run.
The final check rejects intervening commits from other pushes, checks the
resulting revision, and passes its SHA to CD. A newer push must pass its own CI.

CD restores `renv.lock`, installs pak if absent, and installs
`Ramdhadage/ADaMViz.SubmissionSync@<checked-sha>` using pak. It updates only that
package's entry in the runner's lockfile. Other dependency versions remain
locked; the workflow does not commit generated changes.

The bundle retains `R/`, `inst/`, `renv/`, `NAMESPACE`, `DESCRIPTION`,
`renv.lock`, and `app.R`. The app title remains
`ADaMViz.SubmissionSync: Review-Ready Clinical Figures`. Deployment uses the
existing app ID, `lint = FALSE`, and `forceUpdate = TRUE`.

CD uses read-only repository permissions and exposes deployment credentials
only to the deployment step. Uploads are serialized without cancelling an
active deployment. A stale revision fails before dependency restoration or
upload. A push during an active upload cannot make GitHub and shinyapps.io
atomic; a later successful run deploys the newer revision.

Environment preparation repeats because CD has a fresh runner. Package lint,
tests, audit, documentation, and package checks stay in Package CI. Strict
rsconnect dependency resolution remains enabled; deployment failures are not
converted into success or retried with a weaker dependency scanner.

## Verify a deployment

After this workflow is reviewed, committed, and pushed, inspect the Package CD
job nested in the Package CI run. The deployment step writes the deployed SHA
and app URL to the run summary only after `deployApp()` returns successfully.
Use Chrome DevTools to open the app, confirm the Shiny connection, exercise the
upload/continue flow with synthetic data, and inspect console errors.

A browser check of the existing app before that run is baseline evidence. It
does not prove this workflow has restored dependencies or deployed a new bundle.

## Local verification on 2026-10-15

- actionlint 1.7.12 passed for all five changed workflow files.
- The actual CD conditions passed 240 event, branch, and upstream-result cases.
- The actual revision guard accepted same-run generated commits and no-op
  generators; it rejected missing outputs, intervening external commits,
  external commits beneath generated commits, stale reruns, and unrelated
  force-push history. The freshness guard accepted current main and rejected a
  stale revision.
- Embedded R parsed successfully. Focused checks covered missing credentials
  and absent, duplicate, wrong-ID, and wrong-account deployment records. A
  source-level regression probe of locked rsconnect 1.11.0 confirmed that
  `excludeOrphaned = FALSE` retains tracked records before account registration.
- Chrome DevTools observed HTTP 200, an active Shiny connection, the initial
  upload screen, and no console warnings or errors on the existing live app.
  Upload testing was blocked by the browser tool's configured workspace-root
  check. Runner dependency restoration and authenticated CD remain unverified.

The workflow follows [teal.gallery's deployment reference](https://github.com/insightsengineering/teal.gallery/blob/main/.github/workflows/deploy.yml)
for pak bootstrap, renv restoration/cache, secret-backed account setup, and
`deployApp()`. Its scheduled triggers, dependency upgrades, matrix, Cypress
setup, and lockfile commits are outside this app's deployment scope.

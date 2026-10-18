# ADaMViz.SubmissionSync 0.1.0.9017

## Application interface

- Added the F001 prototype's blue product header and GitHub link, plus an
  attribution footer with Source Code and Report Issues links, around the
  existing Create plot workflow bar and five-step workbench.
- Updated the README, feature index, architecture map, and F001 UX guide
  to describe the shared frame and how to load local changes.

## U1 foundation

- Added the package-oriented Shiny application shell.
- Added injected runtime configuration and logical provider/workspace identifiers.
- Added initial validation, traceability, and data-flow security documentation.

## U4 statistical compiler

- Added deterministic type-7 boxplot statistics, explicit plot layers, an
  aligned low-N strip, reproducible R compilation, and pre-execution artifact
  hashes for the first governed plot pattern.
- Generated boxplot scripts now inline their governed statistics and plotting
  helpers, requiring only R and `ggplot2` at runtime; a Nix command is included
  for reproducible execution.

## U9 controlled export

- Added a controlled export service with logical workspace destinations,
  accepted-bundle hash checks, no-overwrite local pair publication,
  staged-export reconciliation, and internal export receipts.

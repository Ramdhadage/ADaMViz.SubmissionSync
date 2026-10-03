# Validate the supported visit-based numeric BDS profile

Explicit parameter, unit, treatment, and visit selections are applied
before visit-key and selected-Y checks. Blocking diagnostics are
separated from nonblocking sparse-data warnings.

## Usage

``` r
validate_bds_profile(snapshot, selections, low_n_threshold = 5)
```

## Arguments

- snapshot:

  A pinned \`study_data_snapshot\`.

- selections:

  A complete list containing \`paramcd\`, \`y_variable\`, \`unit\`,
  \`treatment_variable\`, \`treatment_levels\`, and \`visits\`.

- low_n_threshold:

  The default value \`5\`, or a sponsor-approved list with \`value\`,
  \`rationale\`, \`authority\`, and \`version\`.

## Value

A deterministic \`bds_profile_result\`.

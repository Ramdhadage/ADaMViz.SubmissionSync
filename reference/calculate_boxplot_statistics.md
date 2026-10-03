# Calculate governed longitudinal boxplot statistics

Calculates type-7 hinges, 1.5-IQR whiskers, visible outlier membership,
distinct-subject counts, low-N flags, and median-line rows from the
selected analytical data. Missing selected Y values do not contribute.

## Usage

``` r
calculate_boxplot_statistics(
  data,
  treatment_variable,
  y_variable,
  facet_levels,
  visit_levels,
  low_n_policy
)
```

## Arguments

- data:

  Selected records from a validated visit-based BDS profile.

- treatment_variable:

  Name of the selected treatment variable.

- y_variable:

  Name of the selected numeric Y variable.

- facet_levels:

  Ordered included treatment values.

- visit_levels:

  Ordered included visit labels.

- low_n_policy:

  Retained policy with \`value\`, \`rationale\`, \`authority\`, and
  \`version\`.

## Value

A deterministic \`boxplot_analysis\` object.

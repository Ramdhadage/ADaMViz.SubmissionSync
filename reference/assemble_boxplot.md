# Assemble the governed boxplot and aligned N strip

Uses the independent analytical object as identity statistics,
preserving treatment facets and global visit positions in both panels.

## Usage

``` r
assemble_boxplot(analysis, scale_mode = c("fixed", "free"), unit = NULL)
```

## Arguments

- analysis:

  A \`boxplot_analysis\` object.

- scale_mode:

  Either \`"fixed"\` or \`"free"\` for facet Y scales.

- unit:

  Optional selected unit appended to the Y-axis label.

## Value

A \`boxplot_artifact\` containing plot, N strip, composition, and data.

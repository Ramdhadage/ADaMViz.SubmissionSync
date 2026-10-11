# Compile the deterministic governed boxplot script

The controlled runner provides validated selected records as
\`analysis_data\`. The caller must supply \`analysis_data\`. The script
contains resolved literals, inlined helpers, and uses \`ggplot2\`,
\`cli\`, and \`patchwork\`.

## Usage

``` r
compile_boxplot_script(spec, low_n_policy)
```

## Arguments

- spec:

  A confirmed \`plot_spec\`.

- low_n_policy:

  Retained policy with \`value\`, \`rationale\`, \`authority\`, and
  \`version\`.

## Value

A length-one UTF-8 R script.

# Create the pre-execution boxplot artifact manifest

Binds the exact specification, script, analytical result, and
expected-result contract. Runtime and image hashes remain unset until
controlled execution.

## Usage

``` r
new_artifact_manifest(spec, script, analysis, expected_contract)
```

## Arguments

- spec:

  A confirmed \`plot_spec\`.

- script:

  The exact compiled R script.

- analysis:

  A \`boxplot_analysis\` object.

- expected_contract:

  A list containing the expected-result \`version\`, \`fixture_hash\`,
  and \`review_status\`.

## Value

A \`boxplot_artifact_manifest\`.

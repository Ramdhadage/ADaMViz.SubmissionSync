# Create the governed local study-data provider

Create the governed local study-data provider

## Usage

``` r
local_study_data_provider(root = .synthetic_data_root())
```

## Arguments

- root:

  Directory containing \`scenario-manifest.json\` and its pinned RDS
  snapshots. The default resolves package installation data and then the
  source-tree location.

## Value

A local \`study_data_provider\`.

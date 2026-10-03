# Calculate a stable content hash for study data

The hash is independent of row order while preserving column names,
types, missing values, and stored values.

## Usage

``` r
study_data_content_hash(data)
```

## Arguments

- data:

  A data frame containing a study-data snapshot.

## Value

A SHA-256 content hash.

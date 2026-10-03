# Create the injected runtime configuration provider.

Runtime configuration contains provider identifiers and logical
references, never secret values. Secret material is resolved only
through the injected provider when a domain service explicitly requests
it.

## Usage

``` r
new_runtime_config(
  profile = Sys.getenv("ADAMVIZ_PROFILE", "local"),
  prompt_provider = Sys.getenv("ADAMVIZ_PROMPT_PROVIDER", "mock"),
  workspace = Sys.getenv("ADAMVIZ_WORKSPACE", "local"),
  secret_provider = NULL,
  required_secret_references = character()
)
```

## Arguments

- profile:

  Runtime profile: \`local\`, \`test\`, or \`production\`.

- prompt_provider:

  Logical prompt-provider identifier.

- workspace:

  Logical workspace identifier.

- secret_provider:

  Function accepting a secret reference and returning its value, or
  \`NULL\` when unavailable.

- required_secret_references:

  Character vector of required references.

## Value

An object of class \`submission_sync_runtime_config\`.

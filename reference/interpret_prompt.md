# Interpret a prompt through a provider-neutral adapter

Interpret a prompt through a provider-neutral adapter

## Usage

``` r
interpret_prompt(prompt, context, interpreter, snapshot = NULL)
```

## Arguments

- prompt:

  One natural-language request.

- context:

  A \`prompt_context\`.

- interpreter:

  A prompt interpreter, such as \`mock_prompt_interpreter()\`.

- snapshot:

  Optional pinned snapshot used for U3 semantic validation.

## Value

A \`prompt_interpretation\` with status, candidate, choices, and
provider metadata. It never includes executable code.

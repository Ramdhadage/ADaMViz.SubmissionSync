# limits reject content above their configured boundary

    Code
      enforce_limit("12345", policy$max_prompt_chars, "prompt")
    Condition
      Error in `enforce_limit()`:
      ! prompt exceeds its configured limit


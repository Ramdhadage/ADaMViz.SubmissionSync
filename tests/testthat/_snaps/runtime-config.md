# production provider configuration cannot be selected locally

    Code
      new_runtime_config(profile = "local", prompt_provider = "production")
    Condition
      Error in `new_runtime_config()`:
      ! A production provider cannot be selected outside the production profile
      i Use "mock" for local and test profiles.

# secret references are resolved only by the injected provider

    Code
      resolve_runtime_secret(config, "MISSING")
    Condition
      Error in `resolve_runtime_secret()`:
      ! Secret reference "MISSING" is not configured

# invalid runtime profiles fail closed

    Code
      new_runtime_config(profile = "unknown")
    Condition
      Error in `new_runtime_config()`:
      ! `profile` must be one of "local", "test", and "production"

# runtime parameters are validated at the boundary

    Code
      new_runtime_config(prompt_provider = 1)
    Condition
      Error in `new_runtime_config()`:
      ! `prompt_provider` must be one non-empty identifier

---

    Code
      new_runtime_config(secret_provider = "not-a-function")
    Condition
      Error in `new_runtime_config()`:
      ! `secret_provider` must be a function or "NULL"


# unsupported y variables and unknown provenance are rejected

    Code
      new_plot_spec("adlb-v1", y_variable = "BASE")
    Condition
      Error in `new_plot_spec()`:
      ! `y_variable` must be one of "AVAL", "CHG", and "PCHG"

---

    Code
      new_plot_spec("adlb-v1", provenance = list(path = "prompt"))
    Condition
      Error in `new_plot_spec()`:
      ! Unknown provenance field: path


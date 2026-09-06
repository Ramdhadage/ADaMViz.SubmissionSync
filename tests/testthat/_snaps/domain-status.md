# only legal lifecycle transitions are accepted

    Code
      transition_revision_status("Reviewed", "Draft")
    Condition
      Error in `transition_revision_status()`:
      ! Cannot transition from "Reviewed" to "Draft"


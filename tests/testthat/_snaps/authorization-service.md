# revision creators and ineligible actors cannot approve

    Code
      authorize_revision_action(creator, revision, "approve")
    Condition
      Error in `authorize_revision_action()`:
      ! A revision creator cannot review their own revision

---

    Code
      authorize_revision_action(observer, revision, "approve")
    Condition
      Error in `authorize_revision_action()`:
      ! The current actor is not eligible to approve a revision


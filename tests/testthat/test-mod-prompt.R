test_that("prompt module sends the selected prompt request to the coordinator", {
  catalog <- shiny::reactiveVal(data.frame(
    dataset_id = "adlb-standard",
    purpose = "Passing profile",
    stringsAsFactors = FALSE
  ))
  requests <- list()
  create_revision <- function(dataset_id, prompt, confirm_free_scale) {
    requests[[length(requests) + 1L]] <<- list(
      dataset_id = dataset_id,
      prompt = prompt,
      confirm_free_scale = confirm_free_scale
    )
  }

  shiny::testServer(
    mod_prompt_server,
    args = list(catalog = catalog, create_revision = create_revision),
    {
      session$setInputs(
        dataset_id = "adlb-standard",
        prompt = "Create a boxplot of ALT AVAL by treatment.",
        confirm_free_scale = FALSE
      )
      session$flushReact()
      session$setInputs(
        submit = 1
      )
      session$flushReact()

      expect_length(requests, 1L)
      expect_identical(requests[[1]]$dataset_id, "adlb-standard")
      expect_match(requests[[1]]$prompt, "ALT AVAL")
      expect_identical(requests[[1]]$confirm_free_scale, FALSE)
    }
  )
})

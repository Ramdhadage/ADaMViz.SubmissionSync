test_that("async task service uses Shiny ExtendedTask", {
  task <- new_async_task_service()

  expect_s3_class(task, "ExtendedTask")
})

test_that("async task service returns a mirai result", {
  server <- function(input, output, session) {
    task <- new_async_task_service()
    task$invoke(list(
      function_name = ".execution_attempt_id",
      args = list(idempotency_key = "execute-1")
    ))
    deadline <- Sys.time() + 10
    while (identical(task$status(), "running") && Sys.time() < deadline) {
      getFromNamespace("run_now", "later")(0.1)
    }

    expect_identical(task$status(), "success")
    expect_match(task$result(), "^attempt-")
  }
  shiny::testServer(server, {
    expect_true(TRUE)
  })
})

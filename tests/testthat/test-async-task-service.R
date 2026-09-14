test_that("async task service records completion and idempotent status", {
  tasks <- new_async_task_service(max_active = 1L)

  result <- tasks$submit("task-1", function(value) value + 1L, 1L)

  expect_identical(result$status, "succeeded")
  expect_identical(result$result, 2L)
  expect_identical(tasks$status("task-1")$result, 2L)
  expect_identical(
    tasks$submit("task-1", function(value) value + 2L, 1L)$result,
    2L
  )
})

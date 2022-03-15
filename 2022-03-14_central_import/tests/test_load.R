context("load")

test_that("new tables added", {
  print(after$metadata_row_count)
  print(after$stochastic_row_count)
  expect_equal(after$metadata_row_count - before$metadata_row_count, 1)
  expect_true(after$stochastic_row_count - before$stochastic_row_count > 0)
})

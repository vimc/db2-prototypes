context("load")

test_that("data has been added to stochastic_1 table", {
  expect_true(after$row_num > before$row_num)
})

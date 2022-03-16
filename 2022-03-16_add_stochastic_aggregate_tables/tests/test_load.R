context("load")

test_that("new tables added", {
  expect_equal(setdiff(after, before), c("stochastic_1"))
})

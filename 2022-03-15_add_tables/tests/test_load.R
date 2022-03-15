context("load")

test_that("new tables added", {
  expect_equal(setdiff(after, before), c("metadata", "stochastic_1_age_disag"))
})

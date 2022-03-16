context("load")

test_that("new tables added", {
  expect_equal(setdiff(after, before),
               c("stochastic_file", "stochastic_1", "stochastic_2",
                 "stochastic_3", "stochastic_4"))
})

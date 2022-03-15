context("extract")

testthat::test_that("extracted data is as expected", {
  expect_false(is.null(extracted_data))
  expect_setequal(names(extracted_data),
                  c("yf-no-vaccination", "yf-preventive-default",
                    "yf-preventive-ia2030_target", "yf-routine-default",
                    "yf-routine-ia2030_target"))
  expect_true(nrow(extracted_data[["yf-no-vaccination"]]) > 0)
  expect_true(nrow(extracted_data[["yf-preventive-default"]]) > 0)
  expect_true(nrow(extracted_data[["yf-preventive-ia2030_target"]]) > 0)
  expect_true(nrow(extracted_data[["yf-routine-default"]]) > 0)
  expect_true(nrow(extracted_data[["yf-routine-ia2030_target"]]) > 0)
})

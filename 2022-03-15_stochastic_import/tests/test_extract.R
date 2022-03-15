context("extract")

testthat::test_that("extracted data is as expected", {
  ## Example impl, extend or modify as required.
  expect_false(is.null(extracted_data))
  expect_setequal(names(extracted_data),
                  c("run_ids", "scenarios", "cases", "data"))
  expect_equal(extracted_data$run_ids, 1:200)
  expect_length(extracted_data$scenarios, 5)
  expect_length(extracted_data$cases)
  expect_length(extracted_data$data, 1000)
  for (df in extracted_data$data) {
    expect_true(nrow(df) > 0)
  }
})

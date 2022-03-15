context("extract")

testthat::test_that("extracted data is as expected", {
  expect_false(is.null(extracted_data))
  expect_setequal(names(extracted_data),
                  c("no_vac", "preventive_default", "preventive_ia2030",
                    "routine_default", "routine_ia2030"))
  expect_true(nrow(extracted_data$no_vac) > 0)
  expect_true(nrow(extracted_data$preventive_default) > 0)
  expect_true(nrow(extracted_data$preventive_ia2030) > 0)
  expect_true(nrow(extracted_data$routine_default) > 0)
  expect_true(nrow(extracted_data$routine_ia2030) > 0)
})

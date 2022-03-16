context("transform")

testthat::test_that("transformed data is as expected", {
  ## Example impl, extend or modify as required.
  expect_false(is.null(transformed_data))
  expect_equal(nrow(transformed_data$stochastic_file), 4)

  expect_setequal(colnames(transformed_data$stochastic_1), c(
    "year", "country", "run_id",
    "cases_yf-no-vaccination", "dalys_yf-no-vaccination",
    "deaths_yf-no-vaccination", "cases_yf-preventive-default",
    "dalys_yf-preventive-default", "deaths_yf-preventive-default",
    "cases_yf-preventive-ia2030_target", "dalys_yf-preventive-ia2030_target",
    "deaths_yf-preventive-ia2030_target", "cases_yf-routine-default",
    "dalys_yf-routine-default", "deaths_yf-routine-default",
    "cases_yf-routine-ia2030_target", "dalys_yf-routine-ia2030_target",
    "deaths_yf-routine-ia2030_target"
  ))
  expect_true(nrow(transformed_data$stochastic_1) > 0)

  expect_setequal(colnames(transformed_data$stochastic_2), c(
    "year", "country", "run_id",
    "cases_yf-no-vaccination", "dalys_yf-no-vaccination",
    "deaths_yf-no-vaccination", "cases_yf-preventive-default",
    "dalys_yf-preventive-default", "deaths_yf-preventive-default",
    "cases_yf-preventive-ia2030_target", "dalys_yf-preventive-ia2030_target",
    "deaths_yf-preventive-ia2030_target", "cases_yf-routine-default",
    "dalys_yf-routine-default", "deaths_yf-routine-default",
    "cases_yf-routine-ia2030_target", "dalys_yf-routine-ia2030_target",
    "deaths_yf-routine-ia2030_target"
  ))
  expect_true(nrow(transformed_data$stochastic_2) > 0)

  expect_setequal(colnames(transformed_data$stochastic_3), c(
    "year", "country", "run_id",
    "cases_yf-no-vaccination", "dalys_yf-no-vaccination",
    "deaths_yf-no-vaccination", "cases_yf-preventive-default",
    "dalys_yf-preventive-default", "deaths_yf-preventive-default",
    "cases_yf-preventive-ia2030_target", "dalys_yf-preventive-ia2030_target",
    "deaths_yf-preventive-ia2030_target", "cases_yf-routine-default",
    "dalys_yf-routine-default", "deaths_yf-routine-default",
    "cases_yf-routine-ia2030_target", "dalys_yf-routine-ia2030_target",
    "deaths_yf-routine-ia2030_target"
  ))
  expect_true(nrow(transformed_data$stochastic_3) > 0)

  expect_setequal(colnames(transformed_data$stochastic_4), c(
    "year", "country", "run_id",
    "cases_yf-no-vaccination", "dalys_yf-no-vaccination",
    "deaths_yf-no-vaccination", "cases_yf-preventive-default",
    "dalys_yf-preventive-default", "deaths_yf-preventive-default",
    "cases_yf-preventive-ia2030_target", "dalys_yf-preventive-ia2030_target",
    "deaths_yf-preventive-ia2030_target", "cases_yf-routine-default",
    "dalys_yf-routine-default", "deaths_yf-routine-default",
    "cases_yf-routine-ia2030_target", "dalys_yf-routine-ia2030_target",
    "deaths_yf-routine-ia2030_target"
  ))
  expect_true(nrow(transformed_data$stochastic_4) > 0)
})

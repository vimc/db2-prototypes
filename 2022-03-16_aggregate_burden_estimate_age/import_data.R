#!/usr/bin/env Rscript

library("magrittr")

sum_metrics <- function(data) {
  data %>%
    dplyr::summarise(
      `cases_yf-no-vaccination` = sum(`cases_yf-no-vaccination`),
      `cases_yf-preventive-default` = sum(`cases_yf-preventive-default`),
      `cases_yf-preventive-ia2030_target` = sum(`cases_yf-preventive-ia2030_target`),
      `cases_yf-routine-default` = sum(`cases_yf-routine-default`),
      `cases_yf-routine-ia2030_target` = sum(`cases_yf-routine-ia2030_target`),
      `dalys_yf-no-vaccination` = sum(`dalys_yf-no-vaccination`),
      `dalys_yf-preventive-default` = sum(`dalys_yf-preventive-default`),
      `dalys_yf-preventive-ia2030_target` = sum(`dalys_yf-preventive-ia2030_target`),
      `dalys_yf-routine-default` = sum(`dalys_yf-routine-default`),
      `dalys_yf-routine-ia2030_target` = sum(`dalys_yf-routine-ia2030_target`),
      `deaths_yf-no-vaccination` = sum(`deaths_yf-no-vaccination`),
      `deaths_yf-preventive-default` = sum(`deaths_yf-preventive-default`),
      `deaths_yf-preventive-ia2030_target` = sum(`deaths_yf-preventive-ia2030_target`),
      `deaths_yf-routine-default` = sum(`deaths_yf-routine-default`),
      `deaths_yf-routine-ia2030_target` = sum(`deaths_yf-routine-ia2030_target`),
      .groups = "keep"
    )
}

import <- function() {
  con <- dettl:::db_connect("local", ".")
  metadata = DBI::dbGetQuery(con, "select touchstone, modelling_group, disease from metadata")
  age_disag = DBI::dbGetQuery(con, "select * from stochastic_1_age_disag")

  aggregates <- data.frame(
    is_cohort = c(FALSE, FALSE, TRUE, TRUE),
    is_under5 = c(FALSE, TRUE, FALSE, TRUE)
  )
  stochastic_file <- merge(metadata, aggregates)
  stochastic_1 <- age_disag %>%
    dplyr::select(-cohort_size) %>%
    dplyr::group_by(run_id, year, country) %>%
    sum_metrics()
  under5 <- age_disag %>%
    dplyr::filter(age <= 4)
  stochastic_2 <- under5 %>%
    dplyr::select(-cohort_size) %>%
    dplyr::group_by(run_id, year, country) %>%
    sum_metrics()
  stochastic_3 <- age_disag %>%
    dplyr::mutate(cohort = year - age) %>%
    dplyr::select(-cohort_size, -year) %>%
    dplyr::group_by(run_id, cohort, country) %>%
    sum_metrics()
  stochastic_4 <- under5 %>%
    dplyr::mutate(cohort = year - age) %>%
    dplyr::select(-cohort_size, -year) %>%
    dplyr::group_by(run_id, cohort, country) %>%
    sum_metrics()

  DBI::dbWriteTable(con, "stochastic_file", stochastic_file)
  DBI::dbWriteTable(con, "stochastic_1", stochastic_1)
  DBI::dbWriteTable(con, "stochastic_2", stochastic_2)
  DBI::dbWriteTable(con, "stochastic_3", stochastic_3)
  DBI::dbWriteTable(con, "stochastic_4", stochastic_4)
}

start <- Sys.time()
import()
end <- Sys.time()
time <- end - start
msg <- paste0(time, " ", attr(time, "units"))
message(msg)
output_file <- "timings.txt"
if (!file.exists(output_file)) {
  file.create(output_file)
}
write(msg, file = output_file, append = TRUE)

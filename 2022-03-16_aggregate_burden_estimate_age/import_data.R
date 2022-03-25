#!/usr/bin/env Rscript

library("magrittr")

sum_metrics_yf <- function(data) {
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

sum_metrics_measles <- function(data) {
  data %>%
    dplyr::summarise(
      `cases_measles-no-vaccination` = sum(`cases_measles-no-vaccination`),
      `cases_measles-campaign-default` = sum(`cases_measles-campaign-default`),
      `cases_measles-campaign-only-default` = sum(`cases_measles-campaign-only-default`),
      `cases_measles-mcv1-default` = sum(`cases_measles-mcv1-default`),
      `cases_measles-mcv2-default` = sum(`cases_measles-mcv2-default`),
      `cases_measles-campaign-ia2030_target` = sum(`cases_measles-campaign-ia2030_target`),
      `cases_measles-campaign-only-ia2030_target` = sum(`cases_measles-campaign-only-ia2030_target`),
      `cases_measles-mcv1-ia2030_target` = sum(`cases_measles-mcv1-ia2030_target`),
      `cases_measles-mcv2-ia2030_target` = sum(`cases_measles-mcv2-ia2030_target`),
      `deaths_measles-no-vaccination` = sum(`deaths_measles-no-vaccination`),
      `deaths_measles-campaign-default` = sum(`deaths_measles-campaign-default`),
      `deaths_measles-campaign-only-default` = sum(`deaths_measles-campaign-only-default`),
      `deaths_measles-mcv1-default` = sum(`deaths_measles-mcv1-default`),
      `deaths_measles-mcv2-default` = sum(`deaths_measles-mcv2-default`),
      `deaths_measles-campaign-ia2030_target` = sum(`deaths_measles-campaign-ia2030_target`),
      `deaths_measles-campaign-only-ia2030_target` = sum(`deaths_measles-campaign-only-ia2030_target`),
      `deaths_measles-mcv1-ia2030_target` = sum(`deaths_measles-mcv1-ia2030_target`),
      `deaths_measles-mcv2-ia2030_target` = sum(`deaths_measles-mcv2-ia2030_target`),
      `dalys_measles-no-vaccination` = sum(`dalys_measles-no-vaccination`),
      `dalys_measles-campaign-default` = sum(`dalys_measles-campaign-default`),
      `dalys_measles-campaign-only-default` = sum(`dalys_measles-campaign-only-default`),
      `dalys_measles-mcv1-default` = sum(`dalys_measles-mcv1-default`),
      `dalys_measles-mcv2-default` = sum(`dalys_measles-mcv2-default`),
      `dalys_measles-campaign-ia2030_target` = sum(`dalys_measles-campaign-ia2030_target`),
      `dalys_measles-campaign-only-ia2030_target` = sum(`dalys_measles-campaign-only-ia2030_target`),
      `dalys_measles-mcv1-ia2030_target` = sum(`dalys_measles-mcv1-ia2030_target`),
      `dalys_measles-mcv2-ia2030_target` = sum(`dalys_measles-mcv2-ia2030_target`),
      .groups = "keep"
    )
}

import_metadata <- function() {
  con <- dettl:::db_connect("local", ".")
  metadata = DBI::dbGetQuery(con, "select touchstone, modelling_group, disease from metadata")
  aggregates <- data.frame(
    is_cohort = c(FALSE, FALSE, TRUE, TRUE),
    is_under5 = c(FALSE, TRUE, FALSE, TRUE)
  )
  stochastic_file <- merge(metadata, aggregates)
  DBI::dbWriteTable(con, "stochastic_file", stochastic_file)
  Sys.time()
}

import <- function(id, sum_func) {
  con <- dettl:::db_connect("local", ".")
  table <- sprintf("stochastic_%s_age_disag", id)
  age_disag = DBI::dbGetQuery(con, sprintf("select * from %s", table))

  ## Each stochastic age disag table makes 4 new tables so set id of
  ## tables to be added e.g. stochastic age disag id 1 creates 1- 4
  ## age disag 2 creates 5 - 8 etc.
  new_table_id <- ((id - 1) * 4) + 1
  message(paste0("Writing table stochastic_", new_table_id))
  stochastic_1 <- age_disag %>%
    dplyr::select(-cohort_size) %>%
    dplyr::group_by(run_id, year, country) %>%
    sum_func()
  DBI::dbWriteTable(con, paste0("stochastic_", new_table_id), stochastic_1)
  new_table_id <- new_table_id + 1

  message(paste0("Writing table stochastic_", new_table_id))
  under5 <- age_disag %>%
    dplyr::filter(age <= 4)
  stochastic_2 <- under5 %>%
    dplyr::select(-cohort_size) %>%
    dplyr::group_by(run_id, year, country) %>%
    sum_func()
  DBI::dbWriteTable(con, paste0("stochastic_", new_table_id), stochastic_2)
  new_table_id <- new_table_id + 1

  message(paste0("Writing table stochastic_", new_table_id))
  stochastic_3 <- age_disag %>%
    dplyr::mutate(cohort = year - age) %>%
    dplyr::select(-cohort_size, -year) %>%
    dplyr::group_by(run_id, cohort, country) %>%
    sum_func()
  DBI::dbWriteTable(con, paste0("stochastic_", new_table_id), stochastic_3)
  new_table_id <- new_table_id + 1

  message(paste0("Writing table stochastic_", new_table_id))
  stochastic_4 <- under5 %>%
    dplyr::mutate(cohort = year - age) %>%
    dplyr::select(-cohort_size, -year) %>%
    dplyr::group_by(run_id, cohort, country) %>%
    sum_func()
  DBI::dbWriteTable(con, paste0("stochastic_", new_table_id), stochastic_4)

  Sys.time()
}

# Metadata
start <- Sys.time()
end <- import_metadata()
time <- end - start
msg <- paste0("Metadata import: ", time, " ", attr(time, "units"))
message(msg)
output_file <- "timings.txt"
if (!file.exists(output_file)) {
  file.create(output_file)
}
write(msg, file = output_file, append = TRUE)

# YF
start <- Sys.time()
end <- import(1, sum_metrics_yf)
time <- end - start
msg <- paste0("YF import: ", time, " ", attr(time, "units"))
message(msg)
write(msg, file = output_file, append = TRUE)

# Measles PSU-Ferrari
start <- Sys.time()
end <- import(2, sum_metrics_measles)
time <- end - start
msg <- paste0("Measles PSU-Ferrari import: ", time, " ", attr(time, "units"))
message(msg)
write(msg, file = output_file, append = TRUE)

# Measles LSHTM-Jit
start <- Sys.time()
end <- import(3, sum_metrics_measles)
time <- end - start
msg <- paste0("Measles LSHTM-Jit import: ", time, " ", attr(time, "units"))
message(msg)
write(msg, file = output_file, append = TRUE)

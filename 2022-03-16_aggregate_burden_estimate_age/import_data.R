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

import <- function(con, start_id, sum_func, age_disag) {
  ## Each stochastic age disag table makes 4 new tables so set id of
  ## tables to be added e.g. stochastic age disag id 1 creates 1- 4
  ## age disag 2 creates 5 - 8 etc.
  new_table_id <- ((start_id - 1) * 4) + 1
  message(paste0("Writing table stochastic_", new_table_id))
  stochastic_1 <- age_disag %>%
    dplyr::select(-cohort_size) %>%
    dplyr::group_by(run_id, year, country) %>%
    sum_func()
  DBI::dbWriteTable(con, paste0("stochastic_", new_table_id), stochastic_1,
                    append = TRUE)
  new_table_id <- new_table_id + 1

  message(paste0("Writing table stochastic_", new_table_id))
  under5 <- age_disag %>%
    dplyr::filter(age <= 4)
  stochastic_2 <- under5 %>%
    dplyr::select(-cohort_size) %>%
    dplyr::group_by(run_id, year, country) %>%
    sum_func()
  DBI::dbWriteTable(con, paste0("stochastic_", new_table_id), stochastic_2,
                    append = TRUE)
  new_table_id <- new_table_id + 1

  message(paste0("Writing table stochastic_", new_table_id))
  stochastic_3 <- age_disag %>%
    dplyr::mutate(cohort = year - age) %>%
    dplyr::select(-cohort_size, -year) %>%
    dplyr::group_by(run_id, cohort, country) %>%
    sum_func()
  DBI::dbWriteTable(con, paste0("stochastic_", new_table_id), stochastic_3,
                    append = TRUE)
  new_table_id <- new_table_id + 1

  message(paste0("Writing table stochastic_", new_table_id))
  stochastic_4 <- under5 %>%
    dplyr::mutate(cohort = year - age) %>%
    dplyr::select(-cohort_size, -year) %>%
    dplyr::group_by(run_id, cohort, country) %>%
    sum_func()
  DBI::dbWriteTable(con, paste0("stochastic_", new_table_id), stochastic_4,
                    append = TRUE)
}

## Import stochastic_n_age_disag table from DB and transform into
## stochastic_1 etc. tables
## Note this won't work for measles as it reads all the stochastic age disag
## table into memory and this will be too much data for measles
import_from_db <- function(id, sum_func) {
  con <- dettl:::db_connect("local", ".")
  table <- sprintf("stochastic_%s_age_disag", id)
  age_disag = DBI::dbGetQuery(con, sprintf("select * from %s", table))
  import(con, id, sum_func, age_disag)
  Sys.time()
}

read_scenario <- function(root_name, scenario, country) {
  file_path <- sprintf("processed/%s%s_%s.qs", root_name, scenario, country)
  data <- qs::qread(file_path)
  data %>%
    dplyr::mutate(scenario = paste0("measles-", scenario)) %>%
    dplyr::select(-disease, -country_name) %>%
    tidyr::pivot_wider(id_cols = c("year", "age", "country", "run_id", "cohort_size"),
                       names_from = scenario,
                       values_from = c("cases", "dalys", "deaths"))
}

## Load raw age disaggregated files and import country by country to avoid
## running out of memory
## This imports the qs files saved out by
## 2022-03-24_measles_stochastic_import/split_data.R
import_from_files <- function(id, root_name, sum_func) {
  files <- list.files("processed", pattern = root_name)
  countries <- unique(gsub(sprintf("^%s.+_([A-Z]{2,3})\\.qs$", root_name), "\\1", files))

  scenarios <-  c("no-vaccination", "campaign-default",
                  "campaign-only-default", "mcv1-default",
                  "mcv2-default", "campaign-ia2030_target",
                  "campaign-only-ia2030_target",
                  "mcv1-ia2030_target", "mcv2-ia2030_target")
  con <- dettl:::db_connect("local", ".")

  for (country in countries) {
    message("Processing ", country, " scenario ", scenarios[1])
    country_data <- read_scenario(root_name, scenarios[1], country)
    for (scenario in scenarios[-1]) {
      message("Processing ", country, " scenario ", scenario)
      data <- read_scenario(root_name, scenario, country)
      country_data <- dplyr::full_join(country_data, data,
                                       by = c("year", "age", "country", "run_id", "cohort_size"))
    }
    import(con, id, sum_func, country_data)
  }
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
end <- import_from_db(1, sum_metrics_yf)
time <- end - start
msg <- paste0("YF import: ", time, " ", attr(time, "units"))
message(msg)
write(msg, file = output_file, append = TRUE)
gc()

# Measles PSU-Ferrari
start <- Sys.time()
end <- import_from_files(2, "coverage_202110gavi-3_measles-", sum_metrics_measles)
time <- end - start
msg <- paste0("Measles PSU-Ferrari import: ", time, " ", attr(time, "units"))
message(msg)
write(msg, file = output_file, append = TRUE)
gc()

# Measles LSHTM-Jit
start <- Sys.time()
end <- import_from_files(3, "Han Fu - stochastic_burden_estimate_measles-LSHTM-Jit-", sum_metrics_measles)
time <- end - start
msg <- paste0("Measles LSHTM-Jit import: ", time, " ", attr(time, "units"))
message(msg)
write(msg, file = output_file, append = TRUE)

#!/usr/bin/env Rscript

library("magrittr")

import <- function(id, root_name) {
  scenarios <-  c("measles-no-vaccination", "measles-campaign-default",
                  "measles-campaign-only-default", "measles-mcv1-default",
                  "measles-mcv2-default", "measles-campaign-ia2030_target",
                  "measles-campaign-only-ia2030_target",
                  "measles-mcv1-ia2030_target", "measles-mcv2-ia2030_target")
  files <- sprintf("%s%s.csv.xz", root_name, scenarios)
  file_paths <- file.path("stochastics", files)
  data <- lapply(file_paths, read.csv)

  ## Add scenario column and filter unwanted data
  add_columns <- function(scenario_no) {
    df <- data[[scenario_no]]
    df$scenario <- scenarios[scenario_no]
    df
  }
  run_data <- lapply(seq_along(scenarios), add_columns)
  run_data <- do.call(dplyr::bind_rows, run_data)
  run_data <- run_data %>%
    dplyr::select(-disease, -country_name) %>%
    tidyr::pivot_wider(
      id_cols = c("year", "age", "country", "run_id", "cohort_size"),
      names_from = scenario,
      values_from = c("cases", "dalys", "deaths"))

  stochastic_age_disag = do.call(dplyr::bind_rows, run_data)

  con <- dettl:::db_connect("local", ".")
  DBI::dbAppendTable(con, sprintf("stochastic_%s_age_disag", id),
                     stochastic_age_disag)
}

# PSU-Ferrari
start <- Sys.time()
import(2, "coverage_202110gavi-3_")
end <- Sys.time()
time <- end - start
msg <- paste0("PSU-Ferrari import: ", time, " ", attr(time, "units"))
message(msg)
output_file <- "timings.txt"
if (!file.exists(output_file)) {
  file.create(output_file)
}
write(msg, file = output_file, append = TRUE)

# LSHTM-Jit
start <- Sys.time()
import(3, "Han Fu - stochastic_burden_estimate_measles-LSHTM-Jit-")
end <- Sys.time()
time <- end - start
msg <- paste0("LSHTM-Jit import: ", time, " ", attr(time, "units"))
message(msg)
write(msg, file = output_file, append = TRUE)

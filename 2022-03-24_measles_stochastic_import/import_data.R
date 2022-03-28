#!/usr/bin/env Rscript

library("magrittr")

import <- function(id, root_name) {
  scenarios <-  c("measles-no-vaccination", "measles-campaign-default",
                  "measles-campaign-only-default", "measles-mcv1-default",
                  "measles-mcv2-default", "measles-campaign-ia2030_target",
                  "measles-campaign-only-ia2030_target",
                  "measles-mcv1-ia2030_target", "measles-mcv2-ia2030_target")
  files <- sprintf("%s%s.csv.xz", root_name, scenarios)
  file_paths <- setNames(file.path("stochastics", files), scenarios)

  ## Add scenario column and filter unwanted data
  read_one <- function(name) {
    data <- readr::read_csv(file_paths[[name]])
    data %>%
      dplyr::mutate(scenario = name) %>%
      dplyr::select(-disease, -country_name) %>%
      tidyr::pivot_wider(id_cols = c("year", "age", "country", "run_id", "cohort_size"),
                         names_from = scenario,
                         values_from = c("cases", "dalys", "deaths"))
  }
  all_data <- read_one(names(file_paths)[1])
  for (name in names(file_paths)[-1]) {
    message("Processing ", name)
    data <- read_one(name)
    all_data <- do.call(dplyr::bind_rows, data)
    gc()
  }

  con <- dettl:::db_connect("local", ".")
  DBI::dbAppendTable(con, sprintf("stochastic_%s_age_disag", id),
                     all_data)
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
gc()

# LSHTM-Jit
start <- Sys.time()
import(3, "Han Fu - stochastic_burden_estimate_measles-LSHTM-Jit-")
end <- Sys.time()
time <- end - start
msg <- paste0("LSHTM-Jit import: ", time, " ", attr(time, "units"))
message(msg)
write(msg, file = output_file, append = TRUE)

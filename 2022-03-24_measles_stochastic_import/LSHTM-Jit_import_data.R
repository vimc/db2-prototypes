#!/usr/bin/env Rscript

library("magrittr")

import_single_country <- function(id, root_name, country) {
  scenarios <-  c("no-vaccination", "campaign-default",
                  "campaign-only-default", "mcv1-default",
                  "mcv2-default", "campaign-ia2030_target",
                  "campaign-only-ia2030_target",
                  "mcv1-ia2030_target", "mcv2-ia2030_target")

  read_scenario <- function(scenario) {
    file_path <- sprintf("processed/%s%s_%s.qs", root_name, scenario, country)
    data <- qs::qread(file_path)
    data %>%
      dplyr::mutate(scenario = scenario) %>%
      dplyr::select(-disease, -country_name) %>%
      tidyr::pivot_wider(id_cols = c("year", "age", "country", "run_id", "cohort_size"),
                         names_from = scenario,
                         values_from = c("cases", "dalys", "deaths"))
  }
  message("Processing ", country, " scenario ", scenarios[1])
  country_data <- read_scenario(scenarios[1])
  for (scenario in scenarios[-1]) {
    message("Processing ", country, " scenario ", scenario)
    data <- read_scenario(scenario)
    country_data <- dplyr::full_join(country_data, data,
                                 by = c("year", "age", "country", "run_id", "cohort_size"))
    gc()
  }

  message("Importing ", country)
  con <- dettl:::db_connect("local", ".")
  DBI::dbAppendTable(con, sprintf("stochastic_%s_age_disag", id), country_data)
}

import <- function(id, root_name) {
  files <- list.files("processed")
  ## Bit of an award regex here as Kosovo has code XK (not an iso3)
  countries <- unique(gsub(".+_([A-Z]{2,3})\\.qs$", "\\1", files))
  for (country in countries) {
    import_single_country(id, root_name, country)
  }
}

# PSU-Ferrari
start <- Sys.time()
import(3, "Han Fu - stochastic_burden_estimate_measles-LSHTM-Jit-")
end <- Sys.time()
time <- end - start
msg <- paste0("LSHTM-Jit import: ", time, " ", attr(time, "units"))
message(msg)
output_file <- "timings.txt"
if (!file.exists(output_file)) {
  file.create(output_file)
}
write(msg, file = output_file, append = TRUE)

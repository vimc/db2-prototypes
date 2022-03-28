#!/usr/bin/env Rscript

library("magrittr")

import <- function(id, modelling_group) {
  paths <- list(
    `measles-no-vaccination` = sprintf("central/%s_measles-no-vaccination.csv", modelling_group),
    `measles-campaign-default` = sprintf("central/%s_measles-campaign-default.csv", modelling_group),
    `measles-campaign-only-default` = sprintf("central/%s_measles-campaign-only-default.csv", modelling_group),
    `measles-mcv1-default` = sprintf("central/%s_measles-mcv1-default.csv", modelling_group),
    `measles-mcv2-default` = sprintf("central/%s_measles-mcv2-default.csv", modelling_group),
    `measles-campaign-ia2030_target` = sprintf("central/%s_measles-campaign-ia2030_target.csv", modelling_group),
    `measles-campaign-only-ia2030_target` = sprintf("central/%s_measles-campaign-only-ia2030_target.csv", modelling_group),
    `measles-mcv1-ia2030_target` = sprintf("central/%s_measles-mcv1-ia2030_target.csv", modelling_group),
    `measles-mcv2-ia2030_target` = sprintf("central/%s_measles-mcv2-ia2030_target.csv", modelling_group)
  )

  metadata <- data.frame(
    id = id,
    touchstone = "202110gavi-3",
    modelling_group = modelling_group,
    disease = "Measles",
    version = 1,
    stringsAsFactors = FALSE
  )

  ## 1 table match format of stochastic table
  ## year
  ## country
  ## run_id - 0 for centrals
  ## plus cases, deaths and dalys for each scenario
  read_one <- function(name) {
    data <- readr::read_csv(paths[[name]])
    data %>%
      dplyr::mutate(scenario = name) %>%
      dplyr::select(-disease, -country_name) %>%
      tidyr::pivot_wider(id_cols = c("year", "age", "country", "cohort_size"),
                         names_from = scenario,
                         values_from = c("cases", "dalys", "deaths")) %>%
      dplyr::mutate(run_id = 0) %>%
      dplyr::relocate(year, age, country, run_id)
  }
  all_data <- read_one(names(paths)[1])
  for (name in names(paths)[-1]) {
    message("Processing ", name)
    data <- read_one(name)
    all_data <- do.call(dplyr::bind_rows, data)
    gc()
  }

  ## write the data out here a migration and import as separate
  ## only get timing for the import bit
  if (!dir.exists("processed")) {
    dir.create("processed", FALSE, FALSE)
  }
  write.csv(all_data, sprintf("processed/stochastics_%s_age_disag.csv", id), row.names = FALSE)

  con <- dettl:::db_connect("local", ".")
  start <- Sys.time()
  DBI::dbAppendTable(con, "metadata", metadata)
  DBI::dbWriteTable(con, sprintf("stochastic_%s_age_disag", id), all_data)
  end <- Sys.time()
  end - start
}

time <- import(2, "PSU-Ferrari")
msg <- paste0("PSU-Ferrari import: ", time, " ", attr(time, "units"))
message(msg)
output_file <- "timings.txt"
if (!file.exists(output_file)) {
  file.create(output_file)
}
write(msg, file = output_file, append = TRUE)
gc()

time <- import(3, "LSHTM-Jit")
msg <- paste0("LSHTM-Jit import: ", time, " ", attr(time, "units"))
message(msg)
write(msg, file = output_file, append = TRUE)

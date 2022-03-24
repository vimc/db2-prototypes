#!/usr/bin/env Rscript

library("magrittr")

import <- function(id, modelling_group) {
  input <- list(
    `measles-no-vaccination` = read.csv(sprintf("central/%s_measles-no-vaccination.csv", modelling_group)),
    `measles-campaign-default` = read.csv(sprintf("central/%s_measles-campaign-default.csv", modelling_group)),
    `measles-campaign-only-default` = read.csv(sprintf("central/%s_measles-campaign-only-default.csv", modelling_group)),
    `measles-mcv1-default` = read.csv(sprintf("central/%s_measles-mcv1-default.csv", modelling_group)),
    `measles-mcv2-default` = read.csv(sprintf("central/%s_measles-mcv2-default.csv", modelling_group)),
    `measles-campaign-ia2030_target` = read.csv(sprintf("central/%s_measles-campaign-ia2030_target.csv", modelling_group)),
    `measles-campaign-only-ia2030_target` = read.csv(sprintf("central/%s_measles-campaign-only-ia2030_target.csv", modelling_group)),
    `measles-mcv1-ia2030_target` = read.csv(sprintf("central/%s_measles-mcv1-ia2030_target.csv", modelling_group)),
    `measles-mcv2-ia2030_target` = read.csv(sprintf("central/%s_measles-mcv2-ia2030_target.csv", modelling_group))
  )

  metadata <- data.frame(
    id = id,
    touchstone = "202110gavi-3",
    modelling_group = modelling_gruop,
    disease = "Measles",
    version = 1,
    stringsAsFactors = FALSE
  )

  ## 1 table match format of stochastic table
  ## year
  ## country
  ## run_id - 0 for centrals
  ## plus cases, deaths and dalys for each scenario
  data <- lapply(names(input), function(name) {
    data <- input[[name]]
    data %>%
      dplyr::mutate(scenario = name)
  })
  data <- do.call(dplyr::bind_rows, data)
  ## Q: Do we need to keep cohort size here?
  data <- data %>%
    dplyr::select(-disease, -country_name) %>%
    tidyr::pivot_wider(id_cols = c("year", "age", "country", "cohort_size"),
                       names_from = scenario,
                       values_from = c("cases", "dalys", "deaths")) %>%
    dplyr::mutate(run_id = 0) %>%
    dplyr::relocate(year, age, country, run_id)

  ## write the data out here a migration and import as separate
  ## only get timing for the import bit
  if (!dir.exists("processed")) {
    dir.create("processed", FALSE, FALSE)
  }
  write.csv(data, sprintf("processed/stochastics_%s_age_disag.csv", id), row.names = FALSE)

  con <- dettl:::db_connect("local", ".")
  start <- Sys.time()
  DBI::dbAppendTable(con, "metadata", metadata)
  DBI::dbWriteTable(con, sprintf("stochastic_%s_age_disag", id), data)
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

time <- import(3, "LSHTM-Jit")
msg <- paste0("LSHTM-Jit import: ", time, " ", attr(time, "units"))
message(msg)
write(msg, file = output_file, append = TRUE)

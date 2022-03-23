#!/usr/bin/env Rscript

import <- function() {
  input <- list(
    `yf-no-vaccination` = read.csv("central/yf-no-vaccination.csv"),
    `yf-preventive-default` = read.csv("central/yf-preventive-default.csv"),
    `yf-preventive-ia2030_target` = read.csv("central/yf-preventive-ia2030_target.csv"),
    `yf-routine-default` = read.csv("central/yf-routine-default.csv"),
    `yf-routine-ia2030_target` = read.csv("central/yf-routine-ia2030_target.csv")
  )

  metadata <- data.frame(
    id = 1,
    touchstone = "202110gavi-3",
    modelling_group = "IC-Garske",
    disease = "YF",
    version = 1,
    stringsAsFactors = FALSE
  )

  ## 1 table match format of stochastic table
  ## year
  ## country
  ## run_id - 0 for centrals
  ## cases_no_vac
  ## deaths_no_vac
  ## dalys_no_vac
  ## plus cases, deaths and dalys for each scenario
  data <- lapply(names(input), function(name) {
    data <- input[[name]]
    data %>%
      dplyr::filter(country %in% c("AGO", "BEN", "BFA")) %>%
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

  con <- dettl:::db_connect("local", ".")
  DBI::dbWriteTable(con, "metadata", metadata)
  DBI::dbWriteTable(con, "stochastic_1_age_disag", data)
}

start <- Sys.time()
import()
end <- Sys.time()
time <- end - start
message(time)
output_file <- "timings.txt"
if (!file.exists(output_file)) {
  file.create(output_file)
}
write(time, file = output_file, append = TRUE)

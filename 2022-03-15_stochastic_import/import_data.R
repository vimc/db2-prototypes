#!/usr/bin/env Rscript

library("magrittr")

import <- function() {
  run_ids <- 1:200
  scenarios <-  c("yf-no-vaccination", "yf-preventive-default",
                  "yf-preventive-ia2030_target", "yf-routine-default",
                  "yf-routine-ia2030_target")
  cases <- expand.grid(run_ids, scenarios)
  colnames(cases) <- c("run_id", "scenario")
  files <- vapply(seq_len(nrow(cases)), function(row_no) {
    row <- cases[row_no, ]
    sprintf("Keith Fraser - stochastic-burden-estimates.202110gavi-3_YF_IC-Garske_%s_%s.csv.xz",
            row$scenario, row$run_id)
  }, character(1))
  file_paths <- file.path("stochastics", files)
  data <- lapply(file_paths, read.csv)
  extracted_data <- list(run_ids = run_ids,
       scenarios = scenarios,
       cases = cases,
       data = data)

  process_single_id <- function(run_id) {
    data <- extracted_data$data[which(extracted_data$cases$run_id == run_id)]
    ## Add scenario column and filter unwanted data
    add_columns <- function(scenario_no) {
      df <- data[[scenario_no]]
      df$scenario <- extracted_data$scenarios[scenario_no]
      df
    }
    run_data <- lapply(seq_along(extracted_data$scenarios), add_columns)
    run_data <- do.call(dplyr::bind_rows, run_data)
    run_data <- run_data %>%
      dplyr::select(-disease, -country_name) %>%
      tidyr::pivot_wider(id_cols = c("year", "age", "country", "cohort_size"),
                         names_from = scenario,
                         values_from = c("cases", "dalys", "deaths")) %>%
      dplyr::mutate(run_id = run_id) %>%
      dplyr::relocate(year, age, country, run_id)
  }

  all_data <- lapply(extracted_data$run_ids, process_single_id)
  stochastic_1_age_disag = do.call(dplyr::bind_rows, all_data)

  con <- dettl:::db_connect("local", ".")
  DBI::dbAppendTable(con, "stochastic_1_age_disag", stochastic_1_age_disag)
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

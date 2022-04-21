#!/usr/bin/env Rscript

library("magrittr")

import_single_table <- function(stochastic_id) {
  all_metric_columns <- c("cases_yf-no-vaccination",
                          "cases_yf-preventive-default",
                          "cases_yf-preventive-ia2030_target",
                          "cases_yf-routine-default",
                          "cases_yf-routine-ia2030_target",
                          "dalys_yf-no-vaccination",
                          "dalys_yf-preventive-default",
                          "dalys_yf-preventive-ia2030_target",
                          "dalys_yf-routine-default",
                          "dalys_yf-routine-ia2030_target",
                          "deaths_yf-no-vaccination",
                          "deaths_yf-preventive-default",
                          "deaths_yf-preventive-ia2030_target",
                          "deaths_yf-routine-default",
                          "deaths_yf-routine-ia2030_target",
                          "cases_measles-no-vaccination",
                          "cases_measles-campaign-default",
                          "cases_measles-campaign-only-default",
                          "cases_measles-mcv1-default",
                          "cases_measles-mcv2-default",
                          "cases_measles-campaign-ia2030_target",
                          "cases_measles-campaign-only-ia2030_target",
                          "cases_measles-mcv1-ia2030_target",
                          "cases_measles-mcv2-ia2030_target",
                          "deaths_measles-no-vaccination",
                          "deaths_measles-campaign-default",
                          "deaths_measles-campaign-only-default",
                          "deaths_measles-mcv1-default",
                          "deaths_measles-mcv2-default",
                          "deaths_measles-campaign-ia2030_target",
                          "deaths_measles-campaign-only-ia2030_target",
                          "deaths_measles-mcv1-ia2030_target",
                          "deaths_measles-mcv2-ia2030_target",
                          "dalys_measles-no-vaccination",
                          "dalys_measles-campaign-default",
                          "dalys_measles-campaign-only-default",
                          "dalys_measles-mcv1-default",
                          "dalys_measles-mcv2-default",
                          "dalys_measles-campaign-ia2030_target",
                          "dalys_measles-campaign-only-ia2030_target",
                          "dalys_measles-mcv1-ia2030_target",
                          "dalys_measles-mcv2-ia2030_target")

  con <- dettl:::db_connect("local", ".")
  all_data <- DBI::dbGetQuery(con, paste0("SELECT * FROM stochastic_",
                                          stochastic_id))

  ## Join on any missing columns with NA values
  missing <- all_metric_columns[!(all_metric_columns %in% colnames(all_data))]
  for (col_name in missing) {
    all_data[[col_name]] <- NA_real_
  }
  if ("year" %in% colnames(all_data)) {
    all_data$cohort <- NA_integer_
  } else if ("cohort" %in% colnames(all_data)) {
    all_data$year <- NA_integer_
  }
  all_data$stochastic_id <- stochastic_id

  all_data <- all_data %>%
    dplyr::arrange(stochastic_id, run_id, year, cohort, country) %>%
    dplyr::relocate(stochastic_id, run_id, year, cohort, country)

  message("Importing ", stochastic_id)
  DBI::dbWriteTable(con, "stochastic_all", all_data, append = TRUE)
}

start <- Sys.time()
for (i in 1:12) {
  import_single_table(i)
}
end <- Sys.time()
time <- end - start
msg <- paste0("Import ", time, " ", attr(time, "units"))
message(msg)
output_file <- "timings.txt"
if (!file.exists(output_file)) {
  file.create(output_file)
}
write(msg, file = output_file, append = TRUE)

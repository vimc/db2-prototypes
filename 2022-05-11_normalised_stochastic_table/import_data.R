#!/usr/bin/env Rscript

import <- function() {
  con <- dettl:::db_connect("local", ".")
  DBI::dbBegin(con)
  DBI::dbExecute(con, "CREATE TABLE stochastic_all_normalised (
  stochastic_id integer,
  run_id integer,
  year integer,
  cohort integer,
  country text,
  metric text,
  value double
)")

  data <- dplyr::tbl(con, "stochastic_all") %>%
    tidyr::pivot_longer("cases_yf-no-vaccination":"dalys_measles-mcv2-ia2030_target",
                        names_to = "metric", values_drop_na = TRUE)
  DBI::dbAppendTable(con, "stochastic_all_normalised", data)
  DBI::dbCommit(con)
}

start <- Sys.time()
import()
end <- Sys.time()
time <- end - start
msg <- paste0("Import ", time, " ", attr(time, "units"))
message(msg)
output_file <- "timings.txt"
if (!file.exists(output_file)) {
  file.create(output_file)
}
write(msg, file = output_file, append = TRUE)

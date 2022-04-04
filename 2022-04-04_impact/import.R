#!/usr/bin/env Rscript

library("magrittr")
source("R/coverage_clustering.R")
source("R/db.R")
source("R/extract.R")
source("R/generate_data.R")
source("R/stochastics_functions.R")
source("R/transform.R")
source("R/utils.R")

import <- function() {
  con <- dettl:::db_connect("local", ".")
  data <- extract(".", con)
  transformed <- transform(data)

  ## Import the data
  message("Writing cohort_all_2021")
  DBI::dbWriteTable(con, "cohort_all_2021", transformed$cohort_all_2021)
  message("Writing cohort_under5_2021")
  DBI::dbWriteTable(con, "cohort_under5_2021", transformed$cohort_under5_2021)
  message("Writing cross_all_2021")
  DBI::dbWriteTable(con, "cross_all_2021", transformed$cross_all_2021)
  message("Writing cross_under5_2021")
  DBI::dbWriteTable(con, "cross_under5_2021", transformed$cross_under5_2021)
  message("Writing intervention_all_2021")
  DBI::dbWriteTable(con, "intervention_all_2021", transformed$intervention_all_2021)
  message("Writing bootstrap_2021")
  DBI::dbWriteTable(con, "bootstrap_2021", transformed$bootstrap_2021)
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

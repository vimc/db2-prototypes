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
  con <- dettl:::db_connect("experiment", ".")
  data <- extract(".", con)
  transformed <- transform(data)

  ## Import the data
  browser()
  "test"

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

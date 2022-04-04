#!/usr/bin/env Rscript

library("magrittr")
source("R/blackbox.R")
source("R/coverage_clustering.R")
source("R/extract.R")
source("R/load.R")
source("R/process_bootstrap.R")
source("R/transform.R")
source("R/util.R")

import <- function() {
  con <- dettl:::db_connect("local", ".")
  data <- extract(".", con)
  transformed <- transform(data)

  ## Import the data
  load(transformed, con)
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

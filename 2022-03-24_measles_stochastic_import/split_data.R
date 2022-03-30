#!/usr/bin/env Rscript

process_single_file <- function(file) {
  message("Processing ", file)
  path <- file.path("stochastics", file)
  data <- readr::read_csv(path)
  countries <- unique(data$country)
  for (country in countries) {
    subset <- data[data$country == country, ]
    if (!dir.exists("processed")) {
      dir.create("processed", FALSE, FALSE)
    }
    out_path <- sprintf("processed/%s_%s.qs", tools::file_path_sans_ext(file, compression = TRUE), country)
    message("Writing ", out_path)
    qs::qsave(subset, file = out_path)
  }
}
## This splits the data into much more manageable chunks for importing
split_data <- function(root_name) {
  scenarios <-  c("no-vaccination", "campaign-default",
                  "campaign-only-default", "mcv1-default",
                  "mcv2-default", "campaign-ia2030_target",
                  "campaign-only-ia2030_target",
                  "mcv1-ia2030_target", "mcv2-ia2030_target")
  files <- sprintf("%s%s.csv.xz", root_name, scenarios)
  parallel::mclapply(files, process_single_file)
}

start <- Sys.time()
split_data("Han Fu - stochastic_burden_estimate_measles-LSHTM-Jit-")
end <- Sys.time()
time <- end - start
msg <- paste0("LSHTM-Jit data split: ", time, " ", attr(time, "units"))
message(msg)
output_file <- "data_split_timings.txt"
if (!file.exists(output_file)) {
  file.create(output_file)
}
write(msg, file = output_file, append = TRUE)

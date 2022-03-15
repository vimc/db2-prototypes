#' Extract data from sources.
#'
#' This step should pull data from sources -  local files or database. And load
#' it into memory ready for transform stage. Paths should all be written
#' relative to the root of the import directory.
#'
#' @param con The active DBI connection for extracting any data.
#'
#' @return A list of data frames representing the extracted data.
#'
#' @keywords internal
extract <- function(con) {
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
  list(run_ids = run_ids,
       scenarios = scenarios,
       cases = cases,
       data = data)
}

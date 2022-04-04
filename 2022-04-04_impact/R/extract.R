#' Extract data from sources.
#'
#' This step should pull data from sources -  local files or database. And load
#' it into memory ready for transform stage.
#'
#' @param path Path to the import project root used for finding any local data.
#' @param con The active DBI connection for extracting any data.
#'
#' @return A list of data frames representing the extracted data.
#'
#' @keywords internal
extract <- function(path, con) {
  ## Check if data exists already - if not then run this
  is_test = FALSE

  output_files <- list(
    cohort_all_2021 = "cohort_all.rds",
    cohort_under5_2021 = "cohort_under5.rds",
    cross_all_2021 = "cross_all.rds",
    cross_under5_2021 = "cross_under5.rds",
    intervention_all_2021 = "intervention_all.rds",
    bootstrap_2021 = "bootstrap.rds"
  )
  intermediate_files <- c("Measles", "YF")
  files <- c(unlist(output_files), intermediate_files)
  if (all(file.exists(unlist(output_files)))) {
    data <- output_files
  } else if (any(file.exists(files))) {
    proceed <- askYesNo("Some output files exist but not all - do you want to delete existing files and proceed?")
      if (isTRUE(proceed)) {
        unlink(files, recursive = TRUE)
        data <- generate_data(is_test)
      } else {
        stop("Stopping at user request.")
      }
  } else {
    data <- generate_data(is_test)
  }
  data
}

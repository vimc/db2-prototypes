#' Transform data into a form ready for loading into database.
#'
#' This step is responsible for transforming the extracted data into a form
#' which conforms with the database so it can be loaded at the next stage.
#'
#' @param extracted_data The extracted data from the extract stage.
#'
#' @return A named list of data frames representing the transformed data. This
#' should conform to the database schema, where each list item matches the name
#' of a table in the DB and the column names of each dataframe match the column
#' names from the DB.
#'
#' @keywords internal
transform <- function(extracted_data) {
  ## For each run id
  process_single_id <- function(run_id) {
    data <- extracted_data$data[which(extracted_data$cases$run_id == run_id)]
    ## Add scenario column and filter unwanted data
    add_columns <- function(scenario_no) {
      df <- data[[scenario_no]]
      df$scenario <- extracted_data$scenarios[scenario_no]
      df %>%
        dplyr::filter(country %in% c("AGO", "BEN", "BFA"))
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
  list(
    stochastic_1 = do.call(dplyr::bind_rows, all_data)
  )
}

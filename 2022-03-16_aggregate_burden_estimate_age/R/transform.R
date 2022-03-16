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
  data <- extracted_data$age_disag %>%
    dplyr::select(-cohort_size) %>%
    dplyr::group_by(run_id, year, country) %>%
    dplyr::summarise(
      `cases_yf-no-vaccination` = sum(`cases_yf-no-vaccination`),
      `cases_yf-preventive-default` = sum(`cases_yf-preventive-default`),
      `cases_yf-preventive-ia2030_target` = sum(`cases_yf-preventive-ia2030_target`),
      `cases_yf-routine-default` = sum(`cases_yf-routine-default`),
      `cases_yf-routine-ia2030_target` = sum(`cases_yf-routine-ia2030_target`),
      `dalys_yf-no-vaccination` = sum(`dalys_yf-no-vaccination`),
      `dalys_yf-preventive-default` = sum(`dalys_yf-preventive-default`),
      `dalys_yf-preventive-ia2030_target` = sum(`dalys_yf-preventive-ia2030_target`),
      `dalys_yf-routine-default` = sum(`dalys_yf-routine-default`),
      `dalys_yf-routine-ia2030_target` = sum(`dalys_yf-routine-ia2030_target`),
      `deaths_yf-no-vaccination` = sum(`deaths_yf-no-vaccination`),
      `deaths_yf-preventive-default` = sum(`deaths_yf-preventive-default`),
      `deaths_yf-preventive-ia2030_target` = sum(`deaths_yf-preventive-ia2030_target`),
      `deaths_yf-routine-default` = sum(`deaths_yf-routine-default`),
      `deaths_yf-routine-ia2030_target` = sum(`deaths_yf-routine-ia2030_target`)
    )
  list(
    stochastic_1 = data
  )
}

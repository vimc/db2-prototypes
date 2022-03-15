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
  ## Take separate datasets and transform into
  transformed_data <- lapply(extracted_data, function(data) {
    data %>% dplyr::filter(country %in% c("AGO", "BEN", "BFA"))
  })
  ## Make 1 table containing
  ## id - matches name of 2nd table
  ## touchstone
  ## modelling_group
  ## disease
  ## version?

  ## 1 table match format of stochastic table
  ## year
  ## country
  ## run_id - 0 for centrals
  ## cases_no_vac
  ## detahs_no_vac
  ## dalys_no_vac
  ## plus other scenarios
}

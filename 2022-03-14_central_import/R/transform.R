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
  ## Create metadata entry
  ## matching format of stochastic_file table
  ## id here matches the number which we will upload the
  ## data at i.e. stochastic_1 here
  metadata <- data.frame(
    id = 1,
    touchstone = "202110gavi-3",
    modelling_group = "IC-Garske",
    disease = "YF",
    stringsAsFactors = FALSE
  )

  ## 1 table match format of stochastic table
  ## year
  ## country
  ## run_id - 0 for centrals
  ## cases_no_vac
  ## deaths_no_vac
  ## dalys_no_vac
  ## plus cases, deaths and dalys for each scenario
  data <- lapply(names(extracted_data), function(name) {
    data <- extracted_data[[name]]
    data %>%
      dplyr::filter(country %in% c("AGO", "BEN", "BFA")) %>%
      dplyr::mutate(scenario = name)
  })
  data <- do.call(dplyr::bind_rows, data)
  ## Q: Do we need to keep cohort size here?
  data <- data %>%
    dplyr::select(-disease, -country_name) %>%
    tidyr::pivot_wider(id_cols = c("year", "age", "country", "cohort_size"),
                       names_from = scenario,
                       values_from = c("cases", "dalys", "deaths")) %>%
    dplyr::mutate(run_id = 0) %>%
    dplyr::relocate(year, age, country, run_id)
  list(
    metadata = metadata,
    stochastic_1 = data
  )
}

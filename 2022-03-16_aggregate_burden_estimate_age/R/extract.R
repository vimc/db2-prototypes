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
  list(
    age_disag = DBI::dbGetQuery(con, "select * from stochastic_1_age_disag")
  )
}

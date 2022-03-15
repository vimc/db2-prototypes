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
    `yf-no-vaccination` = read.csv("central/yf-no-vaccination.csv"),
    `yf-preventive-default` = read.csv("central/yf-preventive-default.csv"),
    `yf-preventive-ia2030_target` = read.csv("central/yf-preventive-ia2030_target.csv"),
    `yf-routine-default` = read.csv("central/yf-routine-default.csv"),
    `yf-routine-ia2030_target` = read.csv("central/yf-routine-ia2030_target.csv")
  )
}

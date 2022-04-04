load <- function(transformed_data, con) {

  ## Import failed when part complete so remove some of the setup we
  ## wanted to do when iteratively developing this import.

  if (FALSE) {
    ## Remove tables if exist and create empty ones
    chunks <- c("cross_all_2021", "cross_under5_2021", "cohort_all_2021", "cohort_under5_2021")
    initialise_tables <- function(chunk) {
      table_name <- sprintf("impact_cluster_%s", chunk)
      if (DBI::dbExistsTable(con, table_name)) {
        message(sprintf("Dropping table %s", table_name))
        DBI::dbRemoveTable(con, table_name)
      }
      fields <- data.frame(
        boots_id = integer(0),
        country = character(0),
        year = integer(0),
        gavi73 = logical(0),
        deaths_impact = double(0),
        deaths_novac = double(0),
        dalys_impact = double(0),
        dalys_novac = double(0),
        stringsAsFactors = FALSE
      )
      invisible(DBI::dbCreateTable(con, table_name, fields))
    }
    lapply(chunks, initialise_tables)
  }

  extracted_data <- attr(transformed_data, "extracted_data")
  n <- extracted_data$n_size
  for (bootstrap_id in seq_len(n)) {
    message(sprintf("Processing bootstap sample %s", bootstrap_id))
    process_bootstrap_sample(bootstrap_id, "cross_all_2021", extracted_data,
                             con, upload = TRUE)
    process_bootstrap_sample(bootstrap_id, "cross_under5_2021", extracted_data,
                             con, upload = TRUE)
    process_bootstrap_sample(bootstrap_id, "cohort_all_2021", extracted_data,
                             con, upload = TRUE)
    process_bootstrap_sample(bootstrap_id, "cohort_under5_2021", extracted_data,
                             con, upload = TRUE)
  }
  a = DBI::dbListTables(con)
  print(a[grepl("_2021", a)])
}

verification_queries <- function(con) {
  ## Return a list of data extracted from the DB.
  ## This will get run before and after the load stage and made available
  ## to the load tests so you can check for the differences made by load stage
  list(row_num = as.integer(
    DBI::dbGetQuery(con, "select count(*) from stochastic_1")[1, 1]))
}

#!/usr/bin/env Rscript

import <- function() {
  con <- dettl:::db_connect("local", ".")
  DBI::dbBegin(con)
  DBI::dbExecute(con, "CREATE TABLE stochastic_all_partition (
  LIKE stochastic_all INCLUDING All
) PARTITION BY LIST (stochastic_id)")

  for (id in 1:12) {
    DBI::dbExecute(con, sprintf("CREATE TABLE stochastic_all_partition_%s
PARTITION OF stochastic_all_partition
FOR VALUES IN (%s)", id, id))
  }

  DBI::dbExecute(con,
                 "INSERT INTO stochastic_all_partition SELECT * FROM stochastic_all")

  check <- DBI::dbGetQuery(
    con,
    "select * from stochastic_all_partition where stochastic_id = 12")
  if (nrow(check) > 0) {
    DBI::dbCommit(con)
  } else {
    DBI::dbRollback(con)
  }
}

start <- Sys.time()
import()
end <- Sys.time()
time <- end - start
msg <- paste0("Import ", time, " ", attr(time, "units"))
message(msg)
output_file <- "timings.txt"
if (!file.exists(output_file)) {
  file.create(output_file)
}
write(msg, file = output_file, append = TRUE)

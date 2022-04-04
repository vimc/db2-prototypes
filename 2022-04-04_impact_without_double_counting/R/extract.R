extract <- function(con) {

  is_test <- TRUE
  n_size <- ifelse(is_test, 10, 1e3)

  library(vimpact)
  library(jenner)
  library(dplyr)
  library(rlist)
  load_dll()
  dir.create("cache", FALSE, TRUE)
  dir.create("cache/uploaded", FALSE, TRUE)
  con_science <- db_connect_science()
  con_annex <- db_connect_annex()
  ## This takes a few (~4) minutes to run if not using a cached RDS
  out <- cache_rds(prep(con_science, con_annex), "cache/prep.rds")
  out$con_import_db <- con
  out$n_size <- n_size
  out
}

db_connect_science <- function() {
  config <- dettl:::dettl_config(".")
  password <- "VAULT:/secret/database/users/readonly:password"
  withr::with_envvar(
    dettl:::envir_read(config$path),
    resolved_args <- vaultr::vault_resolve_secrets(
      password,
      addr = config$vault_server
    )
  )
  DBI::dbConnect(RPostgres::Postgres(),
                 dbname = "montagu",
                 host = "support.montagu.dide.ic.ac.uk",
                 port = 5432,
                 user = "readonly",
                 password = resolved_args[[1]])
}

db_connect_experiment <- function() {
  dettl:::db_connect("experiment", ".")
}

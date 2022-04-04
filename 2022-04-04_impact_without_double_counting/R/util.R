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

db_connect_annex <- function() {
  dettl:::db_connect("annex", ".")
}

cache_rds <- function(expr, file) {
  if (file.exists(file)) {
    readRDS(file)
  } else {
    value <- force(expr)
    saveRDS(value, file)
    value
  }
}

read_sql <- function(filename) {
  paste(readLines(filename), collapse = "\n")
}

merge_by_common_cols <- function(d1, d2, ...){
  merge(d1, d2, by = intersect(names(d1), names(d2)), ...)
}

compile_and_load_dll <- function() {
  name <- paste0("proportion", .Platform$dynlib.ext)
  withr::with_dir("src", {
    tryCatch(dyn.unload(name), error = function(e) NULL)
    unlink(name)
    R <- file.path(R.home(), "bin", "R")
    args <- c("CMD", "SHLIB", "proportion.c")
    res <- system2(R, args)
    if (res > 0) {
      stop("Error compiling dll")
    }
    dyn.load("proportion.so")
  })
}

load_dll <- function() {
  dlls <- getLoadedDLLs()
  if (!("proportion" %in% names(dlls))) {
    compile_and_load_dll()
  }
}

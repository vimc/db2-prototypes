## This takes about 1.8s without the index, 0.3s with the index, plus the transfer cost
process_bootstrap_sample_read <- function(con, boots_id, table) {
  query <- "SELECT tmp.boots_id, tmp.disease, country, year,
              deaths_novac, deaths_default, dalys_novac, dalys_default FROM
            (SELECT DISTINCT bootstrap_2021.boots_id, bootstrap_2021.disease, bootstrap_2021.stochastic_file_id, bootstrap_2021.run_id FROM bootstrap_2021 WHERE boots_id = '{boots_id}') AS tmp
            JOIN {table}
            ON tmp.stochastic_file_id = {table}.stochastic_file_id
            AND tmp.run_id = {table}.run_id
            WHERE year BETWEEN 2000 AND 2030"
  DBI::dbGetQuery(con, glue::glue(query, table = table, boots_id = boots_id))
}


process_bootstrap_sample_compute <- function(boots_id, cluster, data, gavi73) {
  d <- proportional_burden_prep(data, cluster, boots_id)
  d2 <- d[!is.na(d$index_level1), ]
  d2 <- d2[order(d2$index_level1, d2$n_vaccines), ]
  browser()
  compute_thing(d2, gavi73)
}


process_bootstrap_sample <- function(boots_id, table, extracted_data,
                                     con, upload) {
  path <- sprintf("cache/uploaded/%s_%d.rds", table, boots_id)
  if (file.exists(path)) {
    if (!upload) {
      message("Skipping this upload")
      return(invisible(NULL))
    }
    res <- readRDS(path)
  } else {
    data <- process_bootstrap_sample_read(con, boots_id, table)
    res <- process_bootstrap_sample_compute(boots_id,
                                            extracted_data$cluster[[table]],
                                            data, extracted_data$gavi73)
    saveRDS(res, path, compress = FALSE)
  }

  if (isTRUE(upload)) {
    table_name <- sprintf("impact_cluster_%s", table)
    stopifnot(grepl("_2021", table_name))
    tryCatch({
      DBI::dbWriteTable(con, table_name, res, append = TRUE)
    },
      error = function(e) {
        warning(sprintf("Import failed for table %s and bootstrap id %s.\nWith message %s",
                        table_name, boots_id, e$message))
    })
  }
  res
}

proportional_burden_prep <- function(d, cluster, boots_id_number) {
  ## Can be replaced by plain assignment
  d <- d %>%
    mutate(index_level1 = paste(boots_id, country, year, sep = "-"),
           index_level2 = paste(country, year, disease, sep = "-"))

  ###sorry, the following becomes more complicated
  ### fist of all, get a copy of demographic data for later use
  a <- cluster %>%
    select(country, year, pop, rmly) %>% unique()

  ### instead of left join, I have to do full join to grab diseases with zero coverage
  d2 <- cluster %>%
    select(-pop, -rmly, - country, -year) %>%
    full_join(d, by = "index_level2") %>%
    mutate(coverage = ifelse(is.na(coverage), 0, coverage),
           prop_with_n_vaccines = ifelse(is.na(prop_with_n_vaccines), 0, prop_with_n_vaccines),
           n_vaccines = ifelse(is.na(n_vaccines), 11, n_vaccines))

  i <- is.na(d2$boots_id)
  t <- d2[i,]
  tmp <- stringr::str_split_fixed(t$index_level2, "-", 3)
  t <- t %>%
    mutate(country = tmp[, 1],
           year = as.numeric(tmp[, 2]),
           disease = as.character(tmp[, 3]),
           boots_id = boots_id_number,
           index_level1 = paste(boots_id, country, year, sep = "-"))

  d2 <- rbind(d2[!i, ], t[names(d2)]) %>%
    left_join(a, by = c("country", "year")) %>%
    dplyr::select(-index_level2) ### we do not have 2000 for rubella because of age re-attribution

  d2 <- d2 %>%
    mutate(deaths_novac = ifelse(is.na(deaths_novac), 0, deaths_novac),
           deaths_default = ifelse(is.na(deaths_default), 0, deaths_default),
           dalys_novac = ifelse(is.na(dalys_novac), 0, dalys_novac),
           dalys_default = ifelse(is.na(dalys_default), 0, dalys_default))   %>%
    mutate(mort_df = deaths_default / pop,
           mort_no = deaths_novac / pop,
           mort_vac = mort_no - (mort_no - mort_df)/coverage
    ) %>%
    mutate(mort_vac = ifelse(is.finite(mort_vac), mort_vac, mort_no)) %>%
    mutate(mort_no_adj = ifelse(mort_vac < 0, mort_df / (1 - coverage), mort_no),
           mort_vac_adj = ifelse(mort_vac < 0, 0, mort_vac)
    ) %>%
    mutate(dalys_df = dalys_default / rmly,
           dalys_no = dalys_novac / rmly,
           dalys_vac = dalys_no - (dalys_no - dalys_df)/coverage
    ) %>%
    mutate(dalys_vac = ifelse(is.finite(dalys_vac), dalys_vac, dalys_no)) %>%
    mutate(dalys_no_adj = ifelse(dalys_vac < 0, dalys_df / (1 - coverage), dalys_no),
           dalys_vac_adj = ifelse(dalys_vac < 0, 0, dalys_vac)
    )
  d2
}

compute_thing <- function(d, gavi73) {
  idx <- rle(d$index_level1)$lengths
  head <- d[cumsum(idx), c("boots_id", "country", "year")]
  head$gavi73 <- head$country %in% gavi73
  rownames(head) <- NULL
  result <- .Call("r_compute_thing", idx, d$prop_with_n_vaccines,
                  d$pop, d$mort_no, d$mort_no_adj, d$mort_vac_adj,
                  d$rmly, d$dalys_no, d$dalys_no_adj, d$dalys_vac_adj,
                  PACKAGE = "proportion")
  result <- matrix(result, ncol = 4, byrow = TRUE)
  colnames(result) <- c("deaths_impact", "deaths_novac",
                        "dalys_impact", "dalys_novac")
  cbind(head, result)
}

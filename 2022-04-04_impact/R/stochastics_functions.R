## annex connection
get_stochastics <- function(annex, meta_stochastic, disease, life_time, under5, year_min = NULL, year_max = NULL, impact_recipe, is_test = TRUE, scenario_type) {
  ## read data
  index <- meta_stochastic[meta_stochastic$disease == disease & meta_stochastic$is_cohort == life_time & meta_stochastic$is_under5 == under5, ]
  burden <- rep(list(NULL), length(index$id))
  year_min <- ifelse(is.null(year_min), 1900, year_min)
  year_max <- ifelse(is.null(year_max), 2100, year_max)

  test_run_id <- ifelse(is_test, "AND run_id <= 10", "")
  time_view <- ifelse(life_time, "cohort_view", "calendar_view")
  age_view <- ifelse(under5, "under5s", "all_age")
  print(paste0("Loading data:", paste(disease, time_view, age_view, sep = ", ")))
  for(i in seq_along(burden)) {
    if (life_time) {
      burden[[i]] <- DBI::dbGetQuery(annex, paste(sprintf("SELECT * FROM %s",
                                                          paste0("stochastic_", index$id[i])),
                                                  "WHERE cohort BETWEEN $1 AND $2", test_run_id), list(year_min, year_max))
      burden[[i]]$year <- burden[[i]]$cohort
      burden[[i]]$cohort <- NULL
    } else {
      burden[[i]] <- DBI::dbGetQuery(annex, paste(sprintf("SELECT * FROM %s",
                                                          paste0("stochastic_", index$id[i])),
                                                  "WHERE year BETWEEN $1 AND $2", test_run_id), list(year_min, year_max))
    }
    # cannot remember what the following is for, comment out for now
    # maybe it was just to get rid of [sia+rcv1] scenario, avoiding confusion
    # this scenario is not used for method2 for 2017 runs, as PHE model did not run this scenario
    # I guess, I need to update recipe this time, as the model now runs for the scenario for 2019 runs
    # if(index$modelling_group[i] == "PHE-Vynnycky") {
    #   message("to make work re-usable, need touchstone constrain here as well")
    #   burden[[i]]$deaths_rcv1 <- NA
    #   burden[[i]]$cases_rcv1 <- NA
    #   burden[[i]]$dalys_rcv1 <- NA
    # }
    burden[[i]]$index <- index$id[i]
    names(burden[[i]]) <- gsub(pattern = "-LiST", "", names(burden[[i]]))
  }

  tmp_cols <- list()
  for(i in seq_along(burden)){
    tmp_cols[[i]] <- names(burden[[i]])
  }
  tmp_cols <- Reduce(intersect, tmp_cols)
  for(i in seq_along(burden)){
    burden[[i]] <- burden[[i]][tmp_cols]
  }

  burden <- do.call(rbind, burden)
  i <- grepl("cases", names(burden)) | grepl("best", names(burden))
  burden <- burden[names(burden)[!i]] # I am not interested in cases or hepb_best

  if(scenario_type == "default"){
    i <- grepl("ia2030_target", names(burden))
  } else if(scenario_type == "ia2030_target"){
    i <- grepl("default", names(burden))
  }
  burden <- burden[names(burden)[!i]]
  burden$disease <- disease

  ## calculate raw impact
  ifelse(life_time,  print("Calculating life-time impact"),
         print("Calculating cross-sectional impact"))

  recipe <- impact_recipe[impact_recipe$disease == disease, ]

  if(disease %in% c("HepB")) {
    recipe$delivery <- paste(recipe$vaccine, recipe$activity_type, recipe$comment, sep = "-")
  } else {
    recipe$delivery <- paste(recipe$vaccine, recipe$activity_type, sep = "-")

  }
  impact_outcomes <- c("deaths", "dalys")
  for(i in seq_along(recipe$delivery)) {
    for(j in impact_outcomes) {
      s <- paste(recipe$delivery[i],
                 paste(j, "averted", sep = "_"),
                 sep = "-")
      baseline <- paste(j, recipe$baseline[i], sep = "_")
      focal <- paste(j, recipe$focal_ingredient[i], sep = "_")
      burden[[s]] <- burden[[baseline]] - burden[[focal]]
    }

  }
  return(burden)
}

## this is method 2 impact calcualtion for per vaccine-delivery
impact_calculate <- function(dat, vaccine, activity_type, t_min, t_max, fvp, meta_stochastic) {
  ##total impact by country
  vaccine1 <- vaccine

  fvp <- fvp[fvp$vaccine %in% vaccine1 & fvp$activity_type == activity_type & fvp$year %in% 2000:2030, ]
  fvp$vaccine <- vaccine
  fvp$gavi_support[is.na(fvp$gavi_support)] <- FALSE
  fvp <- aggregate(cbind(population, fvps, gavi_support) ~ disease + vaccine + activity_type + country + year, data = fvp,  sum, na.rm = TRUE)

  i <- grepl(paste(vaccine, activity_type, sep="-"), names(dat)) & grepl("averted", names(dat))
  value_cols <- names(dat)[i]
  value_cols2 <- paste0(value_cols, "_rate")
  dat <- dat[dat$year %in% t_min:t_max,] %>%
    group_by(index, run_id, country) %>%
    summarise_at(value_cols, sum)

  ## total fvps by country
  dat_fvp <- aggregate(fvps ~ vaccine + activity_type + country, data = fvp, sum)
  dat$fvp <- dat_fvp$fvps[match(dat$country, dat_fvp$country)]
  dat$fvp[is.na(dat$fvp)] <- 0

  ## impact ratio by country
  dat <- dat %>%
    mutate_at(value_cols, funs(. / fvp)) %>%
    mutate_at(value_cols, funs(replace(., which(!is.finite(.)), NA))) %>%
    rename_at(value_cols, ~ value_cols2)

  dat$fvp <- NULL
  dat$index <- meta_stochastic$modelling_group[match(dat$index, meta_stochastic$id)]

  ## calculate impact
  dat <- merge(dat, fvp[c("country", "year", "gavi_support", "population", "fvps")], by = "country", all.x = TRUE)
  for(i in seq_along(value_cols)) {
    dat[[value_cols[i]]] <- dat[[value_cols2[i]]] * dat[["fvps"]]
  }
  dat <- dat %>%
    rename_at("gavi_support", funs(paste(vaccine, activity_type, "gavi_support",  sep="-")))
  dat$fvps <- NULL
  dat$population <- NULL
  return(dat)
}

### this is method 2 impact for per disease
impact_method2 <- function(con, disease, dat_cross, dat_life, fvp, meta_stochastic) {
  y_min <- 2000
  y_max <- 2100
  max_rout <- 2030 #default max rout cohort
  age_default <- DBI::dbReadTable(con, "vaccine_routine_age")
  age_default <- rbind(age_default,
                       data.frame(id = -1, vaccine = 'Typhoid', age = 0))
  #### stage one - get impact ratios
  #### rout - total cohort impact: 2000:2030 for age 0, 1998-2028 for age 2, 1991-2021 for age9, 1998-2030 for rubella focal group
  #### sia - total cross impact: 2000-2100
  #### stage two - impact by year of vaccination

  if (disease == "YF") {
    ## determine routine age, and cohort range for impact rate calculation
    rout_age <- age_default$age[age_default$vaccine == disease]
    d1 <- impact_calculate(dat_cross, vaccine = disease, activity_type = "campaign", t_min = y_min, t_max = y_max, fvp, meta_stochastic)
    d2 <- impact_calculate(dat_life, vaccine = disease, activity_type = "routine", t_min = y_min - rout_age, t_max = max_rout - rout_age, fvp, meta_stochastic)
    dat <- merge(d1, d2, by = intersect(names(d1), names(d2)), all = TRUE)
  } else if (disease == "Measles") {
    rout_age <- age_default$age[age_default$vaccine == "MCV2"]
    d1 <- impact_calculate(dat_life, vaccine = "MCV1", activity_type = "routine", t_min = y_min, t_max = max_rout, fvp, meta_stochastic)
    d2 <- impact_calculate(dat_life, vaccine = "MCV2", activity_type = "routine", t_min = y_min - rout_age, t_max = max_rout - rout_age, fvp, meta_stochastic)
    d3 <- impact_calculate(dat_cross, vaccine = disease, activity_type = "campaign", t_min = y_min, t_max = y_max, fvp, meta_stochastic)

    dat <- Reduce(function(x,y) merge(x = x, y = y, by = intersect(names(x), names(y)), all = TRUE),
                  list(d1, d2, d3))
  } else {
    stop("Unknown disease name.")
  }
  dat$disease <- disease
  return(dat[!is.na(dat$year), ])
}


###
## this function tidies up burden/impact estimates, and conduct bootstrap re-sampling, and save as rds files
fun_bootstrap <- function(paths, n = 100e3, con, annex, is_test) {
  ## this function is to provide bootstrap samples of burden and impact
  all_index <- DBI::dbGetQuery(annex, "SELECT disease, id, modelling_group FROM stochastic_file WHERE touchstone LIKE '%202110gavi%'")
  all_index <- all_index[!(all_index$disease %in% c("Rota", "Hib", "PCV") & all_index$modelling_group == "JHU-Tam"), ]
  country <- DBI::dbReadTable(con, "country")

  ## as we want to use the data for different purposes, each bootstrap re-sampling should apply to all view-age combos - i.e. 4 combos
  ### initialization
  dat_names <- c("cross_all",
                 "cross_under5",
                 "cohort_all",
                 "cohort_under5",
                 "intervention_all")
  is_cohort <- c(FALSE, FALSE, TRUE, TRUE, FALSE)
  is_under5 <- c(FALSE, TRUE, FALSE, TRUE, FALSE)
  year_min <- 2000
  year_max <- 2030

  for(k in seq_along(dat_names)) {
    ### loading data
    dat <- rep(list(NULL), length(paths))
    for(i in seq_along(paths)) {
      disease <- paths[i]
      if(!(is_under5[k] & disease %in% c("HPV"))) {
        files <- list.files(disease)

        if (dat_names[k] == "intervention_all"){
          file <- files[grepl("raw", files) & grepl("intervention", files)]
        } else {
          time_view <- ifelse(is_cohort[k], "cohort", "cross")
          age_view <- ifelse(is_under5[k], "under5", "allage")
          file <- files[grepl("raw", files) & grepl(time_view, files) & grepl(age_view, files)]
        }
        stopifnot(length(file) == 1L)
        d <- readRDS(file.path(disease, file))
        ### initial constraints
        ## allow all cohort impact to be stored for method2b
        if(!is_cohort[k]){
          d <- d[d$year %in% year_min:year_max, ]
        } else{
          d <- d[d$year <= year_max, ]
        }

        if (dat_names[k] == "intervention_all"){
          dat[[i]]  <- re_name(d, disease, is_method2 = TRUE)
        } else {
          dat[[i]]  <- re_name(d, disease)
        }

      } else {
        dat[[i]] <- NULL
      }
    }
    dat <- do.call(rbind, dat)

    dat$country <- country$id[match(dat$country, country$nid)]
    print(paste("creating table", dat_names[k]))

    if (dat_names[k] == "intervention_all") {
      names(dat)[names(dat) == "index"] <- "modelling_group"
    } else {
      names(dat)[names(dat) == "index"] <-"stochastic_file_id"
    }

    saveRDS(dat, paste0(dat_names[k], ".rds"))
  }

  ### re-sampling
  print("bootstrapping")
  all_index2 <- unique(all_index[c("disease", "modelling_group")])
  for(i in unique(all_index2$disease)) {
    all_index2$index2[all_index2$disease == i] <- seq_along(all_index2$disease[all_index2$disease == i])
  }
  all_index <- suppressMessages(left_join(all_index, all_index2))
  all_index <- all_index[order(all_index$disease), ]

  if(is_test){
    sample_pool <- 1:10
  } else {
    sample_pool <- 1:200
  }

  meta <- lapply(1:n, function(i) {
    v <- rep(list(NULL), length(paths))
    for(j in seq_along(v)) {
      v[[j]] <- data_frame(disease = paths[j],
                           index2 = sample(unique(all_index$index2[all_index$disease == paths[j]]), 1, replace = TRUE),
                           run_id = sample(sample_pool, 1, replace = TRUE),
                           boots_id = i)
    }
    do.call(rbind, v)
  })
  meta <- do.call(rbind, meta)
  meta <- suppressMessages(left_join(all_index, meta))
  meta$index <- meta$id
  meta$index2 <- NULL
  meta$id <- NULL

  sql <- "SELECT id FROM stochastic_file WHERE modelling_group = $1 and NOT is_cohort and NOT is_under5"
  meta <- meta %>%
    mutate(index = ifelse(modelling_group == "JHU-Lessler", DBI::dbGetQuery(annex, sql, "JHU-Lessler")[["id"]][1L], index)) %>%
    mutate(index = ifelse(modelling_group == "PHE-Vynnycky", DBI::dbGetQuery(annex, sql, "PHE-Vynnycky")[["id"]][1L], index))
  names(meta)[names(meta) == "index"] <-"stochastic_file_id"

  saveRDS(meta,  "bootstrap.rds")

  rm(list=ls())
  invisible(gc())
}

get_sql_iso <- function(outcome, tab, period, iso) {
  paste(sprintf("SELECT `index`, run_id, SUM(%s) AS value", outcome),
        sprintf("FROM %s", tab),
        sprintf("WHERE year IN %s", sql_in(period, text_item = FALSE)),
        sprintf("AND country IN %s", sql_in(iso, text_item = TRUE)),
        sprintf("GROUP BY `index`, run_id"),
        sep ="\n")
}

get_sql_boot <- function(sql) {
  paste(sprintf("SELECT bootstrap.disease, bootstrap.boots_id, tab1.* FROM"),
        sprintf("(%s) AS tab1", sql),
        sprintf("JOIN bootstrap
                ON bootstrap.`index` = tab1.`index`
                AND bootstrap.run_id = tab1.run_id"),
        sep = "\n")
}

re_name <- function(d, disease_d, ignore.useless = TRUE, is_method2 = FALSE) {
  d <- d[!grepv(c("stop", "only", "best"), names(d), is_and = FALSE)]
  ## local function for renaming method2
  long_to_wide <- function(dat, d, vaccines, activity_types){
    for(i in seq_along(dat)){
      dat[[i]] <- d[c(grepl(paste0(vaccines[i], "-", activity_types[i], "-"), names(d)) | names(d) %in% key_cols)]
      #dat[[i]]$vaccine <- ifelse(disease_d == "Rubella", "Rubella", vaccines[i])
      dat[[i]]$vaccine <- vaccines[i]
      dat[[i]]$activity_type <- activity_types[i]
      names(dat[[i]]) <- gsub(paste0(vaccines[i], "-", activity_types[i], "-"), "", names(dat[[i]]))

    }
    do.call(rbind, dat)
  }

  if (is_method2){
    key_cols <- c("disease", "index", "run_id", "country", "year")

    if (disease_d == "HepB"){
      dat <- rep(list(NULL), 2)
      vaccines <- c("HepB_BD", "HepB")
      activity_types <- c("routine", "routine")
    } else if (disease_d %in% c("PCV", "Hib", "Rota")){
      dat <- rep(list(NULL), 1)
      vaccines <- ifelse(disease_d == "Rota", disease_d, paste0(disease_d, 3))
      activity_types <- c("routine")
    } else if (disease_d %in% c("HPV", "MenA", "YF", "JE", "Typhoid")){
      dat <- rep(list(NULL), 2)
      vaccines <- c(disease_d, disease_d)
      activity_types <- c("campaign", "routine")
    } else if (disease_d == "Rubella"){
      dat <- rep(list(NULL), 3)
      vaccines <- c(disease_d, disease_d, "RCV2")
      activity_types <- c("campaign", "routine","routine")
    } else if (disease_d == "Measles"){
      dat <- rep(list(NULL), 3)
      vaccines <- c("MCV1", "MCV2", disease_d)
      activity_types <- c("routine", "routine", "campaign")
    } else if (disease_d == "Cholera"){
      dat <- rep(list(NULL), 1)
      vaccines <- disease_d
      activity_types <- "campaign"
    }
    d <- long_to_wide(dat, d, vaccines, activity_types)


  } else {

    default_burden <- NA
    default_impact <- "all"

    default_impact <- ifelse(disease_d == "Hib", paste("Hib3", "routine", sep="-"), default_impact)
    default_impact <- ifelse(disease_d == "PCV", paste("PCV3", "routine", sep="-"), default_impact)
    default_impact <- ifelse(disease_d == "Rota", paste("Rota", "routine", sep="-"), default_impact)
    default_impact <- ifelse(disease_d == "Cholera", paste("Cholera", "campaign", sep="-"), default_impact)

    ##burden no vac & default
    if(disease_d == "HepB") {
      default_burden <- "bd-default-hepb-routine"
    } else if (disease_d == "Rubella") {
      default_burden <- "rubella-rcv2"
    } else if (disease_d %in% c("Hib", "PCV", "Rota", "HPV", "MenA", "Typhoid")) {
      default_burden <- "routine"
    } else if(disease_d == "YF") {
      default_burden <- "preventive"
    } else {
      default_burden <- "campaign"
    }

    i <- which(grepv(c("no-vac", "deaths"), names(d)))
    names(d)[i] <- "deaths_novac"

    i <- which(grepv(c("no-vac", "cases"), names(d)))
    names(d)[i] <- "cases_novac"

    i <- which(grepv(c("no-vac", "dalys"), names(d)))
    names(d)[i] <- "dalys_novac"

    i <- which(grepl(default_burden, names(d)) & !grepl("averted", names(d)))
    stopifnot(length(i) == 2L) ## we only have deaths and dalys at the moment
    names(d)[i] <- gsub(pattern = "\\_.*", replacement = "_default", x = names(d[i]))

    i <- which(grepv(c(default_impact, "deaths_averted"), names(d)))
    stopifnot(length(i) == 1L) ## we only have deaths and dalys at the moment
    names(d)[i] <- "deaths_impact"

    i <- which(grepv(c(default_impact, "dalys_averted"), names(d)))
    stopifnot(length(i) == 1L) ## we only have deaths and dalys at the moment
    names(d)[i] <- "dalys_impact"

    if (ignore.useless) {
      d <- d[grepv(c("novac", "default", "impact"), names(d), is_and = FALSE) | !grepv(c("deaths", "dalys"), names(d), is_and = FALSE)]
      d <- d[!grepl(disease_d, names(d), ignore.case = TRUE)]
    }
  }
  return(d)
}

### the aims of this function are
### 1. get cohort vaccination history, record how coverage increase over time for cohrots
### 2. get population level coverage history
### of course, I save source coverage and population data for future use
vaccine_coverage_history <- function(con, touchstone_cov, touchstone_pop, year_first, year_last, cohort_first, cohort_last, 
                                     gavi_support_levels = "with", scenario_type = scenario_type){
  
  if(length(gavi_support_levels) > 1){
    stop("Sorry, you can have only one gavi_support_level at a time!")
  }
  year_min = 1980 # year_min = 1980 for pre-2000 cohorts in years 2000:2030
  year_max = cohort_last + 9 # this is to include HPV routine coverage for cohort_last
  age_min = 0
  age_max = 100
  
  ## extract coverage and population data from the db
  print("extracting population data...")
  
  ### life expectancy
  ### assuming identical life expectatancy for man and women, as we do not have gender specific values
  p_life_ex <- jenner::create_dalys_life_table(con, touchstone_pop, year_first, year_last)
  tmp <- stringr::str_split_fixed(p_life_ex$`.code`, "-", 3)
  p_life_ex$country <- tmp[, 1]
  p_life_ex$year <- as.integer(tmp[, 2])
  p_life_ex$age <- as.integer(tmp[, 3])
  p_life_ex_int <- p_life_ex[-which(names(p_life_ex) %in% c("gender", ".code"))]
  
  touchstone_pop <-  get_touchstone(con, touchstone_pop)

  p_tot_pop <- get_population(con, touchstone_pop, demographic_statistic = "tot_pop", 
                              year_ = year_min:year_max, gender = c("Female", "Both"))
  
  p_int_pop <- get_population(con, touchstone_pop, demographic_statistic = "int_pop", 
                              year_ = year_min:year_max, gender = c("Male", "Female", "Both"))
  
  p_life_ex_birth <- get_population(con, touchstone_pop, "lx0", gender =  c("Both"), year_ = cohort_first:cohort_last) 
  
  ## all gender information are needed from p_int_pop to calculate correct activity_level coverage
  f <- extract_vaccination_history(con, touchstone_cov = touchstone_cov, year_min = year_min, year_max = year_max, gavi_support_levels = gavi_support_levels, external_population_estimates = p_int_pop)
  
  ## HPV is female only, no need of male pop anymore
  p_int_pop <- p_int_pop[p_int_pop$gender != "Male", ]
  
  print("done!")
  
  ## now we need to calculate cohort coverage history
  ## assumption, assume individuals from the same cohort do not receive multiple doses in the same year (except for hepb)
  ## that means, fvps are additive
  print("generating cohort life time coverage history, e.g. 0, 0, 0, 0.5, 0.9, 0.9, 0.9, 0.9...")
  
  t1 <- f[f$disease == "HepB", ]
  t2 <- f[f$disease != "HepB", ]
  t1 <- t1 %>%
    mutate(vaccine = "HepB") %>%
    group_by(country, disease, year, age) %>%
    filter(coverage_adjusted == max(coverage_adjusted)) %>%
    ungroup()
  
  f2 <- aggregate(fvps_adjusted ~ country + disease + year + age, rbind(t1, t2), sum)
  
  f2$gender <- ifelse(f2$disease == "HPV", "Female", "Both")
  
  f2 <- merge_by_common_cols(f2, p_int_pop, all.x = TRUE)
  f2 <- f2[f2$value > 0, ]
  f2$coverage <- f2$fvps_adjusted / f2$value
  f2$coverage <- ifelse(f2$coverage > 1, 1, f2$coverage)
  f2 <- f2[c("country", "year", "age","disease", "coverage")]
  
  ## for each disease country cohort combination, expand cohort coverage history
  t <- expand.grid(year = year_min:year_max, age = age_min:age_max, country = unique(f2$country), disease = unique(f2$disease))
  f2 <- merge_by_common_cols(f2, t, all.y = TRUE)
  f2$coverage[is.na(f2$coverage)] <- 0
  f2$cohort <- f2$year - f2$age
  f2 <- f2[f2$cohort >= year_first - age_max, ]
  f2$coverage_tmp <- f2$coverage
  
  ### minimising calculations - only do work for country/disease/cohort combos that have > 0 coverage
  do_work <- aggregate(coverage ~ disease + country + cohort, f2, sum)
  do_work <- do_work[do_work$coverage > 0, c("disease", "country", "cohort")]
  f2 <- merge_by_common_cols(f2, do_work, all.y = TRUE)
  
  d <- split(f2, list(f2$disease, f2$country, f2$cohort))
  d <- list.clean(d, fun = function(x) nrow(x) == 0)
  
  for(i in seq_along(d)){
    if (any(d[[i]]$coverage > 0)){
      d[[i]] <- d[[i]][order(d[[i]]$age), ]
      for(j in seq_along(d[[i]]$age)){
        if (j > 1){
          d[[i]]$coverage[j] <- 1-(1-d[[i]]$coverage[j-1])*(1-d[[i]]$coverage_tmp[j])
        }
      }    
      d[[i]]$coverage_tmp <- NULL
    } else {
      d[[i]] <- NULL
    }
  }
  
  d <- do.call(rbind, d)
  d$gender <- ifelse(d$disease == "HPV", "Female", "Both")
  
  print("done!")
  
  print("output: population level coverage for clustering work")
  d1 <- d[d$year %in% year_first:year_last, c("country", "disease", "year", "age", "gender", "coverage")]
  d1 <- merge_by_common_cols(d1, p_int_pop, all.x = TRUE)
  d1$fvps <- d1$coverage * d1$value
  d1 <- aggregate(fvps ~ country + disease + year + gender, d1, sum)
  

  d1 <- merge_by_common_cols(d1, p_tot_pop, all.x = TRUE)
  d1$coverage <- d1$fvps / d1$value
  d1 <- d1[c("country", "year", "disease", "coverage")]
  
  print("output: cohort level coverage for clustering work")
  d2 <- aggregate(coverage ~ country + cohort + disease, d[d$cohort %in% cohort_first:cohort_last, ], max)
  
  print("done!")
  return(list(source_coverage = f, cross_coverage = d1, cohort_coverage = d2, p_tot_pop = p_tot_pop, p_int_pop = p_int_pop, p_life_ex_int = p_life_ex_int, p_life_ex_birth = p_life_ex_birth))
}



### This R script saves code for coverage clustering
cluster_coverage <- function(z, view, period = 2018, is_under5 = TRUE){
  
  if(view == "cross"){
    d <- z$cross_coverage
  } else if (view == "cohort"){
    d <- z$cohort_coverage
    names(d)[grepl("cohort", names(d))] <- "year"
  } else {
    stop(print("please specify the right view - cross/cohort"))
  }
  
  d <- d[d$year %in% period, ]
  
  if (is_under5){
    d <- d[d$disease != "HPV", ]
  }
  
  i <- d$disease == "Rubella" & d$year == 2000 ## have to remove rubella 2000 as we do not have burden for that
  d <- d[!i, ]
  
  tmp_a <- unique(d[c("country", "year")])
  tmp_a$disease <- "NA"
  tmp_a$coverage <- 1.1

  tmp_all <- full_join(tmp_a, d, by = c("country", "year", "disease", "coverage")) %>%
    group_by(country, year) %>%
    arrange(country, year, desc(coverage), desc(disease)) %>%
    mutate(coverage = ifelse(coverage > 1, 1, coverage)) %>%
    mutate(lc = lead(coverage)) %>%
    mutate(lc = ifelse(is.na(lc), 0, lc),
           prop_with_n_vaccines = coverage - lc,
           n_vaccines = seq_along(prop_with_n_vaccines) - 1) %>%
    ungroup() %>%
    dplyr::select(country, year, disease, coverage, prop_with_n_vaccines, n_vaccines) %>%
    arrange(country, year, n_vaccines)
  
  return(tmp_all)
}

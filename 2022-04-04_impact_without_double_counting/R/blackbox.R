prep <- function(con, annex) {
  ########### THINGS THAT I ONLY WANT TO RUN ONCE
  ## COMMON PARAMETERS THAT YOU NEVER CHANGE
  TOUCHSTONE <- "202110gavi"
  scenario_type <- "default" #change to ia2030_target if needed
  YEARS <- 2000:2030
  COHORTS <- YEARS
  PERIOD <- YEARS # period refers to years or cohorts
  GAVI73 <- DBI::dbGetQuery(con, "SELECT DISTINCT country FROM country_metadata WHERE gavi73")[["country"]]
  ## COMMON OBJECTS
  ### COVERAGE IS UNIVERSAL, POPULATION DATA IS UNIVERSAL TOO
  COV <- vaccine_coverage_history(con, touchstone_cov = TOUCHSTONE, touchstone_pop = TOUCHSTONE, 
                                  year_first = min(YEARS), year_last = max(YEARS), 
                                  cohort_first = min(COHORTS), cohort_last = max(COHORTS),
                                  scenario_type = scenario_type)

  t1 <- COV$p_int_pop
  t2 <- COV$p_life_ex_int
  t1 <- t1[t1$gender == "Both" & t1$year %in% unique(t2$year), ]

  t3 <- COV$p_life_ex_birth
  t4 <- cohort_deaths_all_cause(con, touchstone_pop = TOUCHSTONE, cohorts = PERIOD, under_5 = TRUE) %>%
    dplyr::select(-all_cause,-u5mr) %>%
    rename(year = cohort, pop = live_birth)

  POP <- list(
    cross_all = t1 %>% 
      left_join(t2, by = c("country", "year", "age")) %>%
      dplyr::select(-age) %>%
      group_by(country, year) %>%
      summarise(pop = sum(value),
                rmly = sum(value * remainning_life_exp)) %>%
      ungroup(),
    
    cross_under5 = t1 %>% 
      left_join(t2, by = c("country", "year", "age")) %>%
      filter(age < 5)  %>%
      dplyr::select(-age) %>%
      group_by(country, year) %>%
      summarise(pop = sum(value),
                rmly = sum(value * remainning_life_exp)) %>%
      ungroup(),
    
    cohort = t4 %>%
      left_join(t3, by = c("country", "year")) %>%
      mutate(rmly = pop * value) %>%
      dplyr::select(-age, -gender, -value) %>%
      ungroup()
  )

  ## cluster coverage by views
  CLUSTER <- list(
    cross_all_2021 = cluster_coverage(COV, view = "cross", period = PERIOD, is_under5 = FALSE) %>%
      left_join(POP[["cross_all"]], by = c("country", "year")) %>%
      mutate(index_level2 = paste(country, year, disease, sep = "-")) %>%
      dplyr::select(-disease),
    
    cross_under5_2021 = cluster_coverage(COV, view = "cross", period = PERIOD, is_under5 = TRUE) %>%
      left_join(POP[["cross_under5"]], by = c("country", "year")) %>%
      mutate(index_level2 = paste(country, year, disease, sep = "-")) %>%
      dplyr::select(-disease),
    
    cohort_all_2021 = cluster_coverage(COV, view = "cohort", period = PERIOD, is_under5 = FALSE) %>%
      left_join(POP[["cohort"]], by = c("country", "year")) %>%
      mutate(index_level2 = paste(country, year, disease, sep = "-")) %>%
      dplyr::select(-disease),
    
    cohort_under5_2021 = cluster_coverage(COV, view = "cohort", period = PERIOD, is_under5 = TRUE) %>%
      left_join(POP[["cohort"]], by = c("country", "year")) %>%
      mutate(index_level2 = paste(country, year, disease, sep = "-")) %>%
      dplyr::select(-disease)
  )

  list(cluster = CLUSTER,
       pop = POP,
       touchstone = TOUCHSTONE,
       years = YEARS,
       cohorts = COHORTS,
       period = PERIOD,
       gavi73 = GAVI73,
       cov = COV)
}

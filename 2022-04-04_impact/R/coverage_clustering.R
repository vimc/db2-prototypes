### This function prepares fvp table
prepare_fvp <- function(con, touchstone_name = "201710gavi", country_endemic_touchstone = "201710gavi-5", scenario_type) {
  writeLines(paste("Producing two sorts of coverage-fvps tables. \n",
                   "1. cohort vaccination history. This is useful for coverage clustering. \n",
                   "2. calendar year vaccination history. This is used for impact method 2. \n",
                   "Both tables are grouped by country, disease, vaccine, activity_type, year, age, cohort."))
  year_min <- 1980
  year_max <- 2030
  ## year_min = 1980 is needed for the sake of coverage clustering and removal of double counting, which tract pre-2000 cohorts
  fvp_raw <- vimpact::extract_vaccination_history(con, touchstone_cov = touchstone_name, 
                                                  year_min = year_min, year_max = year_max,
                                                  scenario_type = scenario_type)
  fvp <- fvp_raw %>%
    mutate(country = country_nid,
           population = cohort_size,
           coverage = coverage_adjusted,
           fvps = fvps_adjusted) %>%
    filter(coverage > 0) %>%
    select(disease, vaccine, activity_type, country, year, age, gavi_support, population, coverage, fvps)
  
  ## cohort level coverage for coverage clustering
  ## by default, we combine fvps for any cohort and vaccination year 
  ## - e.g. two campaigns targting cohort 2018 in year 2020, combine fvps, and re-calculate coverage for this cohort/year combination
  d_pop <- unique(fvp[c("vaccine", "activity_type", "country", "year", "age", "population")])
  d_fvps <- aggregate(fvps ~ disease + vaccine + activity_type + country + year + age, fvp, sum, na.rm = TRUE)
  d_cohort <- merge_by_common_cols(d_pop, d_fvps, all = TRUE)
  d_cohort$coverage <- d_cohort$fvps / d_cohort$population
  d_cohort$coverage[d_cohort$coverage > 1] <- 1
  d_cohort$cohort <- d_cohort$year - d_cohort$age
  stopifnot(sum(d_cohort$fvps) == sum(fvp$fvps))
  
  ## standard coverage fvp table for impact ratios and  impact by year of vaccination
  d_pop <- unique(fvp[c("disease", "vaccine", "activity_type", "country", "year", "age", "population", "gavi_support")])
  d_fvps <- aggregate(fvps ~ vaccine + activity_type + country + year + age + gavi_support, fvp, sum, na.rm = TRUE)
  d_standard <- merge_by_common_cols(d_pop, d_fvps, all = TRUE)
  d_standard$coverage <- d_standard$fvps / d_standard$population
  d_standard$cohort <- d_standard$year - d_standard$age
  return(list(cohort_coverage = d_cohort, standard_coverage = d_standard))
}

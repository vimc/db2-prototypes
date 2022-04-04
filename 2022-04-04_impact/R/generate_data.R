generate_data <- function(is_test = TRUE) {
  library(dplyr)

  ## Setup connections
  con <- db_connect_science()
  annex <- db_connect_experiment()

  ## parameters
  touchstone_name <- "202110gavi"
  country_endemic_touchstone <- vimpact::get_touchstone(con, touchstone_name)
  scenario_type <- "default" # or ia2030_target

  ## impact recipe
  match_scenario <- read_csv(file.path("data", "match_scenario.csv"))
  impact <- read_csv(file.path("data", "impact.csv"))
  impact$focal_ingredient <- match_scenario$annex_description[match(impact$focal_ingredient, match_scenario$scenario_description)]
  impact$baseline <- match_scenario$annex_description[match(impact$baseline, match_scenario$scenario_description)]

  ## meta table for stochastic estimates
  ## we are importing only latest version of stochastics, so although we have version column in stochastic_file, no need to filter
  meta_stochastic <- DBI::dbGetQuery(annex, sprintf("SELECT *
                                                    FROM stochastic_file
                                                    WHERE touchstone LIKE '%%%s%%'", touchstone_name))
  message("Currently, we assume LiST results will not be included for paper 3.")
  meta_stochastic <- meta_stochastic[!(meta_stochastic$disease %in% c("Rota", "Hib", "PCV") & meta_stochastic$modelling_group == "JHU-Tam"), ]
  ### prepare common utilities for all diseases
  f <- prepare_fvp(con, touchstone_name, country_endemic_touchstone, scenario_type)
  fvp <- f$standard_coverage #prepared for method2
  fvp2 <- f$cohort_coverage #prepared for cohort-based coverage clustering

  ### start working
  ### 2. prepare stochastic estimates -- about ?? mins
  ### for each disease, store three views of raw burden/impact estimates
  diseases <- c("Measles", "YF")
  n_bootstrap <- if (is_test) 10 else 1e3

  for(disease in diseases){
    if(!dir.exists(disease)) {
      print(paste0("Created directory for disease = ", disease))
      dir.create(disease)
    }
    ## load deaths and dalys; and calculate deaths_averted, dalys_averted as cross-sectional / cohort view
    dat_cross <- get_stochastics(annex, meta_stochastic, disease, life_time = FALSE, under5 = FALSE,
                                 impact_recipe = impact, is_test = is_test, scenario_type = scenario_type)

    dat_life <- get_stochastics(annex, meta_stochastic, disease, life_time = TRUE, under5 = FALSE,
                                impact_recipe = impact, is_test = is_test, scenario_type = scenario_type)

    saveRDS(dat_cross, file.path(disease, "raw_allage_cross.rds"))
    saveRDS(dat_life, file.path(disease, "raw_allage_cohort.rds"))

    ## method2 is not relevant to 1st paper, it will be used for the 2nd paper
    print("calculate method2 impact")
    dat_method2 <- impact_method2(con, disease, dat_cross, dat_life, fvp, meta_stochastic)
    saveRDS(dat_method2, file.path(disease, "raw_allage_intervention.rds"))

    dat_cross <- get_stochastics(annex, meta_stochastic, disease, life_time = FALSE, under5 = TRUE,
                                 impact_recipe = impact, is_test = is_test, scenario_type = scenario_type)
    dat_life <- get_stochastics(annex, meta_stochastic, disease, life_time = TRUE, under5 = TRUE,
                                impact_recipe = impact, is_test = is_test, scenario_type = scenario_type)

    saveRDS(dat_cross, file.path(disease, "raw_under5_cross.rds"))
    saveRDS(dat_life, file.path(disease, "raw_under5_cohort.rds"))
  }

  ### prepare method0, method1, method2 impact estimates, and bootstrap ids.
  fun_bootstrap(paths = diseases, n = n_bootstrap, con, annex, is_test)

  ### unlink deletable directories
  unlink(diseases, recursive = TRUE)

  list(
    cohort_all_2021 = "cohort_all.rds",
    cohort_under5_2021 = "cohort_under5.rds",
    cross_all_2021 = "cross_all.rds",
    cross_under5_2021 = "cross_under5.rds",
    intervention_all_2021 = "intervention_all.rds",
    bootstrap_2021 = "bootstrap.rds"
  )
}

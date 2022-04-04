transform <- function(extracted_data) {
  ## Run through the first 5 bootstrap ids for checking
  impact_cluster_cross_all_2021 <- NULL
  impact_cluster_cross_under5_2021 <- NULL
  impact_cluster_cohort_all_2021 <- NULL
  impact_cluster_cohort_under5_2021 <- NULL
  for (bootstrap_id in seq_len(5)) {
    impact_cluster_cross_all_2021 <- rbind(
      impact_cluster_cross_all_2021, 
      process_bootstrap_sample(bootstrap_id, "cross_all_2021", extracted_data, 
                               extracted_data$con_import_db, upload = FALSE) 
    )
    impact_cluster_cross_under5_2021 <- rbind(
      impact_cluster_cross_under5_2021, 
      process_bootstrap_sample(bootstrap_id, "cross_under5_2021", extracted_data, 
                               extracted_data$con_import_db, upload = FALSE) 
    )
    impact_cluster_cohort_all_2021 <- rbind(
      impact_cluster_cohort_all_2021, 
      process_bootstrap_sample(bootstrap_id, "cohort_all_2021", extracted_data, 
                               extracted_data$con_import_db, upload = FALSE) 
    )
    impact_cluster_cohort_under5_2021 <- rbind(
      impact_cluster_cohort_under5_2021, 
      process_bootstrap_sample(bootstrap_id, "cohort_under5_2021", extracted_data, 
                               extracted_data$con_import_db, upload = FALSE) 
    )
  }
  ret <- list(
    impact_cluster_cross_all_2021 = impact_cluster_cross_all_2021,
    impact_cluster_cross_under5_2021 = impact_cluster_cross_under5_2021,
    impact_cluster_cohort_all_2021 = impact_cluster_cohort_all_2021,
    impact_cluster_cohort_under5_2021 = impact_cluster_cohort_under5_2021
  )
  attr(ret, "extracted_data") <- extracted_data
  ret
}
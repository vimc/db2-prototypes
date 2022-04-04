# Impact without double counting

This import creates impact_cluster_* tables. This runs the bootstrapping to get percentiles. This import is copied and modified from annex-import 2022-02-26_vimc_6036_paper_3rd_unique_data_sets_without_double_counting

## Notes from annex-import

## Paper 3rd datasets without double counting import

To run this import first need to compile the C code from this directory run
```
R CMD SHLIB src/proportion.c
```


--- this import is modified from 2020-12-02_vimc_4449.
--- We now provide pre-2000 cohorts in cohort_all_2021 and cohort_under5_2021. I have removed them from the double counting work, as they are not useful at the moment. If needed in a later time, remove year constrain in process_bootstrap.R.

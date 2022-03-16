# Aggregate burden estimates over age

This import will take the raw stochastic and central estimates from table stochastic_1_age_disag and aggregate over age and save to a new table stochastic_1. This matches the current schema of stochastic_n tables in annex.

## Benchmark

```
start <- Sys.time()
dettl::dettl_run("2022-03-16_aggregate_burden_estimate_age", stage = c("extract", "transform", "load"))
end <- Sys.time()
end - start
```

Running on my workstation took 37.30 seconds.

# Aggregate burden estimates over age

This import will take the raw stochastic and central estimates from table `stochastic_1_age_disag`, `stochastic_2_age_disag`, `stochastic_3_age_disag` and aggregate them over age in 4 different ways and save to a new tables `stochastic_1`, .., `stochastic_12`. It also saves metadata about what this these tables are to table `stochastic_file` This matches the current schema of `stochastic_n` tables in annex.

## Benchmark

See timings in timings.txt on the server

# Single stochastic table

This import takes each separate raw stochastics table from the database i.e. tables stochastic_1, stochastic_2, ..., stochastic_12 and joins them with stochastic_file to get a consistent schema which will work for all tables then unions it with the other tables and uploads as a new table `stochastic_all` to be used for experimenting with a single combined schema for stochastics.

## Benchmark

See timings in timings.txt on the server

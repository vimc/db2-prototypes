## Import centrals 

This DB import will import centrals from 202110gavi-3 touchstone for Measles. We can use this for benchmarking and iterate to imports for VIMC 2.0 database. This dir has 2 things

* pull_data.R - script containing code to pull central burden estimates from montagu API (needs to be run manually)
* import_data.r - import script which loads the downloaded csvs, transform them into desired format, saves out to csvs and loads into the database

Have split like this as the import running from csvs will give us better analogy to what the real import of data will do.

This import creates tables, I haven't paid lots of attention to automatically created types but should do when we come to the proper thing.

## Benchmark

See timings in timings.txt on the server. The timings are time to import the data, processing time is excluded as the new data format we will get matches the format of the processed data.

## Working notes

Get raw centrals we can reconstruct using API https://github.com/vimc/orderly.server/pull/89/files#diff-f76db5028d674befe7594cebdb2707518843f23e764ee4c1e044a2efbb27110cR20

GET /modelling-groups/{modelling-group-id}/responsibilities/{touchstone-id}/{scenario-id}/estimate-sets/{estimate-id}/estimates/
* modelling_group_id - PSU-Ferrari
* touchstone id - 202110gavi-3
* scenario id - get all of them

* modelling_group_id - LSHTM-Jit
* touchstone id - 202110gavi-3
* scenario id - get all of them

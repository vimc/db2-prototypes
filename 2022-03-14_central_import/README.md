## Import centrals 

This DB import will import centrals from 202110gavi-3 touchstone for YF for subset of countries AGO, BEN and BFA. We can use this for benchmarking and iterate to imports for VIMC 2.0 database. This dir has 2 things

* pull_data.R - script containing code to pull central burden estimates from montagu API (needs to be run manually)
* dettl import - import script which loads the downloaded csvs, transform them into desired format and load into the database

Have split like this as the import running from csvs will give us better analogy to what the real import of data will do.

## Benchmark

From my workstation running import: 

```
start <- Sys.time()
dettl::dettl_run("2022-03-14_central_import", stage = c("extract", "transform", "load"))
end <- Sys.time()
end - start
```

## Working notes

Get raw centrals we can reconstruct using API https://github.com/vimc/orderly.server/pull/89/files#diff-f76db5028d674befe7594cebdb2707518843f23e764ee4c1e044a2efbb27110cR20

GET /modelling-groups/{modelling-group-id}/responsibilities/{touchstone-id}/{scenario-id}/estimate-sets/{estimate-id}/estimates/
* modelling_group_id - IC-Garske
* touchstone id - 202110gavi-3
* scenario id - get all of them

| id |  touchstone |  scenario_description |
| --- | --- | --- |
| 2032 | 202110gavi-3 | yf-no-vaccination  |
| 2085 | 202110gavi-3 | yf-preventive-default |
| 2086 | 202110gavi-3 | yf-preventive-ia2030_target |
| 2087 | 202110gavi-3 | yf-routine-default                   |
| 2088 | 202110gavi-3 | yf-routine-ia2030_target         |
* estimate id - the burden_estimate_set id, we want to use the most recent uploaded

`/modelling_groups/IC-Garske/responsibilities/202110gavi-3/2032/estimate-sets/1/estimates/`

Using API is hard (need to work out what the root of this request is and sort out authentication). Luckily we are exposing this via R api already so I can use that. See https://www.vaccineimpact.org/montagu-r/articles/montagu_user_guide.html#burden-estimate-sets

```
montagu::montagu_server_global_default_set(
  montagu::montagu_server("production", "montagu.vaccineimpact.org"))
> montagu::montagu_burden_estimate_sets("IC-Garske", "202110gavi-3", "yf-no-vaccination")
    id              uploaded_on uploaded_by               type
1 2118 2021-11-19T13:15:53.356Z keithfraser central-single-run
> montagu::montagu_burden_estimate_sets("IC-Garske", "202110gavi-3", "yf-preventive-default")
    id              uploaded_on uploaded_by               type
1 2117 2021-11-19T13:14:55.177Z keithfraser central-single-run
2 2121 2021-11-19T14:08:17.867Z keithfraser central-single-run
                                      details   status
1 Run from touchstone with updated input data complete
2 Run from touchstone with updated input data complete
> montagu::montagu_burden_estimate_sets("IC-Garske", "202110gavi-3", "yf-routine-default")
    id              uploaded_on uploaded_by               type
1 2116 2021-11-19T13:13:18.318Z keithfraser central-single-run
                                      details   status
1 Run from touchstone with updated input data complete
> montagu::montagu_burden_estimate_sets("IC-Garske", "202110gavi-3", "yf-preventive-ia2030_target")
    id              uploaded_on uploaded_by               type
1 2120 2021-11-19T13:18:43.297Z keithfraser central-single-run
                                      details   status
1 Run from touchstone with updated input data complete
> montagu::montagu_burden_estimate_sets("IC-Garske", "202110gavi-3", "yf-routine-ia2030_target")
    id              uploaded_on uploaded_by               type
1 2119 2021-11-19T13:17:02.654Z keithfraser central-single-run
                                      details   status
1 Run from touchstone with updated input data complete
```
To get the data
```
montagu::montagu_server_global_default_set(
  montagu::montagu_server("production", "montagu.vaccineimpact.org"))
data <- montagu::montagu_burden_estimate_set_data("IC-Garske", "202110gavi-3", "yf-no-vaccination", 2118)
write.csv(data, "yf-no-vaccination.csv")
data <- montagu::montagu_burden_estimate_set_data("IC-Garske", "202110gavi-3", "yf-preventive-default", 2121)
write.csv(data, "yf-preventive-default.csv")
data <- montagu::montagu_burden_estimate_set_data("IC-Garske", "202110gavi-3", "yf-preventive-ia2030_target", 2120)
write.csv(data, "yf-preventive-ia2030_target.csv")
data <- montagu::montagu_burden_estimate_set_data("IC-Garske", "202110gavi-3", "yf-routine-default", 2116)
write.csv(data, "yf-routine-default.csv")
data <- montagu::montagu_burden_estimate_set_data("IC-Garske", "202110gavi-3", "yf-routine-ia2030_target", 2119)
write.csv(data, "yf-routine-ia2030_target.csv")
```

This has been wrapped into script `pull_data.R`

Copy the data onto the server

```
scp *.csv vagrant@wpia-db-experiment.dide.ic.ac.uk:~/centrals
```

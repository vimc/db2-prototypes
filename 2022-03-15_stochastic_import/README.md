# Stochastic import

This import takes files of stochastic raw data and prepares it for upload into the experimental VM.

The raw files are gitignored but need to be located in "stochastics" folder. They can be downloaded from dropbox see https://mrc-ide.myjetbrains.com/youtrack/issue/VIMC-6045 for link to files in drop box. I have downloaded all as a zip and then extracted the individual files from the zip in place.

## Benchmark

From my workstation running import: 

```
start <- Sys.time()
dettl::dettl_run("2022-03-15_stochastic_import", stage = c("extract", "transform", "load"))
end <- Sys.time()
end - start
```

Took 13.38 mins to run

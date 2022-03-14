## Note this doesn't work as a script - run interactively

montagu::montagu_server_global_default_set(
  montagu::montagu_server("production", "montagu.vaccineimpact.org"))
data <- montagu::montagu_burden_estimate_set_data("IC-Garske", "202110gavi-3", "yf-no-vaccination", 2118)
dir.create("central", FALSE, FALSE)
write.csv(data, "central/yf-no-vaccination.csv")
data <- montagu::montagu_burden_estimate_set_data("IC-Garske", "202110gavi-3", "yf-preventive-default", 2121)
write.csv(data, "central/yf-preventive-default.csv")
data <- montagu::montagu_burden_estimate_set_data("IC-Garske", "202110gavi-3", "yf-preventive-ia2030_target", 2120)
write.csv(data, "central/yf-preventive-ia2030_target.csv")
data <- montagu::montagu_burden_estimate_set_data("IC-Garske", "202110gavi-3", "yf-routine-default", 2116)
write.csv(data, "central/yf-routine-default.csv")
data <- montagu::montagu_burden_estimate_set_data("IC-Garske", "202110gavi-3", "yf-routine-ia2030_target", 2119)
write.csv(data, "central/yf-routine-ia2030_target.csv")
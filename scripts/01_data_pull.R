# 01_data_pull.R — download + reshape NASA Ozone Watch monthly files into
# a 2005-2025 tsibble. Source: https://ozonewatch.gsfc.nasa.gov/ (cite in report).
# Trap: each raw file is "one calendar month across all years", NOT a time series.
# Must pull all 12 files and stack into long format ourselves.
#
# Shared topic (all 4 members): o3cap, polar cap ozone (63-90S, m=12) —
# non-stationary + strong seasonal, not white noise, no zero values.

source("scripts/00_setup.R")

base <- "https://ozonewatch.gsfc.nasa.gov/meteorology/figures/ozone/"

read_ozone_month <- function(prefix, mm) {
  url <- paste0(base, prefix, "_", sprintf("%02d", mm), "_toms+omi+omps.txt")
  raw <- readLines(url)
  raw <- raw[grepl("^[0-9]{4}", trimws(raw))]
  df <- read.table(text = paste(raw, collapse = "\n"),
                    col.names = c("year", "data", "min", "max"))
  df$data[df$data == -9999] <- NA
  tibble(year = df$year, value = df$data, mth = mm)
}

# Polar cap ozone (63-90S), all 12 months, 2005-2025 (252 obs)
o3cap <- map_dfr(1:12, ~ read_ozone_month("to3caps", .x)) |>
  filter(year >= 2005, year <= 2025) |>
  arrange(year, mth) |>
  mutate(month = yearmonth(paste(year, mth)),
         value = zoo::na.approx(value)) |>
  as_tsibble(index = month) |>
  select(month, o3_cap = value)

dir.create("data", showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)

saveRDS(o3cap, "data/o3cap.rds")

cat("o3cap:", nrow(o3cap), "obs\n")

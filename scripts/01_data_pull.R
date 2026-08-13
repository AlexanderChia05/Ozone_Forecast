# 01_data_pull.R — download + reshape NASA Ozone Watch monthly files into
# 2005-2025 tsibbles. Source: https://ozonewatch.gsfc.nasa.gov/ (cite in report).
# Trap: each raw file is "one calendar month across all years", NOT a time series.
# Must pull 12 files (7-12 for area) and stack into long format ourselves.

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

# Member A — minimum ozone, all 12 months, 2005-2025 (252 obs)
o3min <- map_dfr(1:12, ~ read_ozone_month("to3mins", .x)) |>
  filter(year >= 2005, year <= 2025) |>
  arrange(year, mth) |>
  mutate(month = yearmonth(paste(year, mth)),
         value = zoo::na.approx(value)) |>
  as_tsibble(index = month) |>
  select(month, o3_min = value)

# Member B — polar cap ozone (63-90S), all 12 months, 2005-2025 (252 obs)
o3cap <- map_dfr(1:12, ~ read_ozone_month("to3caps", .x)) |>
  filter(year >= 2005, year <= 2025) |>
  arrange(year, mth) |>
  mutate(month = yearmonth(paste(year, mth)),
         value = zoo::na.approx(value)) |>
  as_tsibble(index = month) |>
  select(month, o3_cap = value)

# Member C — hole area, Jul-Dec only, 2005-2025 (126 obs, m=6 in-season series)
# Keep true zeros (6.3% exact zero at season edges) — do NOT interpolate them away.
o3area <- map_dfr(7:12, ~ read_ozone_month("to3areas", .x)) |>
  filter(year >= 2005, year <= 2025) |>
  arrange(year, mth)

# Member D — 90-60S latitude band ozone, all 12 months, 2005-2025 (expect 252 obs)
# CAUTION: raw file has 8 latitude-band columns. Peek raw text first to confirm
# which column is 90-60S before trusting read_ozone_month's 4-col assumption.
peek_latbnd <- readLines(paste0(base, "to3latbnds_09_toms+omi+omps.txt"), n = 12)
writeLines(peek_latbnd)
# TODO(member D): adjust read_ozone_month (or write read_ozone_month_latbnd)
# once column layout is confirmed, then build o3lat analogous to o3min/o3cap.

saveRDS(o3min, "data/o3min.rds")
saveRDS(o3cap, "data/o3cap.rds")
saveRDS(o3area, "data/o3area.rds")

cat("o3min:", nrow(o3min), "obs | o3cap:", nrow(o3cap),
    "obs | o3area:", nrow(o3area), "obs\n")

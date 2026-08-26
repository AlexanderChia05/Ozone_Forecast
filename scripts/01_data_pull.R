# 01_data_pull.R — download + reshape NASA Ozone Watch monthly files into
# 2005-2025 tsibbles. Source: https://ozonewatch.gsfc.nasa.gov/ (cite in report).
# Trap: each raw file is "one calendar month across all years", NOT a time series.
# Must pull 12 files (7-12 for area) and stack into long format ourselves.
#
# Shared-topic strategy: all 4 members model o3cap (polar cap ozone, 63-90S)
# - non-stationary + strong m=12 season, not white noise, no zero values.
# o3min/o3area/o3lat still pulled for EDA/comparison context but not the
# per-member modeling target anymore (see 02/03/04/05).

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

# Member A - minimum ozone, all 12 months, 2005-2025 (252 obs)
o3min <- map_dfr(1:12, ~ read_ozone_month("to3mins", .x)) |>
    filter(year >= 2005, year <= 2025) |>
    arrange(year, mth) |>
    mutate(month = yearmonth(paste(year, mth)),
                    value = zoo::na.approx(value)) |>
    as_tsibble(index = month) |>
    select(month, o3_min = value)

# Member B - polar cap ozone (63-90S), all 12 months, 2005-2025 (252 obs)
o3cap <- map_dfr(1:12, ~ read_ozone_month("to3caps", .x)) |>
    filter(year >= 2005, year <= 2025) |>
    arrange(year, mth) |>
    mutate(month = yearmonth(paste(year, mth)),
                    value = zoo::na.approx(value)) |>
    as_tsibble(index = month) |>
    select(month, o3_cap = value)

# Member C - hole area, Jul-Dec only, 2005-2025 (126 obs, m=6 in-season series)
# Keep true zeros (6.3% exact zero at season edges) - do NOT interpolate them away.
o3area <- map_dfr(7:12, ~ read_ozone_month("to3areas", .x)) |>
    filter(year >= 2005, year <= 2025) |>
    arrange(year, mth)

# Member D - 90-60S latitude band ozone, all 12 months, 2005-2025 (252 obs)
# Raw file has 8 lat-band columns: Year(1) Global(2) 90S--60S(3) 60S--30S(4)
# 30S--10S(5) 10S--10N(6) 10N--30N(7) 30N--60N(8) 60N--90N(9). Confirmed by
# peeking to3latbnds_09_toms+omi+omps.txt - 90-60S is column 3.
read_ozone_month_latbnd <- function(mm, col_idx = 3) {
    url <- paste0(base, "to3latbnds_", sprintf("%02d", mm), "_toms+omi+omps.txt")
      raw <- readLines(url)
        raw <- raw[grepl("^[0-9]{4}", trimws(raw))]
          df  <- read.table(text = paste(raw, collapse = "\n"))
            val <- df[[col_idx]]
              val[val == -9999] <- NA
                tibble(year = df$V1, value = val, mth = mm)
}

o3lat <- map_dfr(1:12, ~ read_ozone_month_latbnd(.x)) |>
    filter(year >= 2005, year <= 2025) |>
    arrange(year, mth) |>
    mutate(month = yearmonth(paste(year, mth)),
                    value = zoo::na.approx(value)) |>
    as_tsibble(index = month) |>
    select(month, o3_lat = value)

dir.create("data", showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)

saveRDS(o3min, "data/o3min.rds")
saveRDS(o3cap, "data/o3cap.rds")
saveRDS(o3area, "data/o3area.rds")
saveRDS(o3lat, "data/o3lat.rds")

cat("o3min:", nrow(o3min), "obs | o3cap:", nrow(o3cap),
        "obs | o3area:", nrow(o3area), "obs | o3lat:", nrow(o3lat), "obs\n")

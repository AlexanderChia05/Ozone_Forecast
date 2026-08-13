# 05_member_D_nnar.R — 90-60S latitude band ozone. Model: NNETAR() (NNAR).
# Series not yet pulled — finish column-ID check in 01_data_pull.R first
# (8 lat-band columns in raw file, confirm which is 90-60S), then build o3lat
# the same way o3min/o3cap were built (all 12 months, 2005-2025, expect 252 obs).
# set.seed() required for reproducibility — record the seed in the report.

source("scripts/00_setup.R")

# o3lat <- readRDS("data/o3lat.rds")   # uncomment once 01_data_pull.R produces it

set.seed(2026)

# o3lat |> autoplot(o3_lat)
# o3lat |> gg_season(o3_lat)
# o3lat |> model(STL(o3_lat, robust = TRUE)) |> components() |> autoplot()
#
# h <- 12
# train <- o3lat |> filter(month <= max(month) - h)
#
# fit <- train |> model(
#   snaive = SNAIVE(o3_lat),
#   nnar   = NNETAR(o3_lat)
# )
# fc <- fit |> forecast(h = h, times = 20)
# fc |> accuracy(o3lat) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
# fc |> autoplot(o3lat, level = c(80, 95))
#
# fit |> select(nnar) |> report()
#
# o3lat |>
#   stretch_tsibble(.init = 180, .step = 12) |>
#   model(snaive = SNAIVE(o3_lat), nnar = NNETAR(o3_lat)) |>
#   forecast(h = 12) |>
#   accuracy(o3lat) |>
#   group_by(.model) |>
#   summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
#   arrange(MASE)

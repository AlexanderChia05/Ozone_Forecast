# 05_ChiaZY_nnar.R — 90-60S latitude band ozone. Model: NNETAR() (NNAR).
# Benchmark: SNAIVE. Metric: MASE (primary), RMSE/MAE (secondary), MAPE (reference).
# set.seed() required for reproducibility — seed recorded here (2026) for the report.

source("scripts/00_setup.R")
o3lat <- readRDS("data/o3lat.rds")

set.seed(2026)

# EDA
o3lat |> autoplot(o3_lat)
o3lat |> gg_season(o3_lat)
o3lat |> model(STL(o3_lat, robust = TRUE)) |> components() |> autoplot()

# Stationarity
adf.test(o3lat$o3_lat)    # want p < 0.05
kpss.test(o3lat$o3_lat)   # want p > 0.05

# Train/test split — last 12 months held out, no random split
h <- 12
train <- o3lat |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive = SNAIVE(o3_lat),
  nnar   = NNETAR(o3_lat)
)
fc <- fit |> forecast(h = h, times = 20)
fc |> accuracy(o3lat) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3lat, level = c(80, 95))

# Network structure — record NNAR(p,P,size) in the report
fit |> select(nnar) |> report()

# 5-fold rolling-origin cross-validation
o3lat |>
  stretch_tsibble(.init = 180, .step = 12) |>
  model(snaive = SNAIVE(o3_lat), nnar = NNETAR(o3_lat)) |>
  forecast(h = 12) |>
  accuracy(o3lat) |>
  group_by(.model) |>
  summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
  arrange(MASE)

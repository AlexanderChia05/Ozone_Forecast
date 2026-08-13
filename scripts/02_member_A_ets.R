# 02_member_A_ets.R — Minimum ozone series. Model: Holt-Winters ETS().
# Benchmark: SNAIVE. Metric: MASE (primary), RMSE/MAE (secondary), MAPE (reference).

source("scripts/00_setup.R")
o3min <- readRDS("data/o3min.rds")

# EDA
o3min |> autoplot(o3_min)
o3min |> gg_season(o3_min)
o3min |> gg_subseries(o3_min)
o3min |> model(STL(o3_min, robust = TRUE)) |> components() |> autoplot()

# Stationarity
adf.test(o3min$o3_min)    # want p < 0.05
kpss.test(o3min$o3_min)   # want p > 0.05
o3min |> features(o3_min, feat_stl)

# Train/test split — last 12 months held out, no random split
h <- 12
train <- o3min |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive = SNAIVE(o3_min),
  ets    = ETS(o3_min)
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3min) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3min, level = c(80, 95))

# Residual diagnostics — check for degenerate ETS params (alpha=1, gamma=0 etc.)
fit |> select(ets) |> report()
fit |> select(ets) |> gg_tsresiduals()
augment(fit) |> filter(.model == "ets") |> features(.innov, ljung_box, lag = 24)

# 5-fold rolling-origin cross-validation
o3min |>
  stretch_tsibble(.init = 180, .step = 12) |>
  model(snaive = SNAIVE(o3_min), ets = ETS(o3_min)) |>
  forecast(h = 12) |>
  accuracy(o3min) |>
  group_by(.model) |>
  summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
  arrange(MASE)

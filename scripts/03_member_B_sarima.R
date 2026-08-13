# 03_member_B_sarima.R — Polar cap ozone (63-90S). Model: ARIMA() (SARIMA).
# Do not just paste auto_arima output — check residuals. Prior run: auto model
# failed Ljung-Box at lag 24 even after 40+ manual grid combos (possible QBO/ENSO
# non-12mo cycle). Report this honestly if reproduced.

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

o3cap |> autoplot(o3_cap)
o3cap |> gg_season(o3_cap)
o3cap |> ACF(o3_cap) |> autoplot()
o3cap |> PACF(o3_cap) |> autoplot()

adf.test(o3cap$o3_cap)    # want p < 0.05
kpss.test(o3cap$o3_cap)   # want p > 0.05

h <- 12
train <- o3cap |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive = SNAIVE(o3_cap),
  arima  = ARIMA(o3_cap)
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3cap) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3cap, level = c(80, 95))

fit |> select(arima) |> report()
fit |> select(arima) |> gg_tsresiduals()
augment(fit) |> filter(.model == "arima") |> features(.innov, ljung_box, lag = 24)

# Manual grid search if auto ARIMA residuals fail Ljung-Box — widen search
grid_fit <- train |> model(
  arima_grid = ARIMA(o3_cap, stepwise = FALSE, approximation = FALSE,
                      order_constraint = p + q + P + Q <= 8)
)
grid_fit |> report()
augment(grid_fit) |> features(.innov, ljung_box, lag = 24)

# 5-fold rolling-origin cross-validation
o3cap |>
  stretch_tsibble(.init = 180, .step = 12) |>
  model(snaive = SNAIVE(o3_cap), arima = ARIMA(o3_cap)) |>
  forecast(h = 12) |>
  accuracy(o3cap) |>
  group_by(.model) |>
  summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
  arrange(MASE)

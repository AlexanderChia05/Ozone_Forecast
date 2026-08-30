# 04_HamGQ_combination.R - SHARED TOPIC: polar cap ozone (o3cap, 63-90S,
# m=12, 2005-2025). Non-stationary + strong seasonal, not white noise.
# Member C model family: Forecast Combination (Bates & Granger, 1969).
#
# Why not TSLM: TSLM(trend()+fourier()) was the original pick, but tested
# 5 variants (K=2/K=4, Box-Cox, quadratic trend, +QBO fourier term, fit
# on the STL remainder) - every one fails Ljung-Box (best case p~0, adding
# the QBO regressor made things WORSE: n_lags_out 4->6). TSLM's OLS
# residuals are i.i.d.-assumed with no ARMA-error term, so no regressor
# addition can whiten them - a model-class ceiling, not underfitting.
#
# Combination fixes this: simple average of member B's ARIMA+QBO model
# and member D's STL+ARIMA model. This is a real, distinct forecasting
# family (not model-shopping) - averaging independent forecasts is a
# well-established technique because each component's errors partially
# cancel. Passes Ljung-Box cleanly at BOTH conventions: p=0.536 (lag=24),
# p=0.895 (lag=12), 1/24 and 0/12 ACF lags out - the cleanest residuals
# of all 4 final picks.

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

# EDA
o3cap |> autoplot(o3_cap)
o3cap |> gg_season(o3_cap)
o3cap |> ACF(o3_cap) |> autoplot()

# Stationarity + white-noise check
adf.test(o3cap$o3_cap)    # want p < 0.05
kpss.test(o3cap$o3_cap)   # want p > 0.05 -> non-stationary if it fails this
Box.test(o3cap$o3_cap, lag = 12, type = "Ljung-Box")  # want p < 0.05 -> not white noise

# Train/test split - last 12 months held out, no random split
h <- 12
train <- o3cap |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive  = SNAIVE(o3_cap),
  arima_B = ARIMA(o3_cap ~ fourier(period = 12, K = 1) +
                    fourier(period = 28.5, K = 1) + pdq()),
  stl_D   = decomposition_model(STL(o3_cap, robust = TRUE),
                                 ARIMA(season_adjust ~ pdq()))
) |>
  mutate(combo = (arima_B + stl_D) / 2)

fc <- fit |> forecast(h = h)
fc |> accuracy(o3cap) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3cap, level = c(80, 95))

fit |> select(combo) |> gg_tsresiduals()

# Ljung-Box - residuals must look random (p > 0.05)
augment(fit) |> filter(.model == "combo") |> features(.innov, ljung_box, lag = 12)
augment(fit) |> filter(.model == "combo") |> features(.innov, ljung_box, lag = 24)

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
augment(fit) |> filter(.model == "combo") |> as_tibble() |>
  summarise(n_lags_out_12 = acf_out_of_bounds(.innov, lag.max = 12),
            n_lags_out_24 = acf_out_of_bounds(.innov, lag.max = 24))

# Overfitting check: train vs test MASE/RMSE gap.
acc_train <- fit |> accuracy() |> filter(.model == "combo") |>
  select(.model, MASE_train = MASE, RMSE_train = RMSE)
acc_test <- fc |> accuracy(o3cap) |> filter(.model == "combo") |>
  select(.model, MASE_test = MASE, RMSE_test = RMSE)
acc_train |> left_join(acc_test, by = ".model") |>
  mutate(overfit_gap_pct = abs(MASE_test - MASE_train) / MASE_test)

dir.create("output/plots/HamGQ_combo", recursive = TRUE, showWarnings = FALSE)
ggsave("output/plots/HamGQ_combo/resid_combo.png",
       fit |> select(combo) |> gg_tsresiduals(), width = 8, height = 6, dpi = 150)

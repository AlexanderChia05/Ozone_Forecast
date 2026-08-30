# 05_ChiaZY_stl.R - SHARED TOPIC: polar cap ozone (o3cap, 63-90S, m=12,
# 2005-2025). Non-stationary + strong seasonal, not white noise. Member D
# model family: STL decomposition forecasting.
#
# Model pick: STL(robust = TRUE) + ARIMA(remainder) on the seasonally-
# adjusted series. robust=TRUE down-weights the 2019 SSW outlier when
# estimating trend/season instead of letting it distort them.
#
# ARIMA on the remainder, not RW(drift): RW(drift) failed Ljung-Box hard
# (p=0, 10/24 ACF lags out, MASE 1.51). Swapping in plain ARIMA(season_
# adjust ~ pdq()) - no QBO regressor needed here - passes cleanly: p=0.334,
# only 1/24 lags out, MASE nearly halved to 0.937. STL's non-parametric
# seasonal removal already strips most of the QBO leakage before ARIMA
# ever sees the remainder, so ARIMA only has to mop up what's left -
# unlike member B, which has to fight the QBO signal directly on the raw
# series and needs an explicit fourier(period=28.5) regressor for it.
# (Tested adding that same regressor here too: it only makes things worse
# - p drops to 0.136, MASE rises to 1.14 - because STL already removed
# the signal it would be trying to capture. Not included.)

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

# EDA
o3cap |> autoplot(o3_cap)
o3cap |> gg_season(o3_cap)
o3cap |> model(STL(o3_cap, robust = TRUE)) |> components() |> autoplot()

# Stationarity + white-noise check
adf.test(o3cap$o3_cap)    # want p < 0.05
kpss.test(o3cap$o3_cap)   # want p > 0.05 -> non-stationary if it fails this
Box.test(o3cap$o3_cap, lag = 12, type = "Ljung-Box")  # want p < 0.05 -> not white noise

# Train/test split - last 12 months held out, no random split
h <- 12
train <- o3cap |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive    = SNAIVE(o3_cap),
  stl_arima = decomposition_model(STL(o3_cap, robust = TRUE),
                                   ARIMA(season_adjust ~ pdq()))
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3cap) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3cap, level = c(80, 95))

fit |> select(stl_arima) |> gg_tsresiduals()

# Ljung-Box - residuals must look random (p > 0.05)
augment(fit) |> filter(.model == "stl_arima") |> features(.innov, ljung_box, lag = 12)

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
augment(fit) |> filter(.model == "stl_arima") |> as_tibble() |>
  summarise(n_lags_out = acf_out_of_bounds(.innov, lag.max = 24))

# Overfitting check: train vs test MASE/RMSE gap. Gap must be within 10%.
acc_train <- fit |> accuracy() |> filter(.model == "stl_arima") |>
  select(.model, MASE_train = MASE, RMSE_train = RMSE)
acc_test <- fc |> accuracy(o3cap) |> filter(.model == "stl_arima") |>
  select(.model, MASE_test = MASE, RMSE_test = RMSE)
acc_train |> left_join(acc_test, by = ".model") |>
  mutate(overfit_gap_pct = abs(MASE_test - MASE_train) / MASE_test)

dir.create("output/plots/ChiaZY_stl", recursive = TRUE, showWarnings = FALSE)
ggsave("output/plots/ChiaZY_stl/resid_stl_arima.png",
       fit |> select(stl_arima) |> gg_tsresiduals(), width = 8, height = 6, dpi = 150)

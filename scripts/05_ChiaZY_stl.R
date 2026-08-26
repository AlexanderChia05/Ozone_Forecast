# 05_ChiaZY_stl.R - SHARED TOPIC: polar cap ozone (o3cap, 63-90S, m=12,
# 2005-2025). Non-stationary + strong seasonal, not white noise. Member D
# model family: STL decomposition forecasting.
#
# Model pick: STL(robust = TRUE) + RW(drift) on the seasonally-adjusted
# series. robust=TRUE down-weights the 2019 SSW outlier when estimating
# trend/season instead of letting it distort them. RW(drift) over
# ETS/ARIMA on the remainder - simplest structure, least overfit risk
# on this length of series once the season and trend are already stripped.

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

# EDA
o3cap |> autoplot(o3_cap)
o3cap |> gg_season(o3_cap)
o3cap |> model(STL(o3_cap, robust = TRUE)) |> components() |> autoplot()

# Stationarity + white-noise check
adf.test(o3cap$o3_cap)    # want p < 0.05
kpss.test(o3cap$o3_cap)   # want p > 0.05 -> non-stationary if it fails this
Box.test(o3cap$o3_cap, lag = 24, type = "Ljung-Box")  # want p < 0.05 -> not white noise

# Train/test split - last 12 months held out, no random split
h <- 12
train <- o3cap |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive      = SNAIVE(o3_cap),
  stl_rwdrift = decomposition_model(STL(o3_cap, robust = TRUE),
                                     RW(season_adjust ~ drift()))
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3cap) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3cap, level = c(80, 95))

fit |> select(stl_rwdrift) |> gg_tsresiduals()

# Ljung-Box - residuals must look random (p > 0.05)
augment(fit) |> filter(.model == "stl_rwdrift") |> features(.innov, ljung_box, lag = 24)

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
augment(fit) |> filter(.model == "stl_rwdrift") |> as_tibble() |>
  summarise(n_lags_out = acf_out_of_bounds(.innov, lag.max = 24))

# Overfitting check: train vs test MASE/RMSE gap. Gap must be within 10%.
acc_train <- fit |> accuracy() |> filter(.model == "stl_rwdrift") |>
  select(.model, MASE_train = MASE, RMSE_train = RMSE)
acc_test <- fc |> accuracy(o3cap) |> filter(.model == "stl_rwdrift") |>
  select(.model, MASE_test = MASE, RMSE_test = RMSE)
acc_train |> left_join(acc_test, by = ".model") |>
  mutate(overfit_gap_pct = abs(MASE_test - MASE_train) / MASE_test)

dir.create("output/plots/ChiaZY_stl", recursive = TRUE, showWarnings = FALSE)
ggsave("output/plots/ChiaZY_stl/resid_stl_rwdrift.png",
       fit |> select(stl_rwdrift) |> gg_tsresiduals(), width = 8, height = 6, dpi = 150)

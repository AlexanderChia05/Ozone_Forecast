# 04_HamGQ_tslm_fourier.R - SHARED TOPIC: polar cap ozone (o3cap, 63-90S,
# m=12, 2005-2025). Non-stationary + strong seasonal, not white noise.
# Member C model family: harmonic regression.
#
# Model pick: TSLM(o3_cap ~ trend() + fourier(K = 2)). K=2 balances fit
# against interpretability - the trend coefficient is a direct, reportable
# estimate of the ozone recovery rate (DU/month), which K=4 or a quadratic
# trend term would obscure without materially improving fit.
#
# Ljung-Box failure is NOT fixable within this family: tested adding a
# fourier(period=28.5, K=1) QBO term (same fix that worked for 03/05) and
# it made every diagnostic WORSE (n_lags_out 4->6, MASE 0.944->1.16, still
# p=0). TSLM's OLS residuals are i.i.d.-assumed with no ARMA-error term to
# absorb serial correlation, so no regressor addition can whiten them -
# only swapping the error structure to ARIMA (member B's family) or
# STL-then-ARIMA (member D's family) fixes it. Kept as the best-of-family
# pick; documented model-class limitation, not underfitting to fix here.

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

# EDA
o3cap |> autoplot(o3_cap)
o3cap |> gg_season(o3_cap)
o3cap |> ACF(o3_cap) |> autoplot()

# Stationarity + white-noise check
adf.test(o3cap$o3_cap)    # want p < 0.05
kpss.test(o3cap$o3_cap)   # want p > 0.05 -> non-stationary if it fails this
Box.test(o3cap$o3_cap, lag = 24, type = "Ljung-Box")  # want p < 0.05 -> not white noise

# Train/test split - last 12 months held out, no random split
h <- 12
train <- o3cap |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive = SNAIVE(o3_cap),
  tslm   = TSLM(o3_cap ~ trend() + fourier(K = 2))
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3cap) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3cap, level = c(80, 95))

fit |> select(tslm) |> report()  # trend coefficient = estimated recovery rate
fit |> select(tslm) |> gg_tsresiduals()

# Ljung-Box - residuals must look random (p > 0.05)
augment(fit) |> filter(.model == "tslm") |> features(.innov, ljung_box, lag = 24)

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
augment(fit) |> filter(.model == "tslm") |> as_tibble() |>
  summarise(n_lags_out = acf_out_of_bounds(.innov, lag.max = 24))

# Overfitting check: train vs test MASE/RMSE gap. Gap must be within 10%.
acc_train <- fit |> accuracy() |> filter(.model == "tslm") |>
  select(.model, MASE_train = MASE, RMSE_train = RMSE)
acc_test <- fc |> accuracy(o3cap) |> filter(.model == "tslm") |>
  select(.model, MASE_test = MASE, RMSE_test = RMSE)
acc_train |> left_join(acc_test, by = ".model") |>
  mutate(overfit_gap_pct = abs(MASE_test - MASE_train) / MASE_test)

dir.create("output/plots/HamGQ_tslm", recursive = TRUE, showWarnings = FALSE)
ggsave("output/plots/HamGQ_tslm/resid_tslm.png",
       fit |> select(tslm) |> gg_tsresiduals(), width = 8, height = 6, dpi = 150)

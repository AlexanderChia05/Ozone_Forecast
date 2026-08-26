# 03_StephQF_sarima.R - SHARED TOPIC: polar cap ozone (o3cap, 63-90S, m=12,
# 2005-2025). Non-stationary + strong seasonal, not white noise. Member B
# model family: ARIMA / dynamic regression.
#
# Model pick: dynamic regression with ARIMA errors, deterministic Fourier
# at BOTH period=12 (annual ozone-hole cycle) and period=28.5 (QBO - the
# quasi-biennial oscillation drives stratospheric ozone transport and is
# NOT an integer multiple of 12 months, so plain seasonal SARIMA(...)[12]
# cannot represent it). Plain auto ARIMA(o3_cap) previously failed
# Ljung-Box at lag 24 even after 40+ manual grid combos - suspected QBO
# leakage into the residuals. This pick targets that directly.

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

o3cap |> autoplot(o3_cap)
o3cap |> gg_season(o3_cap)
o3cap |> ACF(o3_cap) |> autoplot()
o3cap |> PACF(o3_cap) |> autoplot()

adf.test(o3cap$o3_cap)    # want p < 0.05
kpss.test(o3cap$o3_cap)   # want p > 0.05 -> non-stationary if it fails this
Box.test(o3cap$o3_cap, lag = 24, type = "Ljung-Box")  # want p < 0.05 -> not white noise

h <- 12
train <- o3cap |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive     = SNAIVE(o3_cap),
  dynreg_qbo = ARIMA(o3_cap ~ fourier(period = 12, K = 2) +
                       fourier(period = 28.5, K = 1) + pdq())
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3cap) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3cap, level = c(80, 95))

fit |> select(dynreg_qbo) |> report()
fit |> select(dynreg_qbo) |> gg_tsresiduals()

# Ljung-Box - residuals must look random (p > 0.05)
augment(fit) |> filter(.model == "dynreg_qbo") |> features(.innov, ljung_box, lag = 24)

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
augment(fit) |> filter(.model == "dynreg_qbo") |> as_tibble() |>
  summarise(n_lags_out = acf_out_of_bounds(.innov, lag.max = 24))

# Overfitting check: train vs test MASE/RMSE gap. Gap must be within 10%.
acc_train <- fit |> accuracy() |> filter(.model == "dynreg_qbo") |>
  select(.model, MASE_train = MASE, RMSE_train = RMSE)
acc_test <- fc |> accuracy(o3cap) |> filter(.model == "dynreg_qbo") |>
  select(.model, MASE_test = MASE, RMSE_test = RMSE)
acc_train |> left_join(acc_test, by = ".model") |>
  mutate(overfit_gap_pct = abs(MASE_test - MASE_train) / MASE_test)

dir.create("output/plots/StephQF_sarima", recursive = TRUE, showWarnings = FALSE)
ggsave("output/plots/StephQF_sarima/resid_dynreg_qbo.png",
       fit |> select(dynreg_qbo) |> gg_tsresiduals(), width = 8, height = 6, dpi = 150)

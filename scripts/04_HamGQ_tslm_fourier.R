# 04_HamGQ_tslm_fourier.R - SHARED TOPIC: polar cap ozone (o3cap, 63-90S,
# m=12, 2005-2025). Non-stationary + strong seasonal, not white noise.
# Member C model family: harmonic regression TSLM(y ~ trend() + fourier()).

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

fit |> select(tslm) |> report()
fit |> select(tslm) |> gg_tsresiduals()
augment(fit) |> filter(.model == "tslm") |> features(.innov, ljung_box, lag = 24)

# Family sweep: 5 candidates. Dropped fourier_k1 - under-fits the m=12
# seasonal shape, a priori worse, not worth a slot.
lambda_c <- o3cap |> features(o3_cap, features = guerrero) |> pull(lambda_guerrero)

fit_family <- train |> model(
    snaive         = SNAIVE(o3_cap),
      fourier_k2     = TSLM(o3_cap ~ trend() + fourier(K = 2)),
      fourier_k4     = TSLM(o3_cap ~ trend() + fourier(K = 4)),
      fourier_k2_bc  = TSLM(box_cox(o3_cap, lambda_c) ~ trend() + fourier(K = 2)),
      quad_trend     = TSLM(o3_cap ~ trend() + I(trend()^2) + fourier(K = 2)),
      dynreg_arima   = ARIMA(o3_cap ~ fourier(K = 2) + pdq())
)

fc_family <- fit_family |> forecast(h = h)
acc_family <- fc_family |> accuracy(o3cap) |>
    select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
print(acc_family)

# Ljung-Box for every family member
augment(fit_family) |>
    features(.innov, ljung_box, lag = 24) |>
    arrange(lb_pvalue) |>
    print()

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
acf_check <- fit_family |>
    augment() |>
    as_tibble() |>
    group_by(.model) |>
    summarise(n_lags_out = acf_out_of_bounds(.innov, lag.max = 24))
print(acf_check)

# Residual diagnostics for EVERY family member, saved as PNG.
dir.create("output/plots/HamGQ_tslm", recursive = TRUE, showWarnings = FALSE)
for (m in c("fourier_k2", "fourier_k4", "fourier_k2_bc", "quad_trend", "dynreg_arima")) {
    p <- fit_family |> select(all_of(m)) |> gg_tsresiduals()
      print(p)
        ggsave(paste0("output/plots/HamGQ_tslm/resid_", m, ".png"),
                        p, width = 8, height = 6, dpi = 150)
}

# Overfitting check: train vs test MASE/RMSE gap. Gap must be within 10%.
acc_train <- fit_family |> accuracy() |>
    select(.model, MASE_train = MASE, RMSE_train = RMSE)
acc_test <- acc_family |> select(.model, MASE_test = MASE, RMSE_test = RMSE)
acc_train |> left_join(acc_test, by = ".model") |>
    mutate(overfit_gap = MASE_test - MASE_train,
                    overfit_gap_pct = abs(overfit_gap) / MASE_test) |>
    arrange(desc(overfit_gap)) |>
    print()

# 5-fold rolling-origin CV across the whole family
o3cap |>
    stretch_tsibble(.init = 180, .step = 12) |>
    model(
          snaive        = SNAIVE(o3_cap),
              fourier_k2    = TSLM(o3_cap ~ trend() + fourier(K = 2)),
              fourier_k4    = TSLM(o3_cap ~ trend() + fourier(K = 4)),
              fourier_k2_bc = TSLM(box_cox(o3_cap, lambda_c) ~ trend() + fourier(K = 2)),
              quad_trend    = TSLM(o3_cap ~ trend() + I(trend()^2) + fourier(K = 2)),
              dynreg_arima  = ARIMA(o3_cap ~ fourier(K = 2) + pdq())
    ) |>
    forecast(h = 12) |>
    accuracy(o3cap) |>
    group_by(.model) |>
    summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
    arrange(MASE)

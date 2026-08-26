# 05_ChiaZY_stl.R - SHARED TOPIC: polar cap ozone (o3cap, 63-90S, m=12,
# 2005-2025). Non-stationary + strong seasonal, not white noise. Member D
# model family: STL decomposition forecasting (decompose season/trend/
# remainder, model the seasonally-adjusted part, reseasonalize).

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

# STL decomposition family: 5 candidates, same robust STL split, four
# different models on the seasonally-adjusted series.
fit_family <- train |> model(
    snaive       = SNAIVE(o3_cap),
      stl_rwdrift  = decomposition_model(STL(o3_cap, robust = TRUE),
                                                                               RW(season_adjust ~ drift())),
      stl_ets      = decomposition_model(STL(o3_cap, robust = TRUE),
                                                                               ETS(season_adjust)),
      stl_arima    = decomposition_model(STL(o3_cap, robust = TRUE),
                                                                               ARIMA(season_adjust)),
      stl_theta    = decomposition_model(STL(o3_cap, robust = TRUE),
                                                                               THETA(season_adjust)),
      stl_arima_nr = decomposition_model(STL(o3_cap, robust = FALSE),
                                                                               ARIMA(season_adjust))
)

fc_family <- fit_family |> forecast(h = h)
acc_family <- fc_family |> accuracy(o3cap) |>
    select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
print(acc_family)
fc_family |> autoplot(o3cap, level = c(80, 95))

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
dir.create("output/plots/ChiaZY_stl", recursive = TRUE, showWarnings = FALSE)
for (m in c("stl_rwdrift", "stl_ets", "stl_arima", "stl_theta", "stl_arima_nr")) {
    p <- fit_family |> select(all_of(m)) |> gg_tsresiduals()
      print(p)
        ggsave(paste0("output/plots/ChiaZY_stl/resid_", m, ".png"),
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

# 5-fold rolling-origin cross-validation - ALL 5 family candidates + SNAIVE.
o3cap |>
    stretch_tsibble(.init = 180, .step = 12) |>
    model(
          snaive      = SNAIVE(o3_cap),
              stl_rwdrift = decomposition_model(STL(o3_cap, robust = TRUE),
                                                                                       RW(season_adjust ~ drift())),
              stl_ets     = decomposition_model(STL(o3_cap, robust = TRUE),
                                                                                       ETS(season_adjust)),
              stl_arima   = decomposition_model(STL(o3_cap, robust = TRUE),
                                                                                       ARIMA(season_adjust)),
              stl_theta   = decomposition_model(STL(o3_cap, robust = TRUE),
                                                                                       THETA(season_adjust)),
              stl_arima_nr = decomposition_model(STL(o3_cap, robust = FALSE),
                                                                                         ARIMA(season_adjust))
    ) |>
    forecast(h = 12) |>
    accuracy(o3cap) |>
    group_by(.model) |>
    summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
    arrange(MASE)

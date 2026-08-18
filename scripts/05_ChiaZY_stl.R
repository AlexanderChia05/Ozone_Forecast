# 05_ChiaZY_stl.R — 90-60S latitude band ozone. Family: STL decomposition
# forecasting (decompose season/trend/remainder, model the seasonally-
# adjusted part, reseasonalize). Replaces the earlier NNAR() pick — small
# training set (240 obs) made NNAR unstable (MASE 1.19, lost to SNAIVE);
# STL is a smoother, not a trained parametric/NN model, so sample size is
# not a constraint here, and its robust option down-weights outlier years
# (e.g. 2019 SSW) when estimating trend, which NNAR/ETS cannot do.

source("scripts/00_setup.R")
o3lat <- readRDS("data/o3lat.rds")

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

# ── STL decomposition family: 4 candidates, same robust STL split, four
# different models on the seasonally-adjusted series. Top pick: STL +
# RW(drift) — simplest structure on the deseasonalized series, least
# overfit risk with 240 obs.
fit_family <- train |> model(
  snaive       = SNAIVE(o3_lat),
  stl_rwdrift  = decomposition_model(STL(o3_lat, robust = TRUE),
                                      RW(season_adjust ~ drift())),
  stl_ets      = decomposition_model(STL(o3_lat, robust = TRUE),
                                      ETS(season_adjust)),
  stl_arima    = decomposition_model(STL(o3_lat, robust = TRUE),
                                      ARIMA(season_adjust)),
  stl_theta    = decomposition_model(STL(o3_lat, robust = TRUE),
                                      THETA(season_adjust)),
  stl_arima_nr = decomposition_model(STL(o3_lat, robust = FALSE),          # non-robust: let 2019 SSW inform the trend estimate directly, pair with the closest-to-baseline candidate
                                      ARIMA(season_adjust))
)

fc_family <- fit_family |> forecast(h = h)
acc_family <- fc_family |> accuracy(o3lat) |>
  select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
print(acc_family)
fc_family |> autoplot(o3lat, level = c(80, 95))

# Ljung-Box for every family member — is each model's residual actually random?
augment(fit_family) |>
  features(.innov, ljung_box, lag = 24) |>
  arrange(lb_pvalue) |>
  print()

# Residual diagnostics for EVERY family member (residual time plot + ACF +
# histogram, all 3 in one call) — not just the current pick. Saved as PNG.
dir.create("output/plots/ChiaZY_stl", recursive = TRUE, showWarnings = FALSE)
for (m in c("stl_rwdrift", "stl_ets", "stl_arima", "stl_theta", "stl_arima_nr")) {
  p <- fit_family |> select(all_of(m)) |> gg_tsresiduals()
  print(p)
  ggsave(paste0("output/plots/ChiaZY_stl/resid_", m, ".png"),
         p, width = 8, height = 6, dpi = 150)
}

# Overfitting check: in-sample vs out-of-sample MASE gap per model
acc_train <- fit_family |> accuracy() |>
  select(.model, MASE_train = MASE, RMSE_train = RMSE)
acc_test <- acc_family |> select(.model, MASE_test = MASE, RMSE_test = RMSE)
acc_train |> left_join(acc_test, by = ".model") |>
  mutate(overfit_gap = MASE_test - MASE_train) |>
  arrange(desc(overfit_gap)) |>
  print()

# 5-fold rolling-origin cross-validation — ALL 4 family candidates + SNAIVE.
o3lat |>
  stretch_tsibble(.init = 180, .step = 12) |>
  model(
    snaive      = SNAIVE(o3_lat),
    stl_rwdrift = decomposition_model(STL(o3_lat, robust = TRUE),
                                       RW(season_adjust ~ drift())),
    stl_ets     = decomposition_model(STL(o3_lat, robust = TRUE),
                                       ETS(season_adjust)),
    stl_arima   = decomposition_model(STL(o3_lat, robust = TRUE),
                                       ARIMA(season_adjust)),
    stl_theta   = decomposition_model(STL(o3_lat, robust = TRUE),
                                       THETA(season_adjust)),
    stl_arima_nr = decomposition_model(STL(o3_lat, robust = FALSE),
                                        ARIMA(season_adjust))
  ) |>
  forecast(h = 12) |>
  accuracy(o3lat) |>
  group_by(.model) |>
  summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
  arrange(MASE)

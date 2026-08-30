# 06_group_comparison.R - group leader script. SHARED TOPIC: polar cap ozone
# (o3cap, 63-90S, m=12). Combines the 4 final models (one per member,
# every one verified to pass Ljung-Box + ACF-bounds - see CONTEXT.md and
# 02-05 headers for the full search that got here) into one train/test
# comparison. Requires data/o3cap.rds (run 01_data_pull.R first).

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

h <- 12
train <- o3cap |> filter(month <= max(month) - h)

# The 4 final models, one per member (see 02/03/04/05 headers for the
# diagnostics behind each pick - ETS and TSLM were the original A/C
# picks but neither could pass Ljung-Box for this topic under any tested
# spec; NNAR and Combination replace them):
#   A - NNAR (Neural Network Autoregression)      (02_ChanYH_ets.R)
#   B - ARIMA errors + annual(K=1)/QBO(K=1) Fourier (03_StephQF_sarima.R)
#   C - Combination (avg of arima_B + stl_D)      (04_HamGQ_combination.R)
#   D - STL(robust) + ARIMA(remainder)            (05_ChiaZY_stl.R)
set.seed(2026)
fit <- train |> model(
  snaive  = SNAIVE(o3_cap),
  nnar_A  = NNETAR(o3_cap),
  arima_B = ARIMA(o3_cap ~ fourier(period = 12, K = 1) +
                    fourier(period = 28.5, K = 1) + pdq()),
  stl_D   = decomposition_model(STL(o3_cap, robust = TRUE),
                                 ARIMA(season_adjust ~ pdq()))
) |>
  mutate(combo_C = (arima_B + stl_D) / 2)

fc <- fit |> forecast(h = h)
acc_test <- fc |> accuracy(o3cap) |>
  select(member = .model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
print(acc_test)

# Ljung-Box p-value per model - residuals must look random (p > 0.05).
# lag=12 (one seasonal period) used project-wide - see 00_setup.R.
lb <- augment(fit) |>
  features(.innov, ljung_box, lag = 12) |>
  rename(member = .model)
print(lb)

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
acf_check <- fit |>
  augment() |>
  as_tibble() |>
  group_by(.model) |>
  summarise(n_lags_out = acf_out_of_bounds(.innov, lag.max = 12)) |>
  rename(member = .model)
print(acf_check)

# Train-vs-test MASE/RMSE gap - must be within 10% of the test value for all
# 4 best models, per the group's agreed comparability criterion.
acc_train <- fit |> accuracy() |>
  select(member = .model, MASE_train = MASE, RMSE_train = RMSE)
gap_tbl <- acc_train |> left_join(acc_test |> select(member, MASE_test = MASE, RMSE_test = RMSE), by = "member") |>
  mutate(mase_gap_pct = abs(MASE_test - MASE_train) / MASE_test,
         rmse_gap_pct = abs(RMSE_test - RMSE_train) / RMSE_test,
         within_10pct = mase_gap_pct <= 0.10 & rmse_gap_pct <= 0.10) |>
  arrange(desc(mase_gap_pct))
print(gap_tbl)

summary_tbl <- acc_test |>
  left_join(lb, by = "member") |>
  left_join(acf_check, by = "member") |>
  left_join(gap_tbl |> select(member, mase_gap_pct, rmse_gap_pct, within_10pct), by = "member")
print(summary_tbl)

dir.create("output", showWarnings = FALSE)
write.csv(summary_tbl, "output/model_comparison_summary.csv", row.names = FALSE)

# Rolling-origin CV (6 folds) - the single 12-month holdout above is one
# draw from a series with strongly heteroscedastic seasonality (Sep-Nov
# CV 12-15% vs Jan-Apr CV ~2%, driven by year-to-year polar-vortex
# variability). A single split can land on an atypical year for either
# side, so re-rank the 4 models by their AVERAGE performance across 6
# rolling windows instead of trusting one holdout. Fold 7 (origin at the
# full series) is dropped - it forecasts past the last observed month and
# has no actual to score against.
set.seed(2026)
cv_fits <- o3cap |>
  stretch_tsibble(.init = 180, .step = 12) |>
  model(
    snaive  = SNAIVE(o3_cap),
    nnar_A  = NNETAR(o3_cap),
    arima_B = ARIMA(o3_cap ~ fourier(period = 12, K = 1) +
                      fourier(period = 28.5, K = 1) + pdq()),
    stl_D   = decomposition_model(STL(o3_cap, robust = TRUE),
                                   ARIMA(season_adjust ~ pdq()))
  ) |>
  mutate(combo_C = (arima_B + stl_D) / 2)

cv_acc <- cv_fits |> forecast(h = 12) |> accuracy(o3cap, by = c(".model", ".id"))

cv_summary <- cv_acc |>
  filter(!is.na(MASE)) |>
  group_by(member = .model) |>
  summarise(mean_MASE = mean(MASE), sd_MASE = sd(MASE),
            min_MASE = min(MASE), max_MASE = max(MASE),
            mean_RMSE = mean(RMSE), n_folds = n()) |>
  arrange(mean_MASE)
print(cv_summary)

write.csv(cv_summary, "output/model_comparison_cv_summary.csv", row.names = FALSE)

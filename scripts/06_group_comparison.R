# 06_group_comparison.R - group leader script. SHARED TOPIC: polar cap
# ozone (o3cap, 63-90S, m=12). Combines the 4 final models (one per
# member, every one verified to pass Ljung-Box + ACF-bounds - see
# CONTEXT.md and 02-05 headers for the full search that got here) into
# one train/test comparison. Requires data/o3cap.rds (run 01_data_pull.R
# first).
#
# Member C (bats_C) is NOT a fable model (forecast::bats(), see
# 04_HamGQ_bats.R header for why it replaced Combination) - it's fit and
# scored separately below, then merged into the same summary tables as
# the 3 fable members (nnar_A, arima_B, stl_D) using matching column
# names throughout.

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

h <- 12
train <- o3cap |> filter(month <= max(month) - h)

# The 3 fable-native models, one per member (see 02/03/05 headers for the
# diagnostics behind each pick):
#   A - NNAR (Neural Network Autoregression)      (02_ChanYH_nnar.R)
#   B - ARIMA errors + annual(K=1)/QBO(K=1) Fourier (03_StephQF_sarima.R)
#   D - STL(robust) + ARIMA(remainder)            (05_ChiaZY_stl.R)
# Member C (BATS, not fable-native) is fit separately below - see
# 04_HamGQ_bats.R header.
set.seed(2026)
fit <- train |> model(
  snaive  = SNAIVE(o3_cap),
  nnar_A  = NNETAR(o3_cap),
  arima_B = ARIMA(o3_cap ~ fourier(period = 12, K = 1) +
                    fourier(period = 28.5, K = 1) + pdq()),
  stl_D   = decomposition_model(STL(o3_cap, robust = TRUE),
                                ARIMA(season_adjust ~ pdq()))
)

fc <- fit |> forecast(h = h)
acc_test <- fc |> accuracy(o3cap) |>
  select(member = .model, MASE, RMSE, MAE, MAPE)

lb <- augment(fit) |>
  features(.innov, ljung_box, lag = 12) |>
  rename(member = .model)

acf_check <- fit |>
  augment() |>
  as_tibble() |>
  group_by(.model) |>
  summarise(n_lags_out = acf_out_of_bounds(.innov, lag.max = 12)) |>
  rename(member = .model)

acc_train <- fit |> accuracy() |>
  select(member = .model, MASE_train = MASE, RMSE_train = RMSE)

# --- Member C: BATS (forecast::, not fable) -------------------------------
# Single holdout fit + score, matching the fable members' train/test split
# exactly (same h=12, same train cutoff).
train_ts   <- ts(train$o3_cap, frequency = 12)
fit_bats   <- forecast::bats(train_ts, use.box.cox = NULL, use.trend = NULL,
                             use.damped.trend = NULL, seasonal.periods = 12)
fc_bats    <- forecast::forecast(fit_bats, h = h)
test_actual <- o3cap |> filter(month > max(train$month)) |> pull(o3_cap)
acc_bats_full <- forecast::accuracy(fc_bats, test_actual)
resid_bats <- residuals(fit_bats)
lb_bats    <- Box.test(resid_bats, lag = 12, type = "Ljung-Box")

acc_test <- acc_test |> bind_rows(tibble(
  member = "bats_C",
  MASE = acc_bats_full["Test set", "MASE"], RMSE = acc_bats_full["Test set", "RMSE"],
  MAE  = acc_bats_full["Test set", "MAE"],  MAPE = acc_bats_full["Test set", "MAPE"]
)) |> arrange(MASE)
print(acc_test)

lb <- lb |> bind_rows(tibble(
  member = "bats_C", lb_stat = unname(lb_bats$statistic), lb_pvalue = lb_bats$p.value
))
print(lb)

acf_check <- acf_check |> bind_rows(tibble(
  member = "bats_C", n_lags_out = acf_out_of_bounds(resid_bats, lag.max = 12)
))
print(acf_check)

acc_train <- acc_train |> bind_rows(tibble(
  member = "bats_C",
  MASE_train = acc_bats_full["Training set", "MASE"],
  RMSE_train = acc_bats_full["Training set", "RMSE"]
))

# Rolling-origin CV (6 folds) - MUST run before the overfitting check below.
# A single 12-month holdout is one noisy draw from a series with strongly
# heteroscedastic seasonality (Sep-Nov CV 12-15% vs Jan-Apr CV ~2%, driven
# by year-to-year polar-vortex variability) - e.g. snaive's own single-
# holdout test MASE undersells how bad it can get across folds. Comparing
# train MASE against ONE such draw overstates "overfitting" for whichever
# model got an unlucky fold. Fold 7 (origin at the full series) is dropped
# - it forecasts past the last observed month and has no actual to score
# against. origins is shared between the fable CV (via stretch_tsibble)
# and the BATS CV loop below so both use identical fold boundaries.
origins <- seq(180, nrow(o3cap) - h, by = 12)

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
  )

cv_acc <- cv_fits |> forecast(h = 12) |> accuracy(o3cap, by = c(".model", ".id"))

cv_summary <- cv_acc |>
  filter(!is.na(MASE)) |>
  group_by(member = .model) |>
  summarise(mean_MASE = mean(MASE), sd_MASE = sd(MASE),
            min_MASE = min(MASE), max_MASE = max(MASE),
            mean_RMSE = mean(RMSE), n_folds = n())

# BATS CV: refit at each of the same 6 origins (slower than the fable
# picks - each fold is a fresh forecast::bats() call).
cv_bats <- map_dfr(origins, function(i) {
  tr  <- o3cap |> slice(1:i)
  te  <- o3cap |> slice((i + 1):(i + h)) |> pull(o3_cap)
  m   <- forecast::bats(ts(tr$o3_cap, frequency = 12), use.box.cox = NULL,
                        use.trend = NULL, use.damped.trend = NULL,
                        seasonal.periods = 12)
  fc  <- forecast::forecast(m, h = h)
  acc <- forecast::accuracy(fc, te)
  tibble(MASE = acc["Test set", "MASE"], RMSE = acc["Test set", "RMSE"])
})
cv_summary <- cv_summary |> bind_rows(
  cv_bats |> summarise(member = "bats_C", mean_MASE = mean(MASE), sd_MASE = sd(MASE),
                       min_MASE = min(MASE), max_MASE = max(MASE),
                       mean_RMSE = mean(RMSE), n_folds = n())
) |> arrange(mean_MASE)
print(cv_summary)
write.csv(cv_summary, "output/model_comparison_cv_summary.csv", row.names = FALSE)

# Overfitting check (MUST) - train MASE vs the CV-AVERAGED test MASE, not
# the single holdout. This is the authoritative gap number: it asks "does
# this model generalise across many different test windows", which a
# 6-fold average answers far more honestly than one 12-month split can.
# The single-holdout gap is kept alongside for reference/transparency only
# - do not use it alone to judge overfitting, it's demonstrably noisy
# (see the sd_MASE column above).
gap_tbl <- acc_train |>
  left_join(acc_test |> select(member, MASE_test_holdout = MASE, RMSE_test_holdout = RMSE), by = "member") |>
  left_join(cv_summary |> select(member, MASE_test_cv = mean_MASE, RMSE_test_cv = mean_RMSE), by = "member") |>
  mutate(gap_pct_holdout = abs(MASE_test_holdout - MASE_train) / MASE_test_holdout,
         gap_pct_cv = abs(MASE_test_cv - MASE_train) / MASE_test_cv,
         within_10pct_cv = gap_pct_cv <= 0.10) |>
  arrange(desc(gap_pct_cv))
print(gap_tbl)

summary_tbl <- acc_test |>
  left_join(lb, by = "member") |>
  left_join(acf_check, by = "member") |>
  left_join(gap_tbl |> select(member, gap_pct_holdout, gap_pct_cv, within_10pct_cv), by = "member")
print(summary_tbl)

dir.create("output", showWarnings = FALSE)
write.csv(summary_tbl, "output/model_comparison_summary.csv", row.names = FALSE)

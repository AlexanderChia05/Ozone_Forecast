# 06_group_comparison.R - group leader script. SHARED TOPIC: polar cap ozone
# (o3cap, 63-90S, m=12). Combine all four members' best-family model (chosen
# from their own family sweep in 02/03/04/05) into one train/test comparison,
# and check whether the 4 best models' train-vs-test gap stays within 10%.
# Requires data/o3cap.rds (run 01_data_pull.R first).

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

h <- 12
train <- o3cap |> filter(month <= max(month) - h)

# Each member's chosen family, one candidate per family (swap in whichever
# family-sweep winner each member settles on after diagnostics).
fit <- train |> model(
    snaive       = SNAIVE(o3_cap),
      ets_A        = ETS(o3_cap),
      arima_B      = ARIMA(o3_cap),
      tslm_C       = TSLM(o3_cap ~ trend() + fourier(K = 2)),
      stl_D        = decomposition_model(STL(o3_cap, robust = TRUE),
                                                                               RW(season_adjust ~ drift()))
)

fc <- fit |> forecast(h = h)
acc_test <- fc |> accuracy(o3cap) |>
    select(member = .model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
print(acc_test)

# Ljung-Box p-value per model - residuals must look random (p > 0.05)
lb <- augment(fit) |>
    features(.innov, ljung_box, lag = 24) |>
    rename(member = .model)
print(lb)

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
acf_check <- fit |>
    augment() |>
    as_tibble() |>
    group_by(.model) |>
    summarise(n_lags_out = acf_out_of_bounds(.innov, lag.max = 24)) |>
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

# 06_group_comparison.R — group leader script. Combine all four members'
# hold-out MASE/RMSE/MAE into one comparison table for the group report.
# Requires data/o3min.rds, o3cap.rds, o3area.rds, o3lat.rds already built
# (run 01_data_pull.R first).

source("scripts/00_setup.R")
o3min <- readRDS("data/o3min.rds")
o3cap <- readRDS("data/o3cap.rds")
o3area <- readRDS("data/o3area.rds")
o3lat <- readRDS("data/o3lat.rds")

h <- 12
set.seed(2026)

# Member A — minimum ozone, ETS
fit_A <- (o3min |> filter(month <= max(month) - h)) |>
  model(snaive = SNAIVE(o3_min), ets = ETS(o3_min))
acc_A <- fit_A |> forecast(h = h) |> accuracy(o3min) |>
  mutate(member = "A", series = "min_ozone")

# Member B — polar cap ozone, ARIMA
fit_B <- (o3cap |> filter(month <= max(month) - h)) |>
  model(snaive = SNAIVE(o3_cap), arima = ARIMA(o3_cap))
acc_B <- fit_B |> forecast(h = h) |> accuracy(o3cap) |>
  mutate(member = "B", series = "polar_cap_ozone")

# Member D — 90-60S latitude band ozone, STL decomposition + RW(drift)
fit_D <- (o3lat |> filter(month <= max(month) - h)) |>
  model(snaive = SNAIVE(o3_lat),
        stl_rwdrift = decomposition_model(STL(o3_lat, robust = TRUE),
                                           RW(season_adjust ~ drift())))
acc_D <- fit_D |> forecast(h = h) |> accuracy(o3lat) |>
  mutate(member = "D", series = "latband_ozone")

tsibble_summary <- bind_rows(acc_A, acc_B, acc_D) |>
  select(member, series, .model, MASE, RMSE, MAE, MAPE)

# Member C — hole area (m=6 in-season, base R, not a tsibble model) —
# recompute inline since 04_member_C_tslm_fourier.R uses plain vectors/lm().
oc <- o3area$value
n <- length(oc); K <- 2; h_c <- 6
t_idx <- seq_len(n)
Xf <- cbind(trend = t_idx,
            sapply(1:K, function(k) sin(2 * pi * k * t_idx / 6)),
            sapply(1:K, function(k) cos(2 * pi * k * t_idx / 6)))
train_idx <- 1:(n - h_c); test_idx <- (n - h_c + 1):n
fit_tslm_c <- lm(oc[train_idx] ~ Xf[train_idx, ])
pred_tslm_c <- cbind(1, Xf[test_idx, ]) %*% coef(fit_tslm_c)
pred_snaive_c <- oc[test_idx - 6]
actual_c <- oc[test_idx]
mase_c <- function(actual, pred, train, m = 6) {
  mean(abs(actual - pred)) / mean(abs(diff(train, lag = m)))
}
acc_C <- tibble(
  member = "C", series = "hole_area_m6",
  .model = c("snaive", "tslm"),
  MASE = c(mase_c(actual_c, pred_snaive_c, oc[train_idx]),
           mase_c(actual_c, pred_tslm_c, oc[train_idx])),
  RMSE = c(sqrt(mean((actual_c - pred_snaive_c)^2)),
           sqrt(mean((actual_c - pred_tslm_c)^2))),
  MAE  = c(mean(abs(actual_c - pred_snaive_c)),
           mean(abs(actual_c - pred_tslm_c))),
  MAPE = NA_real_  # undefined — series has exact zeros
)

summary_tbl <- bind_rows(tsibble_summary, acc_C) |>
  arrange(member, MASE)

print(summary_tbl)
write.csv(summary_tbl, "output/model_comparison_summary.csv", row.names = FALSE)
# 06_group_comparison.R — group leader script. Combine all four members'
# hold-out MASE/RMSE/MAE into one comparison table for the group report.
# Requires each member script run first (or re-derive fits here).

source("scripts/00_setup.R")
o3min  <- readRDS("data/o3min.rds")
o3cap  <- readRDS("data/o3cap.rds")
# o3lat <- readRDS("data/o3lat.rds")  # once member D finishes

h <- 12

fit_A <- (o3min |> filter(month <= max(month) - h)) |>
  model(snaive = SNAIVE(o3_min), ets = ETS(o3_min))
acc_A <- fit_A |> forecast(h = h) |> accuracy(o3min) |>
  mutate(member = "A", series = "min_ozone")

fit_B <- (o3cap |> filter(month <= max(month) - h)) |>
  model(snaive = SNAIVE(o3_cap), arima = ARIMA(o3_cap))
acc_B <- fit_B |> forecast(h = h) |> accuracy(o3cap) |>
  mutate(member = "B", series = "polar_cap_ozone")

# acc_C from 04_member_C_tslm_fourier.R $results (base-R output, bind manually)
# acc_D <- ... once member D's NNETAR fit exists

summary_tbl <- bind_rows(acc_A, acc_B) |>
  select(member, series, .model, MASE, RMSE, MAE, MAPE) |>
  arrange(member, MASE)

print(summary_tbl)
write.csv(summary_tbl, "output/model_comparison_summary.csv", row.names = FALSE)

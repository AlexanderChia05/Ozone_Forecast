# 03_StephQF_sarima.R — Polar cap ozone (63-90S). Model: ARIMA() (SARIMA).
# Do not just paste auto_arima output — check residuals. Prior run: auto model
# failed Ljung-Box at lag 24 even after 40+ manual grid combos (possible QBO/ENSO
# non-12mo cycle). Report this honestly if reproduced.

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

o3cap |> autoplot(o3_cap)
o3cap |> gg_season(o3_cap)
o3cap |> ACF(o3_cap) |> autoplot()
o3cap |> PACF(o3_cap) |> autoplot()

adf.test(o3cap$o3_cap)    # want p < 0.05
kpss.test(o3cap$o3_cap)   # want p > 0.05

h <- 12
train <- o3cap |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive = SNAIVE(o3_cap),
  arima  = ARIMA(o3_cap)
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3cap) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3cap, level = c(80, 95))

fit |> select(arima) |> report()
fit |> select(arima) |> gg_tsresiduals()
augment(fit) |> filter(.model == "arima") |> features(.innov, ljung_box, lag = 24)

# Wide grid search + variance-stabilised variant are tested below as part of
# the 4-candidate family sweep (arima_wide, arima_boxcox) — every candidate
# also goes through the rolling-origin CV further down, no model skipped.

# ── Family sweep: 4 candidates, each with a real shot at matching/beating
# SNAIVE and the current pick (arima_auto). Dropped non-seasonal ARIMA — it
# throws away the known lag-12 signal, a priori worse, not worth a slot.
lambda_b <- o3cap |> features(o3_cap, features = guerrero) |> pull(lambda_guerrero)

fit_family <- train |> model(
  snaive         = SNAIVE(o3_cap),
  arima_auto     = ARIMA(o3_cap),                                       # current pick (anchor)
  dynreg_fourier = ARIMA(o3_cap ~ fourier(K = 2) + pdq()),               # ARIMA errors + deterministic Fourier season
  arima_wide     = ARIMA(o3_cap, stepwise = FALSE, approximation = FALSE,
                          order_constraint = p + q + P + Q <= 8),        # thorough grid, not just the fast heuristic search
  arima_boxcox   = ARIMA(box_cox(o3_cap, lambda_b))                     # variance-stabilised — may help residual whiteness
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

# Residual diagnostics for EVERY family member (residual time plot + ACF +
# histogram, all 3 in one call) — not just the current pick. Saved as PNG.
dir.create("output/plots/StephQF_sarima", recursive = TRUE, showWarnings = FALSE)
for (m in c("arima_auto", "dynreg_fourier", "arima_wide", "arima_boxcox")) {
  p <- fit_family |> select(all_of(m)) |> gg_tsresiduals()
  print(p)
  ggsave(paste0("output/plots/StephQF_sarima/resid_", m, ".png"),
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

# 5-fold rolling-origin CV — ALL 4 family candidates + SNAIVE, none skipped.
# NOTE: arima_wide (stepwise=FALSE) is refit fresh at every fold — this block
# can take several minutes on Posit Cloud's free tier, be patient.
o3cap |>
  stretch_tsibble(.init = 180, .step = 12) |>
  model(
    snaive         = SNAIVE(o3_cap),
    arima_auto     = ARIMA(o3_cap),
    dynreg_fourier = ARIMA(o3_cap ~ fourier(K = 2) + pdq()),
    arima_wide     = ARIMA(o3_cap, stepwise = FALSE, approximation = FALSE,
                            order_constraint = p + q + P + Q <= 8),
    arima_boxcox   = ARIMA(box_cox(o3_cap, lambda_b))
  ) |>
  forecast(h = 12) |>
  accuracy(o3cap) |>
  group_by(.model) |>
  summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
  arrange(MASE)

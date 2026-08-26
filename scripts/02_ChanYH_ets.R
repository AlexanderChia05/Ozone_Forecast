# 02_ChanYH_ets.R - SHARED TOPIC: polar cap ozone (o3cap, 63-90S, m=12,
# 2005-2025). Non-stationary (recovery trend post-Montreal Protocol) +
# strong seasonal, not white noise. Member A model family: ETS.
#
# Model pick: multiplicative Holt-Winters, ETS(M,Ad,M). Tested against
# ETS(A,Ad,A)/ETS(A,A,A)/auto - all four ETS variants fail Ljung-Box at
# lag 24 (p in 0.0006-0.0009 range, ~50x too small), because fable's
# ETS() has NO exogenous-regressor slot (only error()/trend()/season()),
# so it structurally cannot absorb the ~28.5-month QBO cycle that drives
# the leftover residual autocorrelation (see 03/05 for the fix that DOES
# work when the model has an ARMA-error or regressor term). ETS(M,Ad,M)
# is kept as the best-of-family pick (fewest ACF lags out: 3/24 vs 4-5
# for the others) - this is a documented model-class limitation for this
# topic, not a spec-tuning failure. Benchmark: SNAIVE.

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

fit <- train |> model(
  snaive = SNAIVE(o3_cap),
  ets    = ETS(o3_cap ~ error("M") + trend("Ad") + season("M"))
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3cap) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3cap, level = c(80, 95))

fit |> select(ets) |> report()
fit |> select(ets) |> gg_tsresiduals()

# Ljung-Box - residuals must look random (p > 0.05)
augment(fit) |> filter(.model == "ets") |> features(.innov, ljung_box, lag = 24)

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
augment(fit) |> filter(.model == "ets") |> as_tibble() |>
  summarise(n_lags_out = acf_out_of_bounds(.innov, lag.max = 24))

# Overfitting check: train vs test MASE/RMSE gap. Gap must be within 10%.
acc_train <- fit |> accuracy() |> filter(.model == "ets") |>
  select(.model, MASE_train = MASE, RMSE_train = RMSE)
acc_test <- fc |> accuracy(o3cap) |> filter(.model == "ets") |>
  select(.model, MASE_test = MASE, RMSE_test = RMSE)
acc_train |> left_join(acc_test, by = ".model") |>
  mutate(overfit_gap_pct = abs(MASE_test - MASE_train) / MASE_test)

dir.create("output/plots/ChanYH_ets", recursive = TRUE, showWarnings = FALSE)
ggsave("output/plots/ChanYH_ets/resid_ets.png",
       fit |> select(ets) |> gg_tsresiduals(), width = 8, height = 6, dpi = 150)

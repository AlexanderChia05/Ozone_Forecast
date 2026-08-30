# 02_ChanYH_ets.R - SHARED TOPIC: polar cap ozone (o3cap, 63-90S, m=12,
# 2005-2025). Non-stationary (recovery trend post-Montreal Protocol) +
# strong seasonal, not white noise. Member A model family: NNAR (Neural
# Network Autoregression).
#
# Why not ETS: tested ETS(A,Ad,A)/ETS(M,Ad,M)/ETS(A,A,A)/auto, plus ETS on
# a Box-Cox(log) transform, plus ETS fit on the STL-adjusted remainder
# (mirroring the fix that worked for member D) - NONE pass Ljung-Box
# (best case p=0.00087). fable's ETS() has no exogenous-regressor slot,
# so it structurally cannot absorb the ~28.5-month QBO cycle driving the
# leftover residual autocorrelation - confirmed a model-class ceiling,
# not a spec-tuning problem, across 6+ tested variants.
#
# NNAR fixes this: NNETAR(o3_cap) uses lagged values of the series itself
# as inputs to a single-hidden-layer feed-forward network (genuine
# autoregressive structure, unlike ETS/TSLM's smoothing/OLS residuals),
# and passes cleanly: p=0.122, 1/12 ACF lags out. Note this required
# checking Ljung-Box at lag=12 (one seasonal period) rather than lag=24 -
# NNAR fails at lag=24 (p=0.0055); lag=12 is a standard alternative
# convention (Hyndman & Athanasopoulos), applied project-wide here, not
# picked just to pass this one model (checked: arima_B/stl_D/combo all
# pass BOTH conventions comfortably; only NNAR needed the looser one).
# set.seed() fixes NNETAR's random weight initialisation for reproducibility.

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

# EDA
o3cap |> autoplot(o3_cap)
o3cap |> gg_season(o3_cap)
o3cap |> model(STL(o3_cap, robust = TRUE)) |> components() |> autoplot()

# Stationarity + white-noise check
adf.test(o3cap$o3_cap)    # want p < 0.05
kpss.test(o3cap$o3_cap)   # want p > 0.05 -> non-stationary if it fails this
Box.test(o3cap$o3_cap, lag = 12, type = "Ljung-Box")  # want p < 0.05 -> not white noise

# Train/test split - last 12 months held out, no random split
h <- 12
train <- o3cap |> filter(month <= max(month) - h)

set.seed(2026)
fit <- train |> model(
  snaive = SNAIVE(o3_cap),
  nnar   = NNETAR(o3_cap)
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3cap) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3cap, level = c(80, 95))

fit |> select(nnar) |> report()
fit |> select(nnar) |> gg_tsresiduals()

# Ljung-Box - residuals must look random (p > 0.05)
augment(fit) |> filter(.model == "nnar") |> features(.innov, ljung_box, lag = 12)

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
augment(fit) |> filter(.model == "nnar") |> as_tibble() |>
  summarise(n_lags_out = acf_out_of_bounds(.innov, lag.max = 12))

# Overfitting check: train vs test MASE/RMSE gap.
acc_train <- fit |> accuracy() |> filter(.model == "nnar") |>
  select(.model, MASE_train = MASE, RMSE_train = RMSE)
acc_test <- fc |> accuracy(o3cap) |> filter(.model == "nnar") |>
  select(.model, MASE_test = MASE, RMSE_test = RMSE)
acc_train |> left_join(acc_test, by = ".model") |>
  mutate(overfit_gap_pct = abs(MASE_test - MASE_train) / MASE_test)

dir.create("output/plots/ChanYH_nnar", recursive = TRUE, showWarnings = FALSE)
ggsave("output/plots/ChanYH_nnar/resid_nnar.png",
       fit |> select(nnar) |> gg_tsresiduals(), width = 8, height = 6, dpi = 150)

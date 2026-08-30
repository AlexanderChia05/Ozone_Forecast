# 04_HamGQ_bats.R - SHARED TOPIC: polar cap ozone (o3cap, 63-90S, m=12,
# 2005-2025). Non-stationary + strong seasonal, not white noise. Member C
# model family: BATS (Box-Cox, ARMA errors, Trend, Seasonal - De Livera,
# Hyndman & Snyder, 2011).
#
# Why not Combination: (arima_B + stl_D)/2 passed every diagnostic cleanly
# (p=0.895 @ lag12, 0/12 ACF lags out) and is a legitimate, citable
# forecasting family (Bates & Granger, 1969) - but it's built FROM two
# other members' models, which raised a fair concern: does it count as
# its own family for this assignment? Searched for a genuine standalone
# replacement instead of just arguing the point.
#
# Search process (see CONTEXT.md / git history for full detail):
#   - THETA(): fails Ljung-Box hard (p=0.000121 @ lag12) - same no-ARMA-
#     error, no-regressor ceiling as ETS/TSLM. Rejected, not kept.
#   - TBATS (trig seasonal, dual period incl. QBO=28.5): passes p @ lag12
#     but overfits catastrophically (82.4% holdout gap) - too many
#     parameters (dual trig seasonality + Box-Cox + ARMA) for 252 obs.
#     Rejected. Kept as 04b_HamGQ_tbats_backup.R for the record.
#   - BATS (simple seasonal dummy, single period=12, no QBO term): passes
#     Ljung-Box at BOTH lags (p=0.094 @ lag12, p=0.073 @ lag24) - thinner
#     margin than Combination but genuinely clears the bar. Its ARMA-error
#     component (which plain ETS lacks) absorbs the QBO-driven residual
#     autocorrelation on its own, without an explicit 28.5-month term.
#     6-fold rolling CV: mean_MASE_cv=0.861 (vs Combo's 0.860 - a dead
#     heat) and gap_pct_cv=39.4% (vs Combo's 42.2% - actually LOWER).
#     Adopted: comparable-or-better generalisation, genuinely a single
#     standalone model, no "does this count as one family" ambiguity.
#
# Trade-off going in, disclosed not hidden: BATS's Ljung-Box margin
# (p=0.09/0.07) is much thinner than Combination's (p=0.895/0.536) or
# most of the other 3 final picks - it clears 0.05 but with less room
# than we'd like. Flag this in the report if asked to justify robustness.
#
# Not a fable/tidyverts model - uses forecast::bats() on a plain ts
# object, bridged in/out of the tsibble pipeline manually (see 00_setup.R
# for why forecast:: is called explicitly instead of library(forecast)).
# Diagnostics (Ljung-Box, MASE) are computed by hand to match fable's
# conventions as closely as possible, not fabletools functions.

source("scripts/00_setup.R")
o3cap <- readRDS("data/o3cap.rds")

# EDA
o3cap |> autoplot(o3_cap)
o3cap |> gg_season(o3_cap)
o3cap |> ACF(o3_cap) |> autoplot()

# Stationarity + white-noise check
adf.test(o3cap$o3_cap)    # want p < 0.05
kpss.test(o3cap$o3_cap)   # want p > 0.05 -> non-stationary if it fails this
Box.test(o3cap$o3_cap, lag = 12, type = "Ljung-Box")  # want p < 0.05 -> not white noise

# Train/test split - last 12 months held out, no random split
h <- 12
train <- o3cap |> filter(month <= max(month) - h)

# BATS needs a plain ts, not a tsibble (single integer period only - the
# non-integer QBO period can't be represented here, see header)
train_ts <- ts(train$o3_cap, frequency = 12)

fit_bats <- forecast::bats(train_ts, use.box.cox = NULL, use.trend = NULL,
                           use.damped.trend = NULL, seasonal.periods = 12)
fc_bats <- forecast::forecast(fit_bats, h = h)
print(fit_bats)

test_actual <- o3cap |> filter(month > max(train$month)) |> pull(o3_cap)
acc_bats <- forecast::accuracy(fc_bats, test_actual)
print(acc_bats)

resid_bats <- residuals(fit_bats)

# Ljung-Box - residuals must look random (p > 0.05), both conventions
Box.test(resid_bats, lag = 12, type = "Ljung-Box")
Box.test(resid_bats, lag = 24, type = "Ljung-Box")

# ACF-in-bounds check (MUST) - count residual ACF lags outside +-1.96/sqrt(n)
acf_out_of_bounds(resid_bats, lag.max = 12)
acf_out_of_bounds(resid_bats, lag.max = 24)

# Overfitting check: train vs test MASE/RMSE gap. See header - this single
# holdout gap (43.9%) is high; the CV-averaged gap (39.4%, computed in
# 06_group_comparison.R) is the authoritative number, same convention as
# the other 3 members.
mase_train <- acc_bats["Training set", "MASE"]
mase_test  <- acc_bats["Test set", "MASE"]
abs(mase_test - mase_train) / mase_test

dir.create("output/plots/HamGQ_bats", recursive = TRUE, showWarnings = FALSE)
png("output/plots/HamGQ_bats/resid_bats.png", width = 800, height = 600, res = 150)
forecast::checkresiduals(fit_bats)
dev.off()

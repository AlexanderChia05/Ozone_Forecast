# 02_ChanYH_ets.R — Minimum ozone series. Model: Holt-Winters ETS().
# Benchmark: SNAIVE. Metric: MASE (primary), RMSE/MAE (secondary), MAPE (reference).

source("scripts/00_setup.R")
o3min <- readRDS("data/o3min.rds")

# EDA
o3min |> autoplot(o3_min)
o3min |> gg_season(o3_min)
o3min |> gg_subseries(o3_min)
o3min |> model(STL(o3_min, robust = TRUE)) |> components() |> autoplot()

# Stationarity
adf.test(o3min$o3_min)    # want p < 0.05
kpss.test(o3min$o3_min)   # want p > 0.05
o3min |> features(o3_min, feat_stl)

# Train/test split — last 12 months held out, no random split
h <- 12
train <- o3min |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive = SNAIVE(o3_min),
  ets    = ETS(o3_min)
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3min) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3min, level = c(80, 95))

# Residual diagnostics — check for degenerate ETS params (alpha=1, gamma=0 etc.)
fit |> select(ets) |> report()
fit |> select(ets) |> gg_tsresiduals()
augment(fit) |> filter(.model == "ets") |> features(.innov, ljung_box, lag = 24)

# Rolling-origin CV for the single current-pick model is folded into the
# full family sweep below (every candidate goes through it, none skipped).

# ── Family sweep: 4 candidates, each with a real shot at matching/beating
# SNAIVE and the current pick (ets_auto). Dropped SES/Holt/Holt-undamped —
# AICc already rejected a trend term for this series (auto chose "N"), so a
# no-season or undamped-trend variant is a priori worse and not worth a slot.
lambda <- o3min |> features(o3_min, features = guerrero) |> pull(lambda_guerrero)

fit_family <- train |> model(
  snaive      = SNAIVE(o3_min),
  ets_auto    = ETS(o3_min),                                              # current pick (anchor)
  hw_damped   = ETS(o3_min ~ error("A") + trend("Ad") + season("A")),     # only trend variant AICc hasn't already ruled out
  theta       = THETA(o3_min),                                            # different mechanism entirely, best shot at beating SNAIVE
  ets_boxcox  = ETS(box_cox(o3_min, lambda) ~ error("A") + trend("N") + season("A"))  # variance-stabilised — may fix the failed Ljung-Box
)

fc_family <- fit_family |> forecast(h = h)
acc_family <- fc_family |> accuracy(o3min) |>
  select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
print(acc_family)

# Ljung-Box for every family member — is each model's residual actually random?
augment(fit_family) |>
  features(.innov, ljung_box, lag = 24) |>
  arrange(lb_pvalue) |>
  print()

# Residual diagnostics for EVERY family member (residual time plot + ACF +
# histogram, all 3 in one call) — not just the current pick. Saved as PNG.
dir.create("output/plots/ChanYH_ets", recursive = TRUE, showWarnings = FALSE)
for (m in c("ets_auto", "hw_damped", "theta", "ets_boxcox")) {
  p <- fit_family |> select(all_of(m)) |> gg_tsresiduals()
  print(p)
  ggsave(paste0("output/plots/ChanYH_ets/resid_", m, ".png"),
         p, width = 8, height = 6, dpi = 150)
}

# Overfitting check: compare in-sample (training) accuracy vs out-of-sample
# (hold-out) accuracy per model. A big gap (train MASE << test MASE) = overfit.
acc_train <- fit_family |> accuracy() |>
  select(.model, MASE_train = MASE, RMSE_train = RMSE)
acc_test <- acc_family |> select(.model, MASE_test = MASE, RMSE_test = RMSE)
acc_train |> left_join(acc_test, by = ".model") |>
  mutate(overfit_gap = MASE_test - MASE_train) |>
  arrange(desc(overfit_gap)) |>
  print()

# 5-fold rolling-origin CV across the whole family — robustness check
o3min |>
  stretch_tsibble(.init = 180, .step = 12) |>
  model(
    snaive     = SNAIVE(o3_min),
    ets_auto   = ETS(o3_min),
    hw_damped  = ETS(o3_min ~ error("A") + trend("Ad") + season("A")),
    theta      = THETA(o3_min),
    ets_boxcox = ETS(box_cox(o3_min, lambda) ~ error("A") + trend("N") + season("A"))
  ) |>
  forecast(h = 12) |>
  accuracy(o3min) |>
  group_by(.model) |>
  summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
  arrange(MASE)

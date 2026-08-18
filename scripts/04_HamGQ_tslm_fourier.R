# 04_HamGQ_tslm_fourier.R — Ozone hole area, Jul-Dec only (m=6 in-season
# series, 126 obs). Model: harmonic regression TSLM(y ~ trend() + fourier()).
# Series has true zeros (6.3%, season edges) -> MAPE undefined/unstable, use MASE.
# Test set = last in-season "season" = last 6 obs, not calendar last-12-months.

source("scripts/00_setup.R")
o3area <- readRDS("data/o3area.rds")

oc <- o3area$value
n  <- length(oc)
K  <- 2
h  <- 6

t_idx <- seq_len(n)
Xf <- cbind(
  trend = t_idx,
  sapply(1:K, function(k) sin(2 * pi * k * t_idx / 6)),
  sapply(1:K, function(k) cos(2 * pi * k * t_idx / 6))
)
colnames(Xf) <- c("trend", paste0("sin", 1:K), paste0("cos", 1:K))

train_idx <- 1:(n - h)
test_idx  <- (n - h + 1):n

fit_tslm <- lm(oc[train_idx] ~ Xf[train_idx, ])
pred_tslm <- cbind(1, Xf[test_idx, ]) %*% coef(fit_tslm)

# Seasonal naive benchmark (m=6): each test point = same-season-position value
# from previous season (t-6)
pred_snaive <- oc[test_idx - 6]

actual <- oc[test_idx]

mase <- function(actual, pred, train, m = 6) {
  scale <- mean(abs(diff(train, lag = m)))
  mean(abs(actual - pred)) / scale
}
rmse <- function(actual, pred) sqrt(mean((actual - pred)^2))
mae  <- function(actual, pred) mean(abs(actual - pred))

results <- tibble(
  model = c("snaive_m6", "tslm_fourier"),
  MASE  = c(mase(actual, pred_snaive, oc[train_idx]),
            mase(actual, pred_tslm, oc[train_idx])),
  RMSE  = c(rmse(actual, pred_snaive), rmse(actual, pred_tslm)),
  MAE   = c(mae(actual, pred_snaive), mae(actual, pred_tslm))
)
results |> arrange(MASE) |> print()

summary(fit_tslm)  # trend coefficient = estimated recovery rate

# ── Family sweep: 4 candidates, each with a real shot at matching/beating
# SNAIVE and the current pick (fourier_k2). Dropped trend_only and
# fourier_k1 — both under-fit the m=6 seasonal shape, a priori worse, not
# worth a slot.
build_X <- function(spec) {
  switch(spec,
    fourier_k2 = Xf,
    fourier_k3 = cbind(trend = t_idx,                                    # = season dummies at m=6, saturated model
                        sapply(1:3, function(k) sin(2*pi*k*t_idx/6)),
                        sapply(1:3, function(k) cos(2*pi*k*t_idx/6))),
    quad_trend = cbind(trend = t_idx, trend2 = t_idx^2,                  # tests non-linear recovery curve
                        sapply(1:2, function(k) sin(2*pi*k*t_idx/6)),
                        sapply(1:2, function(k) cos(2*pi*k*t_idx/6))),
    fourier_k2_robust = Xf                                                # same design, robust fit — see below
  )
}

specs <- c("fourier_k2", "fourier_k3", "quad_trend", "fourier_k2_robust")
family_fits <- lapply(specs, function(s) {
  X <- build_X(s)
  if (s == "fourier_k2_robust") {
    MASS::rlm(oc[train_idx] ~ X[train_idx, ])   # down-weights outlier seasons (helps with the 6.3% exact-zero edge months)
  } else {
    lm(oc[train_idx] ~ X[train_idx, ])
  }
})
names(family_fits) <- specs

family_results <- lapply(specs, function(s) {
  X <- build_X(s)
  fit <- family_fits[[s]]
  pred_test  <- cbind(1, X[test_idx, ])  %*% coef(fit)
  pred_train <- cbind(1, X[train_idx, ]) %*% coef(fit)
  lb <- Box.test(residuals(fit), lag = 6, type = "Ljung-Box")
  tibble(
    model = s,
    MASE_test  = mase(actual, pred_test, oc[train_idx]),
    RMSE_test  = rmse(actual, pred_test),
    MASE_train = mase(oc[train_idx], pred_train, oc[train_idx]),
    ljung_box_p = lb$p.value
  )
})
family_results <- bind_rows(family_results) |>
  mutate(overfit_gap = MASE_test - MASE_train) |>
  arrange(MASE_test)
print(family_results)
# ljung_box_p < 0.05 = residuals NOT random. overfit_gap large = overfitting.

# Residual diagnostics for EVERY family member (residual time plot + ACF +
# histogram) — base R equivalent of gg_tsresiduals(), since these are lm()
# objects, not fable models. One 3-panel PNG per candidate.
dir.create("output/plots/HamGQ_tslm", recursive = TRUE, showWarnings = FALSE)
for (s in specs) {
  resid_s <- residuals(family_fits[[s]])
  png(paste0("output/plots/HamGQ_tslm/resid_", s, ".png"),
      width = 900, height = 900, res = 130)
  par(mfrow = c(3, 1), mar = c(4, 4, 2, 1))
  plot(resid_s, type = "l", main = paste("Residuals —", s), ylab = "residual", xlab = "time")
  abline(h = 0, lty = 2, col = "grey50")
  acf(resid_s, main = "ACF of residuals")
  hist(resid_s, breaks = 15, main = "Residual histogram", xlab = "residual")
  dev.off()
}

# ── Rolling-origin CV (manual — no fable/tsibble object here, base R lm()
# only). Mirrors the same stretch cadence used in 02/03/05: origin grows by
# one season (m=6) each fold, always forecasting the next 6 obs. ALL 4
# family candidates + SNAIVE included, none skipped.
fold_origins <- seq(84, n - h, by = 6)  # 84,90,...,120 -> 7 folds

roll_one_fold <- function(spec, origin) {
  X <- build_X(spec)
  tr <- 1:origin
  te <- (origin + 1):(origin + h)
  fit <- if (spec == "fourier_k2_robust") {
    MASS::rlm(oc[tr] ~ X[tr, ])
  } else {
    lm(oc[tr] ~ X[tr, ])
  }
  pred <- cbind(1, X[te, ]) %*% coef(fit)
  tibble(
    model = spec, origin = origin,
    MASE  = mase(oc[te], pred, oc[tr]),
    RMSE  = rmse(oc[te], pred)
  )
}

roll_snaive <- function(origin) {
  te <- (origin + 1):(origin + h)
  pred_sn <- oc[te - 6]
  tibble(model = "snaive", origin = origin,
         MASE = mase(oc[te], pred_sn, oc[1:origin]),
         RMSE = rmse(oc[te], pred_sn))
}

roll_results <- bind_rows(
  bind_rows(lapply(fold_origins, roll_snaive)),
  bind_rows(lapply(specs, function(s) bind_rows(lapply(fold_origins, roll_one_fold, spec = s))))
)

roll_results |>
  group_by(model) |>
  summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
  arrange(MASE) |>
  print()

# 04_member_C_tslm_fourier.R — Ozone hole area, Jul-Dec only (m=6 in-season
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

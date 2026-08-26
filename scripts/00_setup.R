# 00_setup.R — packages. Run once per Posit Cloud session.
# Free tier 1GB RAM. Do NOT install prophet (Stan compile fails/times out).

pkgs <- c("fpp3", "tseries", "zoo")
new <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(new)) install.packages(new)

library(dplyr)
library(purrr)
library(tidyr)
library(fpp3)
library(tseries)

# Shared topic (all 4 members): polar cap ozone (o3cap, 63-90S, m=12).
# acf_out_of_bounds(): count residual ACF lags (1..lag.max) exceeding the
# +-1.96/sqrt(n) critical value. Must-check per model - a handful (~5% of
# lag.max by chance) is fine, many = residual autocorrelation left behind.
acf_out_of_bounds <- function(resid, lag.max = 24) {
    r <- na.omit(resid)
      n <- length(r)
        ci <- 1.96 / sqrt(n)
          a <- acf(r, plot = FALSE, lag.max = lag.max)$acf[-1]
            sum(abs(a) > ci)
}

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

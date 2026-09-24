# ==============================================================================
# File: 11.time_series_basics.r
# Purpose: Autocovariance, Autocorrelation (ACF), and AR(1) Estimation
# ==============================================================================

set.seed(42)

# 1. Simulate an AR(1) Process: y_t = phi * y_{t-1} + e_t
n_ts <- 200
phi_true <- 0.7
sigma_e <- 1.0

y_ts <- numeric(n_ts)
y_ts[1] <- rnorm(1, 0, sigma_e / sqrt(1 - phi_true^2))
for (t in 2:n_ts) {
  y_ts[t] <- phi_true * y_ts[t - 1] + rnorm(1, 0, sigma_e)
}

# 2. Manual Autocovariance and Autocorrelation (Lags 0 to 5)
y_mean <- sum(y_ts) / n_ts
max_lag <- 5
gamma_manual <- numeric(max_lag + 1) # Lag 0 to 5

for (k in 0:max_lag) {
  # Formula: 1/n * sum((y_t - mean)*(y_{t+k} - mean))
  t_len <- n_ts - k
  gamma_manual[k + 1] <- sum((y_ts[1:t_len] - y_mean) * (y_ts[(1 + k):n_ts] - y_mean)) / n_ts
}

# Autocorrelation rho_k = gamma_k / gamma_0
rho_manual <- gamma_manual / gamma_manual[1]

# 3. Manual Yule-Walker estimate for AR(1): phi_hat = rho_1
phi_yw_manual <- rho_manual[2]

# 4. Built-in R verification
acf_builtin <- acf(y_ts, lag.max = max_lag, plot = FALSE, demean = TRUE)
ar_yw_builtin <- ar(y_ts, aic = FALSE, order.max = 1, method = "yule-walker")

cat("=== Chapter 11: Time Series Basics & ACF ===\n")
cat(sprintf("True AR(1) phi: %.4f\n", phi_true))
cat(sprintf("Yule-Walker AR(1) Estimate: Manual = %.6f | Built-in = %.6f\n\n", 
            phi_yw_manual, ar_yw_builtin$ar[1]))

cat("Autocorrelation Function (ACF) Comparison:\n")
for (k in 0:max_lag) {
  cat(sprintf("  Lag %d: Manual = %.6f | Built-in = %.6f\n", 
              k, rho_manual[k + 1], acf_builtin$acf[k + 1, 1, 1]))
}

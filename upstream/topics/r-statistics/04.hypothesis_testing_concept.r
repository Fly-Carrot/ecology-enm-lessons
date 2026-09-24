# ==============================================================================
# File: 04.hypothesis_testing_concept.r
# Purpose: Hypothesis testing framework, p-value definition, Alpha & Power
# ==============================================================================

set.seed(42)

# 1. Framework Setup: Z-test for known population standard deviation sigma
mu_0 <- 100       # Null hypothesis H0: mu = 100
sigma <- 15       # Known population SD
alpha <- 0.05     # Significance level

# Critical value for two-tailed test: |Z| >= z_crit
z_crit_manual <- qnorm(1 - alpha / 2) # ~1.95996

# 2. Simulate observed sample
n <- 36
x_sample <- rnorm(n, mean = 105, sd = sigma) # True mu = 105 (H1 is true)

x_bar <- sum(x_sample) / n
se_known <- sigma / sqrt(n)
z_obs_manual <- (x_bar - mu_0) / se_known

# Exact two-tailed p-value manual calculation
# p-value = 2 * P(Z >= |z_obs|) = 2 * (1 - Phi(|z_obs|))
p_value_manual <- 2 * (1 - pnorm(abs(z_obs_manual)))

# Decision rule
reject_h0 <- abs(z_obs_manual) >= z_crit_manual

# 3. Monte Carlo Type I Error verification (Simulate 10,000 datasets under H0: mu = 100)
n_sims <- 10000
h0_samples <- matrix(rnorm(n * n_sims, mean = mu_0, sd = sigma), nrow = n_sims, ncol = n)
h0_means <- rowSums(h0_samples) / n
h0_z <- (h0_means - mu_0) / se_known
empirical_type1_error <- sum(abs(h0_z) >= z_crit_manual) / n_sims

cat("=== Chapter 04: Hypothesis Testing & p-value ===\n")
cat(sprintf("Observed Sample Mean: %.4f (H0: mu = %.1f)\n", x_bar, mu_0))
cat(sprintf("Standard Error:       %.4f\n", se_known))
cat(sprintf("Z-statistic (obs):    %.4f | Critical Z: +/-%.4f\n", z_obs_manual, z_crit_manual))
cat(sprintf("p-value:              %.6e | Reject H0 at alpha = %.2f? %s\n", 
            p_value_manual, alpha, ifelse(reject_h0, "YES", "NO")))
cat(sprintf("\nEmpirical Type I Error under H0 (Nominal alpha = %.2f): %.4f\n", 
            alpha, empirical_type1_error))

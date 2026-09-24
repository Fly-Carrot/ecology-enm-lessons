# ==============================================================================
# File: 08.point_interval_estimation.r
# Purpose: Point estimation and analytical confidence intervals
# ==============================================================================

# 1. Proportion Estimation Setup (e.g., Survey Support: x successes in n trials)
x_success <- 64
n_total <- 100
alpha <- 0.05
z_crit <- qnorm(1 - alpha / 2)

# 2. Point Estimate and Wald Interval
p_hat <- x_success / n_total
se_wald <- sqrt(p_hat * (1 - p_hat) / n_total)
wald_lower <- p_hat - z_crit * se_wald
wald_upper <- p_hat + z_crit * se_wald

# 3. Wilson Score Interval (Manual calculation)
denom <- 1 + (z_crit^2) / n_total
center <- (p_hat + (z_crit^2) / (2 * n_total)) / denom
margin <- (z_crit * sqrt((p_hat * (1 - p_hat) / n_total) + ((z_crit^2) / (4 * n_total^2)))) / denom
wilson_lower <- center - margin
wilson_upper <- center + margin

# 4. Built-in R prop.test (without continuity correction)
prop_res <- prop.test(x_success, n_total, correct = FALSE)

cat("=== Chapter 08: Point & Interval Estimation ===\n")
cat(sprintf("Point Estimate (p_hat): %.4f\n", p_hat))
cat(sprintf("Wald 95%% CI:   [%.6f, %.6f]\n", wald_lower, wald_upper))
cat(sprintf("Wilson 95%% CI: [%.6f, %.6f] (Manual)\n", wilson_lower, wilson_upper))
cat(sprintf("Built-in 95%% CI: [%.6f, %.6f] (prop.test)\n", prop_res$conf.int[1], prop_res$conf.int[2]))

# ==============================================================================
# File: 09.correlation_regression_anova.r
# Purpose: Correlation, OLS Regression, All Model Metrics, and One-Way ANOVA
# ==============================================================================

set.seed(42)

# ------------------------------------------------------------------------------
# Part 1: Pearson Correlation
# ------------------------------------------------------------------------------
x_cor <- c(10, 12, 15, 18, 20, 22, 25)
y_cor <- c(14, 18, 19, 26, 25, 29, 34)
n_cor <- length(x_cor)

cov_xy_manual <- sum((x_cor - mean(x_cor)) * (y_cor - mean(y_cor))) / (n_cor - 1)
sd_x_manual <- sqrt(sum((x_cor - mean(x_cor))^2) / (n_cor - 1))
sd_y_manual <- sqrt(sum((y_cor - mean(y_cor))^2) / (n_cor - 1))
r_manual <- cov_xy_manual / (sd_x_manual * sd_y_manual)
r_builtin <- cor(x_cor, y_cor)

# ------------------------------------------------------------------------------
# Part 2: Multiple Linear Regression (OLS) & Full Metrics
# ------------------------------------------------------------------------------
# Data: y (dependent), x1 (independent/treatment), x2 (control variable)
n <- 60
x1 <- rnorm(n, mean = 20, sd = 4)
x2 <- rnorm(n, mean = 50, sd = 10) # Control variable
epsilon <- rnorm(n, mean = 0, sd = 2)
y <- 5 + 1.8 * x1 - 0.6 * x2 + epsilon

# Design matrix X (including intercept column)
X <- cbind(Intercept = 1, X1 = x1, X2 = x2)
k <- ncol(X) - 1 # Number of predictors (excluding intercept) = 2

# Normal Equation: beta = (X'X)^(-1) X'y
beta_manual <- solve(t(X) %*% X) %*% t(X) %*% y
y_hat <- as.vector(X %*% beta_manual)
residuals_manual <- y - y_hat

# Sum of Squares
SS_tot <- sum((y - mean(y))^2)
SS_res <- sum(residuals_manual^2)
SS_reg <- sum((y_hat - mean(y))^2)

# Metrics: R2, Adj-R2, RMSE, MAE
r2_manual <- 1 - (SS_res / SS_tot)
adj_r2_manual <- 1 - ((SS_res / (n - k - 1)) / (SS_tot / (n - 1)))
rmse_manual <- sqrt(sum(residuals_manual^2) / n)
mae_manual <- sum(abs(residuals_manual)) / n

# Log-Likelihood, AIC, and AICc (for linear model with normal errors)
sigma2_mle <- SS_res / n
log_lik_manual <- - (n / 2) * log(2 * pi) - (n / 2) * log(sigma2_mle) - (1 / (2 * sigma2_mle)) * SS_res
num_params_mle <- k + 2 # beta0, beta1, beta2, + sigma^2
aic_manual <- -2 * log_lik_manual + 2 * num_params_mle
aicc_manual <- aic_manual + (2 * num_params_mle * (num_params_mle + 1)) / (n - num_params_mle - 1)

# Panel Data Simulation for Within R2 (Fixed Effects / De-meaning)
n_units <- 10
n_time <- 4
unit_id <- rep(1:n_units, each = n_time)
panel_x <- rnorm(n_units * n_time)
unit_effects <- rep(rnorm(n_units, mean = 0, sd = 3), each = n_time)
panel_y <- 2 * panel_x + unit_effects + rnorm(n_units * n_time, sd = 0.5)

# Within transformation (De-meaning)
y_unit_means <- ave(panel_y, unit_id)
x_unit_means <- ave(panel_x, unit_id)
y_demeaned <- panel_y - y_unit_means
x_demeaned <- panel_x - x_unit_means

beta_within <- sum(x_demeaned * y_demeaned) / sum(x_demeaned^2)
y_hat_within <- beta_within * x_demeaned
ss_res_within <- sum((y_demeaned - y_hat_within)^2)
ss_tot_within <- sum(y_demeaned^2)
within_r2_manual <- 1 - (ss_res_within / ss_tot_within)

# Built-in Regression Benchmarking
lm_fit <- lm(y ~ x1 + x2)
lm_sum <- summary(lm_fit)

# ------------------------------------------------------------------------------
# Part 3: One-Way ANOVA
# ------------------------------------------------------------------------------
group <- factor(rep(c("Treatment_A", "Treatment_B", "Control"), each = 20))
anova_y <- c(rnorm(20, 10, 2), rnorm(20, 14, 2), rnorm(20, 9, 2))
df_anova <- data.frame(group = group, y = anova_y)

grand_mean <- mean(anova_y)
grp_means <- tapply(anova_y, group, mean)
grp_counts <- tapply(anova_y, group, length)
k_groups <- length(grp_means)
n_total_aov <- length(anova_y)

SSB_manual <- sum(grp_counts * (grp_means - grand_mean)^2)
SSW_manual <- sum(tapply(anova_y, group, function(vals) sum((vals - mean(vals))^2)))
df_b_manual <- k_groups - 1
df_w_manual <- n_total_aov - k_groups

MSB_manual <- SSB_manual / df_b_manual
MSW_manual <- SSW_manual / df_w_manual
F_stat_manual <- MSB_manual / MSW_manual
p_anova_manual <- 1 - pf(F_stat_manual, df1 = df_b_manual, df2 = df_w_manual)

aov_res <- summary(aov(y ~ group, data = df_anova))[[1]]

# ------------------------------------------------------------------------------
# Output Validation
# ------------------------------------------------------------------------------
cat("=== Chapter 09: Regression, Model Metrics & ANOVA ===\n")
cat(sprintf("Pearson r:      Manual = %.6f | Built-in = %.6f\n\n", r_manual, r_builtin))

cat("--- Multiple Linear Regression Coefs ---\n")
cat("Manual Beta:\n"); print(beta_manual)
cat("Built-in Coefs:\n"); print(coef(lm_fit))

cat("\n--- Model Quality Metrics ---\n")
cat(sprintf("R^2:            Manual = %.6f | Built-in = %.6f\n", r2_manual, lm_sum$r.squared))
cat(sprintf("Adjusted R^2:   Manual = %.6f | Built-in = %.6f\n", adj_r2_manual, lm_sum$adj.r.squared))
cat(sprintf("Within R^2:     Manual = %.6f (Fixed Effects De-meaning)\n", within_r2_manual))
cat(sprintf("RMSE:           Manual = %.6f | Residual SE = %.6f\n", rmse_manual, lm_sum$sigma))
cat(sprintf("MAE:            Manual = %.6f\n", mae_manual))
cat(sprintf("AIC:            Manual = %.6f | Built-in = %.6f\n", aic_manual, AIC(lm_fit)))
cat(sprintf("AICc:           Manual = %.6f\n\n", aicc_manual))

cat("--- One-Way ANOVA ---\n")
cat(sprintf("F-statistic:    Manual = %.6f | Built-in = %.6f\n", F_stat_manual, aov_res["group", "F value"]))
cat(sprintf("p-value:        Manual = %.6e | Built-in = %.6e\n", p_anova_manual, aov_res["group", "Pr(>F)"]))

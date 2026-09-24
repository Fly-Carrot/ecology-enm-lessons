# ==============================================================================
# File: 05.one_sample_ttest.r
# Purpose: One-sample Student's t-test and confidence intervals from scratch
# ==============================================================================

set.seed(42)

# 1. Dataset (e.g., test scores)
x <- c(78, 82, 85, 79, 90, 88, 76, 84, 89, 91, 80, 83)
mu_0 <- 80
alpha <- 0.05
n <- length(x)

# 2. Manual calculation
x_bar <- sum(x) / n
s2 <- sum((x - x_bar)^2) / (n - 1)
s <- sqrt(s2)
se <- s / sqrt(n)
df_manual <- n - 1

t_stat_manual <- (x_bar - mu_0) / se
p_val_manual <- 2 * (1 - pt(abs(t_stat_manual), df = df_manual))

t_crit <- qt(1 - alpha / 2, df = df_manual)
ci_lower_manual <- x_bar - t_crit * se
ci_upper_manual <- x_bar + t_crit * se

# 3. Built-in R verification
t_builtin <- t.test(x, mu = mu_0, conf.level = 1 - alpha)

cat("=== Chapter 05: One-Sample t-Test ===\n")
cat(sprintf("t-statistic:     Manual = %.6f | Built-in = %.6f\n", t_stat_manual, t_builtin$statistic))
cat(sprintf("Degrees of Free: Manual = %d        | Built-in = %d\n", df_manual, t_builtin$parameter))
cat(sprintf("p-value:         Manual = %.6f | Built-in = %.6f\n", p_val_manual, t_builtin$p.value))
cat(sprintf("95%% CI Lower:    Manual = %.6f | Built-in = %.6f\n", ci_lower_manual, t_builtin$conf.int[1]))
cat(sprintf("95%% CI Upper:    Manual = %.6f | Built-in = %.6f\n", ci_upper_manual, t_builtin$conf.int[2]))

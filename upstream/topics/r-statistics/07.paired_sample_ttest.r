# ==============================================================================
# File: 07.paired_sample_ttest.r
# Purpose: Paired / dependent two-sample t-test implementation
# ==============================================================================

# 1. Paired Dataset (e.g., Blood Pressure Before and After Treatment)
before <- c(142, 138, 150, 145, 132, 158, 140, 135)
after  <- c(135, 130, 142, 139, 130, 148, 132, 128)
n <- length(before)

# 2. Manual Difference Analysis
d <- before - after
d_bar <- sum(d) / n
sd_d <- sqrt(sum((d - d_bar)^2) / (n - 1))
se_d <- sd_d / sqrt(n)
df_manual <- n - 1

t_stat_manual <- d_bar / se_d
p_val_manual <- 2 * (1 - pt(abs(t_stat_manual), df = df_manual))

# 3. Built-in R verification
t_paired_r <- t.test(before, after, paired = TRUE)

cat("=== Chapter 07: Paired Samples t-Test ===\n")
cat(sprintf("Mean Difference (d_bar): %.4f\n", d_bar))
cat(sprintf("SD of Differences (s_d): %.4f\n", sd_d))
cat(sprintf("t-statistic: Manual = %.6f | Built-in = %.6f\n", t_stat_manual, t_paired_r$statistic))
cat(sprintf("Degrees of Free: Manual = %d        | Built-in = %d\n", df_manual, t_paired_r$parameter))
cat(sprintf("p-value:         Manual = %.6f | Built-in = %.6f\n", p_val_manual, t_paired_r$p.value))

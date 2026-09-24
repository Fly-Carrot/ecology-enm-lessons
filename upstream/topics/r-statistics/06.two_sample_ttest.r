# ==============================================================================
# File: 06.two_sample_ttest.r
# Purpose: Independent two-sample t-test (Pooled Student's & Welch's)
# ==============================================================================

# 1. Sample Data
g1 <- c(24.5, 26.1, 23.8, 25.0, 27.2, 24.9, 25.8)
g2 <- c(21.2, 22.8, 20.5, 23.1, 21.9, 20.8)

n1 <- length(g1); n2 <- length(g2)
m1 <- sum(g1) / n1; m2 <- sum(g2) / n2
s1_sq <- sum((g1 - m1)^2) / (n1 - 1)
s2_sq <- sum((g2 - m2)^2) / (n2 - 1)

# 2. Case A: Pooled t-test (Equal Variance assumed)
sp_sq <- ((n1 - 1) * s1_sq + (n2 - 1) * s2_sq) / (n1 + n2 - 2)
se_pooled <- sqrt(sp_sq * (1/n1 + 1/n2))
t_pooled_manual <- (m1 - m2) / se_pooled
df_pooled_manual <- n1 + n2 - 2
p_pooled_manual <- 2 * (1 - pt(abs(t_pooled_manual), df = df_pooled_manual))

# 3. Case B: Welch's t-test (Unequal Variance)
se_welch <- sqrt(s1_sq / n1 + s2_sq / n2)
t_welch_manual <- (m1 - m2) / se_welch
df_welch_manual <- (s1_sq / n1 + s2_sq / n2)^2 / 
  (((s1_sq / n1)^2 / (n1 - 1)) + ((s2_sq / n2)^2 / (n2 - 1)))
p_welch_manual <- 2 * (1 - pt(abs(t_welch_manual), df = df_welch_manual))

# 4. Built-in comparison
t_pooled_r <- t.test(g1, g2, var.equal = TRUE)
t_welch_r  <- t.test(g1, g2, var.equal = FALSE)

cat("=== Chapter 06: Independent Two-Sample t-Test ===\n")
cat("--- Case A: Equal Variance (Pooled) ---\n")
cat(sprintf("t-stat: Manual = %.6f | Built-in = %.6f\n", t_pooled_manual, t_pooled_r$statistic))
cat(sprintf("df:     Manual = %-8d | Built-in = %d\n", df_pooled_manual, t_pooled_r$parameter))
cat(sprintf("p-val:  Manual = %.6f | Built-in = %.6f\n\n", p_pooled_manual, t_pooled_r$p.value))

cat("--- Case B: Unequal Variance (Welch's) ---\n")
cat(sprintf("t-stat: Manual = %.6f | Built-in = %.6f\n", t_welch_manual, t_welch_r$statistic))
cat(sprintf("df:     Manual = %.6f | Built-in = %.6f\n", df_welch_manual, t_welch_r$parameter))
cat(sprintf("p-val:  Manual = %.6f | Built-in = %.6f\n", p_welch_manual, t_welch_r$p.value))

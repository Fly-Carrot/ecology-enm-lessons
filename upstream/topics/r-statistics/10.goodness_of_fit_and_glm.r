# ==============================================================================
# File: 10.goodness_of_fit_and_glm.r
# Purpose: Chi-Square, Contingency Table, Wilcoxon Non-parametric & IRLS GLM
# ==============================================================================

set.seed(42)

# ------------------------------------------------------------------------------
# Part 1: Chi-Square Test of Independence (2x2 Table)
# ------------------------------------------------------------------------------
# Observed contingency matrix
# Rows: Treatment vs Control; Cols: Outcome Success vs Failure
obs_mat <- matrix(c(45, 15, 30, 30), nrow = 2, byrow = TRUE)
row_totals <- rowSums(obs_mat)
col_totals <- colSums(obs_mat)
grand_total <- sum(obs_mat)

# Expected frequencies matrix: E_ij = (Row_i * Col_j) / N
exp_mat <- (row_totals %*% t(col_totals)) / grand_total

# Chi-square statistic: sum((O - E)^2 / E)
chi2_stat_manual <- sum((obs_mat - exp_mat)^2 / exp_mat)
df_chi2_manual <- (nrow(obs_mat) - 1) * (ncol(obs_mat) - 1)
p_chi2_manual <- 1 - pchisq(chi2_stat_manual, df = df_chi2_manual)

chisq_builtin <- chisq.test(obs_mat, correct = FALSE)

# ------------------------------------------------------------------------------
# Part 2: Non-parametric Wilcoxon Rank-Sum Test
# ------------------------------------------------------------------------------
grp_a <- c(3.2, 4.5, 6.1, 7.8, 8.0)
grp_b <- c(1.5, 2.3, 3.0, 4.0, 5.2, 5.8)
n_a <- length(grp_a); n_b <- length(grp_b)

combined_data <- data.frame(
  val = c(grp_a, grp_b),
  grp = c(rep("A", n_a), rep("B", n_b))
)
combined_data$rank <- rank(combined_data$val)

# Sum of ranks for Group A
w_manual <- sum(combined_data$rank[combined_data$grp == "A"])
# Mann-Whitney U statistic for Group A
u_manual <- w_manual - (n_a * (n_a + 1)) / 2

wilcox_builtin <- wilcox.test(grp_a, grp_b, exact = TRUE)

# ------------------------------------------------------------------------------
# Part 3: GLM Logistic Regression via Newton-Raphson / IRLS
# ------------------------------------------------------------------------------
n_glm <- 100
x_val <- rnorm(n_glm, 0, 1)
true_prob <- 1 / (1 + exp(-( -0.5 + 1.5 * x_val)))
y_bin <- rbinom(n_glm, size = 1, prob = true_prob)

X_mat <- cbind(Intercept = 1, X = x_val)
beta_irls <- matrix(0, nrow = ncol(X_mat), ncol = 1) # initialize beta at 0

# Iteratively Reweighted Least Squares loop
for (iter in 1:10) {
  eta <- as.vector(X_mat %*% beta_irls)
  p <- 1 / (1 + exp(-eta))
  w <- p * (1 - p)
  W_mat <- diag(w)
  gradient <- t(X_mat) %*% (y_bin - p)
  hessian <- - t(X_mat) %*% W_mat %*% X_mat
  beta_update <- solve(-hessian) %*% gradient
  beta_irls <- beta_irls + beta_update
  if (max(abs(beta_update)) < 1e-8) break
}

glm_builtin <- glm(y_bin ~ x_val, family = binomial(link = "logit"))

# ------------------------------------------------------------------------------
# Print Comparisons
# ------------------------------------------------------------------------------
cat("=== Chapter 10: Contingency, Non-parametric & GLM ===\n")
cat("--- Chi-Square Test of Independence ---\n")
cat(sprintf("Chi2 Stat:  Manual = %.6f | Built-in = %.6f\n", chi2_stat_manual, chisq_builtin$statistic))
cat(sprintf("p-value:    Manual = %.6e | Built-in = %.6e\n\n", p_chi2_manual, chisq_builtin$p.value))

cat("--- Wilcoxon / Mann-Whitney Test ---\n")
cat(sprintf("Wilcoxon W: Manual = %.1f | Built-in (W) = %.1f\n\n", u_manual, wilcox_builtin$statistic))

cat("--- GLM (Logistic Regression) Coefficients ---\n")
cat("Manual IRLS Beta:\n"); print(as.vector(beta_irls))
cat("Built-in glm():\n"); print(coef(glm_builtin))

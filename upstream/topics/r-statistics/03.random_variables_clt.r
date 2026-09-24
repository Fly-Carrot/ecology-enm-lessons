# ==============================================================================
# File: 03.random_variables_clt.r
# Purpose: Properties of expectation, variance, LLN, and CLT simulation
# ==============================================================================

set.seed(42)

# 1. Theoretical parameters for Exponential distribution Exp(lambda)
lambda <- 0.5
theo_mean <- 1 / lambda       # mu = 2.0
theo_var  <- 1 / (lambda^2)   # sigma^2 = 4.0
theo_sd   <- sqrt(theo_var)   # sigma = 2.0

# 2. Central Limit Theorem Simulation
n_reps <- 10000
sample_sizes <- c(2, 5, 30, 100)

cat("=== Chapter 03: Law of Large Numbers & Central Limit Theorem ===\n")
cat(sprintf("True Population: Exp(lambda = %.2f) | Mean = %.2f | SD = %.2f\n\n", 
            lambda, theo_mean, theo_sd))

for (n in sample_sizes) {
  # Generate n_reps samples each of size n
  samples_matrix <- matrix(rexp(n * n_reps, rate = lambda), nrow = n_reps, ncol = n)
  
  # Manual computation of sample means: rowSums / n
  sample_means <- rowSums(samples_matrix) / n
  
  # Standardized CLT statistic: Z = (x_bar - mu) / (sigma / sqrt(n))
  z_scores <- (sample_means - theo_mean) / (theo_sd / sqrt(n))
  
  # Compute empirical moments of Z
  z_mean <- sum(z_scores) / n_reps
  z_var  <- sum((z_scores - z_mean)^2) / (n_reps - 1)
  z_skew <- (sum((z_scores - z_mean)^3) / n_reps) / (z_var^(1.5))
  
  cat(sprintf("Sample Size n = %-3d | Mean(Z) = %7.4f (theo: 0) | Var(Z) = %6.4f (theo: 1) | Skewness = %7.4f\n",
              n, z_mean, z_var, z_skew))
}

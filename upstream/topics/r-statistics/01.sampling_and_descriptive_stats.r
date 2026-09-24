# ==============================================================================
# File: 01.sampling_and_descriptive_stats.r
# Purpose: Basic sampling simulation and first-principle descriptive statistics
# ==============================================================================

set.seed(42)

# 1. Simulate a population (e.g., adult heights in cm)
population_size <- 100000
true_mean <- 172.5
true_sd <- 8.2
population <- rnorm(population_size, mean = true_mean, sd = true_sd)

# 2. Draw a simple random sample (SRS)
n <- 30
sample_data <- sample(population, size = n, replace = FALSE)

# 3. First-principle manual calculation of descriptive statistics
# Mean: sum(x) / n
manual_sum <- sum(sample_data)
manual_mean <- manual_sum / n

# Variance: sum((x - mean)^2) / (n - 1)
deviations <- sample_data - manual_mean
squared_deviations <- deviations^2
manual_sum_sq <- sum(squared_deviations)
manual_var <- manual_sum_sq / (n - 1)

# Standard deviation: sqrt(variance)
manual_sd <- sqrt(manual_var)

# Standard error of the mean: sd / sqrt(n)
manual_se <- manual_sd / sqrt(n)

# 4. Built-in R functions for validation
builtin_mean <- mean(sample_data)
builtin_var <- var(sample_data)
builtin_sd <- sd(sample_data)
builtin_se <- builtin_sd / sqrt(length(sample_data))

# 5. Print comparison results
cat("=== Chapter 01: Descriptive Statistics & Sampling ===\n")
cat(sprintf("Sample Size (n): %d\n", n))
cat(sprintf("Mean:               Manual = %.6f | Built-in = %.6f | Diff = %.2e\n", 
            manual_mean, builtin_mean, abs(manual_mean - builtin_mean)))
cat(sprintf("Variance (s^2):     Manual = %.6f | Built-in = %.6f | Diff = %.2e\n", 
            manual_var, builtin_var, abs(manual_var - builtin_var)))
cat(sprintf("Std Deviation (s):  Manual = %.6f | Built-in = %.6f | Diff = %.2e\n", 
            manual_sd, builtin_sd, abs(manual_sd - builtin_sd)))
cat(sprintf("Std Error (SE):     Manual = %.6f | Built-in = %.6f | Diff = %.2e\n", 
            manual_se, builtin_se, abs(manual_se - builtin_se)))

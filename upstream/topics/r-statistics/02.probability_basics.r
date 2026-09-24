# ==============================================================================
# File: 02.probability_basics.r
# Purpose: Classical probability, combinatorics, and Monte Carlo empirical limit
# ==============================================================================

set.seed(42)

# 1. Classical Probability: Two fair 6-sided dice, event A: sum = 7
sample_space <- expand.grid(die1 = 1:6, die2 = 1:6)
sample_space$sum <- sample_space$die1 + sample_space$die2

total_outcomes <- nrow(sample_space) # |Omega| = 36
favorable_outcomes <- sum(sample_space$sum == 7) # |A| = 6

theoretical_prob <- favorable_outcomes / total_outcomes

# 2. Empirical Probability (Monte Carlo Simulation)
sim_sizes <- c(10, 100, 1000, 10000, 100000)
empirical_probs <- numeric(length(sim_sizes))

for (i in seq_along(sim_sizes)) {
  n_trials <- sim_sizes[i]
  roll1 <- sample(1:6, size = n_trials, replace = TRUE)
  roll2 <- sample(1:6, size = n_trials, replace = TRUE)
  empirical_probs[i] <- sum((roll1 + roll2) == 7) / n_trials
}

# 3. Bayes' Theorem Manual Implementation
# P(Disease|Positive) = P(Positive|Disease)*P(Disease) / P(Positive)
# Prior P(D) = 0.01, Sensitivity P(+|D) = 0.95, Specificity P(-|not D) = 0.90 -> P(+|not D) = 0.10
p_d <- 0.01
p_pos_given_d <- 0.95
p_pos_given_not_d <- 0.10
p_not_d <- 1 - p_d

p_pos <- (p_pos_given_d * p_d) + (p_pos_given_not_d * p_not_d)
posterior_bayes <- (p_pos_given_d * p_d) / p_pos

cat("=== Chapter 02: Probability Foundations ===\n")
cat(sprintf("Theoretical Probability P(Sum = 7): %d / %d = %.6f\n", 
            favorable_outcomes, total_outcomes, theoretical_prob))
cat("Empirical Convergence:\n")
for (i in seq_along(sim_sizes)) {
  cat(sprintf("  N = %-7d | Empirical P = %.6f | Error = %.6f\n", 
              sim_sizes[i], empirical_probs[i], abs(empirical_probs[i] - theoretical_prob)))
}
cat(sprintf("\nBayes Posterior P(Disease | Positive): %.6f\n", posterior_bayes))

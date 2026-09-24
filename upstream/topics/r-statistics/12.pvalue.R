set.seed(42)
mu_true <- 10.05
mu_0 <- 10
sigma <- 1

sample_sizes <- c(20, 100, 1000, 10000, 50000)

for (n in sample_sizes) {
  x <- rnorm(n, mean = mu_true, sd = sigma)
  x_bar <- mean(x)
  se <- sd(x) / sqrt(n)
  t_val <- (x_bar - mu_0) / se
  p_val <- 2 * (1 - pt(abs(t_val), df = n - 1))
  
  cat(sprintf("样本量 n = %-6d | 样本均值 = %.4f | t 统计量 = %7.3f | p-value = %.4e\n", 
              n, x_bar, t_val, p_val))
}

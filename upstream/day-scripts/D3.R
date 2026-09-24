# ==============================================================================
# Day 3: Variable Screening and Model Evaluation (ROC/AUC)
# ==============================================================================

# Install required packages if missing
# install.packages(c("usdm", "pROC", "ggplot2"))

library(terra)
library(maxnet)
library(usdm)        # For Variance Inflation Factor (VIF) calculations
library(pROC)        # For ROC and AUC calculations
library(ggplot2)     # For high-quality, publication-ready plotting
library(data.table)

# Note: We assume 'model_dt' (the combined presence-background data.table) 
# and 'clim_study_area' (SpatRaster) from Day 2 are loaded.

# ------------------------------------------------------------------------------
# Step 1: Dealing with Multicollinearity (Variable Screening)
# ------------------------------------------------------------------------------
cat("Screening environmental variables for collinearity...\n")

# Isolate the environmental predictors only
env_dt <- model_dt[, .SD, .SDcols = !c("lon", "lat", "presence")]

# 1.1 Quick look at the correlation matrix
cor_matrix <- cor(env_dt, method = "pearson")
# print(round(cor_matrix, 2))

# 1.2 Use Variance Inflation Factor (VIF) to automatically select variables
# A common threshold for VIF is 10 (or sometimes 5 in strict ecological studies)
# Note: usdm::vifstep expects a standard data.frame
vif_selection <- vifstep(as.data.frame(env_dt), th = 10)

cat("Variables retained after VIF screening:\n")
print(vif_selection@results$Variables)

# Extract the names of the retained variables
selected_vars <- as.character(vif_selection@results$Variables)

# Subset the original data.table to keep only coordinates, presence, and selected vars
cols_to_keep <- c("lon", "lat", "presence", selected_vars)
model_dt_selected <- model_dt[, ..cols_to_keep]

# ------------------------------------------------------------------------------
# Step 2: Data Splitting (Train vs. Test)
# ------------------------------------------------------------------------------
cat("Splitting data into 70% training and 30% testing...\n")

# Set a random seed for reproducibility
set.seed(42)

# Generate row indices for the training set (70%)
train_indices <- sample(seq_len(nrow(model_dt_selected)), 
                        size = floor(0.7 * nrow(model_dt_selected)))

# Use data.table row subsetting to split the data
train_dt <- model_dt_selected[train_indices]
test_dt  <- model_dt_selected[-train_indices]

cat("Training records:", nrow(train_dt), "\n")
cat("Testing records:", nrow(test_dt), "\n")

# ------------------------------------------------------------------------------
# Step 3: Refitting the Model (Training Set Only)
# ------------------------------------------------------------------------------
cat("Refitting Maxent model on the training set with selected variables...\n")

p_train <- train_dt$presence
env_train <- train_dt[, .SD, .SDcols = !c("lon", "lat", "presence")]

# Fit the Maxent model using only the independent, selected variables
maxent_model_final <- maxnet(p = p_train, data = env_train)

# ------------------------------------------------------------------------------
# Step 4: Evaluating Model Performance (Test Set)
# ------------------------------------------------------------------------------
cat("Evaluating model on the independent testing set...\n")

# Extract the environmental variables for the test set
env_test <- test_dt[, .SD, .SDcols = !c("lon", "lat", "presence")]

# Predict probabilities (cloglog) for the test set
test_dt[, pred_cloglog := predict(maxent_model_final, newdata = env_test, type = "cloglog")]

# Calculate ROC and AUC using the pROC package
# Response is the true presence/background (1/0), predictor is our modeled probability
roc_obj <- roc(response = test_dt$presence, predictor = test_dt$pred_cloglog, quiet = TRUE)

# Extract the AUC value
auc_value <- round(auc(roc_obj), 3)
cat("Model AUC on testing set:", auc_value, "\n")

# ------------------------------------------------------------------------------
# Step 5: Publication-Ready Visualization of the ROC Curve
# ------------------------------------------------------------------------------
cat("Plotting ROC Curve using ggplot2...\n")

# Extract specificity and sensitivity from the ROC object for ggplot
roc_dt <- data.table(
  specificity = roc_obj$specificities,
  sensitivity = roc_obj$sensitivities
)

# In ROC plots, the x-axis is usually 1 - Specificity (False Positive Rate)
roc_dt[, false_positive_rate := 1 - specificity]

# Create the plot
roc_plot <- ggplot(roc_dt, aes(x = false_positive_rate, y = sensitivity)) +
  geom_line(color = "blue", linewidth = 1.2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50") +
  labs(
    title = "Receiver Operating Characteristic (ROC) Curve",
    subtitle = paste("Area Under Curve (AUC) =", auc_value),
    x = "False Positive Rate (1 - Specificity)",
    y = "True Positive Rate (Sensitivity)"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.title = element_text(size = 12)
  )

# Display the plot
print(roc_plot)

# ------------------------------------------------------------------------------
# Step 6: Demystifying the ROC Curve and Threshold Dynamics
# ------------------------------------------------------------------------------
cat("Simulating continuous threshold changes to compute Sensitivity, Specificity, and TSS...\n")

# Note: We assume 'test_dt' from the previous step is available, 
# containing 'presence' (1/0) and 'pred_cloglog' (predicted probabilities).

# Create a sequence of thresholds from 0 to 1
threshold_seq <- seq(0, 1, by = 0.01)

# Initialize a data.table to store the evaluation metrics for each threshold
eval_metrics_dt <- data.table(threshold = threshold_seq)

# Total number of true presences and true absences in the test set
total_presences <- sum(test_dt$presence == 1)
total_absences  <- sum(test_dt$presence == 0)

# Calculate metrics for each threshold using lapply (vectorized approach)
# Sensitivity (True Positive Rate) = TP / Total True Presences
# Specificity (True Negative Rate) = TN / Total True Absences
# TSS = Sensitivity + Specificity - 1
eval_metrics_dt[, c("sensitivity", "specificity") := {
  
  sens <- sapply(threshold, function(th) {
    true_positives <- sum(test_dt$presence == 1 & test_dt$pred_cloglog >= th)
    return(true_positives / total_presences)
  })
  
  spec <- sapply(threshold, function(th) {
    true_negatives <- sum(test_dt$presence == 0 & test_dt$pred_cloglog < th)
    return(true_negatives / total_absences)
  })
  
  list(sens, spec)
}]

# Calculate True Skill Statistic (TSS)
eval_metrics_dt[, TSS := sensitivity + specificity - 1]

# Find the threshold that maximizes TSS (a common way to binarize continuous SDM outputs)
max_tss_row <- eval_metrics_dt[which.max(TSS)]
cat("Optimal Threshold (Max TSS):", max_tss_row$threshold, 
    "| Max TSS:", round(max_tss_row$TSS, 3), "\n")

# ------------------------------------------------------------------------------
# Visualization 1: Threshold Dynamics (Sensitivity, Specificity, TSS)
# ------------------------------------------------------------------------------
cat("Plotting Threshold vs. Evaluation Metrics...\n")

# Reshape the data.table from wide to long format using 'melt' for ggplot2
metrics_long_dt <- melt(eval_metrics_dt, 
                        id.vars = "threshold", 
                        measure.vars = c("sensitivity", "specificity", "TSS"),
                        variable.name = "metric", 
                        value.name = "value")

# Plot the dynamics
dynamics_plot <- ggplot(metrics_long_dt, aes(x = threshold, y = value, color = metric)) +
  geom_line(size = 1.2) +
  geom_vline(xintercept = max_tss_row$threshold, linetype = "dashed", color = "black") +
  annotate("text", x = max_tss_row$threshold + 0.05, y = 0.05, 
           label = paste("Max TSS Threshold\n=", max_tss_row$threshold), hjust = 0) +
  scale_color_manual(values = c("sensitivity" = "#0072B2", 
                                "specificity" = "#D55E00", 
                                "TSS" = "#009E73")) +
  labs(title = "Dynamics of Evaluation Metrics across Thresholds",
       x = "Continuous Probability Threshold",
       y = "Metric Value") +
  theme_bw() +
  theme(plot.title = element_text(face = "bold", size = 14),
        legend.position = "bottom",
        legend.title = element_blank())

print(dynamics_plot)

# ------------------------------------------------------------------------------
# Visualization 2: Reconstructing the ROC Curve Manually
# ------------------------------------------------------------------------------
cat("Plotting the manual ROC curve from our simulated data.table...\n")

# In an ROC plot, X-axis is False Positive Rate (1 - Specificity) 
# and Y-axis is True Positive Rate (Sensitivity)
eval_metrics_dt[, false_positive_rate := 1 - specificity]

manual_roc_plot <- ggplot(eval_metrics_dt, aes(x = false_positive_rate, y = sensitivity)) +
  geom_line(color = "purple", size = 1.2) +
  geom_point(data = max_tss_row, aes(x = 1 - specificity, y = sensitivity), 
             color = "red", size = 4) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50") +
  annotate("text", x = (1 - max_tss_row$specificity) + 0.05, y = max_tss_row$sensitivity - 0.05, 
           label = "Optimal Cutoff\n(Max TSS)", color = "red", hjust = 0) +
  labs(title = "Manually Reconstructed ROC Curve",
       subtitle = "Every point on the curve represents a different threshold",
       x = "False Positive Rate (1 - Specificity)",
       y = "True Positive Rate (Sensitivity)") +
  theme_bw() +
  theme(plot.title = element_text(face = "bold", size = 14))

print(manual_roc_plot)

# ==============================================================================
# Day 6: Sensitivity Analysis (Partitions, Background, RM, Feature Classes)
# ==============================================================================

# Install required packages if missing
# install.packages(c("ENMeval", "terra", "data.table", "ggplot2"))

library(ENMeval)
library(terra)
library(data.table)
library(ggplot2)

# Note: Assumes 'occurrences_clean' (data.table) and 'env_selected' (SpatRaster) are loaded.

# ------------------------------------------------------------------------------
# Step 1: Preparing Different Background Sets
# ------------------------------------------------------------------------------
cat("Preparing Global and Buffered Background points...\n")

# 1.1 Global Random Background (Sampled across the entire study extent)
bg_global_pts <- spatSample(env_selected[[1]], size = 10000, method = "random", 
                            as.points = TRUE, na.rm = TRUE)
bg_global <- as.data.frame(crds(bg_global_pts))
colnames(bg_global)<-c("lon", "lat")
# 1.2 Buffered Background (Sampled only within 500km of occurrences)
# Convert occurrences to SpatVector
occ_pts <- vect(occurrences_clean, geom = c("lon", "lat"), crs = "epsg:4326")

# Buffer occurrences by 500,000 meters (500km)
# Note: terra handles meters for EPSG:4326 buffers natively in recent versions
occ_buffer <- buffer(occ_pts, width = 500000)
occ_buffer_merged <- aggregate(occ_buffer) # Merge overlapping buffers

# Mask the environment with the buffer and sample background
env_buffered <- mask(env_selected[[1]], occ_buffer_merged)
bg_buffered_pts <- spatSample(env_buffered, size = 10000, method = "random", 
                              as.points = TRUE, na.rm = TRUE)
bg_buffered <- as.data.frame(crds(bg_buffered_pts))
colnames(bg_buffered)<-c("lon", "lat")
occ_coords <- as.data.frame(occurrences_clean[, .(lon, lat)])

# ------------------------------------------------------------------------------
# Step 2: Defining the Tuning Grid and Running Scenarios
# ------------------------------------------------------------------------------
cat("Running multi-scenario ENMevaluate grid. This will take some time...\n")

# To keep computation time reasonable for teaching, we test a focused grid
grid_test <- list(fc = c("L", "LQ"), rm = c(0.5, 1, 2, 3))

# Scenario A: Random k-fold + Global BG (Often yields artificially high AUC)
cat("Running Scenario A: Random k-fold + Global BG...\n")
run_A <- ENMevaluate(occs = occ_coords, envs = env_selected, bg = bg_global, 
                     algorithm = "maxnet", partitions = "randomkfold", 
                     tune.args = grid_test, quiet = TRUE)

# Scenario B: Spatial Block + Global BG (Controls spatial autocorrelation)
cat("Running Scenario B: Block + Global BG...\n")
run_B <- ENMevaluate(occs = occ_coords, envs = env_selected, bg = bg_global, 
                     algorithm = "maxnet", partitions = "block", 
                     tune.args = grid_test, quiet = TRUE)

# Scenario C: Spatial Block + Buffered BG (Controls spatial auto. & sampling bias)
cat("Running Scenario C: Block + Buffered BG...\n")
run_C <- ENMevaluate(occs = occ_coords, envs = env_selected, bg = bg_buffered, 
                     algorithm = "maxnet", partitions = "block", 
                     tune.args = grid_test, quiet = TRUE)

# ------------------------------------------------------------------------------
# Step 3: Aggregating Results using data.table
# ------------------------------------------------------------------------------
cat("Aggregating results for comparison...\n")

# Convert results slots to data.tables and tag them with their scenario names
dt_A <- as.data.table(run_A@results)[, Scenario := "A: Random-kFold + Global BG"]
dt_B <- as.data.table(run_B@results)[, Scenario := "B: Block + Global BG"]
dt_C <- as.data.table(run_C@results)[, Scenario := "C: Block + Buffered BG"]

# Efficiently bind all scenarios together into a single master data.table
results_master <- rbindlist(list(dt_A, dt_B, dt_C))

# Create explicit columns for FC and RM for easier plotting in ggplot2
#results_master[, fc := tstrsplit(tune.args, "_")[[1]]]
#results_master[, rm := as.numeric(tstrsplit(tune.args, "_")[[2]])]

# ------------------------------------------------------------------------------
# Step 4: Visualizing the Impacts
# ------------------------------------------------------------------------------
cat("Generating comparative plots...\n")

# Ensure scenarios plot in the correct order
results_master[, Scenario := factor(Scenario, levels = c("A: Random-kFold + Global BG", 
                                                         "B: Block + Global BG", 
                                                         "C: Block + Buffered BG"))]

# Plot 1: The Impact on Validation AUC
# Goal: Show how random k-fold inflates AUC, and how buffered BG lowers the baseline
plot_auc <- ggplot(results_master, aes(x = as.factor(rm), y = auc.val.avg, 
                                       color = Scenario, group = Scenario)) +
  geom_point(size = 3) +
  geom_line(size = 1) +
  facet_grid(~ fc) + # Facet by Feature Classes
  labs(title = "Impact of Partitions and BG on Validation AUC",
       subtitle = "Facets = Feature Classes (FC) | X-axis = Regularization Multiplier (RM)",
       x = "Regularization Multiplier (RM)",
       y = "Mean Validation AUC") +
  theme_bw() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold", size = 14))

print(plot_auc)

# Plot 2: The Impact on Overfitting (AUC Difference)
# Goal: Show how complex models (LQH) + low RM (0.5) lead to massive overfitting (high AUC diff),
# especially revealed by spatial block partitioning.
plot_overfit <- ggplot(results_master, aes(x = as.factor(rm), y = auc.diff.avg, 
                                           color = Scenario, group = Scenario)) +
  geom_point(size = 3) +
  geom_line(size = 1) +
  facet_grid(~ fc) + 
  labs(title = "Detecting Overfitting: AUC Difference (Train AUC - Test AUC)",
       subtitle = "Higher values indicate severe overfitting. Notice how Block partitions reveal this.",
       x = "Regularization Multiplier (RM)",
       y = "AUC Difference (Overfitting Metric)") +
  theme_bw() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold", size = 14))

print(plot_overfit)

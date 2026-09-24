# ==============================================================================
# Day 5: Advanced Model Tuning with ENMeval
# ==============================================================================

# Install ENMeval if missing (this may take a moment as it has several dependencies)
# install.packages(c("ENMeval", "data.table", "terra", "maxnet"))

library(ENMeval)
library(terra)
library(data.table)

# Note: We assume the following from previous days:
# 1. 'occurrences_clean' (data.table with lon, lat)
# 2. 'bg_dt' (data.table with background lon, lat)
# 3. 'clim_study_area' (SpatRaster containing the environment)
# 4. 'selected_vars' (character vector of non-collinear variables)

# ------------------------------------------------------------------------------
# Step 1 & 2: Preparing Data for ENMeval
# ------------------------------------------------------------------------------
cat("Extracting coordinate matrices for ENMeval...\n")

# ENMeval strictly requires coordinates as data.frames or matrices (lon, lat)
# We subset our data.tables to ensure only the coordinate columns are passed
occ_coords <- as.data.frame(occurrences_clean[, .(lon, lat)])
bg_coords  <- as.data.frame(bg_dt[, .(lon, lat)])
env_selected <- clim_study_area[[selected_vars]]
# ------------------------------------------------------------------------------
# Step 3 & 4: Setting up and Executing the Evaluation Grid
# ------------------------------------------------------------------------------
cat("Starting the ENMeval tuning process. This may take several minutes...\n")

# We define our tuning grid:
# - fc: Feature Classes. L=Linear, Q=Quadratic, H=Hinge.
# - rm: Regularization Multiplier. Lower = more complex, Higher = smoother/more penalized.
tune_grid <- list(fc = c("L", "LQ"), 
                  rm = seq(0.5, 3.0, by = 0.5))

cat("Checking the distribution of occurrences across spatial blocks...\n")

# Use ENMeval's built-in partitioning function to simulate the 'block' split
block_split <- get.block(occ = occ_coords, bg = bg_coords)

# Count how many occurrence points fall into each of the 4 folds
# If any group has very few points (e.g., < 10), complex models will crash glmnet
block_counts <- table(block_split$occs.grp)
occ_coords_bak<-occ_coords
occ_coords_bak$block<-block_split$occs.grp
ggplot(occ_coords_bak)+geom_point(aes(x=lon, y=lat, color=factor(block)))
print(block_counts)

# Run ENMevaluate
# 'partitions = "block"' splits the study area into 4 spatial quadrants based on lat/lon
# This is a robust way to test if the model predicts well in novel geographic space
eval_results <- ENMevaluate(occs = occ_coords, 
                            envs = env_selected, 
                            bg = bg_coords, 
                            algorithm = "maxnet", 
                            partitions = "randomkfold", 
                            tune.args = tune_grid,
                            parallel = FALSE) # Set parallel=TRUE if you have many cores configured

# ------------------------------------------------------------------------------
# Step 5: Selecting the Optimal Model using data.table
# ------------------------------------------------------------------------------
cat("Evaluation complete. Extracting results...\n")

# Convert the results slot into a data.table for easy querying
res_dt <- as.data.table(eval_results@results)

# The most robust metric for Maxent model selection is often AICc.
# We look for the model with the lowest AICc score (i.e., delta.AICc == 0).
# In case of a tie, we break it by choosing the lowest omission rate (or.10p.avg),
# followed by the highest validation AUC (auc.val.avg).
setorder(res_dt, delta.AICc, or.10p.avg, -auc.val.avg)

cat("\nTop 5 Model Configurations:\n")
# Print the key columns of the top 5 models
print(res_dt[1:5, .(tune.args, delta.AICc, auc.val.avg, auc.diff.avg, or.10p.avg)])

# Isolate the parameters of the absolute best model
best_tune_args <- res_dt[1, tune.args]
cat("\nOptimal Model Configuration Selected:", best_tune_args, "\n")

# ------------------------------------------------------------------------------
# Step 6: Extracting and Projecting the Best Model
# ------------------------------------------------------------------------------
cat("Extracting the tuned model and generating the final prediction...\n")

# ENMeval stores all trained model objects in the @models slot.
# We can extract our best model using its name (the tune.args string)
best_model <- eval_results@models[[best_tune_args]]

# Predict spatial suitability using the optimal model
# We use type="cloglog" for Maxent-style probability output
tuned_prediction <- predict(env_selected, best_model, type = "cloglog", na.rm=T)

# Visualize the final, highly-optimized SDM
plot(tuned_prediction, 
     main = paste("Tuned Habitat Suitability (", best_tune_args, ")", sep=""),
     col = terrain.colors(100, rev = TRUE))


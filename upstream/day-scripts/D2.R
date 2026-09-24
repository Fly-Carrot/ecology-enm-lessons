# ==============================================================================
# Day 2: Presence-Background Models (GLM & Maxent)
# ==============================================================================

# Install new packages if needed
# install.packages(c("maxnet", "data.table"))

library(terra)
library(maxnet)      # R-native implementation of Maxent (Java-free)
library(data.table)  # High-performance data manipulation

# Note: We assume 'clim_study_area' (SpatRaster) and 'occurrences_clean' (data.table) 
# from Day 1 are already loaded in the environment.

# ------------------------------------------------------------------------------
# Step 1 & 2: Generating Background Points
# ------------------------------------------------------------------------------
cat("Sampling background points across the study area...\n")

# Use terra::spatSample to generate 10,000 random background points
# 'as.points = TRUE' returns a SpatVector, 'na.rm = TRUE' ensures points fall on land
bg_pts <- spatSample(clim_study_area[[1]], size = 10000, 
                     method = "random", as.points = TRUE, na.rm = TRUE)

# Extract coordinates and convert directly to data.table
bg_dt <- as.data.table(crds(bg_pts))
setnames(bg_dt, c("x", "y"), c("lon", "lat")) # Standardize coordinate names

# Assign a presence value of 0 for background points using reference semantics (:=)
bg_dt[, presence := 0]

# ------------------------------------------------------------------------------
# Step 3: Constructing the Modeling data.table
# ------------------------------------------------------------------------------
cat("Building the presence-background matrix using data.table...\n")

# Assign a presence value of 1 for the actual occurrences
occurrences_clean[, presence := 1]

# Efficiently bind presences and background points row-wise
# We only select lon, lat, and presence columns to keep it clean
all_pts_dt <- rbindlist(list(
  occurrences_clean[, .(lon, lat, presence)], 
  bg_dt[, .(lon, lat, presence)]
))

# Extract environmental values for all points using terra::extract
# Inputting only the coordinates subset of our data.table
env_vals <- extract(clim_study_area, all_pts_dt[, .(lon, lat)])

# Convert extraction results to data.table and remove the auto-generated 'ID' column
env_dt <- as.data.table(env_vals)
env_dt[, ID := NULL]

# Column-bind coordinates/presence with environmental variables
model_dt <- cbind(all_pts_dt, env_dt)

# Clean the data: remove rows with NAs using data.table's internal na.omit
model_dt <- na.omit(model_dt)

cat("Modeling dataset ready. Total records:", nrow(model_dt), "\n")

# ------------------------------------------------------------------------------
# Step 4: Fitting a Generalized Linear Model (GLM)
# ------------------------------------------------------------------------------
cat("Fitting GLM...\n")

# A simple additive logistic regression using a subset of bioclimatic variables
glm_model <- glm(presence ~ bio1 + bio12 + bio16, 
                 family = binomial(link = "logit"), 
                 data = model_dt)

summary(glm_model)

# ------------------------------------------------------------------------------
# Step 5: Fitting a Maxent Model (maxnet)
# ------------------------------------------------------------------------------
cat("Fitting Maxent model...\n")

# Extract the response vector (presence/background status)
p_vector <- model_dt$presence

# Dynamically subset the data.table to keep ONLY environmental predictors
# .SDcols excludes spatial coordinates and the presence column
env_matrix <- model_dt[, .SD, .SDcols = !c("lon", "lat", "presence")]

# Fit the Maxent model
# Note: maxnet expects a data.frame for the predictors; data.table works perfectly here
maxent_model <- maxnet(p = p_vector, data = env_matrix)

# ------------------------------------------------------------------------------
# Step 6: Predicting and Comparing
# ------------------------------------------------------------------------------
cat("Generating spatial predictions...\n")

# Predict using GLM
# type = "response" gives probability values [0, 1]
glm_pred <- predict(clim_study_area, glm_model, type = "response")

# Predict using Maxent
# type = "cloglog" is the standard Maxent output format (suitability index)
maxent_pred <- predict(clim_study_area, maxent_model, type = "cloglog", na.rm=TRUE)

# Visualization: Side-by-side comparison
par(mfrow = c(1, 2))

plot(glm_pred, main = "GLM Prediction", 
     col = terrain.colors(100, rev = TRUE))
plot(maxent_pred, main = "Maxent Prediction (cloglog)", 
     col = terrain.colors(100, rev = TRUE))

# Reset par to default
par(mfrow = c(1, 1))

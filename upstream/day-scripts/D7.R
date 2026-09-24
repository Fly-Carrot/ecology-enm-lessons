# ==============================================================================
# Day 7: Visualizing G-Space and E-Space Niche Boundaries
# ==============================================================================

# Install new required packages for spatial shapes
# install.packages(c("ggplot2", "data.table", "terra", "concaveman", "cluster"))

library(terra)
library(data.table)
library(ggplot2)
library(concaveman)  # For Concave Hull calculation
library(cluster)     # For Minimum Volume Ellipsoid calculation

# Note: Assumes 'run_C' (from Day 6), 'env_selected' (SpatRaster), and 'selected_vars' are loaded.

# ------------------------------------------------------------------------------
# Step 1: Geographical Space (G-Space) Visualization
# ------------------------------------------------------------------------------
cat("Visualizing Geographic Space (Continuous and Binary)...\n")

# Extract two contrasting models from our ENMeval results (Day 6)
# Simple model (Linear features only, RM=1) vs Complex (Linear, Quadratic, Hinge, RM=0.5)
mod_simple  <- run_C@models[["fc.L_rm.1"]]
mod_complex <- run_C@models[["fc.LQ_rm.0.5"]]

# Predict continuous suitability (cloglog) across the raster
pred_sim_rast <- predict(env_selected, mod_simple, type = "cloglog", na.rm=TRUE)
pred_com_rast <- predict(env_selected, mod_complex, type = "cloglog", na.rm=TRUE)

# Convert to data.table for ggplot2
g_space_dt <- as.data.table(as.data.frame(c(pred_sim_rast, pred_com_rast), xy = TRUE))
setnames(g_space_dt, c("x", "y", "Simple_L1", "Complex_LQH0.5"))

# Melt the data.table to long format for easy faceting
g_long_dt <- melt(g_space_dt, id.vars = c("x", "y"), 
                  variable.name = "Model", value.name = "Suitability")

# Define an arbitrary threshold for binary maps (e.g., 0.5)
g_long_dt[, Binary := fcase(Suitability >= 0.5, "Presence", default = "Absence")]

# Plot 1: Continuous Maps Comparison
plot_g_cont <- ggplot(g_long_dt, aes(x = x, y = y, fill = Suitability)) +
  geom_tile() +
  facet_wrap(~ Model) +
  scale_fill_viridis_c(option = "turbo") +
  coord_fixed() +
  labs(title = "G-Space: Continuous Suitability Maps", x = "Longitude", y = "Latitude") +
  theme_bw() + theme(panel.grid = element_blank())

print(plot_g_cont)

# ------------------------------------------------------------------------------
# Step 2: Translating to Environmental Space (E-Space) via PCA
# ------------------------------------------------------------------------------
cat("Running PCA on the environmental matrix...\n")

# Extract all non-NA background pixels from the environment
env_dt <- as.data.table(as.data.frame(env_selected, xy = TRUE, na.rm = TRUE))
env_vars_only <- env_dt[, .SD, .SDcols = selected_vars]

# Perform Principal Component Analysis (scaling is crucial for climate data)
pca_res <- prcomp(env_vars_only, scale. = TRUE)

# Append PC1 and PC2 coordinates to our background data.table
env_dt[, PC1 := pca_res$x[, 1]]
env_dt[, PC2 := pca_res$x[, 2]]

# Predict the suitability of the SIMPLE model in the environmental data.table
# maxnet::predict accepts a data.frame/data.table directly
env_dt[, pred_prob := predict(mod_simple, newdata = env_vars_only, type = "cloglog")]

# Filter the pixels that the model predicts as "Presence" (our predicted niche)
# We use a threshold of 0.5 for demonstration
niche_dt <- env_dt[pred_prob >= 0.5]

# ------------------------------------------------------------------------------
# Step 3: Calculating Niche Boundaries in E-Space
# ------------------------------------------------------------------------------
cat("Calculating Bounding Box, Convex Hull, Concave Hull, and Ellipsoid...\n")

# --- 1. Range Box (Bounding Box) ---
box_x <- range(niche_dt$PC1)
box_y <- range(niche_dt$PC2)
box_dt <- data.table(
  PC1 = c(box_x[1], box_x[2], box_x[2], box_x[1], box_x[1]),
  PC2 = c(box_y[1], box_y[1], box_y[2], box_y[2], box_y[1])
)

# --- 2. Convex Hull ---
# chull() returns the row indices of the points that form the convex hull
hull_idx <- chull(niche_dt$PC1, niche_dt$PC2)
convex_dt <- niche_dt[c(hull_idx, hull_idx[1]), .(PC1, PC2)] # add first point to close polygon

# --- 3. Concave Hull ---
# concaveman creates a non-convex polygon shrinking towards dense point areas
concave_pts <- concaveman(as.matrix(niche_dt[, .(PC1, PC2)]), concavity = 2)
concave_dt <- as.data.table(concave_pts)
setnames(concave_dt, c("V1", "V2"), c("PC1", "PC2"))

# --- 4. Minimum Volume Ellipsoid (MVE) ---
# ellipsoidhull fits the smallest possible ellipsoid containing the points
ell_fit <- ellipsoidhull(as.matrix(niche_dt[, .(PC1, PC2)]))
ell_pts <- predict(ell_fit) # Generates the outline points of the ellipsoid
ell_dt <- as.data.table(ell_pts)
setnames(ell_dt, c("V1", "y"), c("PC1", "PC2"))

# ------------------------------------------------------------------------------
# Step 4: Multi-Shape Visualization in E-Space
# ------------------------------------------------------------------------------
cat("Plotting Niche boundaries in Environmental Space...\n")

# Plot the background, the predicted niche, and overlay all 4 geometries
plot_e_space <- ggplot() +
  # 1. Background Environment (Gray)
  geom_point(data = env_dt, aes(x = PC1, y = PC2), 
             color = "grey85", size = 0.5, alpha = 0.5) +
  
  # 2. Predicted Niche points (Light Blue)
  geom_point(data = niche_dt, aes(x = PC1, y = PC2), 
             color = "lightblue", size = 0.8, alpha = 0.7) +
  
  # 3. Geometries (Mapped to string constants to force a legend)
  geom_path(data = box_dt,     aes(x = PC1, y = PC2, color = "1. Range Box"), size = 1.2, linetype = "dashed") +
  geom_path(data = convex_dt,  aes(x = PC1, y = PC2, color = "2. Convex Hull"), size = 1.2) +
  geom_path(data = ell_dt,     aes(x = PC1, y = PC2, color = "3. Min Vol Ellipsoid"), size = 1.2) +
  geom_polygon(data = concave_dt, aes(x = PC1, y = PC2, color = "4. Concave Hull"), fill = NA, size = 1.2) +
  
  # Styling and labels
  scale_color_manual(name = "Niche Boundaries",
                     values = c("1. Range Box" = "#E69F00",        # Orange
                                "2. Convex Hull" = "#56B4E9",      # Blue
                                "3. Min Vol Ellipsoid" = "#CC79A7",# Pink/Purple
                                "4. Concave Hull" = "#009E73")) +  # Green
  labs(title = "Species Niche Boundaries in Environmental Space (PCA)",
       subtitle = "Comparing different geometrical approaches to define Hutchinson's hypervolume",
       x = paste0("PC1 (", round(summary(pca_res)$importance[2,1]*100, 1), "% Variance)"),
       y = paste0("PC2 (", round(summary(pca_res)$importance[2,2]*100, 1), "% Variance)")) +
  theme_bw() +
  theme(plot.title = element_text(face = "bold", size = 14),
        legend.position = "right",
        legend.background = element_rect(fill = "white", color = "black"))

print(plot_e_space)

# ==============================================================================
# Day 4: Future Climate Projections and Range Shifts
# ==============================================================================

# Install required packages if missing
# install.packages(c("terra", "ggplot2", "data.table"))

library(terra)
library(ggplot2)
library(data.table)

# Note: We assume the following objects from Day 3 are available:
# 1. 'maxent_model_final' (The trained model)
# 2. 'clim_study_area' (The current climate SpatRaster)
# 3. 'max_tss_row$threshold' (The optimal cutoff value calculated in Day 3)
# 4. 'selected_vars' (The character vector of non-collinear variables, e.g., "bio1", "bio12")

# Let's set a fallback threshold just in case Day 3 isn't loaded in your session
optimal_threshold <- if(exists("max_tss_row")) max_tss_row$threshold else 0.45

# ------------------------------------------------------------------------------
# Step 1: Preparing Future Climate Scenarios (Simulation via Map Algebra)
# ------------------------------------------------------------------------------
cat("Simulating a future climate scenario (+2.0 C warming)...\n")

# In a real study, you would download CMIP6 data like this:
# future_clim <- geodata::cmip6_world(model="MPI-ESM1-2-HR", ssp="245", time="2041-2060", var="bioc", res=10, path=tempdir())

# For teaching stability, we simulate a future scenario by modifying current climate.
# We create a deep copy of our selected current climate layers.
clim_future <- copy(clim_study_area[[selected_vars]])

# Example Modification: 
# Bio1 (Annual Mean Temp) increases by 2.0 degrees C.
# Bio12 (Annual Precipitation) decreases by 10% (multiply by 0.9).
# Note: Check the units of your specific data source! Sometimes temp is stored as C * 10.
if("bio1" %in% names(clim_future)) clim_future[["bio1"]] <- clim_future[["bio1"]] + 2.0
if("bio12" %in% names(clim_future)) clim_future[["bio12"]] <- clim_future[["bio12"]] * 0.9

# ------------------------------------------------------------------------------
# Step 2: Projecting the Model into the Future
# ------------------------------------------------------------------------------
cat("Projecting the model onto current and future environments...\n")

# Predict continuous suitability (cloglog) for BOTH current and future
pred_current <- predict(clim_study_area[[selected_vars]], maxent_model_final, 
                        type = "cloglog", na.rm=TRUE)
pred_future  <- predict(clim_future, maxent_model_final, 
                        type = "cloglog", na.rm=TRUE)

# ------------------------------------------------------------------------------
# Step 3: Binarizing Predictions (Presence vs. Absence)
# ------------------------------------------------------------------------------
cat("Applying the optimal threshold to binarize maps...\n")

# Convert continuous probabilities into 1 (Presence) and 0 (Absence)
bin_current <- pred_current >= optimal_threshold
bin_future  <- pred_future  >= optimal_threshold

# ------------------------------------------------------------------------------
# Step 4: Mapping Distribution Changes using Map Algebra
# ------------------------------------------------------------------------------
cat("Calculating spatial range shifts...\n")

# A classic GIS map algebra trick: Current + (Future * 2)
# Current = 0, Future = 0  --> 0 + 0 = 0 (Absent in both)
# Current = 1, Future = 0  --> 1 + 0 = 1 (Loss / Contraction)
# Current = 0, Future = 1  --> 0 + 2 = 2 (Gain / Expansion)
# Current = 1, Future = 1  --> 1 + 2 = 3 (Stable / Persistence)

shift_map <- bin_current + (bin_future * 2)
names(shift_map) <- "shift_category"

# ------------------------------------------------------------------------------
# Step 5: Quantifying and Visualizing the Impact (using data.table & ggplot2)
# ------------------------------------------------------------------------------
cat("Quantifying range shifts using data.table...\n")

# Convert the shift SpatRaster to a data.frame with coordinates, then to data.table
shift_dt <- as.data.table(as.data.frame(shift_map, xy = TRUE))

# Use data.table's fcase (fast case) to assign descriptive labels
shift_dt[, status := fcase(
  shift_category == 0, "Absent",
  shift_category == 1, "Loss",
  shift_category == 2, "Gain",
  shift_category == 3, "Stable"
)]

# Convert 'status' to a factor with a specific order for consistent plot legends
shift_dt[, status := factor(status, levels = c("Absent", "Loss", "Gain", "Stable"))]

# Calculate the number of pixels (area) for each category
# .N is a special data.table variable holding the number of rows in the group
summary_dt <- shift_dt[, .(pixel_count = .N), by = status]
summary_dt[, percentage := round((pixel_count / sum(pixel_count)) * 100, 2)]

print("Range Shift Summary:")
print(summary_dt[status != "Absent"]) # We usually don't care about the total empty ocean/land

# ------------------------------------------------------------------------------
# Visualization: Publication-Ready Range Shift Map
# ------------------------------------------------------------------------------
cat("Rendering the Range Shift map...\n")

# Define distinct colors for each category
shift_colors <- c("Absent" = "gray95", 
                  "Loss"   = "#D55E00",   # Red/Orange
                  "Gain"   = "#0072B2",   # Blue
                  "Stable" = "#009E73")   # Green

# Plot using ggplot2 and geom_tile (very efficient for raster data formats)
shift_plot <- ggplot(shift_dt, aes(x = x, y = y, fill = status)) +
  geom_tile() +
  scale_fill_manual(values = shift_colors, name = "Range Shift") +
  coord_fixed() + # Ensure the map isn't stretched (aspect ratio 1:1)
  labs(
    title = "Predicted Range Shifts under Future Climate (+2°C)",
    subtitle = paste("Threshold applied:", round(optimal_threshold, 3)),
    x = "Longitude",
    y = "Latitude"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "right",
    panel.grid = element_blank() # Remove gridlines for a cleaner map look
  )

print(shift_plot)

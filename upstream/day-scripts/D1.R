# ==============================================================================
# Day 1: Create your first SDM in R
# Target Species: Grus japonensis (Red-crowned crane)
# ==============================================================================

# Install necessary packages if not already installed
# install.packages(c("geodata", "terra", "sf", "dismo", "data.table"))

library(geodata)      # For downloading species and climate data
library(terra)        # Core package for modern raster data processing
library(sf)           # Core package for modern vector data processing
library(dismo)        # Classic SDM package
library(data.table)   # High-performance data manipulation
setwd("~/GIT/ENM_curriculum/ENM_curriculum")
# ------------------------------------------------------------------------------
# Step 1: Downloading the occurrences
# ------------------------------------------------------------------------------
cat("Downloading GBIF data for Grus japonensis...\n")

# Fetch GBIF data using geodata package, saving to temporary directory
occ_file<-"../Data/Occurrences/crane_gbif.rda"
if (file.exists(occ_file)){
  crane_dt<-readRDS(occ_file)
}else{
  crane_gbif <- sp_occurrence(genus = "Grus", species = "japonensis", path = tempdir())
  
  # Convert to data.table for efficient processing
  crane_dt <- as.data.table(crane_gbif)
  saveRDS(crane_dt, occ_file)
}

# ------------------------------------------------------------------------------
# Step 2: Getting environmental predictors
# ------------------------------------------------------------------------------

cat("Downloading WorldClim Bioclimatic variables...\n")

# Download global Bioclim data (10 arc-minutes resolution, 19 variables)
raster_folder<-"../Data/Bioclim"
if (dir.exists(raster_folder)){
  files<-list.files(raster_folder, pattern = "*.asc", full.names = T)
  clim_global<-rast(files)
}else{
  clim_global <- worldclim_global(var = "bio", res = 10, path = tempdir())
}
#https://www.worldclim.org/data/bioclim.html

study_extent <- ext(110, 150, 30, 55) 
clim_study_area <- crop(clim_global, study_extent)

# ------------------------------------------------------------------------------
# Step 3: Advanced Spatial Cleaning (NA Removal & Spatial Thinning)
# ------------------------------------------------------------------------------
cat("Performing spatial cleaning based on raster resolution...\n")
occurrences_raw <- crane_dt[!is.na(lon) & !is.na(lat), .(lon, lat)]
# 3.1 Extract the raster cell ID for each occurrence coordinate
# terra::cellFromXY returns the exact cell number that a coordinate falls into
pts_matrix <- as.matrix(occurrences_raw[, .(lon, lat)])
occurrences_raw[, cell_id := cellFromXY(clim_study_area, pts_matrix)]

# 3.2 Extract environmental values to check for NAs (e.g., points in the ocean)
# We use the first layer (Bio1) as the mask. The returned object is a matrix/data.frame,
# where the second column contains the actual extracted values.
env_vals <- extract(clim_study_area[[1]], pts_matrix)
occurrences_raw[, env_val := env_vals[, 1]]

# 3.3 Remove points that fall in NA areas (ocean or outside raster bounds)
occ_no_na <- occurrences_raw[!is.na(env_val)]
cat("Occurrences after removing NAs:", nrow(occ_no_na), "\n")

# 3.4 Spatial Thinning: Keep only ONE point per raster cell
# data.table's 'unique' function with 'by' argument does this instantly
occurrences_clean <- unique(occ_no_na, by = "cell_id")
cat("Occurrences after spatial thinning (1 per cell):", nrow(occurrences_clean), "\n")

# ------------------------------------------------------------------------------
# Step 3.5: Visualizing the Cleaning Process
# ------------------------------------------------------------------------------
cat("Plotting before-and-after spatial cleaning...\n")

# Set up a side-by-side plotting area
par(mfrow = c(1, 2))

# Plot 1: Raw Data (Includes overlapping points and points in the ocean)
plot(clim_study_area[[1]], main = "Raw Occurrences", legend = FALSE)
points(occurrences_raw$lon, occurrences_raw$lat, col = "black", pch = 16, cex = 0.6)

# Plot 2: Cleaned Data (No ocean NAs, thinned to 1 point per pixel)
plot(clim_study_area[[1]], main = "Cleaned & Thinned", legend = FALSE)
points(occurrences_clean$lon, occurrences_clean$lat, col = "red", pch = 16, cex = 0.6)

# Reset plot parameters
par(mfrow = c(1, 1))

# ------------------------------------------------------------------------------
# Step 4: Running your first ENM (Bioclim approach)
# ------------------------------------------------------------------------------
cat("Fitting the Bioclim model...\n")

# Fit the Bioclim model using only our strictly cleaned occurrence data.frame
# dismo's bioclim accepts a Raster object and a data.frame of coordinates
bc_model <- bioclim(as(clim_study_area, "Raster"), as.data.frame(occurrences_clean[, .(lon, lat)]))

# ------------------------------------------------------------------------------
# Step 5: Visualizing the results
# ------------------------------------------------------------------------------
cat("Predicting spatial distribution...\n")

# Predict and convert back to terra's SpatRaster
suitability_map <- predict(as(clim_study_area, "Raster"), bc_model)
suitability_map <- rast(suitability_map)

# Plot the final suitability map
plot(suitability_map, main = "Habitat Suitability for Grus japonensis (Bioclim)", 
     col = terrain.colors(100, rev = TRUE))
points(occurrences_clean$lon, occurrences_clean$lat, col = "blue", pch = 20, cex = 0.5)


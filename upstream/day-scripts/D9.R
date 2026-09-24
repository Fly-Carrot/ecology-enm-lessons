# ==============================================================================
# Day 9: Niche Shift Analysis (Native vs. Invaded Range)
# Target Species: Sciurus carolinensis (Eastern Gray Squirrel)
# ==============================================================================

# Install required packages if missing
# install.packages(c("ecospat", "terra", "geodata", "data.table"))

library(ecospat)     # Core package for niche dynamics and shift analysis
library(terra)
library(geodata)
library(data.table)
library(rgbif)
# ------------------------------------------------------------------------------
# Step 1: Data Preparation (Downloading subsetted data directly via rgbif)
# ------------------------------------------------------------------------------
# Note: Sciurus carolinensis has over 1,000,000 records on GBIF. 
# A standard download will crash the synchronous API. We use rgbif to limit the query.

# install.packages("rgbif")


cat("Downloading a random subset of 5,000 occurrences per region via rgbif...\n")

# 1.1 Download Native Range (North America)
# Using bounding box directly in the API request: lon -130 to -60, lat 25 to 60
gbif_na <- occ_data(scientificName = "Sciurus carolinensis", 
                    hasCoordinate = TRUE, 
                    decimalLongitude = "-130,-60",
                    decimalLatitude = "25,60",
                    limit = 5000) # Limit to 5000 for teaching speed

# 1.2 Download Invaded Range (Europe)
# Using bounding box directly in the API request: lon -15 to 30, lat 35 to 65
gbif_eu <- occ_data(scientificName = "Sciurus carolinensis", 
                    hasCoordinate = TRUE, 
                    decimalLongitude = "-15,30",
                    decimalLatitude = "35,65",
                    limit = 5000)

# 1.3 Convert directly to data.table and extract coordinates
occ_na <- as.data.table(gbif_na$data)[!is.na(decimalLongitude), .(lon = decimalLongitude, lat = decimalLatitude)]
occ_eu <- as.data.table(gbif_eu$data)[!is.na(decimalLongitude), .(lon = decimalLongitude, lat = decimalLatitude)]

cat("Successfully retrieved:", nrow(occ_na), "Native records and", nrow(occ_eu), "Invaded records.\n")

# (From here, you can proceed directly to Step 1.3 in the original script: Load global climate)

# 1.3 Load global climate and crop to respective backgrounds
raster_folder<-"../Data/Bioclim"
if (dir.exists(raster_folder)){
  files<-list.files(raster_folder, pattern = "*.asc", full.names = T)
  clim_global<-rast(files)
}else{
  clim_global <- worldclim_global(var = "bio", res = 10, path = tempdir())
}
# Define Extents: NA (Native) and EU (Invaded)
ext_na <- ext(-130, -60, 25, 60)
ext_eu <- ext(-15, 30, 35, 65)

env_na <- crop(clim_global, ext_na)
env_eu <- crop(clim_global, ext_eu)

# Extract background environmental points (10,000 per region)
bg_na_pts <- as.data.table(crds(spatSample(env_na[[c("bio1", "bio12")]], 
                                           10000, method="random", as.points=TRUE, na.rm=TRUE)))
bg_eu_pts <- as.data.table(crds(spatSample(env_eu[[c("bio1", "bio12")]], 
                                           10000, method="random", as.points=TRUE, na.rm=TRUE)))

# Extract environment for background and occurrences
# Note: For teaching simplicity, we use only Bio1 (Temp) and Bio12 (Precip)
env_bg_na <- as.data.table(extract(env_na, bg_na_pts[, .(x, y)]))[, ID := NULL]
env_bg_eu <- as.data.table(extract(env_eu, bg_eu_pts[, .(x, y)]))[, ID := NULL]

env_occ_na <- as.data.table(extract(env_na, occ_na))[, ID := NULL]
env_occ_eu <- as.data.table(extract(env_eu, occ_eu))[, ID := NULL]

# Clean up NAs
env_bg_na <- na.omit(env_bg_na); env_bg_eu <- na.omit(env_bg_eu)
env_occ_na <- na.omit(env_occ_na); env_occ_eu <- na.omit(env_occ_eu)

# ------------------------------------------------------------------------------
# Step 2: Constructing the Global Environmental Space (PCA-env)
# ------------------------------------------------------------------------------
cat("Calibrating Global PCA on combined background climates...\n")

# Combine NA and EU backgrounds to create a global baseline for PCA
global_bg <- rbindlist(list(env_bg_na, env_bg_eu))

# Run PCA
pca_global <- prcomp(global_bg, scale. = TRUE)

# Project all datasets into this shared PCA space (PC1 and PC2)
scores_bg_global <- as.data.table(pca_global$x[, 1:2])
scores_bg_na     <- as.data.table(predict(pca_global, env_bg_na)[, 1:2])
scores_bg_eu     <- as.data.table(predict(pca_global, env_bg_eu)[, 1:2])
scores_occ_na    <- as.data.table(predict(pca_global, env_occ_na)[, 1:2])
scores_occ_eu    <- as.data.table(predict(pca_global, env_occ_eu)[, 1:2])

# ------------------------------------------------------------------------------
# Step 3: Quantifying Niche Dynamics (The ecospat framework)
# ------------------------------------------------------------------------------
cat("Calculating Niche Grids and Dynamics Indexes...\n")

# 3.1 Calculate environmental density grids
# R = 100 sets the resolution of the grid (100x100 pixels in PCA space)
grid_na <- ecospat.grid.clim.dyn(glob = scores_bg_global, 
                                 glob1 = scores_bg_na, 
                                 sp = scores_occ_na, R = 100)

grid_eu <- ecospat.grid.clim.dyn(glob = scores_bg_global, 
                                 glob1 = scores_bg_eu, 
                                 sp = scores_occ_eu, R = 100)

# 3.2 Calculate Niche Overlap (Schoener's D)
overlap <- ecospat.niche.overlap(grid_na, grid_eu, cor = TRUE)
cat("Schoener's D (Niche Overlap):", round(overlap$D, 3), "\n")

# 3.3 Calculate Niche Dynamics Indexes (Expansion, Stability, Unfilling)
# We test EU (invaded) against NA (native)
niche_dyn <- ecospat.niche.dyn.index(grid_na, grid_eu, intersection = 0.1)

cat("Niche Expansion (Shift):", round(niche_dyn$dynamic.index.w[1], 3), "\n")
cat("Niche Stability:", round(niche_dyn$dynamic.index.w[2], 3), "\n")
cat("Niche Unfilling:", round(niche_dyn$dynamic.index.w[3], 3), "\n")

# ------------------------------------------------------------------------------
# Step 4: Visualizing Niche Shifts and Analogous Climates
# ------------------------------------------------------------------------------
cat("Plotting ecospat Niche Dynamics...\n")

# Set up the plot area
par(mfrow = c(1, 2))

# Plot 1: The Native Niche (North America)
ecospat.plot.niche(grid_na, title = "Native Niche (North America)", name.axis1 = "PC1", name.axis2 = "PC2")
# The solid contour line shows 100% of the available background climate in NA.

# Plot 2: Niche Dynamics (Shift, Unfilling, Stability)
ecospat.plot.niche.dyn(grid_na, grid_eu, quant = 0.25, interest = 2,
                       title = "Niche Dynamics: Invaded vs. Native",
                       name.axis1 = "PC1", name.axis2 = "PC2")

# Add a legend manually for the dynamics plot
legend("topright", legend = c("Stability", "Expansion (Shift)", "Unfilling"),
       fill = c("blue", "red", "green"), bg = "white", cex = 0.8)

# Reset plotting parameters
par(mfrow = c(1, 1))

# ------------------------------------------------------------------------------
# Step 4: Visualizing Niche Shifts and Analogous Climates (ggplot2 approach)
# ------------------------------------------------------------------------------
cat("Converting ecospat grids to data.table for ggplot2 visualization...\n")

# Install patchwork if you want elegant side-by-side ggplot arrangement
# install.packages("patchwork")
library(patchwork)
library(ggplot2)

# 4.1 Extract the grid matrices into a single data.table
# ecospat creates a 100x100 grid (R=100) across PC1 and PC2.
# expand.grid perfectly matches the matrix vectorization in R.
dyn_dt <- as.data.table(expand.grid(PC1 = grid_na$x, PC2 = grid_na$y))

# Extract species occurrence densities (z.uncor means uncorrected density)
dyn_dt[, occ_na := as.vector(grid_na$z.uncor)]
dyn_dt[, occ_eu := as.vector(grid_eu$z.uncor)]

# Extract background densities (available climate in both regions)
dyn_dt[, bg_na := as.vector(grid_na$z)]
dyn_dt[, bg_eu := as.vector(grid_eu$z)]

# 4.2 Define Niche Categories (Unfilling, Stability, Expansion)
# We consider a pixel occupied if the species density is greater than 0
dyn_dt[, Dynamics := fcase(
  occ_na > 0 & occ_eu == 0, "Unfilling (Native only)",
  occ_na > 0 & occ_eu > 0,  "Stability (Shared)",
  occ_na == 0 & occ_eu > 0, "Expansion (Invaded only)",
  default = NA_character_
)]

# Convert to factor with a specific order for the legend
dyn_dt[, Dynamics := factor(Dynamics, levels = c("Unfilling (Native only)", 
                                                 "Stability (Shared)", 
                                                 "Expansion (Invaded only)"))]

# Create a subset data.table removing NA categories for cleaner tile plotting
dyn_plot_dt <- dyn_dt[!is.na(Dynamics)]

# ------------------------------------------------------------------------------
# 4.3 Plot 1: The Native Niche
# ------------------------------------------------------------------------------
plot_native <- ggplot() +
  # 1. Plot the density of the Native species
  geom_tile(data = dyn_dt[occ_na > 0], aes(x = PC1, y = PC2, fill = occ_na)) +
  scale_fill_viridis_c(option = "mako", direction = -1, name = "Occurrence\nDensity") +
  
  # 2. Add Native Background contour (Solid line)
  # breaks = 1e-5 identifies the absolute edge where background climate > 0
  geom_contour(data = dyn_dt, aes(x = PC1, y = PC2, z = bg_na), 
               breaks = 1e-5, color = "black", size = 0.8, linetype = "solid") +
  
  labs(title = "Native Niche (North America)",
       subtitle = "Solid black line = 100% Available Native Climate",
       x = "PC1", y = "PC2") +
  theme_bw() +
  theme(plot.title = element_text(face = "bold", size = 13))

# ------------------------------------------------------------------------------
# 4.4 Plot 2: Niche Dynamics
# ------------------------------------------------------------------------------
# Define colors typically used in ecospat papers (Green, Blue, Red)
dyn_colors <- c("Unfilling (Native only)"  = "#00BA38", # Green
                "Stability (Shared)"       = "#619CFF", # Blue
                "Expansion (Invaded only)" = "#F8766D") # Red

plot_dyn <- ggplot() +
  # 1. Plot the categorical Niche Dynamics
  geom_tile(data = dyn_plot_dt, aes(x = PC1, y = PC2, fill = Dynamics)) +
  scale_fill_manual(values = dyn_colors, name = "Niche Dynamics") +
  
  # 2. Add Native Background contour (Solid black line)
  geom_contour(data = dyn_dt, aes(x = PC1, y = PC2, z = bg_na), 
               breaks = 1e-5, color = "black", size = 0.8, linetype = "solid") +
  
  # 3. Add Invaded Background contour (Dashed red line)
  geom_contour(data = dyn_dt, aes(x = PC1, y = PC2, z = bg_eu), 
               breaks = 1e-5, color = "red", size = 0.8, linetype = "dashed") +
  
  labs(title = "Niche Dynamics: Invaded vs. Native",
       subtitle = "Black solid = NA Background | Red dashed = EU Background",
       x = "PC1", y = "PC2") +
  theme_bw() +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom")

# ------------------------------------------------------------------------------
# 4.5 Display Side-by-Side using patchwork
# ------------------------------------------------------------------------------
# The '+' operator comes from the patchwork package, combining plots instantly
final_combined_plot <- plot_native + plot_dyn + 
  plot_layout(guides = "collect") & 
  theme(legend.position = "bottom")

print(final_combined_plot)


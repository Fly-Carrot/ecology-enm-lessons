# ==============================================================================
# Quantitative Evaluation of Cross-Validation Partitioning Schemes
# Metrics: Validation AUC (Predictive Power) & AUC Difference (Overfitting)
# ==============================================================================

# Load required libraries
library(ENMeval)
library(terra)
library(geodata)
library(data.table)
library(ggplot2)
library(patchwork)

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

env_study <- crop(clim_global[[c("bio1", "bio12")]], study_extent)
names(env_study) <- c("bio1", "bio12")

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


occ_clean <- unique(occurrences_clean[!is.na(lon) & !is.na(lat), .(lon, lat)])

# Sample random background points
bg_pts <- spatSample(env_study[[1]], size = 5000, method = "random", as.points = TRUE, na.rm = TRUE)
bg_clean <- as.data.table(crds(bg_pts))
setnames(bg_clean, c("x", "y"), c("lon", "lat"))

occ_df <- as.data.frame(occ_clean)
bg_df  <- as.data.frame(bg_clean)
# Load coastline vector for spatial context
coastline <- ne_coastline(scale = "medium", returnclass = "sf")

# ------------------------------------------------------------------------------
# Step 2: Compute Partition Folds via ENMeval
# ------------------------------------------------------------------------------
cat("Computing partition assignments across all 4 schemes...\n")

# 1. Random 4-fold
part_random <- get.randomkfold(occ = occ_df, bg = bg_df, kfolds = 4)

# 2. Spatial Block (4 quadrants)
part_block <- get.block(occ = occ_df, bg = bg_df)

# 3. Checkerboard (2 folds, aggregation factor = 8 cells)
cb1_agg <- 8
part_cb1 <- get.checkerboard(occ = occ_df, envs = env_study, bg = bg_df, 
                              aggregation.factor = cb1_agg)


# Helper function to assemble partition tables
build_dt <- function(part_obj, name) {
  occ_part <- copy(occ_clean)[, `:=`(Fold = as.factor(part_obj$occs.grp), 
                                     Type = "Occurrence")]
  bg_part  <- copy(bg_clean)[, `:=`(Fold = as.factor(part_obj$bg.grp), 
                                    Type = "Background")]
  combined <- rbindlist(list(occ_part, bg_part))
  combined[, Scheme := name]
  return(combined)
}

dt_random <- build_dt(part_random, "Random 4-Fold")
dt_block  <- build_dt(part_block,  "Spatial Block")
dt_cb1    <- build_dt(part_cb1,    "Checkerboard")

# ------------------------------------------------------------------------------
# Step 3: Compute Spatial Boundary Coordinates (Dashed Partition Lines)
# ------------------------------------------------------------------------------
cat("Calculating exact partition boundary coordinates...\n")

# --- Block Split Lines ---
# get.block calculates longitudinal and latitudinal lines that divide occurrences
# We extract the boundary coordinates dividing Fold 1/2 from Fold 3/4
lon_block_split <- median(occ_clean$lon)
lat_block_split <- median(occ_clean$lat)

# --- Checkerboard 1 Grid Lines ---
res_x <- res(env_study)[1]
res_y <- res(env_study)[2]

x_breaks_cb1 <- seq(xmin(env_study), xmax(env_study), by = res_x * cb1_agg)
y_breaks_cb1 <- seq(ymin(env_study), ymax(env_study), by = res_y * cb1_agg)

# --- Checkerboard 2 Grid Lines (Hierarchical: Coarse + Fine) ---
x_breaks_cb2_coarse <- seq(xmin(env_study), xmax(env_study), by = res_x * cb2_agg[2])
y_breaks_cb2_coarse <- seq(ymin(env_study), ymax(env_study), by = res_y * cb2_agg[2])

x_breaks_cb2_fine   <- seq(xmin(env_study), xmax(env_study), by = res_x * cb2_agg[1])
y_breaks_cb2_fine   <- seq(ymin(env_study), ymax(env_study), by = res_y * cb2_agg[1])

# ------------------------------------------------------------------------------
# Step 4: Construct Individual Partition Plots with Dashed Lines
# ------------------------------------------------------------------------------
cat("Generating geographic plots with explicit boundary lines...\n")

fold_colors <- c("1" = "#D55E00", "2" = "#0072B2", "3" = "#009E73", "4" = "#CC79A7")

# Base plotting function
plot_partition_base <- function(dt_subset, plot_title, plot_sub) {
  ggplot() +
    geom_sf(data = coastline, fill = "gray95", color = "gray75", size = 0.3) +
    geom_point(data = dt_subset[Type == "Background"], 
               aes(x = lon, y = lat, color = Fold), 
               alpha = 0.2, size = 0.6) +
    geom_point(data = dt_subset[Type == "Occurrence"], 
               aes(x = lon, y = lat, fill = Fold), 
               shape = 21, color = "black", size = 2.2, stroke = 0.5) +
    scale_color_manual(values = fold_colors, name = "Fold") +
    scale_fill_manual(values = fold_colors, name = "Fold") +
    coord_sf(xlim = c(110, 150), ylim = c(30, 55), expand = FALSE) +
    labs(title = plot_title, subtitle = plot_sub, x = "Longitude", y = "Latitude") +
    theme_bw() +
    theme(
      plot.title = element_text(face = "bold", size = 11),
      plot.subtitle = element_text(size = 8.5, color = "gray30"),
      panel.grid = element_blank(),
      legend.position = "right"
    )
}

# 1. Random 4-Fold (No boundaries)
p_random <- plot_partition_base(
  dt_random, 
  "1. Random 4-Fold", 
  "Uniformly scrambled: No spatial boundaries exist."
)

# 2. Spatial Block (Quadrant Dashed Lines)
p_block <- plot_partition_base(
  dt_block, 
  "2. Spatial Block (4 Quadrants)", 
  "Divided by median coordinates into 4 discrete geographic zones."
) +
  geom_vline(xintercept = lon_block_split, linetype = "dashed", color = "black", size = 0.8) +
  geom_hline(yintercept = lat_block_split, linetype = "dashed", color = "black", size = 0.8)

# 3. Checkerboard 1 (Single Grid Lines)
p_cb1 <- plot_partition_base(
  dt_cb1, 
  "3. Checkerboard 1 (2 Folds)", 
  "Single-tier grid lines: Alternates like a chessboard."
) +
  geom_vline(xintercept = x_breaks_cb1, linetype = "dashed", color = "gray20", size = 0.4) +
  geom_hline(yintercept = y_breaks_cb1, linetype = "dashed", color = "gray20", size = 0.4)

# ------------------------------------------------------------------------------
# Step 5: Combine into Publication Layout
# ------------------------------------------------------------------------------
cat("Rendering combined layout...\n")

combined_spatial_plot <- (p_random | p_block | p_cb1) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

print(combined_spatial_plot)

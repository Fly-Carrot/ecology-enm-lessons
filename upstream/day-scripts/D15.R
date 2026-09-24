# ==============================================================================
# Day 15: Expert Range Filtering, Maxent Feature Analysis, ENMeval Tuning, 
#         and Geometric Envelopes
# Target Species: Grus japonensis (Red-crowned Crane)
# ==============================================================================

# ------------------------------------------------------------------------------
# Step 0: Library Initialization & JVM Verification
# ------------------------------------------------------------------------------

# Load required packages
library(data.table)
library(ggplot2)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(terra)
library(ggrepel)
library(units)
library(ENMeval)
library(rJava)

# Initialize Java Virtual Machine (JVM) and verify system architecture
.jinit()
java_version <- .jcall("java/lang/System", "S", "getProperty", "java.version")
java_arch    <- .jcall("java/lang/System", "S", "getProperty", "os.arch")

cat("Java Version:", java_version, "\n")
cat("Java Architecture:", java_arch, "\n")

# Smoke test JVM object instantiation
test_string <- .jnew("java/lang/String", "Hello, rJava is working!")
cat("Java Object Output:", test_string$toString(), "\n")

# Set working directory
setwd("~/GIT/ENM_curriculum/ENM_curriculum")

# ------------------------------------------------------------------------------
# Step 1: Occurrence Cleaning and IUCN Range Filtering
# ------------------------------------------------------------------------------

# 1.1 Load and clean raw GBIF occurrences
df <- fread("../Data/Occurrences/0006777-241107131044228.csv")
df <- df[, .(species, decimalLongitude, decimalLatitude)]
df <- df[!is.na(decimalLongitude) & !is.na(decimalLatitude)]
setnames(df, c("decimalLongitude", "decimalLatitude"), c("x", "y"))
fwrite(df, "../Data/Occurrences/occ.csv")

# 1.2 Load IUCN Red List expert range map
iucn <- read_sf("../Data/IUCN/Red crowned Crane/data_0.shp")

# Inspect presence and seasonal categories
ggsave(
  ggplot(iucn) + geom_sf(aes(fill = factor(PRESENCE))) + theme_bw(),
  filename = "../Figures/IUCN_PRESENCE.png"
)

ggsave(
  ggplot(iucn) + geom_sf(aes(fill = factor(SEASONAL))) + theme_bw(),
  filename = "../Figures/IUCN_SEASONAL.png"
)

# 1.3 Filter target native extant & breeding ranges (PRESENCE = 1, SEASONAL = 1 or 2)
iucn_target <- iucn[which(iucn$PRESENCE %in% c(1) & iucn$SEASONAL %in% c(1, 2)), ]

ggsave(
  ggplot(iucn) +
    geom_sf(fill = NA, color = "gray80") +
    geom_sf(data = iucn_target, aes(fill = factor(SEASONAL))) +
    theme_bw(),
  filename = "../Figures/IUCN_Filtered.png"
)

# 1.4 Overlay occurrences with IUCN range and continental basemap
continent <- read_sf("../Data/Shape/continents/continent.shp")
st_crs(continent) <- st_crs(iucn)

p_occ_iucn <- ggplot() +
  geom_sf(data = continent, fill = NA, color = "gray70") +
  geom_sf(data = iucn, fill = NA, color = "gray85") +
  geom_sf(data = iucn_target, aes(fill = factor(SEASONAL)), alpha = 0.5) +
  geom_point(data = df, aes(x = x, y = y), size = 0.5, color = "black") +
  coord_sf(xlim = c(100, 150), ylim = c(22, 55), expand = FALSE) +
  theme_bw() +
  theme(axis.title = element_blank())

print(p_occ_iucn)
ggsave(p_occ_iucn, filename = "../Figures/IUCN_Filtered_Overlay.png")

# ------------------------------------------------------------------------------
# Step 2: Strict vs. Buffer-Based Spatial Point Filtering
# ------------------------------------------------------------------------------

# Convert occurrence table to sf spatial points
occs_sf <- st_as_sf(df, coords = c("x", "y"), crs = st_crs(iucn))

# 2.1 Strict Point-in-Polygon intersection
contain_strict <- st_contains(iucn_target, occs_sf)
df[, is_in_strictly := 0]
df[unlist(contain_strict), is_in_strictly := 1]

# Full-view plot of strict filtering
p_strict_full <- ggplot() +
  geom_sf(data = continent, fill = NA, color = "gray70") +
  geom_sf(data = iucn_target, aes(color = factor(SEASONAL)), fill = NA, size = 0.8) +
  geom_point(data = df, aes(x = x, y = y, color = factor(is_in_strictly)), size = 1) +
  scale_color_manual(values = c("0" = "gray60", "1" = "red", "2" = "blue", "3" = "forestgreen")) +
  coord_sf(xlim = c(100, 150), ylim = c(22, 55), expand = FALSE) +
  theme_bw() +
  theme(axis.title = element_blank())
ggsave(p_strict_full, filename = "../Figures/IUCN_Filtered_strict_full.png")

# Zoomed-in view of breeding core area
p_strict_sub <- ggplot() +
  geom_sf(data = continent, fill = NA, color = "gray70") +
  geom_sf(data = iucn_target, aes(color = factor(SEASONAL)), fill = NA, size = 0.8) +
  geom_point(data = df, aes(x = x, y = y, color = factor(is_in_strictly)), size = 1.2) +
  scale_color_manual(values = c("0" = "gray60", "1" = "red")) +
  coord_sf(xlim = c(125, 135), ylim = c(45, 52), expand = FALSE) +
  theme_bw() +
  theme(axis.title = element_blank())
ggsave(p_strict_sub, filename = "../Figures/IUCN_Filtered_strict_sub.png")

# 2.2 Buffer-based inclusion (10 km threshold to account for GPS error / boundary mismatch)
iucn_target_buffer_10km <- st_buffer(iucn_target, dist = set_units(10, "km"))
contain_buffer <- st_contains(iucn_target_buffer_10km, occs_sf)

df[, is_in_buffer := 0]
df[unlist(contain_buffer), is_in_buffer := 1]

p_buffer_sub <- ggplot() +
  geom_sf(data = continent, fill = NA, color = "gray70") +
  geom_sf(data = iucn_target_buffer_10km, aes(color = factor(SEASONAL)), fill = NA, linetype = "dashed") +
  geom_point(data = df, aes(x = x, y = y, color = factor(is_in_buffer)), size = 1.2) +
  scale_color_manual(values = c("0" = "gray60", "1" = "red")) +
  coord_sf(xlim = c(125, 135), ylim = c(45, 52), expand = FALSE) +
  theme_bw() +
  theme(axis.title = element_blank())
ggsave(p_buffer_sub, filename = "../Figures/IUCN_Filtered_buffer_sub.png")

# Export filtered occurrences
fwrite(df[is_in_buffer == 1, .(species, x, y)], "../Data/occ_buffer.csv")
cat("Occurrence filtering summary:\n")
print(table(df$is_in_buffer))

# ------------------------------------------------------------------------------
# Step 3: Comparative Visualizations of Precomputed Maxent Models
# ------------------------------------------------------------------------------

# Helper plotting function for Maxent raster predictions
plot_maxent_surface <- function(raster_path, title_text) {
  r <- rast(raster_path)
  r_df <- as.data.frame(r, xy = TRUE)
  setnames(r_df, names(r), "suitability")
  
  ggplot(r_df) +
    geom_tile(aes(x = x, y = y, fill = suitability)) +
    scale_fill_gradient2(low = "#005AB5", mid = "#FFFFFF", high = "#DC3220", 
                         midpoint = 0.5, limits = c(0, 1), name = "Suitability") +
    coord_sf(xlim = c(100, 150), ylim = c(22, 55), expand = FALSE) +
    labs(title = title_text) +
    theme_bw() +
    theme(axis.title = element_blank(), legend.position = "right")
}

# 3.1 Data subsetting effect: 10 km Buffer vs. Full raw dataset
print(plot_maxent_surface("../Data/Maxent/maxent.buffer/Grus_japonensis.asc", "Maxent (10km Buffered Dataset)"))
print(plot_maxent_surface("../Data/Maxent/maxent.full/Grus_japonensis.asc",   "Maxent (Full Unfiltered Dataset)"))

# 3.2 Individual feature class constraints
print(plot_maxent_surface("../Data/Maxent/maxent.linear/Grus_japonensis.asc",    "Maxent (Linear Features Only)"))
print(plot_maxent_surface("../Data/Maxent/maxent.quadratic/Grus_japonensis.asc", "Maxent (Quadratic Features Only)"))
print(plot_maxent_surface("../Data/Maxent/maxent.product/Grus_japonensis.asc",   "Maxent (Product Features Only)"))

# ------------------------------------------------------------------------------
# Step 4: Hyperparameter Optimization with ENMeval (maxnet)
# ------------------------------------------------------------------------------
cat("Preparing environmental data and running ENMevaluate...\n")

# Load environmental predictors
envs_files <- list.files('../Data/Bioclim', pattern = "\\.asc$", full.names = TRUE)
envs <- rast(envs_files)

# Clean occurrence coordinates against raster grid
occs_enmeval <- df[is_in_buffer == 1, .(x, y)]
setnames(occs_enmeval, c("x", "y"), c("lon", "lat"))
v_occs <- as.data.table(extract(envs, occs_enmeval))
occs_enmeval <- occs_enmeval[!is.na(rowSums(v_occs))]

# Generate 10,000 background points
bg_sample <- spatSample(envs[[1]], size = 10000, method = "random", as.points = TRUE, na.rm = TRUE)
bg_pts <- as.data.table(crds(bg_sample))
setnames(bg_pts, c("x", "y"), c("lon", "lat"))
v_bg <- as.data.table(extract(envs, bg_pts))
bg_pts <- bg_pts[!is.na(rowSums(v_bg))]

# Run grid search across Feature Classes and Regularization Multipliers
enmeval_result <- ENMevaluate(
  occs       = as.data.frame(occs_enmeval),
  envs       = envs,
  bg         = as.data.frame(bg_pts),
  algorithm  = 'maxnet',
  partitions = 'randomkfold',
  tune.args  = list(
    fc = c("L", "Q", "P", "LQ", "QP"),
    rm = c(0.1, 1, 10)
  )
)

# Extract and cache evaluation results
enmeval_elu <- as.data.table(enmeval_result@results)
saveRDS(enmeval_elu, "../Data/enmeval_elu.rda")

# 4.2 Model Selection: AICc vs. Training AUC Pareto Front
enmeval_elu[, label := paste(fc, rm, sep = " | rm=")]
best_models <- enmeval_elu[AICc == min(AICc, na.rm = TRUE) | auc.train == max(auc.train, na.rm = TRUE)]

p_tuning <- ggplot(enmeval_elu, aes(x = AICc, y = auc.train)) +
  geom_point(size = 2, color = "gray30") +
  geom_point(data = best_models, aes(x = AICc, y = auc.train), color = "#DC3220", shape = 4, size = 4, stroke = 1.5) +
  geom_label_repel(data = best_models, aes(x = AICc, y = auc.train, label = label), size = 3.5) +
  labs(
    title = "ENMeval Hyperparameter Selection (maxnet)",
    subtitle = "Red crosses mark minimum AICc (optimal model) and maximum training AUC",
    x = "AICc (Model Parsimony & Complexity Penalty)",
    y = "Training AUC (Fit Quality)"
  ) +
  theme_bw()

print(p_tuning)

# ------------------------------------------------------------------------------
# Step 5: Visualizing Optimal and Subsetted Predictions
# ------------------------------------------------------------------------------

# Optimal model across all bioclimatic layers
print(plot_maxent_surface("../Data/Maxent/maxent.enmeval.best/Grus_japonensis.asc", 
                          "Optimal Model (All Bioclim Predictors)"))

# Optimal model restricted to Bio1 and Bio12
print(plot_maxent_surface("../Data/Maxent/maxent.enmeval.best.1.12/Grus_japonensis.asc", 
                          "Optimal Model (Bio1 & Bio12 Only)"))

# Optimal model with low background point density (n = 100)
print(plot_maxent_surface("../Data/Maxent/maxent.enmeval.best.1.12.100bg/Grus_japonensis.asc", 
                          "Model with Limited Background Sampling (n = 100)"))

# ------------------------------------------------------------------------------
# Step 6: Geometric Envelopes, Convex Hulls, and Centroid Trajectories
# ------------------------------------------------------------------------------

# 6.1 Decompose multipart geometries into individual single polygons
iucn_polys <- st_cast(iucn_target, "POLYGON")

# 6.2 Calculate Minimum Convex Hulls
iucn_hull <- st_convex_hull(iucn_polys)

# 6.3 Calculate spatial centroids
center_polys <- st_centroid(iucn_polys)
center_hull  <- st_centroid(iucn_hull)

# Plot polygon envelope comparison
plot(st_geometry(iucn_hull[1, ]), col = "gray90", border = "black", linetype = "dashed",
     main = "Geometric Envelopes: Original Polygon vs. Convex Hull & Centroids")
plot(st_geometry(iucn_polys[1, ]), col = "red", border = "darkred", add = TRUE)
plot(st_geometry(center_polys[1, ]), pch = 2, col = "blue", cex = 1.5, lwd = 2, add = TRUE)
plot(st_geometry(center_hull[1, ]),  pch = 3, col = "black", cex = 1.5, lwd = 2, add = TRUE)
legend("topleft", legend = c("Convex Hull", "Original Range", "Range Centroid", "Hull Centroid"),
       col = c("gray90", "red", "blue", "black"), pch = c(NA, NA, 2, 3), lty = c(2, 1, NA, NA), lwd = 2)
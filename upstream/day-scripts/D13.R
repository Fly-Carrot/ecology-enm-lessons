# ==============================================================================
# Geographic Projections, Raster Transformation, and G- vs. E-Space Analysis
# ==============================================================================

# Install required packages if missing
# install.packages(c("sf", "terra", "ggplot2", "rnaturalearth", "rnaturalearthdata", "data.table", "patchwork"))

library(sf)
library(terra)
library(ggplot2)
library(rnaturalearth)
library(data.table)
library(patchwork)

# ------------------------------------------------------------------------------
# Part 1: Global Map Projections (Vector Transformations)
# ------------------------------------------------------------------------------

# 1.1 Load world boundary vector (WGS84 / EPSG:4326)
world_sf <- ne_countries(scale = "medium", returnclass = "sf")
world_dt <- as.data.table(world_sf)

# Base Geographic Coordinate System (Unprojected Longitude / Latitude)
p_lonlat <- ggplot(world_sf) +
  geom_sf(fill = "antiquewhite", color = "gray70", size = 0.3) +
  labs(title = "1. Geographic CRS (WGS84 / EPSG:4326)",
       subtitle = "Plate Carrée representation: Angular degrees on flat axes") +
  theme_minimal()
print(p_lonlat)

# 1.2 Azimuthal Equidistant Projections (Varying Centers)
# Definition: True distance and direction preserved from the projection center

# A. Centered at Equator / Prime Meridian (lon_0 = 0, lat_0 = 0)
crs_aeqd_origin <- "+proj=aeqd +lon_0=0 +lat_0=0 +datum=WGS84 +units=m +no_defs"
p_aeqd_origin <- ggplot(st_transform(world_sf, crs = crs_aeqd_origin)) +
  geom_sf(fill = "antiquewhite", color = "gray70", size = 0.3) +
  labs(title = "2. Azimuthal Equidistant (Origin: 0°E, 0°N)",
       subtitle = "Equatorial center view") +
  theme_minimal()
print(p_aeqd_origin)

# B. Centered at East Asia Equator (lon_0 = 110, lat_0 = 0)
crs_aeqd_asia <- "+proj=aeqd +lon_0=110 +lat_0=0 +datum=WGS84 +units=m +no_defs"
p_aeqd_asia <- ggplot(st_transform(world_sf, crs = crs_aeqd_asia)) +
  geom_sf(fill = "antiquewhite", color = "gray70", size = 0.3) +
  labs(title = "3. Azimuthal Equidistant (Origin: 110°E, 0°N)",
       subtitle = "Asia-Pacific equatorial focus") +
  theme_minimal()
print(p_aeqd_asia)

# C. Centered at North Pole (lon_0 = 0, lat_0 = 90) - Full Globe
crs_aeqd_polar <- "+proj=aeqd +lon_0=0 +lat_0=90 +datum=WGS84 +units=m +no_defs"
p_aeqd_polar <- ggplot(st_transform(world_sf, crs = crs_aeqd_polar)) +
  geom_sf(fill = "antiquewhite", color = "gray70", size = 0.3) +
  labs(title = "4. Polar Azimuthal Equidistant (North Pole)",
       subtitle = "Notice extreme peripheral stretching along outer boundary") +
  theme_minimal()
print(p_aeqd_polar)

# D. Polar Projection Excluding Antarctica (UN Logo Perspective)
# Filter Antarctica using data.table row selection on sf object
world_no_ata <- st_as_sf(world_dt[sov_a3 != "ATA"])

p_aeqd_un_0 <- ggplot(st_transform(world_no_ata, crs = crs_aeqd_polar)) +
  geom_sf(fill = "antiquewhite", color = "gray70", size = 0.3) +
  labs(title = "5. Polar Azimuthal Equidistant (Excl. Antarctica)",
       subtitle = "lon_0 = 0°, lat_0 = 90° (Prime meridian orientation)") +
  theme_minimal()
print(p_aeqd_un_0)

# E. Polar Projection Rotated (lon_0 = 90, lat_0 = 90)
crs_aeqd_polar_rot <- "+proj=aeqd +lon_0=90 +lat_0=90 +datum=WGS84 +units=m +no_defs"
p_aeqd_un_90 <- ggplot(st_transform(world_no_ata, crs = crs_aeqd_polar_rot)) +
  geom_sf(fill = "antiquewhite", color = "gray70", size = 0.3) +
  labs(title = "6. Polar Azimuthal Equidistant (Rotated)",
       subtitle = "lon_0 = 90°E, lat_0 = 90° (Asian meridian orientation)") +
  theme_minimal()
print(p_aeqd_un_90)

# 1.3 Equal-Area Projection (Mollweide)
crs_mollweide <- "+proj=moll +lon_0=0 +datum=WGS84 +units=m +no_defs"
p_mollweide <- ggplot(st_transform(world_sf, crs = crs_mollweide)) +
  geom_sf(fill = "antiquewhite", color = "gray70", size = 0.3) +
  labs(title = "7. Mollweide Pseudocylindrical Equal-Area Projection",
       subtitle = "Preserves area globally (Distorts shape at high latitudes)") +
  theme_minimal()
print(p_mollweide)


# ------------------------------------------------------------------------------
# Part 2: Environmental Raster Extraction & Processing
# ------------------------------------------------------------------------------

# 2.1 Load continuous raster surfaces
# Update paths to your local bioclimatic ASCII rasters as needed
bio1  <- rast("../Data/bioclim/bio1.asc")   # Annual Mean Temperature
bio12 <- rast("../Data/bioclim/bio12.asc")  # Annual Precipitation

# Reproject raster to Azimuthal Equidistant CRS
bio1_aeqd <- project(bio1, crs_aeqd_origin)

# 2.2 Convert SpatRaster objects to data.tables and merge
dt_bio1  <- as.data.table(as.data.frame(bio1, xy = TRUE, na.rm = TRUE))
dt_bio12 <- as.data.table(as.data.frame(bio12, xy = TRUE, na.rm = TRUE))

setnames(dt_bio1, old = names(bio1), new = "bio1")
setnames(dt_bio12, old = names(bio12), new = "bio12")

# Set keys on spatial coordinates for high-speed inner joining
setkey(dt_bio1, x, y)
setkey(dt_bio12, x, y)
clim_dt <- dt_bio1[dt_bio12, nomatch = NULL]

# 2.3 Create standardized long-format data.table for facet visualizations
long_clim_dt <- melt(
  clim_dt,
  id.vars = c("x", "y"),
  measure.vars = c("bio1", "bio12"),
  variable.name = "var",
  value.name = "v"
)

# Standardize variables (Z-score scaling per group using data.table syntax)
long_clim_dt[, scale_v := as.numeric(scale(v)), by = var]

# Plot 1: Raw Environmental Surface Maps
p_raw_map <- ggplot(long_clim_dt, aes(x = x, y = y, fill = v)) +
  geom_tile() +
  facet_wrap(~ var, nrow = 2, scales = "free") +
  scale_fill_viridis_c(option = "magma") +
  coord_cartesian() +
  labs(title = "Raw Environmental Variables (G-Space)", x = "Longitude", y = "Latitude") +
  theme_minimal()
print(p_raw_map)

# Plot 2: Standardized Surface Maps (Z-Score)
p_scale_map <- ggplot(long_clim_dt, aes(x = x, y = y, fill = scale_v)) +
  geom_tile() +
  facet_wrap(~ var, nrow = 2) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0) +
  coord_cartesian() +
  labs(title = "Standardized Climate Variables (Z-Score)", x = "Longitude", y = "Latitude") +
  theme_minimal()
print(p_scale_map)

# Plot 3: Standardized Climate Distributions (Histograms)
p_hist <- ggplot(long_clim_dt, aes(x = scale_v, fill = var)) +
  geom_histogram(bins = 50, color = "black", alpha = 0.7) +
  facet_wrap(~ var, nrow = 2, scales = "free_y") +
  labs(title = "Frequency Distribution of Standardized Predictors", x = "Standardized Value (Z-score)", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none")
print(p_hist)


# ------------------------------------------------------------------------------
# Part 3: Geographic Space (G-Space) vs. Environmental Space (E-Space)
# ------------------------------------------------------------------------------

# 3.1 Convert merged climate table to sf points for spatial querying
clim_pts_sf <- st_as_sf(clim_dt, coords = c("x", "y"), crs = 4326, remove = FALSE)

# Generate a uniform background sample for rapid E-space plotting
set.seed(42)
bg_sampled_dt <- clim_dt[sample(.N, 1000)]

# 3.2 Modular function to extract country points and plot G- vs. E-Space
analyze_country_niche <- function(iso_codes, country_label, highlight_color = "red") {
  
  # Extract country boundary polygon
  country_sf <- st_as_sf(world_dt[iso_a3 %in% iso_codes])
  
  # Spatial intersection: Identify points falling inside the country boundary
  intersect_idx <- which(lengths(st_within(clim_pts_sf, country_sf)) > 0)
  country_pts_dt <- clim_dt[intersect_idx]
  
  # Plot A: Geographic Boundary Context
  p_geo_context <- ggplot() +
    geom_sf(data = world_sf, fill = "gray95", color = "gray80", size = 0.2) +
    geom_sf(data = country_sf, fill = highlight_color, color = "black", size = 0.4) +
    coord_sf(expand = FALSE) +
    labs(title = paste0(country_label, ": Geographic Location"), x = "", y = "") +
    theme_minimal()
  
  # Plot B: Geographic Space Overlay (G-Space)
  p_g_space <- ggplot() +
    geom_point(data = bg_sampled_dt, aes(x = x, y = y), color = "gray80", size = 0.8, alpha = 0.5) +
    geom_point(data = country_pts_dt, aes(x = x, y = y), color = highlight_color, size = 1.2) +
    coord_fixed() +
    labs(title = paste0(country_label, ": G-Space (Coordinates)"), x = "Longitude", y = "Latitude") +
    theme_minimal()
  
  # Plot C: Environmental Space Occupation (E-Space)
  p_e_space <- ggplot() +
    geom_point(data = bg_sampled_dt, aes(x = bio1, y = bio12), color = "gray80", size = 0.8, alpha = 0.5) +
    geom_point(data = country_pts_dt, aes(x = bio1, y = bio12), color = highlight_color, size = 1.2, alpha = 0.6) +
    labs(title = paste0(country_label, ": E-Space (Bio1 vs Bio12)"), 
         x = "Bio1 (Annual Mean Temp)", y = "Bio12 (Annual Precip)") +
    theme_minimal()
  
  # Combine with patchwork
  combined <- (p_geo_context | p_g_space | p_e_space)
  print(combined)
  
  return(country_pts_dt)
}

# 3.3 Execute analyses across contrasting biogeographic regions
cat("Extracting and mapping country climate envelopes...\n")

mys_dt <- analyze_country_niche("MYS", "Malaysia (Tropical Rainforest)", highlight_color = "#00BA38")
lby_dt <- analyze_country_niche("LBY", "Libya (Hot Arid Desert)",       highlight_color = "#E69F00")
col_dt <- analyze_country_niche("COL", "Colombia (Tropical Montane)",    highlight_color = "#0072B2")
chn_dt <- analyze_country_niche(c("CHN", "TWN"), "China (Temperate to Subtropical)", highlight_color = "#D55E00")

# 3.4 Multi-Country Niche Overlay in Shared Environmental Space
p_niche_comp <- ggplot() +
  # Global background points
  geom_point(data = bg_sampled_dt, aes(x = bio1, y = bio12), color = "gray85", size = 0.8, alpha = 0.5) +
  # Regional niche envelopes
  geom_point(data = col_dt, aes(x = bio1, y = bio12, color = "Colombia"), alpha = 0.3, size = 1.2) +
  geom_point(data = chn_dt, aes(x = bio1, y = bio12, color = "China"), alpha = 0.3, size = 1.2) +
  geom_point(data = lby_dt, aes(x = bio1, y = bio12, color = "Libya"), alpha = 0.3, size = 1.2) +
  geom_point(data = mys_dt, aes(x = bio1, y = bio12, color = "Malaysia"), alpha = 0.3, size = 1.2) +
  scale_color_manual(
    name = "Country Climate Space",
    values = c(
      "Colombia"       = "#0072B2",
      "China" = "#D55E00",
      "Libya"          = "#E69F00",
      "Malaysia"       = "#00BA38"
    )
  ) +
  labs(
    title = "Macroclimatic Niche Realization Across Biogeographic Realms",
    subtitle = "Points projected into bivariate Environmental Space (Bio1 vs. Bio12)",
    x = "Bio1: Annual Mean Temperature (°C / Scaled)",
    y = "Bio12: Annual Precipitation (mm)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom"
  )

print(p_niche_comp)

# ==============================================================================
# Day 0: Vector vs. Raster, Projections, and Coordinate Transformations
# ==============================================================================

# Install required packages if missing
# install.packages(c("sf", "terra", "ggplot2", "rnaturalearth", "rnaturalearthdata", "data.table"))

library(sf)             # For Vector data manipulation
library(terra)          # For Raster data manipulation
library(ggplot2)        # For mapping and visualization
library(rnaturalearth)  # For global map datasets
library(data.table)     # For tabular manipulation

# ------------------------------------------------------------------------------
# Part 1: Vector vs. Raster Representation
# ------------------------------------------------------------------------------
cat("Visualizing the difference between Vector and Raster data...\n")

# 1.1 Create a Vector object (A mathematical perfect polygon/circle)
# We define a point and buffer it to create a perfect circle
center_pt <- st_sfc(st_point(c(0, 0)))
vector_poly <- st_buffer(center_pt, dist = 10) # Vector representation (Polygon)

# 1.2 Convert to Raster (Rasterization) at two different resolutions
# Create an empty raster template
template_coarse <- rast(ext(-15, 15, -15, 15), resolution = 2)
template_fine   <- rast(ext(-15, 15, -15, 15), resolution = 0.5)

# Rasterize the polygon (Value 1 inside the polygon, NA outside)
raster_coarse <- rasterize(vect(vector_poly), template_coarse, field = 1)
raster_fine   <- rasterize(vect(vector_poly), template_fine, field = 1)

# Visualization
par(mfrow = c(1, 3))
plot(vector_poly, col = "lightblue", main = "1. Vector (Polygon)\nContinuous math shape", border = "blue")
plot(raster_coarse, col = "lightblue", main = "2. Raster (Coarse)\nDiscrete grid (res=2)", legend = FALSE)
plot(raster_fine, col = "lightblue", main = "3. Raster (Fine)\nDiscrete grid (res=0.5)", legend = FALSE)
par(mfrow = c(1, 1))

# ------------------------------------------------------------------------------
# Part 2 & 3: Understanding Projections (Cylindrical vs. Conic)
# ------------------------------------------------------------------------------
cat("Demonstrating map projections: Geographic -> Cylindrical -> Conic...\n")

# Load world map as a vector sf object (Geographic CRS: WGS84, Lat/Lon)
world <- ne_countries(scale = "medium", returnclass = "sf")

# 1. Geographic (Unprojected) - WGS84 EPSG:4326
# The earth is treated as a 3D globe, coordinates are angles (degrees).
plot_geo <- ggplot(data = world) +
  geom_sf(fill = "antiquewhite") +
  theme_minimal() +
  labs(title = "Geographic (WGS84: Degrees)",
       subtitle = "Not a true 2D map, just plotting angles as X/Y.")

# 2. Cylindrical Projection (e.g., Mercator)
# Concept: Wrap a cylinder around the equator. 
# Result: Lat/Lon lines form perfect 90-degree rectangles. Extreme distortion at poles.
# PROJ string: +proj=merc
plot_cyl <- ggplot(data = world) +
  geom_sf(fill = "antiquewhite") +
  coord_sf(crs = "+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") +
  theme_minimal() +
  labs(title = "Cylindrical Projection (Mercator)",
       subtitle = "Notice the rectangular graticules. Antarctica becomes infinitely huge.")

# 3. Conic Projection (e.g., Lambert Conformal Conic)
# Concept: Place a cone over a hemisphere (touching at specific latitudes).
# Result: Longitude lines fan out from the pole, Latitude lines are curved arcs.
# PROJ string: +proj=lcc +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=0
plot_conic <- ggplot(data = world) +
  geom_sf(fill = "antiquewhite") +
  coord_sf(crs = "+proj=lcc +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +units=m") +
  theme_minimal() +
  labs(title = "Conic Projection (LCC)",
       subtitle = "Notice the fan-shaped graticules. Best for mid-latitude countries like China/USA.")

# To display these together in a real script, you could use the 'patchwork' package.
print(plot_cyl)
print(plot_conic)

# ------------------------------------------------------------------------------
# Part 4: The UN Emblem (Azimuthal Equidistant Projection)
# ------------------------------------------------------------------------------
cat("Recreating the United Nations Logo Projection...\n")

# The UN Logo uses an Azimuthal Equidistant projection centered on the North Pole.
# Concept: Projecting outward from a single center point. Distance from center is true.
# PROJ definition: +proj=aeqd (Azimuthal Equidistant), +lat_0=90 (North Pole center)

# The official UN emblem only goes down to 60 degrees South latitude (cutting off Antarctica).
# We use data.table syntax on the sf object's embedded data frame to filter it out.
# Note: sf objects behave like data.frames, so data.table can filter their rows.
world_dt <- as.data.table(world)
world_un_filtered <- st_as_sf(world_dt[continent != "Antarctica"])

# Define the exact projection used by the UN
un_crs <- "+proj=aeqd +lat_0=90 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

# Transform the world map to the UN projection
world_un <- st_transform(world_un_filtered, crs = un_crs)

# Create a target-like bounding circle (the outline of the UN logo)
# We draw a buffer from the North Pole reaching down to 60°S.
# (Radius roughly equates to degrees * meters-per-degree: 150 deg * 111.32 km)
pole_pt <- st_sfc(st_point(c(0, 0)), crs = un_crs)
un_boundary <- st_buffer(pole_pt, dist = 16680000) # approximate 60S boundary in meters

# Plotting the UN Emblem style map
un_logo_plot <- ggplot() +
  # Draw the outer boundary and the graticules background
  geom_sf(data = un_boundary, fill = "#005b9f", color = "white", size = 1) +
  
  # Draw the projected continents
  geom_sf(data = world_un, fill = "white", color = "#005b9f", size = 0.2) +
  
  # Force ggplot to draw concentric circle graticules (like a target)
  coord_sf(crs = un_crs, datum = un_crs, expand = FALSE) +
  
  # Styling to match the UN aesthetics
  theme_void() +
  theme(
    panel.grid.major = element_line(color = "white", size = 0.5), # White spiderweb lines
    plot.background = element_rect(fill = "white", color = NA),
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5, color = "#005b9f"),
    plot.subtitle = element_text(hjust = 0.5, color = "gray40")
  ) +
  labs(title = "Azimuthal Equidistant Projection",
       subtitle = "Centered on the North Pole (The UN Emblem Geometry)")

print(un_logo_plot)
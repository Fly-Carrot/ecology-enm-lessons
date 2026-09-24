# ==============================================================================
# Geometric and Mathematical Foundations of Cylindrical and Conic Projections
# ==============================================================================

# Install required libraries if missing
# install.packages(c("data.table", "ggplot2", "patchwork"))

library(data.table)
library(ggplot2)
library(patchwork)

# ------------------------------------------------------------------------------
# Part 1: Cross-Section Ray-Tracing Geometry (Side Profile in r-z Plane)
# ------------------------------------------------------------------------------
cat("Generating cross-section ray-tracing geometries...\n")

R <- 1 # Unit Earth Radius

# 1.1 Sphere Profile (Quarter Circle: 0 to 90 degrees latitude)
angles_rad <- seq(0, pi/2, length.out = 200)
dt_sphere <- data.table(
  r = R * cos(angles_rad),
  z = R * sin(angles_rad)
)

# 1.2 Ray Tracing Angles (Equator, 30°, 45°, 60°, 75°)
target_lats_deg <- c(0, 30, 45, 60, 75)
target_lats_rad <- target_lats_deg * (pi / 180)

# --- Cylindrical Cross-Section Geometry ---
# Cylinder touches at Equator (r = R = 1, z goes from 0 to 4)
dt_cyl_surface <- data.table(r = c(R, R), z = c(0, 3.8))

# Rays from origin (0,0) to cylinder at r = 1: z_cyl = R * tan(phi)
dt_cyl_rays <- rbindlist(lapply(target_lats_rad, function(p) {
  z_hit <- R * tan(p)
  data.table(
    lat_deg = round(p * 180 / pi),
    r_start = 0, z_start = 0,
    r_sphere = R * cos(p), z_sphere = R * sin(p),
    r_cyl = R, z_cyl = z_hit
  )
}))

# --- Conic Cross-Section Geometry (Tangent at phi_0 = 45°) ---
phi_0 <- 45 * (pi / 180)
apex_z <- R / sin(phi_0) # Apex height on z-axis = 1 / sin(45°) ≈ 1.414

# Cone slant line: connects Apex (0, apex_z) to Tangent Point (cos(phi_0), sin(phi_0)) and extends
dt_cone_surface <- data.table(
  r = c(0, cos(phi_0), 1.2 * cos(phi_0)),
  z = c(apex_z, sin(phi_0), sin(phi_0) - 0.2 * (apex_z - sin(phi_0)))
)

# Rays intersecting the tangent cone slant line
# Slant line equation in (r, z): z - sin(phi_0) = -tan(90 - phi_0) * (r - cos(phi_0))
# Ray equation: z = tan(phi) * r
# Intersection: r_hit = (sin(phi_0) + cot(phi_0)*cos(phi_0)) / (tan(phi) + cot(phi_0))
cot_phi0 <- 1 / tan(phi_0)
dt_cone_rays <- rbindlist(lapply(target_lats_rad[target_lats_rad > 0 & target_lats_rad <= 75 * pi / 180], function(p) {
  r_hit <- (sin(phi_0) + cot_phi0 * cos(phi_0)) / (tan(p) + cot_phi0)
  z_hit <- r_hit * tan(p)
  data.table(
    lat_deg = round(p * 180 / pi),
    r_start = 0, z_start = 0,
    r_sphere = R * cos(p), z_sphere = R * sin(p),
    r_cone = r_hit, z_cone = z_hit
  )
}))

# ------------------------------------------------------------------------------
# Part 2: Unrolling Developable Surfaces to 2D Coordinates (X, Y)
# ------------------------------------------------------------------------------
cat("Computing unrolled 2D map grids from analytical equations...\n")

# Longitude: -180° to 180°, Latitude: -75° to 75° (excluding poles for stability)
grid_lons <- seq(-180, 180, by = 15)
grid_lats <- seq(-75, 75, by = 15)

# --- A. Unrolling Cylindrical Grid ---
# Formula: X = R * lambda, Y = R * tan(phi) (Central Cylindrical)
cyl_meridians <- rbindlist(lapply(grid_lons, function(lon) {
  lats <- seq(-75, 75, length.out = 100)
  data.table(
    lon = lon,
    lat = lats,
    X = R * (lon * pi / 180),
    Y = R * tan(lats * pi / 180),
    group = paste0("lon_", lon)
  )
}))

cyl_parallels <- rbindlist(lapply(grid_lats, function(lat) {
  lons <- seq(-180, 180, length.out = 100)
  data.table(
    lon = lons,
    lat = lat,
    X = R * (lons * pi / 180),
    Y = R * tan(lat * pi / 180),
    group = paste0("lat_", lat)
  )
}))

# --- B. Unrolling Conic Grid ---
# Formula: Simple Conic (Equidistant) tangent at phi_0 = 45° N
# n = sin(phi_0), rho(phi) = R * cot(phi_0) - R * (phi - phi_0)
# theta = n * (lambda - lambda_0), X = rho * sin(theta), Y = rho_0 - rho * cos(theta)
n_const <- sin(phi_0)
rho_0 <- R * cot_phi0

conic_meridians <- rbindlist(lapply(grid_lons, function(lon) {
  lats <- seq(0, 85, length.out = 100)
  lats_rad <- lats * pi / 180
  rho <- rho_0 - R * (lats_rad - phi_0)
  theta <- n_const * (lon * pi / 180)
  data.table(
    lon = lon,
    lat = lats,
    X = rho * sin(theta),
    Y = rho_0 - rho * cos(theta),
    group = paste0("lon_", lon)
  )
}))

conic_parallels <- rbindlist(lapply(seq(0, 85, by = 15), function(lat) {
  lons <- seq(-180, 180, length.out = 200)
  lat_rad <- lat * pi / 180
  rho <- rho_0 - R * (lat_rad - phi_0)
  theta <- n_const * (lons * pi / 180)
  data.table(
    lon = lons,
    lat = lat,
    X = rho * sin(theta),
    Y = rho_0 - rho * cos(theta),
    group = paste0("lat_", lat)
  )
}))

# ------------------------------------------------------------------------------
# Part 3: Rendering the 4-Panel Educational Layout
# ------------------------------------------------------------------------------
cat("Plotting geometry profiles and unrolled coordinates...\n")

# Panel 1: Cylindrical Cross-Section Geometry
p1_geo <- ggplot() +
  geom_path(data = dt_sphere, aes(x = r, y = z), size = 1.2, color = "gray20") +
  geom_segment(data = dt_cyl_surface, aes(x = r[1], y = z[1], xend = r[2], yend = z[2]), 
               size = 1.5, color = "#0072B2") +
  geom_segment(data = dt_cyl_rays, aes(x = 0, y = 0, xend = r_cyl, yend = z_cyl), 
               linetype = "dashed", color = "#D55E00", size = 0.6) +
  geom_point(data = dt_cyl_rays, aes(x = r_sphere, y = z_sphere), color = "black", size = 2) +
  geom_point(data = dt_cyl_rays, aes(x = r_cyl, y = z_cyl), color = "#0072B2", size = 2.5) +
  geom_text(data = dt_cyl_rays[lat_deg <= 60], aes(x = r_cyl + 0.1, y = z_cyl, label = paste0(lat_deg, "° -> Y = ", round(z_cyl, 2))), 
            hjust = 0, size = 3, fontface = "bold") +
  annotate("text", x = 0.5, y = 0.1, label = "R = 1", fontface = "italic") +
  annotate("text", x = 1.05, y = 3.6, label = "Cylinder Surface\n(r = R)", color = "#0072B2", fontface = "bold", hjust = 0) +
  coord_fixed(xlim = c(0, 2.5), ylim = c(0, 4)) +
  labs(
    title = "A. Cylindrical Projection: 3D Cross-Section",
    subtitle = "Ray from origin (0,0) projects latitude phi onto cylinder (r=R):\nFormula: Y = R * tan(phi)",
    x = "Radial Distance (r)", y = "Axial Height (z)"
  ) +
  theme_bw()

# Panel 2: Conic Cross-Section Geometry
p2_geo <- ggplot() +
  geom_path(data = dt_sphere, aes(x = r, y = z), size = 1.2, color = "gray20") +
  geom_path(data = dt_cone_surface, aes(x = r, y = z), size = 1.5, color = "#009E73") +
  geom_segment(data = dt_cone_rays, aes(x = 0, y = 0, xend = r_cone, yend = z_cone), 
               linetype = "dashed", color = "#D55E00", size = 0.6) +
  geom_point(data = dt_cone_rays, aes(x = r_sphere, y = z_sphere), color = "black", size = 2) +
  geom_point(data = dt_cone_rays, aes(x = r_cone, y = z_cone), color = "#009E73", size = 2.5) +
  annotate("point", x = 0, y = apex_z, color = "red", size = 3) +
  annotate("text", x = 0.08, y = apex_z, label = "Cone Apex\nz = R/sin(phi_0)", hjust = 0, size = 3) +
  annotate("point", x = cos(phi_0), y = sin(phi_0), color = "purple", size = 3.5) +
  annotate("text", x = cos(phi_0) + 0.08, y = sin(phi_0), label = "Tangent Point (phi_0 = 45°)", color = "purple", fontface = "bold", hjust = 0, size = 3) +
  coord_fixed(xlim = c(0, 1.8), ylim = c(0, 2)) +
  labs(
    title = "B. Conic Projection: 3D Cross-Section",
    subtitle = "Cone placed tangent at standard parallel phi_0 = 45°.\nRays project from center onto slant cone line.",
    x = "Radial Distance (r)", y = "Axial Height (z)"
  ) +
  theme_bw()

# Panel 3: Unrolled Cylindrical Map Grid
p3_unroll <- ggplot() +
  geom_line(data = cyl_meridians, aes(x = X, y = Y, group = group), color = "gray70", size = 0.4) +
  geom_line(data = cyl_parallels, aes(x = X, y = Y, group = group), color = "#0072B2", size = 0.6) +
  geom_hline(yintercept = 0, color = "black", size = 0.8) +
  annotate("text", x = 0, y = 0.2, label = "Equator (phi = 0°): Standard Line with Zero Distortion", fontface = "bold", size = 3.2) +
  coord_fixed(ylim = c(-3.8, 3.8)) +
  labs(
    title = "C. Unrolled Cylindrical Surface (2D Map)",
    subtitle = "Rectangular grid: Parallels stretch toward infinity at poles (Y -> Inf as phi -> 90°)",
    x = "X = R * (lambda - lambda_0)", y = "Y = R * tan(phi)"
  ) +
  theme_bw()

# Panel 4: Unrolled Conic Map Grid
p4_unroll <- ggplot() +
  geom_line(data = conic_meridians, aes(x = X, y = Y, group = group), color = "gray70", size = 0.4) +
  geom_line(data = conic_parallels, aes(x = X, y = Y, group = group), color = "#009E73", size = 0.6) +
  geom_line(data = conic_parallels[lat == 45], aes(x = X, y = Y), color = "purple", size = 1.1) +
  annotate("text", x = 0, y = 0.15, label = "Standard Parallel (phi_0 = 45°): True Scale Arc", color = "purple", fontface = "bold", size = 3.2) +
  coord_fixed(xlim = c(-2.5, 2.5), ylim = c(-1.5, 1.8)) +
  labs(
    title = "D. Unrolled Conic Surface (2D Map)",
    subtitle = "Fan-shaped grid: Concentric arcs (parallels) & radiating lines (meridians)",
    x = "X = rho(phi) * sin(n * lambda)", y = "Y = rho_0 - rho(phi) * cos(n * lambda)"
  ) +
  theme_bw()

# Combine All 4 Panels (Top: Geometric Cross-sections, Bottom: Unrolled 2D Map Grids)
master_projection_plot <- (p1_geo | p2_geo) / (p3_unroll | p4_unroll) +
  plot_annotation(
    title = "The Mathematical Mechanics of Map Projections: Developing the Sphere",
    subtitle = "Comparing ray-traced intersections on developable 3D surfaces vs. their unrolled 2D Cartesian coordinates",
    theme = theme(plot.title = element_text(face = "bold", size = 15))
  )

print(master_projection_plot)
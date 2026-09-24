# ==========================================
# 1. Load Required Packages
# ==========================================
# If not installed, run:
# install.packages(c("readxl", "data.table", "ggplot2", "ggrepel", "maps"))
library(readxl)
library(data.table)
library(ggplot2)
library(ggrepel)
library(maps)
library(showtext)
font_add_google("Noto Sans SC", "chinese_font")
showtext_auto()
# ==========================================
# 2. Read and Aggregate Data (data.table)
# ==========================================
# Read Sheet2 from list.xlsx and convert to data.table
dt <- as.data.table(read_excel("../list.xlsx", sheet = "Sheet2"))

# Aggregate count and coordinates by Abbreviation and City
dt_summary <- dt[, .(
  count = .N,
  lon = mean(as.numeric(Lon), na.rm = TRUE),
  lat = mean(as.numeric(Lat), na.rm = TRUE)
), by = .(Abbr, City)]

# Generate label text: "Abbr (Count)"
dt_summary[, label_text := paste0(Abbr, " (", count, ")")]

# Inspect summary
print(dt_summary)

# ==========================================
# 3. Plot Map with Guide Lines
# ==========================================
china_map <- map_data("world")

p <- ggplot() +
  # 1. Base map layer
  geom_polygon(data = china_map, aes(x = long, y = lat, group = group),
               fill = "#f4f6f9", color = "#b8c2cc", linewidth = 0.3) +
  
  # 2. Points layer (size mapped to frequency)
  geom_point(data = dt_summary, aes(x = lon, y = lat, size = count),
             color = "#e63946", alpha = 0.8) +
  
  # 3. Pointer lines and labels
  geom_label_repel(
    data = dt_summary,
    aes(x = lon, y = lat, label = label_text),
    size = 4,
    color = "#1d3557",
    fill = alpha("white", 0.85),
    label.padding = unit(0.2, "lines"),
    label.size = 0.2,
    box.padding = 0.4,
    point.padding = 0.3,
    segment.color = "#457b9d",
    segment.size = 0.5,
    segment.alpha = 0.7,
    arrow = arrow(length = unit(0.015, "npc"), type = "closed"),
    max.overlaps = 50,
    force = 3
  ) +
  
  # 4. Map projection and display limits
  coord_fixed(ratio = 1.2, xlim = c(65, 140), ylim = c(5, 52)) +
  
  # 5. Scales and Theme Styling
  scale_size_continuous(range = c(2, 6), breaks = c(1, 3, 5, 10), name = "Frequency") +
  labs(
    title = "Geographical Distribution of Participants",
    x = "Longitude (°E)",
    y = "Latitude (°N)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(color = "gray40", size = 11, hjust = 0.5, margin = margin(b = 10)),
    panel.background = element_rect(fill = "#ffffff", color = NA),
    panel.grid.major = element_line(color = "#f0f0f0", linetype = "dashed", linewidth = 0.3),
    panel.grid.minor = element_blank(),
    legend.position = "right",
    axis.title = element_blank()
  )

# Display plot
print(p)

# Save to file (optional)
ggsave(
  filename = "../Figures/Participants_distribution_map.pdf",
  plot = p,
  #device = cairo_pdf,
  width = 12,
  height = 9,
  dpi = 300
)


# Level A: Count applicants per school within each city
school_agg <- dt[, .(count = .N), by = .(City, Abbr)]

# Format each institution item as "Abbr (count)"
school_agg[, school_item := paste0(Abbr, " (", count, ")")]

# Level B: Aggregate at the City level and bundle all schools into one multi-line block
city_dt <- school_agg[, .(
  schools_list = paste(school_item, collapse = "\n"),
  n_types      = .N
), by = .(City)]

# Calculate total applicant count and mean coordinates for each city
city_coords <- dt[, .(
  total_count = .N,
  lon = mean(as.numeric(Lon), na.rm = TRUE),
  lat = mean(as.numeric(Lat), na.rm = TRUE)
), by = .(City)]

# Merge to construct the master city summary dataset
city_summary <- merge(city_coords, city_dt, by = "City")

# Create the full multi-line label text: "[City]: N\nDetail 1\nDetail 2..."
city_summary[, label_text := paste0("[", City, "]: ", total_count, "\n", schools_list)]

# ==============================================================================
# 3. Outer-Ring Projection Algorithm (Push All Labels Outside China Map)
# ==============================================================================
# Approximate geographic reference center of mainland China
center_lon <- 108.0
center_lat <- 34.0

# 1. Compute raw geographic bearing angle (radians) from national center to each city
city_summary[, raw_angle := atan2(lat - center_lat, (lon - center_lon) * 1.15)]

# 2. Sort cities by geographic bearing to prevent spoke lines from crossing
setorder(city_summary, raw_angle)

# 3. Evenly distribute target angles around the 360-degree perimeter to eliminate label overlap
n_cities <- nrow(city_summary)
city_summary[, target_angle := seq(-pi + 0.1, pi - 0.1, length.out = n_cities)]

# 4. Outer Ring Radius: Define perimeter boundary ring beyond China borders
# Longitude radius Rx ~ 30°, Latitude radius Ry ~ 23°
Rx <- 30.0
Ry <- 23.0

city_summary[, `:=`(
  xend = center_lon + Rx * cos(target_angle),
  yend = center_lat + Ry * sin(target_angle)
)]

# Inspect processed coordinates
print(city_summary[, .(City, total_count, lon, lat, xend, yend)])

# ==============================================================================
# 4. Visualization: Map with Perimeter Spoke Labels
# ==============================================================================
# Retrieve China boundary polygon
china_map <- map_data("world", region = c("China", "Taiwan"))

p <- ggplot() +
  # 1. Background map layer
  geom_polygon(data = china_map, aes(x = long, y = lat, group = group),
               fill = "#f2f4f8", color = "#bdc3c7", linewidth = 0.3) +
  
  # 2. Straight radial spoke lines from internal city nodes to outer perimeter labels
  geom_segment(data = city_summary,
               aes(x = lon, y = lat, xend = xend, yend = yend),
               color = "#4a69bd", linewidth = 0.4, alpha = 0.7,
               arrow = arrow(length = unit(0.012, "npc"), type = "closed")) +
  
  # 3. Internal map: City bubbles (size mapped to total applicants in that city)
  geom_point(data = city_summary,
             aes(x = lon, y = lat, size = total_count),
             color = "#e55039", fill = "#eb2f06", alpha = 0.85, shape = 21, stroke = 0.8) +
  
  # 4. Internal map: City name label positioned under the bubble
  geom_text(data = city_summary,
            aes(x = lon, y = lat, label = City),
            family = "roboto_font",
            fontface = "bold", size = 4,
            color = "#1e272e", vjust = 1.8) +
  
  # 5. External Perimeter: Consolidated multi-line label boxes outside the map
  geom_label_repel(data = city_summary,
             aes(x = xend, y = yend, label = label_text),
             size = 4, color = "#2c3e50",
             fill = alpha("#ffffff", 0.92), label.size = 0.2,
             label.padding = unit(0.2, "lines"), lineheight = 0.95) +
  
  # 6. Expanded canvas limits to fit perimeter labels comfortably
  coord_fixed(ratio = 1.2, xlim = c(68, 148), ylim = c(6, 62)) +
  
  # 7. Scales, legends, and styling
  scale_size_area(max_size = 10, name = "City Total Applicants") +
  labs(
    title = "Geographical Distribution of University & Institute Applicants",
    x = "Longitude (°E)",
    y = "Latitude (°N)"
  ) +
  theme_minimal(base_size = 12, base_family = "sans") +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0.5),
    plot.subtitle = element_text(color = "gray40", size = 10, hjust = 0.5, margin = margin(b = 12)),
    panel.background = element_rect(fill = "#fafbfc", color = NA),
    panel.grid.major = element_line(color = "#ebeef0", linetype = "dashed", linewidth = 0.25),
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    axis.title = element_blank()
  )

# Display plot
print(p)

# ==============================================================================
# 5. Export to Vector PDF (Clean Vector Embedding)
# ==============================================================================
ggsave(
  filename = "../Figures/Participants_distribution_map_2.pdf",
  plot = p,
  width = 16,
  height = 12,
  dpi = 300
)


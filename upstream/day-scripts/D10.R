# ==============================================================================
# Day 10: The Scales of Time and Space in Macroecology
# ==============================================================================

# Install required packages if missing
# install.packages(c("ggplot2", "data.table", "patchwork"))

library(ggplot2)
library(data.table)
library(patchwork)

# ------------------------------------------------------------------------------
# Part 1: The Temporal Scale (Simulating Deep Time to Future Climate)
# ------------------------------------------------------------------------------
cat("Generating scientifically representative climate curves across 4 time scales...\n")

# Note: For teaching, we simulate curves that mimic the exact shape of real proxy data
# (e.g., Zachos 2001 for Deep Time, EPICA Ice Cores for Pleistocene, CMIP6 for Future).

# 1.1 Phanerozoic (500 Million Years Ago to Present)
# Mimicking major greenhouse (Mesozoic) and icehouse periods.
dt_500ma <- data.table(Time_Ma = seq(-500, 0, by = 1))
dt_500ma[, TempAnomaly := 5 * sin(Time_Ma / 20) + 10 * exp(Time_Ma / 300) + rnorm(.N, 0, 1)]

# 1.2 Pliocene-Pleistocene (3.6 Million Years Ago to Present)
# Mimicking Milankovitch cycles (41k to 100k year glaciation cycles)
dt_3ma <- data.table(Time_Ma = seq(-3.6, 0, by = 0.01))
dt_3ma[, amplitude := 1 + abs(Time_Ma)] # Glacial cycles get stronger near present
dt_3ma[, TempAnomaly := amplitude * sin(Time_Ma * 50) - 2 + rnorm(.N, 0, 0.2) + (Time_Ma)]

# 1.3 Holocene (12,000 Years Ago to Present)
# Mimicking the rapid warming from the Younger Dryas/LGM, Holocene optimum, and stability.
dt_12ka <- data.table(Time_ka = seq(-12, 0, by = 0.1))
# Rapid rise, then flat with slight cooling, and sudden modern spike
dt_12ka[, TempAnomaly := fcase(
  Time_ka < -10, (Time_ka + 12) * 2 - 4,
  Time_ka >= -10 & Time_ka < -0.1, -0.5 * (Time_ka + 10)/10 + 1 + rnorm(.N, 0, 0.1),
  Time_ka >= -0.1, 1 + (Time_ka + 0.1) * 20
)]

# 1.4 Anthropocene (1850 to 2100)
# Historical instrument records + CMIP6 SSP5-8.5 Future Projections
dt_2100 <- data.table(Year = seq(1850, 2100, by = 1))
dt_2100[, TempAnomaly := fcase(
  Year <= 1950, rnorm(.N, 0, 0.1),
  Year > 1950 & Year <= 2024, 0.015 * (Year - 1950) + rnorm(.N, 0, 0.1),
  Year > 2024, 1.11 + 0.04 * (Year - 2024) + rnorm(.N, 0, 0.1)
)]

# Plotting the 4 Time Scales
p_500ma <- ggplot(dt_500ma, aes(x = Time_Ma, y = TempAnomaly)) + 
  geom_line(color = "#D55E00") + theme_bw() + 
  labs(title = "1. Phanerozoic (500 Ma - 0)", x = "Million Years Ago", y = "ΔT (°C)")

p_3ma <- ggplot(dt_3ma, aes(x = Time_Ma, y = TempAnomaly)) + 
  geom_line(color = "#0072B2") + theme_bw() + 
  labs(title = "2. Pliocene-Pleistocene (3.6 Ma - 0)", x = "Million Years Ago", y = "ΔT (°C)")

p_12ka <- ggplot(dt_12ka, aes(x = Time_ka, y = TempAnomaly)) + 
  geom_line(color = "#009E73") + theme_bw() + 
  labs(title = "3. Holocene (12 ka - 0)", x = "Thousand Years Ago", y = "ΔT (°C)")

p_2100 <- ggplot(dt_2100, aes(x = Year, y = TempAnomaly)) + 
  geom_line(color = "red") + geom_vline(xintercept = 2024, linetype="dashed") + theme_bw() + 
  labs(title = "4. Anthropocene & Future (1850 - 2100)", x = "Year", y = "ΔT (°C)")

time_plot <- (p_500ma | p_3ma) / (p_12ka | p_2100) + 
  plot_annotation(title = "The Temporal Scale of Climate Change", 
                  subtitle = "Notice how the X-axis compresses dramatically across panels.")
print(time_plot)

# ------------------------------------------------------------------------------
# Part 2: The Spatial Scale (Earth Geometry vs. The Biosphere)
# ------------------------------------------------------------------------------
cat("Generating spatial scale comparisons...\n")

# 2.1 Macro-Space: Earth Radius vs Mount Everest
# Earth Radius: ~6371 km. Everest: ~8.848 km. 
macro_dt <- data.table(
  Category = c("Earth Core to Surface", "Mount Everest (Highest Peak)", "Mariana Trench (Deepest)"),
  Value_km = c(6371, 8.848, -10.994)
)

# A bar plot to show how statistically invisible the topography is compared to the radius
p_macro <- ggplot(macro_dt, aes(x = Category, y = Value_km, fill = Category)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("gray50", "white", "black"), guide = "none") +
  labs(title = "Macro-Space: The Smooth Earth",
       subtitle = "If Earth were a billiard ball, Everest wouldn't even be a noticeable scratch.",
       y = "Distance in Kilometers (km)", x = "") +
  theme_dark() +
  theme(plot.title = element_text(face = "bold", color = "white"),
        plot.subtitle = element_text(color = "gray80"))

# 2.2 Micro-Space: The Paper-Thin Biosphere
# Comparing vertical layers where life actually interacts with climate
micro_dt <- data.table(
  Level = c(
    "Mt. Everest (Atmosphere extreme)", 
    "Tree Line (Alpine limit)", 
    "WorldClim Grid Res (Often 100m-1km proxy)", 
    "Microclimate Canopy (5m)", 
    "Weather Station (Standard 2m)"
  ),
  Height_m = c(8848, 3500, 100, 5, 2)
)

# Reorder factors for logical vertical plotting
micro_dt[, Level := factor(Level, levels = rev(Level))]

# We use a logarithmic scale to make the 2m and 5m levels visible relative to 8848m
p_micro <- ggplot(micro_dt, aes(x = Height_m, y = Level)) +
  geom_point(size = 5, color = "#E69F00") +
  geom_segment(aes(x = 0, xend = Height_m, y = Level, yend = Level), color = "#E69F00", size = 1.5) +
  scale_x_log10(breaks = c(1, 2, 5, 100, 1000, 8848), labels = c("1m", "2m", "5m", "100m", "1km", "8848m")) +
  labs(title = "Micro-Space: The Paper-Thin Biosphere",
       subtitle = "Notice the mismatch: Weather stations (2m) vs WorldClim (~100m) vs Real Microclimates (0-5m)",
       x = "Height in Meters (Log10 Scale)", y = "") +
  theme_bw() +
  theme(plot.title = element_text(face = "bold"),
        panel.grid.minor.x = element_blank())

space_plot <- p_macro / p_micro
print(space_plot)

# ------------------------------------------------------------------------------
# Step 1.5: The Pacemaker of the Ice Ages (Milankovitch Cycles)
# ------------------------------------------------------------------------------
cat("Simulating Milankovitch orbital cycles over the last 1 million years...\n")

# Load required packages
library(data.table)
library(ggplot2)
library(patchwork)

# Define the time sequence: Last 1 Million Years (from -1000 ka to 0)
milankovitch_dt <- data.table(Time_ka = seq(-1000, 0, by = 1))

# 1. Eccentricity (~100,000 year cycle)
# Controls the shape of the orbit. Influences total annual solar radiation.
milankovitch_dt[, Eccentricity := sin(2 * pi * Time_ka / 100)]

# 2. Obliquity (~41,000 year cycle)
# Controls the axial tilt (22.1 to 24.5 degrees). Drives the strength of seasonality.
milankovitch_dt[, Obliquity := sin(2 * pi * Time_ka / 41)]

# 3. Precession (~23,000 year cycle)
# The axial wobble. Determines which hemisphere faces the sun at closest approach (perihelion).
milankovitch_dt[, Precession := sin(2 * pi * Time_ka / 23)]

# 4. Combined Solar Forcing (Simplified Insolation model)
# The complex Glacial-Interglacial climate curve is essentially the mathematical sum 
# (with varying weights) of these three orbital interacting waves.
milankovitch_dt[, Combined_Forcing := Eccentricity + (0.5 * Obliquity) + (0.3 * Precession)]

# ------------------------------------------------------------------------------
# Visualization: The Architecture of Climate Cycles
# ------------------------------------------------------------------------------
cat("Plotting the individual orbital waves and their combined forcing...\n")

# Melt the data.table to long format for easy facet plotting with ggplot2
mil_long <- melt(milankovitch_dt, 
                 id.vars = "Time_ka", 
                 measure.vars = c("Eccentricity", "Obliquity", "Precession", "Combined_Forcing"),
                 variable.name = "Cycle_Type", 
                 value.name = "Amplitude")

# Assign specific labels to make the plot highly educational
mil_long[, Cycle_Label := fcase(
  Cycle_Type == "Eccentricity", "1. Eccentricity (Orbit shape): ~100k yrs",
  Cycle_Type == "Obliquity",    "2. Obliquity (Axial tilt): ~41k yrs",
  Cycle_Type == "Precession",   "3. Precession (Axial wobble): ~23k yrs",
  Cycle_Type == "Combined_Forcing", "4. Combined Solar Forcing (Ice Age Pacemaker)"
)]

# Convert to factor to preserve the plotting order
mil_long[, Cycle_Label := factor(Cycle_Label, levels = unique(Cycle_Label))]

# Define distinct colors for the physics vs. the resulting climate
cycle_colors <- c("#D55E00", "#009E73", "#56B4E9", "black")

# Create the multi-panel plot
milankovitch_plot <- ggplot(mil_long, aes(x = Time_ka, y = Amplitude, color = Cycle_Type)) +
  geom_line(size = 0.8) +
  scale_color_manual(values = cycle_colors, guide = "none") +
  facet_wrap(~ Cycle_Label, ncol = 1, scales = "free_y") +
  labs(title = "Milankovitch Cycles: The Metronome of Earth's Climate",
       subtitle = "How the interaction of three orbital wobbles drives the Glacial-Interglacial cycles",
       x = "Thousands of Years Ago (ka)",
       y = "Standardized Amplitude") +
  theme_bw() +
  theme(plot.title = element_text(face = "bold", size = 14),
        strip.background = element_rect(fill = "gray90"),
        strip.text = element_text(face = "bold", size = 10))

print(milankovitch_plot)
# ==============================================================================
# Day 11: Model Clamping and Extrapolation Behavior using biomod2
# Target Species: Grus japonensis (Red-crowned crane)
# ==============================================================================

# Install packages if missing
# install.packages(c("biomod2", "terra", "geodata", "data.table", "ggplot2"))

library(geodata)
library(terra)
library(mgcv)          # Core package for Generalized Additive Models (GAM)
library(randomForest)  # Core package for Random Forest (RF)
library(maxnet)        # Native Maxent implementation
library(data.table)
library(ggplot2)

# ------------------------------------------------------------------------------
# Step 1: Data Preparation (Rapid setup for bio1 and bio12)
# ------------------------------------------------------------------------------
cat("Preparing occurrence and environmental data...\n")

# Fetch data and clean it using data.table
occ_file<-"../Data/Occurrences/crane_gbif.rda"
if (file.exists(occ_file)){
  crane_dt<-readRDS(occ_file)
}else{
  crane_gbif <- sp_occurrence(genus = "Grus", species = "japonensis", path = tempdir())
  
  # Convert to data.table for efficient processing
  crane_dt <- as.data.table(crane_gbif)
  saveRDS(crane_dt, occ_file)
}

# Fetch climate and crop
raster_folder<-"../Data/Bioclim"
if (dir.exists(raster_folder)){
  files<-list.files(raster_folder, pattern = "*.asc", full.names = T)
  clim_global<-rast(files)
}else{
  clim_global <- worldclim_global(var = "bio", res = 10, path = tempdir())
}
study_extent <- ext(110, 150, 30, 55) 

env_layers <- crop(clim_global[[c("bio1", "bio12")]], study_extent)
names(env_layers) <- c("bio1", "bio12")

occ_dt <- unique(crane_dt[!is.na(lon) & !is.na(lat), .(lon, lat)])
occ_dt[, presence := 1]

# 1.3 Sample background points across the study extent
bg_pts <- spatSample(env_layers[[1]], size = 10000, method = "random", as.points = TRUE, na.rm = TRUE)
bg_dt <- as.data.table(crds(bg_pts))
setnames(bg_dt, c("x", "y"), c("lon", "lat"))
bg_dt[, presence := 0]

# 1.4 Combine into single data.table and extract environmental values
pts_master <- rbindlist(list(occ_dt, bg_dt))
extracted_vals <- as.data.table(extract(env_layers, pts_master[, .(lon, lat)]))[, ID := NULL]

model_dt <- cbind(pts_master, extracted_vals)
model_dt <- na.omit(model_dt)

cat("Modeling dataset built. Presences:", sum(model_dt$presence == 1), 
    "| Backgrounds:", sum(model_dt$presence == 0), "\n")
# ------------------------------------------------------------------------------
# Step 1: Truncate Environmental Gradient (Keep only the Left-Half of bio1)
# ------------------------------------------------------------------------------
cat("Truncating training dataset: keeping only the lower half of bio1...\n")

# Calculate the median bio1 among presences (or across the whole domain)
bio1_cutoff <- median(model_dt[presence == 1, bio1])
full_bio1_min <- min(model_dt$bio1)
full_bio1_max <- max(model_dt$bio1)
mean_bio12    <- mean(model_dt$bio12)

cat("Full bio1 Range: [", round(full_bio1_min, 1), "°C to", round(full_bio1_max, 1), "°C]\n")
cat("Truncation Cutoff (Left-Half): bio1 <=", round(bio1_cutoff, 1), "°C\n")

# Filter training set using data.table: discard everything above the cutoff
train_dt <- model_dt[bio1 <= bio1_cutoff]

cat("Training points retained:", nrow(train_dt), 
    "| Presences in left-half:", sum(train_dt$presence == 1), "\n")

# ------------------------------------------------------------------------------
# Step 2: Fit Models on the Truncated Data ONLY
# ------------------------------------------------------------------------------
cat("Training models on truncated (left-half) climate conditions...\n")

# 0. Bioclim (Profile model fitted ONLY on presence coordinates/values)
bc_fit <- bioclim(as.data.frame(train_dt[presence == 1, .(bio1, bio12)]))

# 1. GLM (Logistic regression with quadratic term)
glm_fit <- glm(presence ~ poly(bio1, 2) + bio12, 
               data = train_dt, 
               family = binomial(link = "logit"))

# 2. GAM (Spline regression)
gam_fit <- gam(presence ~ s(bio1, k = 4) + s(bio12, k = 4), 
               data = train_dt, 
               family = binomial(link = "logit"))

# 3. Random Forest (Tree Ensemble)
rf_fit <- randomForest(as.factor(presence) ~ bio1 + bio12, 
                       data = train_dt, 
                       ntree = 500)

# 4. Maxnet (Lasso Penalized Regression with native clamping)
env_matrix <- as.data.frame(train_dt[, .(bio1, bio12)])
maxnet_fit <- maxnet(p = train_dt$presence, data = env_matrix, 
                     clamp=T)
maxnet_fit_no_clamp <- maxnet(p = train_dt$presence, data = env_matrix, 
                              clamp=F)

# ------------------------------------------------------------------------------
# Step 3: Predict Across the FULL Gradient (Interpolation + Forced Extrapolation)
# ------------------------------------------------------------------------------
cat("Projecting models across the full (and extended) temperature gradient...\n")

# Create synthetic sequence covering the truncated zone and the unseen warm zone
synth_dt <- data.table(
  bio1 = seq(full_bio1_min - 2, full_bio1_max + 5, length.out = 600),
  bio12 = mean_bio12
)

# Generate predictions for all models
synth_dt[, Bioclim          := predict(bc_fit, as.data.frame(synth_dt[, .(bio1, bio12)]))]
synth_dt[, GLM    := predict(glm_fit, newdata = synth_dt, type = "response")]
synth_dt[, GAM    := predict(gam_fit, newdata = synth_dt, type = "response")]
synth_dt[, RF     := predict(rf_fit, newdata = synth_dt, type = "prob")[, "1"]]
synth_dt[, MAXNET_CLAMPED := predict(maxnet_fit, 
                                     newdata = as.data.frame(synth_dt[, .(bio1, bio12)]), 
                                     type = "cloglog", 
                                     clamp = TRUE)]
synth_dt[, MAXNET_NO_CLAMPED := predict(maxnet_fit_no_clamp, 
                                      newdata = as.data.frame(synth_dt[, .(bio1, bio12)]), 
                                      type = "cloglog", 
                                      clamp = FALSE)]


# Reshape data.table for ggplot2
plot_dt <- melt(synth_dt, 
                id.vars = "bio1", 
                measure.vars = c("Bioclim", "GLM", "GAM", "RF", 
                                 "MAXNET_CLAMPED", 
                                 "MAXNET_NO_CLAMPED"),
                variable.name = "Algorithm", 
                value.name = "Probability")

# ------------------------------------------------------------------------------
# Step 4: Visualizing the Truncated Clamping Effect
# ------------------------------------------------------------------------------
cat("Rendering the truncation and extrapolation plot...\n")

trunc_plot <- ggplot(plot_dt, aes(x = bio1, y = Probability, color = Algorithm)) +
  # Highlight the actual training domain (Left Half)
  annotate("rect", xmin = full_bio1_min - 2, xmax = bio1_cutoff, ymin = 0, ymax = 1, 
           alpha = 0.15, fill = "gray30") +
  # Draw vertical boundary line at the cutoff
  geom_vline(xintercept = bio1_cutoff, linetype = "dashed", color = "red", size = 1) +
  
  # Model response curves
  geom_line(size = 1.3) +
  
  # Labels and annotations
  annotate("text", x = (full_bio1_min + bio1_cutoff) / 2, y = 0.95, 
           label = "Training Domain\n(Left-Half Only)", fontface = "bold", size = 4) +
  annotate("text", x = (bio1_cutoff + full_bio1_max) / 2, y = 0.95, 
           label = "Forced Extrapolation\n(Completely Unseen Climate)", 
           fontface = "bold", color = "red3", size = 4) +
  annotate("text", x = bio1_cutoff - 0.5, y = 0.2, 
           label = "Truncation Threshold", angle = 90, color = "red3", fontface = "italic") +
  
  scale_color_manual(values = c(
    "Bioclim" = "#000000",
    "GLM" = "#D55E00", 
    "GAM" = "#009E73", 
    "RF" = "#0072B2", 
    "MAXNET_CLAMPED" = "#CC79A7",
    "MAXNET_NO_CLAMPED" = "#E69F00")) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(
    title = "Forced Extrapolation: Training on Lower Half of Temperature Gradient",
    subtitle = "Models trained exclusively on bio1 <= median. Notice the extreme divergence to the right of the red line.",
    x = "Annual Mean Temperature (bio1, °C)",
    y = "Predicted Suitability / Probability"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    legend.title = element_blank()
  )

print(trunc_plot)

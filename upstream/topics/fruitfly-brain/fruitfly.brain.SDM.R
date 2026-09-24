library(data.table)
library(Matrix)
library(ggplot2)
library(terra)

#download the data via https://male-cns.janelia.org/download/
edges <- as.data.table(arrow::read_feather("../MaleCNS/connectome-weights-male-cns-v1.0-minconf-0.5.feather"))
ann <- as.data.table(arrow::read_feather("../MaleCNS/body-annotations-male-cns-v1.0-minconf-0.5.feather"))
node_ids <- unique(c(edges$body_pre, edges$body_post))
node_map <- data.table(bodyId = node_ids, node_index = seq_along(node_ids))
setkey(node_map, bodyId)
edges[node_map, pre_index := i.node_index, on = c(body_pre = "bodyId")]
edges[node_map, post_index := i.node_index, on = c(body_post = "bodyId")]
edges[is.na(pre_index) | is.na(post_index), .N]
A <- sparseMatrix(i = edges$pre_index, j = edges$post_index, x = edges$weight, 
                  dims = c(nrow(node_map), nrow(node_map)),
                  dimnames = list(as.character(node_map$bodyId), as.character(node_map$bodyId))
)
setkey(ann, bodyId)

#choose descending neurons
dn_ids <- ann[grepl("^DN", type), bodyId]

edges[ann, pre_type := i.type, on = c(body_pre = "bodyId")]
edges[ann, post_type := i.type, on = c(body_post = "bodyId")]

edges[ann, pre_class := i.class, on = c(body_pre = "bodyId")]

edges[ann, post_class := i.class, on = c(body_post = "bodyId")]
#sensory → interneuron → descending neuron
unique(ann$class)
ann[class %in% c("hygrosensory", "thermosensory"), .N, by = .(class, type)][order(-N)]
sensory_ids <- ann[class %in% c("hygrosensory", "thermosensory"), bodyId]

#sensory → downstream
sensory_edges <- edges[body_pre %in% sensory_ids]
layer1_ids <- unique(sensory_edges$body_post)
layer2_edges <- edges[body_pre %in% layer1_ids]
network_edges <- rbindlist(list(sensory_edges, layer2_edges), use.names = TRUE)
dim(network_edges)
network_edges <- unique(network_edges)
network_nodes <- unique(c(network_edges$body_pre, network_edges$body_post))
#create subnetwork adjacency matrix
network_map <- data.table(bodyId = network_nodes, node_index = seq_along(network_nodes))
setkey(network_map, bodyId)
network_edges[network_map, i := i.node_index, on = c(body_pre = "bodyId")]
network_edges[network_map, j := i.node_index, on = c(body_post = "bodyId")]
A_sub <- sparseMatrix(i = network_edges$i, j = network_edges$j, x = network_edges$weight,
                      dims = c(nrow(network_map), nrow(network_map)),
                      dimnames = list(as.character(network_map$bodyId), as.character(network_map$bodyId))
)

#environment -> sensory encoding -> REAL MaleCNS -> neural activity -> behavioral output ->habitat suitability
occurrences<-fread("../Data/Occurrences/occ.csv")
bio1<-rast("../Data/Bioclim/bio1.asc")
bio12<-rast("../Data/Bioclim/bio12.asc")

env <- c(bio1, bio12)
names(env) <- c("temperature", "precipitation")
xy <- as.data.table(as.data.frame(env, cells = TRUE, xy = TRUE, na.rm = TRUE))

occ_cells <- cellFromXY(env, as.matrix(occurrences[, .(x, y)]))
occ_cells <- unique(na.omit(occ_cells))
xy[, occurrence := fifelse(cell %in% occ_cells, 1, 0)]
table(xy$occurrence)
if (F){
  ggplot(xy)+geom_tile(aes(x=x, y=y, fill=factor(occurrence)))
}


xy <- xy[is.finite(temperature) & is.finite(precipitation) & occurrence %in% c(0, 1)]

# ============================================================
# 2. Make sure matrix node names are available
# ============================================================

matrix_ids <- rownames(A_sub)
network_map <- data.table(bodyId = matrix_ids)
network_map[, matrix_idx := seq_len(.N)]
network_map[, bodyId := as.character(bodyId)]

ann[, bodyId := as.character(bodyId)]

# ============================================================
# 3. Identify thermosensory and hygrosensory neurons
# ============================================================

thermo_ann <- ann[class == "thermosensory"]
hygro_ann  <- ann[class == "hygrosensory"]

thermo_ids <- unique(thermo_ann$bodyId)
hygro_ids  <- unique(hygro_ann$bodyId)

# ============================================================
# 4. Map sensory neurons onto A_sub
# ============================================================

thermo_idx <- match(thermo_ids, network_map$bodyId)
hygro_idx  <- match(hygro_ids, network_map$bodyId)

thermo_idx <- thermo_idx[!is.na(thermo_idx)]
hygro_idx  <- hygro_idx[!is.na(hygro_idx)]

thermo_ids <- network_map$bodyId[thermo_idx]
hygro_ids  <- network_map$bodyId[hygro_idx]

cat("Thermosensory neurons in annotation:", length(thermo_ids), "\n")
cat("Hygrosensory neurons in annotation:", length(hygro_ids), "\n")


# ============================================================
# 5. Normalize the connectome
#
# A_sub[i, j] represents:
#
#      presynaptic neuron j
#              |
#              v
#      postsynaptic neuron i
#
# Therefore columns represent outgoing connections.
# Column normalization makes the total outgoing weight
# of each presynaptic neuron approximately equal to 1.
# ============================================================

A_sub_norm <- A_sub

col_sums <- Matrix::colSums(A_sub_norm)
col_sums[col_sums == 0] <- 1

A_sub_norm <- A_sub_norm %*% Diagonal(x = 1 / col_sums)
dimnames(A_sub_norm) <- list(matrix_ids, matrix_ids)

# ============================================================
# 6. Neural network parameters
# ============================================================

n_steps   <- 10
gain      <- 1
leak      <- 0.2
n_neurons <- nrow(A_sub_norm)

# ============================================================
# 7. Environmental sensory encoding
#
# Temperature controls thermosensory neurons.
# Precipitation is used as the environmental moisture proxy
# for hygrosensory neurons.
#
# The four sensory parameters are estimated from occurrence data.
# ============================================================

encode_environment <- function(temperature, precipitation, Topt, Tsigma, Popt, Psigma, thermo_idx, hygro_idx, n_neurons) {
  x0 <- numeric(n_neurons)
  
  thermo_activity <- exp(-0.5 * ((temperature - Topt) / Tsigma)^2)
  hygro_activity  <- exp(-0.5 * ((precipitation - Popt) / Psigma)^2)
  
  x0[thermo_idx] <- thermo_activity
  x0[hygro_idx]  <- hygro_activity
  
  x0
}

# ============================================================
# 8. Run MaleCNS neural propagation
#
# A_sub[i, j] = j -> i
#
# Therefore:
#
#      A_sub %*% x
#
# propagates presynaptic activity to postsynaptic neurons.
# ============================================================

run_network <- function(A, x0, n_steps = 10, gain = 1, leak = 0.2) {
  x <- x0
  for (step in seq_len(n_steps)) {
    input <- as.numeric(A %*% x)
    x <- ((1 - leak) * x + gain * input)
    x <- pmax(x, 0)
  }
  x
}

# ============================================================
# 9. Extract neural summary
#
# Sensory neurons themselves are excluded from the final
# neural summary because we want to characterize downstream
# network activity rather than merely reproduce the input.
# ============================================================

non_sensory_idx <- setdiff(seq_len(n_neurons), unique(c(thermo_idx, hygro_idx)))

summarize_neural_activity <- function(x, non_sensory_idx) {
  y <- x[non_sensory_idx]
  c(
    neural_total = mean(y),
    neural_max   = max(y),
    neural_sd    = sd(y)
  )
}

# ============================================================
# 10. Convert neural activity into model predictors
#
# Standardization prevents neural_max and neural_total from
# having very different numerical scales during optimization.
# ============================================================

calculate_neural_features <- function(xy_data, Topt, Tsigma, Popt, Psigma, A, thermo_idx, hygro_idx, non_sensory_idx, n_steps, gain, leak) {
  n_sites <- nrow(xy_data)
  result  <- matrix(0, nrow = n_sites, ncol = 3)
  
  for (i in seq_len(n_sites)) {
    print(paste(i, n_sites))
    x0 <- encode_environment(
      temperature   = xy_data$temperature[i],
      precipitation = xy_data$precipitation[i],
      Topt          = Topt,
      Tsigma        = Tsigma,
      Popt          = Popt,
      Psigma        = Psigma,
      thermo_idx    = thermo_idx,
      hygro_idx     = hygro_idx,
      n_neurons     = n_neurons
    )
    
    x <- run_network(
      A       = A,
      x0      = x0,
      n_steps = n_steps,
      gain    = gain,
      leak    = leak
    )
    
    result[i, ] <- summarize_neural_activity(x = x, non_sensory_idx = non_sensory_idx)
  }
  
  result <- as.data.table(result)
  setnames(result, c("neural_total", "neural_max", "neural_sd"))
  result
}

# ============================================================
# 11. Training data
#
# Only occurrence observations are used to estimate the model.
# ============================================================

presence<-xy[occurrence==1]
#presence<-presence[sample(nrow(presence), 100)]
absence<-xy[occurrence==0]
absence<-absence[between(x, min(presence$x), max(presence$x)) &
                   between(y, min(presence$y), max(presence$y))]
absence<-absence[sample(nrow(absence), 2000)]

train_data <- rbindlist(list(presence, absence))

# ============================================================
# 12. Initial sensory parameter values
#
# Initial values are based on the observed environmental range.
# They are NOT treated as final biological parameters.
# ============================================================

T_range <- range(train_data$temperature, na.rm = TRUE)
P_range <- range(train_data$precipitation, na.rm = TRUE)

T_mean  <- mean(train_data$temperature, na.rm = TRUE)
P_mean  <- mean(train_data$precipitation, na.rm = TRUE)

T_sd    <- sd(train_data$temperature, na.rm = TRUE)
P_sd    <- sd(train_data$precipitation, na.rm = TRUE)

if (!is.finite(T_sd) || T_sd <= 0) {
  T_sd <- diff(T_range) / 4
}

if (!is.finite(P_sd) || P_sd <= 0) {
  P_sd <- diff(P_range) / 4
}

# ============================================================
# 13. Initial neural features
# ============================================================

initial_features <- calculate_neural_features(
  xy_data         = train_data,
  Topt            = T_mean,
  Tsigma          = T_sd,
  Popt            = P_mean,
  Psigma          = P_sd,
  A               = A_sub_norm,
  thermo_idx      = thermo_idx,
  hygro_idx       = hygro_idx,
  non_sensory_idx = non_sensory_idx,
  n_steps         = n_steps,
  gain            = gain,
  leak            = leak
)

# ============================================================
# 14. Neural feature scaling
#
# Scaling parameters are fixed using the initial network run.
# This keeps the optimization numerically stable.
# ============================================================

feature_center <- c(
  neural_total = mean(initial_features$neural_total, na.rm = TRUE),
  neural_max   = mean(initial_features$neural_max, na.rm = TRUE),
  neural_sd    = mean(initial_features$neural_sd, na.rm = TRUE)
)

feature_scale <- c(
  neural_total = sd(initial_features$neural_total, na.rm = TRUE),
  neural_max   = sd(initial_features$neural_max, na.rm = TRUE),
  neural_sd    = sd(initial_features$neural_sd, na.rm = TRUE)
)

feature_scale[!is.finite(feature_scale) | feature_scale == 0] <- 1

scale_features <- function(features, feature_center, feature_scale) {
  features[, neural_total := (neural_total - feature_center["neural_total"]) / feature_scale["neural_total"]]
  features[, neural_max   := (neural_max - feature_center["neural_max"]) / feature_scale["neural_max"]]
  features[, neural_sd    := (neural_sd - feature_center["neural_sd"]) / feature_scale["neural_sd"]]
  features
}

initial_features_scaled <- scale_features(copy(initial_features), feature_center, feature_scale)

# ============================================================
# 15. Initial logistic regression
#
# This provides starting values for the neural-to-occurrence
# relationship.
# ============================================================

initial_glm <- glm(
  occurrence ~ neural_total + neural_max + neural_sd,
  data   = cbind(train_data, initial_features_scaled),
  family = binomial()
)
summary(initial_glm)
initial_beta <- coef(initial_glm)
initial_beta[!is.finite(initial_beta)] <- 0

# ============================================================
# 16. Objective function
#
# Parameter vector:
#
# 1 = Topt
# 2 = Tsigma
# 3 = Popt
# 4 = Psigma
# 5 = beta0
# 6 = beta_total
# 7 = beta_max
# 8 = beta_sd
#
# The optimizer simultaneously estimates:
#
#      environmental tuning
#            +
#      neural-to-occurrence relationship
# ============================================================

objective_function <- function(par) {
  Topt   <- par[1]
  Tsigma <- par[2]
  Popt   <- par[3]
  Psigma <- par[4]
  
  beta0      <- par[5]
  beta_total <- par[6]
  beta_max   <- par[7]
  beta_sd    <- par[8]
  
  if (Tsigma <= 0 || Psigma <= 0) {
    return(1e20)
  }
  
  features <- tryCatch(
    calculate_neural_features(
      xy_data         = train_data,
      Topt            = Topt,
      Tsigma          = Tsigma,
      Popt            = Popt,
      Psigma          = Psigma,
      A               = A_sub_norm,
      thermo_idx      = thermo_idx,
      hygro_idx       = hygro_idx,
      non_sensory_idx = non_sensory_idx,
      n_steps         = n_steps,
      gain            = gain,
      leak            = leak
    ),
    error = function(e) {
      NULL
    }
  )
  
  if (is.null(features)) {
    return(1e20)
  }
  
  features <- scale_features(features, feature_center, feature_scale)
  
  eta <- (beta0 + beta_total * features$neural_total + beta_max * features$neural_max + beta_sd * features$neural_sd)
  eta <- pmax(pmin(eta, 30), -30)
  
  probability <- plogis(eta)
  probability <- pmin(pmax(probability, 1e-12), 1 - 1e-12)
  
  log_likelihood <- sum(train_data$occurrence * log(probability) + (1 - train_data$occurrence) * log(1 - probability))
  
  if (!is.finite(log_likelihood)) {
    return(1e20)
  }
  
  -log_likelihood
}

# ============================================================
# 17. Initial parameter vector
# ============================================================

beta0_start      <- ifelse(is.finite(initial_beta["(Intercept)"]), initial_beta["(Intercept)"], 0)
beta_total_start <- ifelse(is.finite(initial_beta["neural_total"]), initial_beta["neural_total"], 0)
beta_max_start   <- ifelse(is.finite(initial_beta["neural_max"]), initial_beta["neural_max"], 0)
beta_sd_start    <- ifelse(is.finite(initial_beta["neural_sd"]), initial_beta["neural_sd"], 0)

start_par <- c(
  T_mean,
  T_sd,
  P_mean,
  P_sd,
  beta0_start,
  beta_total_start,
  beta_max_start,
  beta_sd_start
)

# ============================================================
# 18. Parameter bounds
# ============================================================

lower_par <- c(
  T_range[1],
  max(diff(T_range) / 100, 1e-6),
  P_range[1],
  max(diff(P_range) / 100, 1e-6),
  -20, -20, -20, -20
)

upper_par <- c(
  T_range[2],
  max(diff(T_range) * 2, 1e-6),
  P_range[2],
  max(diff(P_range) * 2, 1e-6),
  20, 20, 20, 20
)

# ============================================================
# 19. Fit the connectome-constrained SDM
#
# This is the computationally expensive step.
# ============================================================

fit <- optim(
  par     = start_par,
  fn      = objective_function,
  method  = "L-BFGS-B",
  lower   = lower_par,
  upper   = upper_par,
  control = list(
    maxit = 1, #100 no time to run 100 repeats
    factr = 1e7
  )
)
saveRDS(fit, "../Data/Fruitfly.Brain.SDM/fit.rda")
# ============================================================
# 20. Extract fitted parameters
# ============================================================

fitted_parameters <- data.table(
  parameter = c(
    "Topt",
    "Tsigma",
    "Popt",
    "Psigma",
    "beta0",
    "beta_neural_total",
    "beta_neural_max",
    "beta_neural_sd"
  ),
  estimate = fit$par
)

print(fitted_parameters)

cat("\nOptimization convergence code:", fit$convergence, "\n")
cat("Final negative log-likelihood:", fit$value, "\n")

# ============================================================
# 21. Calculate neural features using fitted sensory parameters
# ============================================================

training_features <- calculate_neural_features(
  xy_data         = train_data,
  Topt            = fit$par[1],
  Tsigma          = fit$par[2],
  Popt            = fit$par[3],
  Psigma          = fit$par[4],
  A               = A_sub_norm,
  thermo_idx      = thermo_idx,
  hygro_idx       = hygro_idx,
  non_sensory_idx = non_sensory_idx,
  n_steps         = n_steps,
  gain            = gain,
  leak            = leak
)

training_features_scaled <- scale_features(copy(training_features), feature_center, feature_scale)

# ============================================================
# 22. Calculate fitted occurrence probability
# ============================================================

training_features_scaled[, suitability := plogis(
  fit$par[5] +
    fit$par[6] * neural_total +
    fit$par[7] * neural_max +
    fit$par[8] * neural_sd
)]

# ============================================================
# 23. Add training predictions back to occurrence data
# ============================================================

train_result <- cbind(
  train_data,
  training_features,
  training_features_scaled[, .(suitability)]
)

# ============================================================
# 24. Predict all environmental locations
#
# This includes both observed presences and absences.
# ============================================================

all_features <- calculate_neural_features(
  xy_data         = xy,
  Topt            = fit$par[1],
  Tsigma          = fit$par[2],
  Popt            = fit$par[3],
  Psigma          = fit$par[4],
  A               = A_sub_norm,
  thermo_idx      = thermo_idx,
  hygro_idx       = hygro_idx,
  non_sensory_idx = non_sensory_idx,
  n_steps         = n_steps,
  gain            = gain,
  leak            = leak
)
saveRDS(all_features, "../Data/Fruitfly.Brain.SDM/all_features.rda")
all_features_scaled <- scale_features(copy(all_features), feature_center, feature_scale)

all_features_scaled[, suitability := plogis(
  fit$par[5] +
    fit$par[6] * neural_total +
    fit$par[7] * neural_max +
    fit$par[8] * neural_sd
)]

# ============================================================
# 25. Final SDM result
# ============================================================

sdm_result <- cbind(
  xy,
  all_features,
  suitability = all_features_scaled$suitability
)

# ============================================================
# 26. Classify suitability
#
# The threshold is estimated from training predictions using
# the midpoint between mean predicted presence and mean
# predicted absence.
# ============================================================

presence_threshold <- mean(sdm_result[occurrence == 1, suitability], na.rm = TRUE)
absence_threshold  <- mean(sdm_result[occurrence == 0, suitability], na.rm = TRUE)

suitability_threshold <- (presence_threshold + absence_threshold) / 2

sdm_result[, suitable := suitability >= suitability_threshold]

# ============================================================
# 27. Final prediction table for occurrence == 0 locations
#
# These are the locations where suitability is being predicted
# rather than used as occurrence observations.
# ============================================================

prediction_result <- sdm_result[
  occurrence == 0,
  .(
    lon,
    lat,
    temperature,
    precipitation,
    neural_total,
    neural_max,
    neural_sd,
    suitability,
    suitable
  )
]

# ============================================================
# 28. Print summary
# ============================================================

cat("\n==============================\n")
cat("Connectome-constrained SDM\n")
cat("==============================\n")

cat("Number of training sites:", nrow(train_data), "\n")
cat("Presence sites:", train_data[occurrence == 1, .N], "\n")
cat("Absence sites:", train_data[occurrence == 0, .N], "\n")
cat("Thermosensory neurons:", length(thermo_idx), "\n")
cat("Hygrosensory neurons:", length(hygro_idx), "\n")
cat("Network neurons:", n_neurons, "\n")
cat("Network propagation steps:", n_steps, "\n")
cat("Suitability threshold:", suitability_threshold, "\n")
cat("Predicted suitable absence sites:", prediction_result[suitable == TRUE, .N], "\n")
cat("Predicted unsuitable absence sites:", prediction_result[suitable == FALSE, .N], "\n")

# ============================================================
# 29. Save important outputs
# ============================================================

result <- list(
  fitted_parameters     = fitted_parameters,
  training_result       = train_result,
  sdm_result            = sdm_result,
  prediction_result     = prediction_result,
  suitability_threshold = suitability_threshold,
  A_sub_norm            = A_sub_norm,
  thermo_idx            = thermo_idx,
  hygro_idx             = hygro_idx,
  network_map           = network_map,
  optimization          = fit
)
install.packages("natmanager")
natmanager::check_pat()
natmanager::install(pkgs = "natverse/malecns")
library(nat)
library(neuprintr)
library(malecns)
library(data.table)
library(Matrix)
library(terra)
library(arrow)
dr_malecns()
pnmeta <- mcns_neuprint_meta("/.+_[adl]+PN")
head(pnmeta)
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

sum(
  sensory_ids %in% network_map$bodyId
)


make_sensory_parameters <- function(sensory_ids, temperature_range, precipitation_range) {
  n <- length(sensory_ids)
  data.table(
    bodyId = sensory_ids,
    temperature_preference = seq(temperature_range[1], temperature_range[2], length.out = n),
    temperature_sigma = diff(temperature_range) / 4,
    precipitation_preference = seq(precipitation_range[1], precipitation_range[2], length.out = n),
    precipitation_sigma = diff(precipitation_range) / 4
  )
}

sensory_params <- make_sensory_parameters(
  sensory_ids         = sensory_ids,
  temperature_range   = range(xy$temperature, na.rm = TRUE),
  precipitation_range = range(xy$precipitation, na.rm = TRUE)
)

encode_environment <- function(temperature, precipitation, sensory_params) {
  temperature_activity   <- exp(-0.5 * ((temperature - sensory_params$temperature_preference) / sensory_params$temperature_sigma)^2)
  precipitation_activity <- exp(-0.5 * ((precipitation - sensory_params$precipitation_preference) / sensory_params$precipitation_sigma)^2)
  
  temperature_activity * precipitation_activity
}
run_network <- function(A, x0, n_steps = 20, gain = 1, leak = 0.2) {
  x <- x0
  decay <- 1 - leak
  At <- Matrix::t(A)
  
  for (step in seq_len(n_steps)) {
    #input <- as.numeric(At %*% x)
    input <- as.numeric(A %*% x)
    x <- pmax(decay * x + gain * input, 0)
  }
  
  x
}

A_sub_norm <- A_sub
col_sums <- Matrix::colSums(A_sub_norm)

col_sums[col_sums == 0] <- 1

A_sub_norm <- A_sub_norm %*% Diagonal(x = 1 / col_sums)

simulate_neural_response <- function(temperature, precipitation, sensory_params, A, network_map, n_steps = 20) {
  x0 <- numeric(nrow(network_map))
  
  sensory_activity <- encode_environment(temperature, precipitation, sensory_params)
  sensory_idx      <- match(sensory_params$bodyId, network_map$bodyId)
  keep             <- !is.na(sensory_idx)
  
  x0[sensory_idx[keep]] <- sensory_activity[keep]
  
  run_network(A = A, x0 = x0, n_steps = n_steps)
}

dn_idx <- match(dn_ids, network_map$bodyId)
dn_idx <- dn_idx[!is.na(dn_idx)]
length(dn_idx)

#create three neural feature
#feature 1 = total descending activity
#feature 2 = maximum descending activity
#feature 3 = activity variability

extract_neural_features <- function(x, dn_idx) {
  dn_activity <- x[dn_idx]
  
  c(
    neural_total = sum(dn_activity),
    neural_max   = max(dn_activity),
    neural_sd    = sd(dn_activity)
  )
}

simulate_all_points <- function(dat, sensory_params, A, network_map, dn_idx, n_steps = 20) {
  results <- vector("list", nrow(dat))
  
  for (i in seq_len(nrow(dat))) {
    print(paste(i, nrow(dat)))
    x <- simulate_neural_response(
      temperature    = dat$temperature[i],
      precipitation  = dat$precipitation[i],
      sensory_params = sensory_params,
      A              = A,
      network_map    = network_map,
      n_steps        = n_steps
    )
    results[[i]] <- extract_neural_features(x = x, dn_idx = dn_idx)
  }
  
  neural_features <- rbindlist(lapply(results, as.list))
  
  cbind(dat, neural_features)
}
set.seed(1)
presence<-xy[occurrence==1]
#presence<-presence[sample(nrow(presence), 100)]
absence<-xy[occurrence==0]
absence<-absence[between(x, min(presence$x), max(presence$x)) &
                   between(y, min(presence$y), max(presence$y))]
absence<-absence[sample(nrow(absence), 2000)]
dat_neural <- simulate_all_points(
  dat = rbindlist(list(presence, absence)),
  sensory_params = sensory_params,
  A = A_sub_norm,
  network_map = network_map,
  dn_idx = dn_idx,
  n_steps = 20
)

sdm <- glm(occurrence ~ neural_total + neural_max + neural_sd,
           data = dat_neural, family = binomial())
summary(sdm)
dat_neural[, suitable := predict(sdm, newdata = dat_neural, type = "response")]

#check code

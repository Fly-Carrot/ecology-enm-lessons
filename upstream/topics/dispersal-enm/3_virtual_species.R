##The dispersalENM package is tested on virtual species.
################################################################################
# Set working directory
get_script_dir <- function() {
  cmdArgs <- commandArgs(trailingOnly = FALSE)
  fileArg <- "--file="
  match <- grep(fileArg, cmdArgs)
  if (length(match) > 0) {
    return(dirname(normalizePath(sub(fileArg, "", cmdArgs[match]))))
  }
  
  if (interactive() && requireNamespace("rstudioapi", quietly = TRUE)) {
    path <- tryCatch(
      rstudioapi::getActiveDocumentContext()$path,
      error = function(e) ""
    )
    if (nzchar(path)) {
      return(dirname(path))
    }
  }
  
  return(NULL)
}

script_dir <- get_script_dir()
if (!is.null(script_dir)) {
  setwd(script_dir)
}
################################################################################
setwd("~/GIT/ENM_curriculum/ENM_curriculum")
library(ggplot2)
library(terra)
library(RStoolbox)
library(stats)
library(dismo)
library(sf)
library(dispersalENM)
if(F){
  ######################sample occurrence data####################################
  if(F){
    env <- rast(list.files("../Data/Dispersal_ENM/env/trainenv", pattern = "tif",
                           full.names = TRUE))
    mask <- st_read("../Data/Dispersal_ENM/EurAsia/eurasia.shp")
    env_EA <- crop(env, mask, mask=T)
    saveRDS(env_EA, "../Data/Dispersal_ENM/env/env_EA.rda")
    
    China <- st_read("../Data/Dispersal_ENM/China/China.shp")
    env <- crop(env_EA, China, mask=T)
    saveRDS(env, "../Data/Dispersal_ENM/env/env_China.rda")
  }
  env <- readRDS("../Data/Dispersal_ENM/env/env_China.rda")
  n=3
  sds_means <- list()
  rate <-  0.30
  pc_comb<- NULL
  i=3
  pc_means <- c(3000, 310, 220)
  for (i in c(1:3)){
    pc_max <- global(env[[i]], "max", na.rm = TRUE)[1,1]
    pc_min <- global(env[[i]], "min", na.rm = TRUE)[1,1]
    pc_range <- round((pc_max-pc_min))
    pc_sd <- c(rate*pc_range)
    #pc_mean <- seq(round(pc_min),round(pc_max), by=(pc_range)/4)[2]
    pc_mean <- pc_means[i]
    pccomb <- tidyr::crossing(pc_mean,pc_sd)
    pccomb$id <- c(1:nrow(pccomb))
    names <- colnames(pccomb)
    colnames(pccomb) <- paste0(names,"_",i)
    pc_comb <- tidyr::crossing(pc_comb,pccomb)
  }
  saveRDS(pc_comb,"../Data/Dispersal_ENM/occ/sp_infor.rda")
  pccomb <- pc_comb
  means <- NULL
  sds <- NULL
  thr_o <- NULL
  pccomb$thr <-NA
  pccomb$sp_id <- NA
  #gaussian function
  .prob.gaussian <- function(x, means, sds)
  {
    prod(stats::dnorm(x, mean = means, sd = sds))
  }
  for(j in c(seq(1,ncol(pc_comb)-2,3))){
    means <- c(means, as.numeric(pccomb[1,j]))
    sds <- c(sds, as.numeric(pccomb[1,j+1]))
    thr_o <- c(thr_o, as.numeric(pccomb[1,j])-as.numeric(pccomb[1,j+1]))
  }
  #suitable raster
  suitab.raster <- app(env, fun = function(x, ...) {
    .prob.gaussian(x, means = means, sds = sds)
  })
  max_ <- global(suitab.raster, "max", na.rm = TRUE)[1,1]
  min_ <- global(suitab.raster, "min", na.rm = TRUE)[1,1]
  suitab.raster <- (suitab.raster - min_)/(max_ - min_)
  writeRaster(suitab.raster, "../Data/Dispersal_ENM/occ/suitab.raster.tif",overwrite=TRUE)
  #distribution raster
  thr_s <- prod(stats::dnorm(thr_o, mean = means, sd = sds))
  thr <- round((thr_s - min_)/(max_ - min_),2)
  #thr =  0.47
  pccomb$thr <- thr
  pccomb$sp_id <- i
  if(thr<1){
    distrib_sp <- suitab.raster
    values(distrib_sp)[which(values(distrib_sp)>=thr)] <- 1
    values(distrib_sp)[which(values(distrib_sp)<thr)] <- 0
    N_ALL <- length(values(distrib_sp)[which(!is.na(values(distrib_sp)))])
    N <- length(values(distrib_sp)[which(values(distrib_sp)==1)])
    if(N/N_ALL>=0.01){
      writeRaster(distrib_sp, "../Data/Dispersal_ENM/occ/distrib_raster_1.tif", overwrite=TRUE)
    }else{
      print(paste(i,"no exists",sep=" "))
    }
  }
  distrib_sp <- rast("../Data/Dispersal_ENM/occ/distrib_raster_1.tif")
  plot(distrib_sp)
  #creat distribution
  sp_points <- as.data.frame(distrib_sp,xy=T)
  colnames(sp_points) <- c("x","y","thr")
  sp_points_pc <-subset(sp_points,thr==1,select=c("x","y"))
  set.seed(123)
  occ <- sp_points_pc[sample(nrow(sp_points_pc), 300, replace = FALSE),]
  model <- maxent_model(occ, env, fc=c("L","Q"), nbg=nrow(occ)*10,
                        rm=1, doclamp="false")
  prediction <- predict(env, model, na.rm=TRUE)
  all_training_v<-terra::extract(prediction, occ[, c("x", "y")], ID=FALSE)
  thr <- quantile(all_training_v, c(0.01), na.rm=T)
  predictenv <- readRDS("../Data/Dispersal_ENM/env/env_EA.rda")
  prediction_all <- predict(predictenv, model, na.rm=TRUE)
  prediction_all_bin <- ifel(prediction_all < thr, 0, 1)
  plot(prediction_all_bin, main =  paste(pc_means, collapse = "_"))
  writeRaster(prediction_all_bin, "../Data/Dispersal_ENM/occ/distrib_raster.tif", overwrite=TRUE)
  #sample occ
  distrib_sp <- rast("../Data/Dispersal_ENM/occ/distrib_raster.tif")
  E <- st_read("../Data/Dispersal_ENM/hybas_eu_lev01/hybas_eu_lev01_v1c.shp")
  distrib_sp_2 <- terra::mask(distrib_sp, E)
  sp_points <- as.data.frame(distrib_sp_2,xy=T)
  colnames(sp_points) <- c("x","y","thr")
  sp_points_pc <-subset(sp_points,thr==1,select=c("x","y"))
  occourence <- sp_points_pc[sample(nrow(sp_points_pc), 300, replace = FALSE),]
  saveRDS(occourence, "../Data/Dispersal_ENM/occ/occ.rda")
  
}

###############################Applied##########################################
####Read data----
env <- readRDS("../Data/Dispersal_ENM/env/env_EA.rda")
E <- st_read("../Data/Dispersal_ENM/hybas_eu_lev01/hybas_eu_lev01_v1c.shp")
env_2 <- mask(env, E)
saveRDS(env_2, "../Data/Dispersal_ENM/env/env_E.rda")
trainenv <- readRDS("../Data/Dispersal_ENM/env/env_E.rda")
####Species occurrence data processing (occ_filter)----
occ_data <- readRDS("../Data/Dispersal_ENM/occ/occ.rda")
trainenv <- readRDS("../Data/Dispersal_ENM/env/env_E.rda")

occourence <-occ_filter(occs = occ_data[,c("x","y")],
                        env_1 = trainenv[[1]])
saveRDS(occourence, "../Data/Dispersal_ENM/occ/occourence.rda")
####Environmental data (env_correlation)----
data <- env_correlation(occs = occourence,env = trainenv)
####Model tuning (model_tuning)----
set.seed(123)
model_tuning_results <- model_tuning(occs = occourence, env = trainenv, nbg=10000,
                                     f_c=c("L","Q","P"), r_m=c(1, 0.5, 3))
results <- model_tuning_results
Result <- results[results$delta.AICc==0,][,c("fc","rm")]
print(Result)
saveRDS(results, "../Data/Dispersal_ENM/ENMeval_results.rda")
#select LQP  1
####Model (maxent_model)----
fc <- strsplit(Result$fc, "")[[1]]
rm <- Result$rm
set.seed(123)
model <- maxent_model(occourence, trainenv, fc= fc, nbg=nrow(occourence)*10,
                      rm=rm, doclamp="false")
saveRDS(model, "../Data/Dispersal_ENM/VS_model.rda")
prediction2 <- terra::predict(trainenv, model, na.rm = TRUE)
all_training_v<-terra::extract(prediction2, occourence[, c("x", "y")], ID=FALSE)
thr <- quantile(all_training_v, c(0.01), na.rm=T)
#1% 
#0.29009 



####Predict (prediction)----
if(F){
  mask <- st_read("../Data/Dispersal_ENM/EurAsia/eurasia.shp")
  vars <- c("pre","tasmax","tasmin")
  for(var in vars){
    print(var)
    for(i in c(2025:2050)){
      print(i)
      data <- rast(sprintf("../Source/rcp85/GFDL-ESM2M_rcp85_%s_%d_eck4.tif", var, i))
      data1 <- project(data, "EPSG:4326")
      data2 <- crop(data1, mask,mask=T)
      writeRaster(data2, sprintf("predictenv/GFDL-ESM2M_rcp85_%s_%d.tif", var, i), overwrite=TRUE)
    }
  }
}
model <- readRDS("../Data/Dispersal_ENM/VS_model.rda")
trainenv <-   readRDS("../Data/Dispersal_ENM/env/env_E.rda")
dir_out <- "../Data/Dispersal_ENM/output"
vars <- c("pre","tasmax","tasmin")
if(F){
  library(stringr)
  pre_infor <- readRDS(system.file("extdata", "pre_infor.rda",
                                   package = "dispersalENM"))
  pre_infor <- pre_infor[rep(seq_len(nrow(pre_infor)), length.out = 26), ]
  pre_infor$EnvPath<-"../Data/Dispersal_ENM/env/predictenv"
  #pre_infor$Time <- 2025:2035
  pre_infor$EnvScene <- "GFDL-ESM2M_rcp45"
  saveRDS(pre_infor, "../Data/Dispersal_ENM/pre_infor.rda")
  ALL_infor <- readRDS(system.file("extdata", "ALL_infor.rda",
                                   package = "dispersalENM"))
  ALL_infor <- ALL_infor[rep(seq_len(nrow(ALL_infor)), length.out = 26), ]
  #ALL_infor$time <- 2025:2035
  ALL_infor$path <- paste0("../Data/Dispersal_ENM/tif/GFDL-ESM2M_rcp85_", ALL_infor$time, ".tif")
  ALL_infor$thr  <- thr
  ALL_infor$barrier <- "barrier/barrier_EA.tif"
  saveRDS(ALL_infor, "../Data/Dispersal_ENM/ALL_infor.rda")
}

pre_infor <- readRDS("../Data/Dispersal_ENM/pre_infor.rda")
pre_infor$EnvPath<-"../Data/Dispersal_ENM/env/predictenv_EA/rcp45"
prediction(model, trainenv, vars, pre_infor, dir_out)
data_tif <- rast("../Data/Dispersal_ENM/output/results/tif/GFDL-ESM2M_rcp45_2025.tif")
plot(data_tif)
####Dispersal (dispersal)----
##############################native###################################
types <- c("invasive","native")
vars <- c("no_dispersal","poor_dispersal","good_dispersal","unlimited_dispersal","wind_impact")

for(type in types){
  folder_path <- sprintf("../Data/Dispersal_ENM/output/results/%s",type)
  if (!dir.exists(folder_path)) dir.create(folder_path, recursive = TRUE)
  for(var in vars){
    folder_path <- sprintf("../Data/Dispersal_ENM/output/results/%s/%s", type, var)
    if (!dir.exists(folder_path)) dir.create(folder_path, recursive = TRUE)
  }
}
{
  ####no dispersal, unlimit dispersal----
  dis_crs <- "+proj=eck4 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
  current <- rast("../Data/Dispersal_ENM/output/results/tif/GFDL-ESM2M_rcp45_2025.tif")
  barrier <- rast("../Data/Dispersal_ENM/barrier/barrier_EA.tif")
  current <- mask(current,barrier)
  cur_binary <- ifel(current >= 0.9, 2, 0)
  occourence <- readRDS("../Data/Dispersal_ENM/occ/occourence.rda")
  cur_patch <- terra::patches(cur_binary, zeroAsNA = TRUE, directions = 8)
  names(cur_patch) <- "patches"
  occ_extract <- terra::extract(cur_patch, occourence[,c("x","y")], ID = FALSE)
  truepatches <- unique(occ_extract$patches)
  truepatches <- truepatches[which(!is.na(truepatches))]
  current_D <- terra::match(cur_patch, truepatches)
  current_D <- ifel(!is.na(current_D), 2, NA)
  cur_bin0 <- ifel(is.na(cur_binary), NA, 0)
  current_D <- merge(current_D,cur_bin0)
  current_D <- terra::project(current_D, dis_crs,  method = "bilinear")
  cur_binary <- terra::project(cur_binary, dis_crs,  method = "bilinear")
  plot(current_D)
  plot(cur_binary)
  writeRaster(current_D, "../Data/Dispersal_ENM/native/no_dispersal/2025_no_dispersal.tif",
              overwrite = TRUE)
  writeRaster(cur_binary, "../Data/Dispersal_ENM/native/no_dispersal/2025_unlimited_dispersal.tif",
              overwrite = TRUE)
  t = 2026
  for(t in c(2026:2035)){
    print(t)
    future <- rast(sprintf("../Data/Dispersal_ENM/output/results/tif/GFDL-ESM2M_rcp45_%d.tif", t))
    future <- terra::project(future, dis_crs,  method = "bilinear")
    future_B <- ifel(future >= thr, 1, 0)
    future_D <- (current_D == 2) & (future_B == 1)
    future_D[future_D == 1] <- 2
    future_D <- ifel(future_D == 2, 2,
                     ifel(future_D == 0 & future_B == 1, 1,
                          ifel(future_D == 0 & future_B == 0, 0, NA)))
    future_D <- as.int(future_D)
    current_D <- future_D
    plot(current_D)
    writeRaster(future_D, sprintf("../Data/Dispersal_ENM/native/no_dispersal/%d_no_dispersal.tif", t),
                overwrite = TRUE)
    future_D2 <- future_B
    future_D2[future_D2 == 1] <- 2
    writeRaster(future_D2, sprintf("../Data/Dispersal_ENM/native/unlimited_dispersal/%d_unlimited_dispersal.tif", t),
                overwrite = TRUE)
  }
  ####poor dispersal----
  ALL_infor <- readRDS("../Data/Dispersal_ENM/ALL_infor.rda")
  ALL_infor$path <- sprintf("../Data/Dispersal_ENM/output/results/tif/GFDL-ESM2M_rcp45_%d.tif", ALL_infor$time)
  ALL_infor$thr <- thr
  ALL_infor[1,"thr"] <- 0.9
  ALL_infor$max_disp <- 30000
  ALL_infor$barrier <- "../Data/Dispersal_ENM/barrier/barrier_EA.tif"
  ALL_infor<-unique(ALL_infor)
  occourence <- readRDS("../Data/Dispersal_ENM/occ/occourence.rda")
  dirout <- "../Data/Dispersal_ENM/output/results/native/poor_dispersal"
  dispersal(all_infor = ALL_infor, occ = occourence, out_dir=dirout, n = 8,
            figure = F)
  ####good dispersal----
  ALL_infor <- readRDS("../Data/Dispersal_ENM/ALL_infor.rda")
  ALL_infor$path <- sprintf("../Data/Dispersal_ENM/output/results/tif/GFDL-ESM2M_rcp45_%d.tif", ALL_infor$time)
  ALL_infor$thr <- thr
  ALL_infor[1,"thr"] <- 0.9
  ALL_infor$max_disp <- 100000
  ALL_infor$barrier <- "../Data/Dispersal_ENM/barrier/barrier_EA.tif"
  ALL_infor<-unique(ALL_infor)
  
  occourence <- readRDS("../Data/Dispersal_ENM/occ/occourence.rda")
  dirout <- "../Data/Dispersal_ENM/output/results/native/good_dispersal"
  dispersal(all_infor = ALL_infor, occ = occourence, out_dir=dirout, n = 8,
            figure = FALSE)
  ####wind----
  ALL_infor <- readRDS("../Data/Dispersal_ENM/ALL_infor.rda")
  ALL_infor$path <- sprintf("../Data/Dispersal_ENM/output/results/tif/GFDL-ESM2M_rcp45_%d.tif", ALL_infor$time)
  ALL_infor$thr <- thr
  ALL_infor[1,"thr"] <- 0.9
  ALL_infor$max_disp <- 30000
  ALL_infor$data_v <- "../Data/Dispersal_ENM/wind_VS/wind_v_VS.tif"
  ALL_infor$data_u <- "../Data/Dispersal_ENM/wind_VS/wind_u_VS.tif"
  ALL_infor$barrier <- "../Data/Dispersal_ENM/barrier/barrier_EA.tif"
  ALL_infor<-unique(ALL_infor)
  
  occourence <- readRDS("../Data/Dispersal_ENM/occ/occourence.rda")
  dirout <- "../Data/Dispersal_ENM/output/results/native/wind_impact"
  dispersal(all_infor = ALL_infor, occ = occourence, out_dir=dirout, n = 8,
            k_value = 100000, figure = FALSE)
}

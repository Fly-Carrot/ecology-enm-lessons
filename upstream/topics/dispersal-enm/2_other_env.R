##Cutting other environmental factors: barrier, resistance, wind
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
##################################barrier#######################################
#Virtual species: Assuming that species cannot survive at altitudes above 3000km
library(terra)
library(sf)
elev <- rast("../Data/Source/wc2.1_10m_elev.tif")
mask <- st_read("../Data/EurAsia/eurasia.shp")
barrier <- crop(elev, mask, mask=T)
mask <- rast("../Data/mask_EA.tif")
barrier <- resample(barrier, mask, method="bilinear")
barrier <- ifel(barrier > 3000, 0, 1)
writeRaster(barrier, "../Data/barrier/barrier_EA.tif", overwrite=TRUE)
################################resistance######################################
if(F){
  library(terra)
  dem <- rast("../Data/Source/wc2.1_10m_elev.tif")
  slope <- terrain(dem, "slope", unit="degree")
  resistance <- 0.1 * slope
  barrier <- rast("../Data/barrier/barrier.tif")
  resistance <- crop(resistance, barrier, mask=T)
  writeRaster(resistance, "../Data/resistance/resistance.tif", overwrite=TRUE)
}


################################wind######################################
#Convert wind speed units to km/year
convert_mps_to_kmpy <- function(v_mps) {
  v_mps * 0.001 * 365 * 24 * 3600
}


#Virtual species
library(terra)
wind_u <- rast("../Data/Source/Wind/u_T=6.5_P=100.tif")
wind_v <- rast("../Data/Source/Wind/v_T=6.5_P=100.tif")
ext(wind_u) <- c(-180, 180, -90, 90)
ext(wind_v) <- c(-180, 180, -90, 90)
crs(wind_u) <- "EPSG:4326"
crs(wind_v) <- "EPSG:4326"
env <- rast(list.files("../Data/env/trainenv", pattern = "tif",
                       full.names = TRUE))
r_new <- rast(env[[1]])
ku <- resample(wind_u, r_new, method = "bilinear")
kv <- resample(wind_v, r_new, method = "bilinear")
kup <- convert_mps_to_kmpy(ku)
kvp <- convert_mps_to_kmpy(kv)
library(sf)
mask <- st_read("../Data/EurAsia/eurasia.shp")
kup <- crop(kup, mask, mask=T)
kvp <- crop(kvp, mask, mask=T)
writeRaster(kup,"../Data/wind_VS/wind_u_VS.tif", overwrite=TRUE)
writeRaster(kvp,"../Data/wind_VS/wind_v_VS.tif", overwrite=TRUE)





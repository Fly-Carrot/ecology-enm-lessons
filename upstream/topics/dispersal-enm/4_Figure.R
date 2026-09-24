##PLOTS
#install.packages("av")
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

library(terra)
library(data.table)
library(ggplot2)
library(av)
maptheme <- theme(axis.text = element_blank(),
                  axis.ticks = element_blank(),
                  axis.title = element_blank(),
                  panel.grid = element_blank(),
                  panel.background = element_rect(fill = "#FFFFFF"),
                  plot.margin = unit(c(0, 0, 0.5, 0), 'cm'))
{
#Figure 3
out_dir <- "../Data/virtual_species"
types <- c("invasive","native")
#types <- "native"
vars <- c("no_dispersal","poor_dispersal","good_dispersal","unlimited_dispersal")
env <- rast("../Data/virtual_species/results/tif/GFDL-ESM2M_rcp85_2025.tif")
data_list <- list()
i = 1
t = 2050
for(type in types){
  print(type)
  for(var in vars){
    print(var)
    if(var %in% c("no_dispersal", "unlimited_dispersal")){
      Rd <- rast(sprintf("%s/%s/%s/%d_%s.tif", out_dir, type, var, t, var))
    }else{
      Rd <- rast(sprintf("%s/%s/%s/dispersal_tif/%d_dispersal.tif", out_dir, type, var, t))
    }
    Rd <- terra::project(Rd, crs(env),  method = "near")
    data_d <- as.data.frame(Rd, xy=T)
    colnames(data_d) <- c("x","y","value")
    data_d$year <- t
    data_d$type <- type
    var <- gsub("_", " ", var)
    data_d$var <-var
    data_list[[i]] <- data_d
    i = i+1
  }
}
DATA_ALL <- data.frame(rbindlist(data_list))
colors <- c("#D9D9D9", "#4575B4", "#B40426")

library(ggplot2)
DATA_ALL$value <- as.character(DATA_ALL$value)
DATA_ALL$var <- factor(DATA_ALL$var,
                       levels = c("no dispersal","poor dispersal", "good dispersal", "unlimited dispersal"))
P3 <- ggplot(data = DATA_ALL) +
  geom_tile(aes(x = x, y = y, fill = value)) +
  scale_fill_manual(values = colors,
                    breaks = c("0", "1", "2"),
                    labels = c("0 (non-distribution)", "1 (potential suitable habitat)",
                               "2 (potential distribution)"))+
  scale_y_continuous(position = "right") +
  labs(x = NULL, y = NULL, fill = "")+
  coord_sf(xlim = c(-30, ext(Rd)[c(2)]), ylim =  ext(Rd)[c(3,4)],
           expand = FALSE)+
  theme_bw()+
  facet_grid(var ~ type, switch = "y")+
  theme(panel.grid = element_blank(),
        strip.text = element_text(size = 14),
        axis.text = element_text(size = 12),
        legend.text = element_text(size = 12),
        legend.key.size = unit(1, "cm"),
        legend.position = "bottom")
ggsave(P3, filename = "../Figure/figure_VS1.png",width = 13.5, height = 12)
ggsave(P3, filename = "../Figure/figure_VS1.pdf",width = 13.5, height = 12)
}

{
#Figure 4
out_dir <- "../Data/virtual_species"
types <- c("invasive","native")
vars <- c("poor_dispersal","wind_impact")
data_list <- list()
i = 1
t = 2035
for(type in types){
  print(type)
  Rd_n <- rast(sprintf("%s/%s/poor_dispersal/dispersal_tif/%d_dispersal.tif", out_dir, type, t))
  Rd_n <- terra::project(Rd_n, crs(env),  method = "near")
  Rd_i <- rast(sprintf("%s/%s/wind_impact/dispersal_tif/%d_dispersal.tif", out_dir, type, t))
  Rd_i <- terra::project(Rd_i, crs(env),  method = "near")
  data_d <- as.data.frame(Rd_n, xy=T)
  colnames(data_d) <- c("x","y","value_n")
  data_d$value_i <- extract(Rd_i, data_d[,c("x","y")])[,2]
  data_d$year <- t
  data_d$type <- type
  data_list[[i]] <- data_d
  i = i+1
}
DATA_ALL <- data.table(rbindlist(data_list))
DATA_ALL$value_n <- ifelse(DATA_ALL$value_n == 2, 2, 0)
DATA_ALL$value_i <- ifelse(DATA_ALL$value_i == 2, 2, 0)
DATA_ALL$change <- -999
DATA_ALL$change <- ifelse(DATA_ALL$value_n == 0 & DATA_ALL$value_i == 2, 1, DATA_ALL$change)
DATA_ALL$change <- ifelse(DATA_ALL$value_n == 2 & DATA_ALL$value_i == 0, -1, DATA_ALL$change)
DATA_ALL$change <- ifelse(DATA_ALL$value_n == 2 & DATA_ALL$value_i == 2, 0, DATA_ALL$change)
#DATA_ALL <- DATA_ALL[change != -999]
#colors <- c("#D9D9D9", "#4575B4", "#B40426")

#colors <- c("#4575B4", "#FEE090", "red")
library(ggplot2)
DATA_ALL$change <- as.character(DATA_ALL$change)
P4 <- ggplot(data = DATA_ALL) +
  geom_tile(aes(x = x, y = y, fill = change)) +
  scale_fill_manual(values = c("-999" = "#D9D9D9", "-1" = "#4575B4",
                               "0" = "#FEE090", "1" = "red"),
                    breaks = c("-1", "0", "1"),
                    labels = c("loss", "refugia", "gain"))+
#  scale_y_continuous(position = "right") +
  labs(x = NULL, y = NULL, fill = "")+
  coord_sf(xlim = c(-30, ext(Rd)[c(2)]), ylim =  ext(Rd)[c(3,4)],
           expand = FALSE)+
  theme_bw()+
  facet_grid( ~ type, switch = "y")+
  theme(panel.grid = element_blank(),
        strip.text = element_text(size = 14),
        axis.text = element_text(size = 12),
        legend.text = element_text(size = 12),
        legend.key.size = unit(1, "cm"),
        legend.position = "bottom")
ggsave(P4, filename = "../Figure/figure_VS2.png",width = 12, height = 4)
ggsave(P4, filename = "../Figure/figure_VS2.pdf",width = 12, height = 4)
}


####image----
#example: good_dispersal
library(ggh4x)
env <- rast("../Data/virtual_species/results/tif/GFDL-ESM2M_rcp85_2025.tif")
out_dir <- "../Data/virtual_species"
type <- "invasive"
var <- "good_dispersal"
colors <- c("#D9D9D9", "#4575B4", "#B40426")
for(t in c(2025:2050)){
  print(t)
  ####dispersal
  Rd <- rast(sprintf("%s/%s/%s/dispersal_tif/%d_dispersal.tif", out_dir, type, var, t))
  Rd <- terra::project(Rd, crs(env),  method = "near")
  Rd_cat <- as.factor(Rd)
  levels(Rd_cat) <- data.frame(id = c(0, 1, 2), 
                               category = c("0 (non-distribution)", 
                                            "1 (potential suitable habitat)",
                                            "2 (potential distribution)"))
  e <- ext(Rd_cat)
  png(sprintf("../Figure/Figure_%s/dispersal_png/figure_%s_%d.png", var, var, t),
      width = 1200, height = 720, res = 120)
  plot(Rd_cat, main = t,
       xlim = c(-30, e$xmax),
       ylim = c(e$ymin, e$ymax),
       type = "classes",                
       col = colors,
       plg = list(x = "bottom"),  
       mar = c(6, 3, 3, 3))
  dev.off()
  
  #statistics
  Rd <- rast(sprintf("%s/%s/%s/statistics_tif/%d_statistics.tif", out_dir, type, var, t))
  Rd <- terra::project(Rd, crs(env),  method = "near")
  Rd_cat <- as.factor(Rd)
  levels(Rd_cat) <- data.frame(id = c(0, 3, 4, 5), 
                               category = c("0 (non-distribution)", 
                                            "3 (loss of potential distribution)",
                                            "4 (stability of potential distribution)",
                                            "5 (gain of potential distribution)"))
  e <- ext(Rd_cat)
  png(sprintf("../Figure/Figure_%s/statistics_png/figure_%s_%d.png", var, var, t),
      width = 1300, height = 720, res = 120)
  plot(Rd_cat, main = t,
       xlim = c(-30, e$xmax),
       ylim = c(e$ymin, e$ymax),
       type = "classes",
       mar = c(2, 2, 2, 12))   
  dev.off()
  
  ####expose
  Rd <- rast(sprintf("%s/%s/%s/expose_tif/%d_expose.tif", out_dir, type, var, t))
  Rd <- terra::project(Rd, crs(env),  method = "near")
  png(sprintf("../Figure/Figure_%s/expose_png/figure_%s_%d.png", var, var, t),
      width = 1200, height = 720, res = 120)
  plot(Rd, main = paste0("Lag time: ",t),
       xlim = c(-30, e$xmax),
       ylim = c(e$ymin, e$ymax))
  dev.off()
}
#connect
library(av)
C <- c("dispersal","statistics","expose")
var <- "good_dispersal"
for(c in C){
  print(c)
  img_files <- list.files(sprintf("../Figure/Figure_%s/%s_png", 
                                  var, c), 
                          pattern = "*.png", full.names = TRUE)
  av_encode_video(
    img_files,
    output = sprintf("../Figure/Figure_%s/%s.mp4", var, c),  # 输出文件名
    framerate = 1          # 设置帧率（每秒 10 帧）
  )
}







##install packages
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
# install.packages("ggplot2")
# install.packages("data.table")
# install.packages("dplyr")
# install.packages("terra")
# install.packages("dismo")
# install.packages("stats")
# install.packages("RStoolbox")
# install.packages("stringr")
# install.packages("ggh4x")
# install.packages("ENMeval")
#install.packages("ape")
library(ggplot2)
library(sf)
library(data.table)
library(dplyr)
library(terra)
library(dismo)
library(stats)
library(RStoolbox)
library(stringr)
library(ggh4x)
library(ENMeval)
library(ape)
install.packages("../dispersalENM_0.2.1.tar.gz", repos=NULL)
library(dispersalENM)

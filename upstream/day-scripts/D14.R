library(biomod2)
library(terra)

# Load species abundances (20 species available)
data('DataSTOC')
head(DataSTOC)

# Divide into calibration/validation and evaluation
period1 <- which(DataSTOC[, 'period'] == '2006-2011')
period2 <- which(DataSTOC[, 'period'] == '2012-2017')

# Select the name of the studied species
myRespName <- 'Periparus.ater'

# Get corresponding count data
myResp <- as.numeric(DataSTOC[, myRespName])

# Get corresponding XY coordinates
myRespXY <- DataSTOC[, c('X_WGS84', 'Y_WGS84')]

# Get corresponding environmental variables
myExpl <- DataSTOC[, c('temp', 'precip', 'sdiv_hab',
                       'cover_agri', 'cover_water', 'cover_wet')]

# Format data with count data type
myBiomodData <- BIOMOD_FormatingData(resp.name = myRespName, 
                                     resp.var = myResp[period1],
                                     resp.xy = myRespXY[period1, ],
                                     expl.var = myExpl[period1, ],
                                     eval.resp.var = myResp[period2],
                                     eval.resp.xy = myRespXY[period2, ],
                                     eval.expl.var = myExpl[period2, ],
                                     data.type = 'count')
myBiomodData
summary(myBiomodData)
myPlot <- plot(myBiomodData, plot.eval = TRUE)


# Model single models
myBiomodSM <- BIOMOD_Modeling(bm.format = myBiomodData,
                              modeling.id = 'AllModels',
                              models = c('DNN', 'GBM', 'GLM', 'MARS', 'RF', 'XGBOOST'),
                              CV.strategy = 'block',
                              OPT.strategy = 'bigboss',
                              metric.eval = c('Rsquared', 'Rsquared_aj', 'RMSE'),
                              var.import = 3)
# seed.val = 123)
# nb.cpu = 8)
myBiomodSM

# Get evaluation scores & variables importance
get_evaluations(myBiomodSM)
get_variables_importance(myBiomodSM)

# Represent evaluation scores & variables importance
myPlot <- bm_PlotEvalMean(bm.out = myBiomodSM, dataset = 'calibration', metric.eval = c('Rsquared', 'Rsquared_aj'))
myPlot <- bm_PlotEvalMean(bm.out = myBiomodSM, dataset = 'validation', metric.eval = c('Rsquared', 'Rsquared_aj'))
myPlot <- bm_PlotEvalBoxplot(bm.out = myBiomodSM, dataset = 'calibration', group.by = c('algo', 'algo'))
myPlot <- bm_PlotEvalBoxplot(bm.out = myBiomodSM, dataset = 'calibration', group.by = c('algo', 'run'))
myPlot <- bm_PlotVarImpBoxplot(bm.out = myBiomodSM, group.by = c('expl.var', 'algo', 'algo'))
myPlot <- bm_PlotVarImpBoxplot(bm.out = myBiomodSM, group.by = c('expl.var', 'algo', 'run'))
myPlot <- bm_PlotVarImpBoxplot(bm.out = myBiomodSM, group.by = c('algo', 'expl.var', 'run'))
names(myPlot)

# Create model subsets
mySet1 <- get_built_models(myBiomodSM)[c(1:3, 7:9)]
mySet2 <- get_built_models(myBiomodSM)[3]

# Represent response curves
myPlot <- bm_PlotResponseCurves(bm.out = myBiomodSM, models.chosen = mySet1, fixed.var = 'median')
myPlot <- bm_PlotResponseCurves(bm.out = myBiomodSM, models.chosen = mySet1, fixed.var = 'min')
myPlot <- bm_PlotResponseCurves(bm.out = myBiomodSM, models.chosen = mySet2, do.bivariate = TRUE)

# Explore models' outliers & residuals
myPlot <- bm_ModelAnalysis(bm.mod = myBiomodSM, models.chosen = mySet1)
names(myPlot)


# Project single models
myBiomodProj <- BIOMOD_Projection(bm.mod = myBiomodSM,
                                  proj.name = 'Period1',
                                  new.env = myExpl[period1, ],
                                  new.env.xy = myRespXY[period1, ],
                                  models.chosen = 'all',
                                  build.clamping.mask = TRUE, 
                                  digits = 1)
myBiomodProj
plot(myBiomodProj, coord = myRespXY[period1, ])

# Project onto future conditions
myBiomodProjectionFuture <- BIOMOD_Projection(bm.mod = myBiomodSM,
                                              proj.name = 'Period2',
                                              new.env = myExpl[period2, ],
                                              new.env.xy = myRespXY[period2, ],
                                              models.chosen = 'all',
                                              build.clamping.mask = TRUE)

# Compute differences
myBiomodRangeSize <- BIOMOD_RangeSize(proj.current = myBiomodProj, 
                                      proj.future = myBiomodProjectionFuture,
                                      metric.binary = 'TSS')

myBiomodRangeSize@Compt.By.Models


# Get a summary report
BIOMOD_Report(bm.out = myBiomodSM, strategy = 'report')

# Get a pre-filled ODMAP
BIOMOD_Report(bm.out = myBiomodSM, strategy = 'ODMAP')

# Get a code report
BIOMOD_Report(bm.out = myBiomodSM, strategy = 'code')
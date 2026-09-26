# ENM Curriculum for Beginners

> 本仓库最初由[乔慧捷老师的 ENM Curriculum](https://github.com/qiaohj/ENM_curriculum) fork 而来。下方英文课程提纲和原始脚本予以保留；新增的中文学习注释由本仓库维护者独立整理，不代表乔老师或课程的官方说明。感谢乔老师开放课程代码，让我们能够逐步理解物种分布模型的建模思路。原始代码采用 [MIT 许可](LICENSE)，原版权声明保留在 `LICENSE` 中。

## 中文入口

- [十二章中文讲解网页｜在线阅读](https://bird-map-ecology-david.robbleeglish.chatgpt.site/)——从一条鸟类记录出发，把模型、验证和应用连成一段完整的故事；[网页文件与数据也保存在本仓库](website/README.md)。
- [中文课程故事与逐日索引](README.zh-CN.md)——跟着一个生态问题读懂 Day 0–15，配有课程复现数据图。
- [课程课件 PDF 与逐份导读](course/courseware/README.md)——按 6 个主题阅读 13 份已获授权课件；每份都说明用途、核心内容和阅读收获。
- [课程故事：图背后的问题](docs/课程故事.md)——把目标、模型、验证和外推连成一条线。
- [学习导航：从生态问题走到模型地图](docs/学习导航.md)——按问题串起 D1–D15，并列出各脚本的输入与用途。
- [方法理解：读懂模型输出与边界](docs/方法理解.md)——解释出现点、背景点、适宜性、验证和外推。
- [课程仓库系统化建设 SPEC](docs/课程仓库系统化建设SPEC.md)——说明新材料怎样深读、代码怎样复现、中文索引怎样建设，以及哪些原件可以公开。
- [来源与致谢](docs/来源与致谢.md)——分清原课程代码、我们的注释和外部数据。
- [上游原始代码与文件对照](upstream/README.md)——按课程脚本、专题和辅助示例查找原文件；文件迁移前后的路径见 `catalog/upstream-file-map.csv`。

想边读边动手，可以从[学习导航的准备说明](docs/学习导航.md#运行前先看这里)开始；新加入的图表也附有[数据和绘图代码](docs/figures/README.md)，方便逐张对照。

## Day 0: Environment Setup, Toolchain Installation, and Course Asset Preparation
+ **1. Scientific Computing & Geospatial Software Toolchain**
  + Installing the core statistical environment: **R** (>= 4.3) and **RStudio Desktop** (or VS Code with R extension).
  + Installing Java Development Kit (**JDK** 11/17/21, matching system architecture) for `rJava` and standalone MaxEnt.
  + Setting up Geographic Information System (GIS): **QGIS** (LTM release) for spatial vector and raster inspection.
  + Installing version control tools: **Git** and GUI client (**Fork** / GitHub Desktop).
  + Deploying standalone **MaxEnt** (`maxent.jar` v3.4.4+) into R library paths.
+ **2. Repository Cloning & Standard Directory Architecture**
  + Cloning the official course repository from GitHub (`https://github.com/qiaohj/ENM_curriculum`).
  + Establishing the standardized reproducible directory structure (`Data/`, `Figures/`, `Scripts/`, `Output/`).
+ **3. Automated R Package Installation & Dependency Resolution**
  + Installing core spatial engines: `terra`, `sf`, `geodata`, `rnaturalearth`, `rnaturalearthdata`, `units`.
  + Installing data wrangling & visualization libraries: `data.table`, `ggplot2`, `patchwork`, `ggrepel`, `viridis`.
  + Installing ecological modeling frameworks: `ENMeval`, `biomod2`, `dismo`, `maxnet`, `mgcv`, `randomForest`, `ecospat`.
  + Testing and validating Java integration via `rJava::.jinit()`.
+ **4. Course Datasets & Baseline Environmental Asset Downloads**
  + Downloading global bioclimatic rasters (**WorldClim** v2.1: 19 BioClim layers at 10m, 5m, 2.5m, and 30s resolutions).
  + Downloading auxiliary spatial layers: Digital Elevation Model (SRTM/GMTED2010), Land Cover, and Global Continents basemap.
  + Downloading curated species occurrence records (GBIF clean exports) and expert range maps (IUCN Red List Spatial Data) from the course repository / Figshare repository ([course dataset](https://doi.org/10.6084/m9.figshare.33453802)).
+ **5. System Environment & Toolchain Self-Test**
  + Running an automated diagnostic R script to verify GDAL, GEOS, PROJ, and Java backends.
  
## Day 1: Create your first SDM in R (End-to-End Workflow)
+ **1. Downloading the occurrences**
  + Fetching *Grus japonensis* (Red-crowned crane) data from GBIF 
+ **2. Getting environmental predictors**
  + Downloading WorldClim bioclimatic variables via https://www.worldclim.org/data/worldclim21.html
  + Cropping environmental layers to the study area
+ **2. Cleaning up the occurrences**
  + Dropping points with missing coordinates
  + Removing points that fall outside the environmental layers (NA removal)
  + Spatial thinning: keeping only one occurrence per raster cell
  + Visualizing the Raw vs. Cleaned occurrences
+ **4. Running your first ENM**
  + Formatting data for modeling (extracting values)
  + Fitting a simple profile model (e.g., Bioclim from *dismo*)
+ **5. Visualizing the results**
  + Plotting the current habitat suitability map
  
## Day 2: Moving to Presence-Background Models (GLM & Maxent)
+ **1. Understanding the Absence of Data**
  + The concept: True Absences vs. Pseudo-absences vs. Background points
  + Why modern models require a contrastting sample
+ **2. Generating Background Points**
  + Randomly sampling points across the study extent
  + Ensuring spatial consistency with environmental layers
+ **3. Constructing the Modeling DataFrame**
  + Combining presences (1) and background points (0)
  + Extracting climatic values for all coordinates
  + Handling NAs in the extracted data
+ **4. Fitting a Generalized Linear Model (GLM)**
  + Formulating a logistic regression for species distribution
  + Running the model and interpreting coefficients
+ **5. Fitting a Maxent Model (via *maxnet*)**
  + Why Maxent is popular in ecology
  + Training the model using the `maxnet` package (Java-free)
+ **6. Predicting and Comparing**
  + Generating continuous suitability maps for both GLM and Maxent
  + Visualizing and comparing the spatial predictions side-by-side
  
## Day 3: Variable Screening and Model Evaluation
+ **1. Dealing with Multicollinearity**
  + Understanding why highly correlated predictors harm models
  + Calculating the Pearson correlation matrix
  + Using Variance Inflation Factor (VIF) to drop collinear variables (*usdm* package)
+ **2. Data Splitting (Train vs. Test)**
  + The concept of out-of-sample prediction
  + Splitting the dataset into 70% training and 30% testing sets using *data.table*
+ **3. Refitting the Model**
  + Training the GLM/Maxent model strictly on the training subset using selected variables
+ **4. Evaluating Model Performance**
  + Predicting probabilities on the independent test set
  + Understanding the Confusion Matrix and ROC Curve
  + Calculating Area Under the Curve (AUC) using the *pROC* package
+ **5. Publication-Ready Visualization**
  + Plotting the ROC curve cleanly using *ggplot2*
+ **6 Demystifying the ROC Curve (Manual Simulation)**
  + Iterating through continuous probability thresholds (0.00 to 1.00)
  + Calculating Confusion Matrix elements dynamically (TP, FP, TN, FN)
  + Tracking the trade-off between Sensitivity and Specificity
  + Calculating True Skill Statistic (TSS) to find the optimal threshold
  + Visualizing threshold dynamics and plotting the manual ROC curve

## Day 4: Future Climate Projections and Range Shifts
+ **1. Preparing Future Climate Scenarios**
  + The challenge of CMIP6 data size in classroom settings
  + Simulating a future scenario (e.g., +2.0°C warming) using spatial raster algebra
+ **2. Projecting the Model into the Future**
  + Predicting continuous suitability across the future landscape
  + Comparing Current vs. Future continuous maps side-by-side
+ **3. Binarizing Predictions**
  + Applying the optimal threshold (Max TSS) from Day 3
  + Converting probabilities into Presence (1) / Absence (0) maps
+ **4. Mapping Distribution Changes (Range Shifts)**
  + Using map algebra to identify Stable, Loss, and Gain areas
  + `Current + (Future * 2)` spatial trick
+ **5. Quantifying and Visualizing the Impact**
  + Converting rasters to `data.table` for rapid area calculation
  + Summarizing the percentage of range contraction and expansion
  + Creating a publication-ready Range Shift map using *ggplot2*

## Day 5: Advanced Model Tuning and Selection (*ENMeval*)
+ **1. The Danger of Default Settings**
  + What are Feature Classes (FC) and Regularization Multipliers (RM)?
  + The trade-off between model complexity and overfitting
+ **2. Preparing Data for *ENMeval***
  + Formatting occurrences and background points
  + Aligning with selected environmental predictors
+ **3. Setting up Spatial Cross-Validation**
  + Why random k-fold fails in spatial data (Spatial Autocorrelation)
  + Introducing the "block" partitioning method for robust evaluation
+ **4. Executing the Evaluation Grid**
  + Running combinations of FCs (e.g., L, LQ, LQH) and RMs (e.g., 0.5 to 3.0)
  + Using the Java-free `maxnet` algorithm within *ENMeval*
+ **5. Selecting the Optimal Model**
  + Interpreting the *ENMeval* results table
  + Using Delta AICc (Akaike Information Criterion) to find the most parsimonious model
  + Checking the omission rate and AUC difference (AUC_diff) to avoid overfitting
+ **6. Extracting and Projecting the Best Model**
  + Retrieving the optimal `maxnet` model object
  + Generating the final tuned suitability map

## Day 6: Advanced Sensitivity Analysis of Model Parameters
+ **1. Designing the Experiment**
  + Defining the parameter space: `partitions`, `bg` extents, `rm`, and `fc`.
  + Scenario A: Random k-fold + Global Background (The Naive approach)
  + Scenario B: Spatial Block + Global Background (Controlling spatial autocorrelation)
  + Scenario C: Spatial Block + Buffered Background (Controlling sampling bias)
+ **2. Preparing Different Background Sets**
  + Generating global random background points
  + Creating a 500km spatial buffer around occurrences for targeted background
+ **3. Batch Executing ENMevaluate**
  + Running multiple *ENMeval* iterations to capture the performance metrics
+ **4. Aggregating and Visualizing Results**
  + Using *data.table* to combine evaluation matrices
  + Plotting Validation AUC: How partitioning inflates accuracy metrics
  + Plotting AUC Difference (Overfitting): How FCs and RMs behave under different scenarios

## Day 7: Visualizing Predictions in Geographical and Environmental Space
+ **1. Geographical Space Visualization (G-Space)**
  + Comparing a simple model (Linear) vs. a complex model (Linear-Quadratic-Hinge)
  + Plotting continuous suitability maps
  + Applying a threshold to visualize binary presence/absence maps
+ **2. Translating to Environmental Space (E-Space)**
  + Extracting the background environmental matrix
  + Running Principal Component Analysis (PCA) to reduce climate dimensions to PC1 and PC2
+ **3. Defining Niche Boundaries in E-Space**
  + Projecting the predicted presence pixels into the PCA space
  + Calculating **Range Box** (Bounding Box): The absolute min/max limits
  + Calculating **Convex Hull**: The smallest convex polygon enclosing all points
  + Calculating **Concave Hull**: A tighter, non-convex boundary matching point density
  + Calculating **Minimum Volume Ellipsoid (MVE)**: The core statistical niche shape
+ **4. Multi-Shape Niche Visualization**
  + Plotting the background E-Space (gray points)
  + Overlaying the predicted niche points and the 4 boundary shapes in a single *ggplot2* framework
  
## Day 8: Spatial Data and Map Projections Foundation
+ **1. The Two Worlds of Spatial Data: Vector vs. Raster**
  + **Vector:** Representing discrete objects (Points, Lines, Polygons) using mathematical coordinates.
  + **Raster:** Representing continuous surfaces (like climate) using a grid of pixels (cells).
  + Converting Vector to Raster (Rasterization) and understanding resolution limits.
+ **2. Understanding Coordinate Reference Systems (CRS)**
  + Geographic CRS (3D spherical: Longitude/Latitude in degrees)
  + Projected CRS (2D flat Cartesian: X/Y in meters)
+ **3. The Geometry of Projections: Unrolling the Earth**
  + **Cylindrical Projection:** Wrapping the Earth in a cylinder (e.g., Mercator). Graticules form a rigid rectangular grid; severe polar distortion.
  + **Conic Projection:** Dropping a cone over a hemisphere (e.g., Lambert Conformal Conic). Graticules form a fan shape; excellent for mid-latitudes.
+ **4. The Azimuthal Equidistant Projection (The UN Emblem)**
  + Projecting from the North Pole outward.
  + Preserving accurate distances and directions from the center.
  + Recreating the iconic United Nations logo map using R and *ggplot2*.
  
## Day 9: Niche Shift and Invasion Biology (Native vs. Invaded Ranges)
+ **1. Defining the Biogeographic Realms**
  + Splitting the occurrence data into Native (North America) and Invaded (Europe) ranges.
  + Defining range-specific background environments (NA_bg and EU_bg).
+ **2. Constructing the Global Environmental Space (PCA-env)**
  + Calibrating a global PCA using the combined backgrounds of both ranges.
  + Projecting Native and Invaded occurrences into this shared E-Space.
+ **3. Quantifying Niche Dynamics (*ecospat* framework)**
  + Calculating species occurrence densities via kernel smoothers in PCA space.
  + Computing Schoener's $D$ metric for niche overlap.
  + Extracting Niche Stability, Unfilling, and Expansion indexes.
+ **4. Visualizing Niche Shifts and Analogous Climates**
  + Plotting the density grids to identify True Shifts vs. Climatic differences.
  + Interpreting the solid and dashed contour lines (available background vs. occupied niche).

## Day 10: The Scales of Time and Space in Macroecology
+ **1. The Temporal Scale: Climate Through Deep Time**
  + Where real paleo-data comes from (e.g., Zachos 2001 Benthic Isotope Stack, EPICA Ice Cores, CMIP6).
  + Phanerozoic Eon (500 Ma to present): Greenhouse and Icehouse Earth cycles.
  + Pliocene-Pleistocene (3.6 Ma to present): Milankovitch cycles and the onset of glaciations.
  + The Holocene (12 ka to present): The stable interglacial window that allowed human civilization.
  + The Anthropocene (1850 to 2100): The unprecedented velocity of modern climate change.
+ **2. The Spatial Scale: Earth's Geometry vs. The Biosphere**
  + The Macro-Space: Comparing Earth's radius (6,371 km) to its highest peak (Mount Everest, 8.8 km). The Earth is smoother than a billiard ball.
  + The Micro-Space: The paper-thin layer of life.
  + Reconciling standard meteorological measurements (2m height) vs. macroclimate grids (1km/100m) vs. organismal microclimates (0-5m).
+ **3. Visualizing the Extremes**
  + Using *ggplot2* to create multi-panel time-series comparisons.
  + Creating conceptual vertical profiles to demonstrate the true scale of the biosphere.
+ **4 The Pacemaker of the Ice Ages: Milankovitch Cycles**
  + **Eccentricity (100,000-year cycle):** The shape of Earth's orbit (circular vs. elliptical).
  + **Obliquity (41,000-year cycle):** The tilt of Earth's axis (from 22.1° to 24.5°).
  + **Precession (23,000-year cycle):** The wobble of Earth's axis (like a spinning top).
  + How orbital interactions dictate solar insolation and trigger Glacial-Interglacial cycles.
  + Simulating and combining orbital waves to reconstruct paleoclimate forcing using *data.table*.
  
## Day 11: Multi-Algorithm Extrapolation and Clamping Behavior (Direct Native Models)
+ **1. The Mechanics of Algorithm Extrapolation**
  + Parametric vs. Semi-parametric vs. Tree-based vs. Maximum Entropy algorithms.
+ **2. Data Preparation and Feature Extraction**
  + Constructing presence-background matrix for *Grus japonensis* using *data.table*.
  + Extracting `bio1` (Temperature) and `bio12` (Precipitation) predictors.
+ **3. Fitting Direct Native Models**
  + **GLM:** Logistic regression with polynomial/quadratic terms (`stats::glm`).
  + **GAM:** Thin plate regression splines (`mgcv::gam`).
  + **Random Forest:** Ensemble of decision trees (`randomForest::randomForest`).
  + **Maxnet:** Penalized regression with default feature classes (`maxnet::maxnet`).
+ **4. Designing the Synthetic Novel Environmental Gradient**
  + Identifying empirical training boundaries for `bio1` ($[\min, \max]$).
  + Generating extended environmental values ($\pm 15^\circ\text{C}$ beyond the training data).
  + Holding secondary variables (`bio12`) fixed at the sample mean.
+ **5. Multi-Model Prediction and Clamping Visualization**
  + Vectorized multi-model prediction using *data.table*.
  + Visualizing the divergence between "Clamping" and "Exploding" in *ggplot2*.

## Day 12: Spatial Cross-Validation and Partitioning Schemes
+ **1. Spatial Autocorrelation and the Independence Dilemma**
  + Why random k-fold fails in spatial data (Tobler's First Law of Geography).
  + The trade-off between spatial independence, sample balance, and transferability.
+ **2. Data Preparation and Spatial Baseline Setup**
  + Processing presence and background coordinates for *Grus japonensis* with *data.table*.
  + Aligning environmental rasters and extracting spatial extent boundaries.
+ **3. Implementing Geographic Partitioning Schemes (*ENMeval*)**
  + **Random 4-Fold:** Non-spatial random assignment baseline (`get.randomkfold`).
  + **Spatial Block:** 4-quadrant division by coordinate medians (`get.block`).
  + **Checkerboard 1:** Single-tier alternating regular spatial grid (`get.checkerboard1`).
  + **Checkerboard 2:** Hierarchical dual-resolution nested grid (`get.checkerboard2`).
+ **4. Mapping Spatial Boundaries and Fold Allocations**
  + Computing geographic split lines (median coordinate axes and grid step lines).
  + Visualizing spatial fold assignments and dashed partition boundaries with *ggplot2* and *sf*.
+ **5. Quantitative Performance and Overfitting Assessment**
  + Training standardized Maxent models across all four partition configurations.
  + Extracting and comparing Validation AUC ($\text{AUC}_{\text{val}}$) and AUC Difference ($\text{AUC}_{\text{diff}}$).
  + Generating comparative barplots with error bars to quantify spatial overfitting.
  
## Day 13: Map Projections, Raster Transformations, and Geographic vs. Environmental Space
+ **1. Global Map Projections and Geometric Distortions**
  + Comparing Geographic Coordinate Systems (WGS84 / EPSG:4326) with Projected Systems.
  + Exploring Azimuthal Equidistant projections across different origin points ($\lambda_0, \phi_0$).
  + Reconstructing the polar perspective (UN emblem style) and global equal-area projections (Mollweide).
+ **2. Environmental Raster Processing and Reprojection**
  + Loading continuous bioclimatic surfaces (e.g., `bio1` Temperature, `bio12` Precipitation) with *terra*.
  + Executing raster reprojection (`terra::project`) across custom PROJ coordinate definitions.
  + Converting raster matrices into high-speed *data.table* structures and standardizing predictors ($Z$-scores).
+ **3. The Duality of Geographic Space (G-Space) and Environmental Space (E-Space)**
  + Conceptualizing the mapping between physical coordinates ($X, Y$) and bivariate niche dimensions ($Bio_1, Bio_{12}$).
  + Converting raster data tables into spatial simple features (`sf`) for spatial intersection and topological querying (`st_within`).
+ **4. Macroclimatic Niche Realization Across Biogeographic Realms**
  + Extracting country-specific climate points for contrasting biomes:
    + *Malaysia* (Tropical Rainforest)
    + *Libya* (Hot Arid Desert)
    + *Colombia* (Tropical Montane)
    + *China* (Temperate to Subtropical Gradient)
  + Plotting multi-panel diagnostic maps combining geographic boundaries, G-Space distributions, and E-Space occupancy.
  + Overlaying regional climate envelopes onto global background space to demonstrate realized climatic constraints.
  
## Day 14: Modeling Species Abundance (Count Data), Ensembles, and Reproducible Reporting (*biomod2*)
+ **1. Beyond Binary Data: Modeling Count and Abundance Data**
  + Transitioning from Presence/Absence ($0/1$) to continuous Count Data (`data.type = "count"`).
  + Structuring temporal evaluation: Splitting multi-year monitoring surveys (*DataSTOC*, e.g., 2006–2011 calibration vs. 2012–2017 independent evaluation).
  + Formatting multi-temporal count responses and environmental predictors with `BIOMOD_FormatingData`.
+ **2. Multi-Algorithm Ensemble for Abundance Modeling**
  + Fitting regression and machine learning algorithms: Deep Neural Networks (`DNN`), Gradient Boosting (`GBM`), Generalized Linear Models (`GLM`), Multivariate Adaptive Regression Splines (`MARS`), Random Forests (`RF`), and `XGBOOST`.
  + Applying Spatial Block cross-validation (`CV.strategy = "block"`) and standardized tuning parameter presets (`OPT.strategy = "bigboss"`).
  + Assessing continuous model metrics: $R^2$, Adjusted $R^2$, and Root Mean Square Error (`RMSE`).
+ **3. Model Diagnostics, Variable Importance, and Response Curves**
  + Quantifying permutation-based variable importance across models and cross-validation runs (`bm_PlotVarImpBoxplot`).
  + Comparing model calibration vs. validation performance distributions (`bm_PlotEvalBoxplot`).
  + Visualizing univariate and bivariate environmental response curves (`bm_PlotResponseCurves`).
  + Diagnostic inspection of model residuals and spatial outliers (`bm_ModelAnalysis`).
+ **4. Multi-Temporal Projections and Range Size Dynamics**
  + Projecting fitted count models onto calibration (Period 1) and evaluation (Period 2) environmental states (`BIOMOD_Projection`).
  + Tracking novel environmental boundaries and clamping masks (`build.clamping.mask = TRUE`).
  + Quantifying temporal range changes, stability, and shifts across models using `BIOMOD_RangeSize`.
+ **5. Reproducibility and Standardized Model Reporting**
  + Exporting automated modeling summary and code audit reports (`BIOMOD_Report`).
  + Generating standardized **ODMAP** (Overview, Data, Model, Assessment, and Prediction) protocol tables for academic publication compliance.

## Day 15: Expert Range Validation (IUCN Ranges), Maxent Feature Constraints, Model Tuning (*ENMeval*), and Geometric Envelopes
+ **1. Expert Range Mapping and Spatial Quality Control**
  + Decoding IUCN Red List attribute codes (`PRESENCE` and `SEASONAL` categories).
  + Filtering target native and breeding ranges for *Grus japonensis*.
  + Topological point-in-polygon validation (`st_contains`) and buffer sensitivity analysis (`st_buffer` with *units*).
+ **2. Feature Class Constraints and Maxent Complexity**
  + Comparing projection behavior across discrete feature combinations: Linear (`L`), Quadratic (`Q`), Product (`P`), and full model setups.
  + Diagnosing geographic suitability patterns under constrained vs. unconstrained feature spaces.
+ **3. Automated Model Tuning and Model Selection via *ENMeval***
  + Extracting bioclimatic predictors and removing `NA` values across occurrence and background sets.
  + Evaluating parameter grids across Feature Classes (`fc`: L, Q, P, LQ, QP) and Regularization Multipliers (`rm`: 0.1, 1.0, 10.0).
  + Identifying optimal model balance using AICc vs. Training AUC pareto fronts with *ggrepel*.
+ **4. Sensitivity Analysis of Predictor Subsets and Background Sizes**
  + Comparing full bioclimatic predictions against reduced models (`bio1` and `bio12`).
  + Assessing suitability surface sensitivity across varying background sample densities (e.g., 100 background points vs. standard samples).
+ **5. Spatial Geometric Envelopes and Centroid Dynamics**
  + Decomposing multipart shapes into discrete polygons (`st_cast`).
  + Constructing minimum bounding convex hulls (`st_convex_hull`) and tracking geographic centroid shifts (`st_centroid`).

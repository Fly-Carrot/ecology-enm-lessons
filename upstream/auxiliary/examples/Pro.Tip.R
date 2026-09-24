# ==============================================================================
# Pro Tip: Downloading GBIF data with a DOI using 'rgbif'
# Note: This is the required standard for publishing peer-reviewed papers.
# ==============================================================================

# install.packages(c("rgbif", "data.table"))
library(rgbif)
library(data.table)

# ------------------------------------------------------------------------------
# Step 1: Set up your GBIF credentials
# ------------------------------------------------------------------------------
# To request a formal download (which generates a DOI), you MUST have a free GBIF account.
# Best practice is to store these in your .Renviron file, but for demonstration:
# Sys.setenv(GBIF_USER = "your_username", 
#            GBIF_PWD = "your_password", 
#            GBIF_EMAIL = "your_email@example.com")

cat("Step 1 complete: Credentials configured (ensure you use your real account info).\n")

# ------------------------------------------------------------------------------
# Step 2: Find the Taxon Key
# ------------------------------------------------------------------------------
# GBIF uses numeric keys for taxonomy. We first need the exact usageKey for our species.
species_name <- "Grus japonensis"
taxon_info <- name_backbone(name = species_name)
t_key <- taxon_info$usageKey

cat("Taxon key for", species_name, "is:", t_key, "\n")

# ------------------------------------------------------------------------------
# Step 3: Submit the asynchronous download request
# ------------------------------------------------------------------------------
# This sends a request to GBIF servers to prepare a zip file.
# We also apply server-side filters to only get useful records.
dl_request <- occ_download(
  pred("taxonKey", t_key),
  pred("hasCoordinate", TRUE),         # Only records with coordinates
  pred("hasGeospatialIssue", FALSE),   # Remove records with known spatial errors
  format = "SIMPLE_CSV"
)

cat("Download requested. GBIF is processing your data...\n")

# ------------------------------------------------------------------------------
# Step 4: Wait for the download to finish, then fetch it
# ------------------------------------------------------------------------------
# This pauses R until the GBIF servers finish preparing your file.
occ_download_wait(dl_request)

# Download the zip file to a local directory (e.g., temporary directory)
dl_archive <- occ_download_get(dl_request, path = tempdir())

# ------------------------------------------------------------------------------
# Step 5: Import into R and convert to data.table
# ------------------------------------------------------------------------------
# Import the CSV from the zip file and explicitly cast it as a data.table
gbif_raw <- occ_download_import(dl_archive)
crane_dt <- as.data.table(gbif_raw)

# Clean up using data.table syntax (keeping only essential columns)
# Note: gbif_raw contains many columns, we select decimalLongitude and decimalLatitude
crane_clean_dt <- crane_dt[!is.na(decimalLongitude) & !is.na(decimalLatitude), 
                           .(lon = decimalLongitude, lat = decimalLatitude, year, basisOfRecord)]

cat("Data successfully imported as data.table. Number of rows:", nrow(crane_clean_dt), "\n")

# ------------------------------------------------------------------------------
# Step 6: Retrieve your DOI for publication!
# ------------------------------------------------------------------------------
# This is the exact DOI you will cite in your paper's Data Availability statement.
dl_meta <- occ_download_meta(dl_request)
cat("====================================================\n")
cat("YOUR CITEABLE DOI IS:", dl_meta$doi, "\n")
cat("====================================================\n")
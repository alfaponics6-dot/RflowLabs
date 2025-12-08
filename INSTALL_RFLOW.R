################################################################################
# PERMANENT INSTALLATION SCRIPT FOR RFLOW
# This script tries multiple methods to install Rflow
# Works around GitHub API download issues
################################################################################

cat("\n")
cat("================================================================================\n")
cat("RFLOW - PERMANENT INSTALLATION SCRIPT\n")
cat("================================================================================\n\n")

install_rflow <- function() {

  # Method 1: Try different download methods
  cat("METHOD 1: Trying different download methods...\n")
  cat("----------------------------------------------\n")

  methods <- c("libcurl", "wininet", "wget", "curl")

  for (method in methods) {
    cat("Trying download method:", method, "...\n")
    options(download.file.method = method)
    options(timeout = 300)  # 5 minutes

    result <- tryCatch({
      remotes::install_github("carlychery2001/RflowLabs",
                             auth_token = NULL,
                             upgrade = "never")
      TRUE
    }, error = function(e) {
      cat("  Failed with method", method, "\n")
      FALSE
    })

    if (result) {
      cat("\n✓ SUCCESS! Installed using method:", method, "\n")
      return(TRUE)
    }
  }

  # Method 2: Direct ZIP download from GitHub
  cat("\nMETHOD 2: Direct ZIP download from GitHub...\n")
  cat("----------------------------------------------\n")

  tryCatch({
    temp_dir <- tempdir()
    zip_file <- file.path(temp_dir, "Rflow.zip")
    extract_dir <- file.path(temp_dir, "Rflow-main")

    # Download ZIP
    cat("Downloading ZIP file...\n")
    download.file(
      url = "https://github.com/carlychery2001/RflowLabs/archive/refs/heads/main.zip",
      destfile = zip_file,
      mode = "wb",
      method = "auto"
    )

    # Extract
    cat("Extracting...\n")
    unzip(zip_file, exdir = temp_dir)

    # Find the extracted directory
    extracted <- list.files(temp_dir, pattern = "RflowLabs-main", full.names = TRUE)
    if (length(extracted) > 0) {
      pkg_dir <- extracted[1]

      # Install
      cat("Installing from local directory...\n")
      devtools::install(pkg_dir, upgrade = "never")

      # Cleanup
      unlink(zip_file)
      unlink(pkg_dir, recursive = TRUE)

      cat("\n✓ SUCCESS! Installed from ZIP download\n")
      return(TRUE)
    }
  }, error = function(e) {
    cat("  Failed:", e$message, "\n")
  })

  # Method 3: Install from local directory (if available)
  cat("\nMETHOD 3: Local installation...\n")
  cat("----------------------------------------------\n")

  local_path <- "C:/Users/carly/Downloads/Rflow worked version 3/Rflow"
  if (dir.exists(local_path)) {
    cat("Found local directory:", local_path, "\n")
    tryCatch({
      setwd(local_path)
      devtools::install()
      cat("\n✓ SUCCESS! Installed from local directory\n")
      return(TRUE)
    }, error = function(e) {
      cat("  Failed:", e$message, "\n")
    })
  }

  # Method 4: Install from git URL directly
  cat("\nMETHOD 4: Installing from git URL...\n")
  cat("----------------------------------------------\n")

  tryCatch({
    remotes::install_git(
      "https://github.com/carlychery2001/RflowLabs.git",
      upgrade = "never"
    )
    cat("\n✓ SUCCESS! Installed from git URL\n")
    return(TRUE)
  }, error = function(e) {
    cat("  Failed:", e$message, "\n")
  })

  # If all methods fail
  cat("\n")
  cat("================================================================================\n")
  cat("ALL AUTOMATIC METHODS FAILED\n")
  cat("================================================================================\n\n")

  cat("Please try MANUAL INSTALLATION:\n\n")
  cat("1. Download ZIP manually:\n")
  cat("   https://github.com/carlychery2001/RflowLabs/archive/refs/heads/main.zip\n\n")
  cat("2. Extract the ZIP file\n\n")
  cat("3. Run in R:\n")
  cat("   setwd('path/to/extracted/RflowLabs-main')\n")
  cat("   devtools::install()\n\n")

  return(FALSE)
}

# Install dependencies first
cat("Installing dependencies...\n")
if (!require("remotes")) install.packages("remotes")
if (!require("devtools")) install.packages("devtools")

cat("\n")

# Run installation
success <- install_rflow()

if (success) {
  cat("\n")
  cat("================================================================================\n")
  cat("INSTALLATION SUCCESSFUL!\n")
  cat("================================================================================\n\n")

  cat("Test it now:\n")
  cat("  library(Rflow)\n")
  cat("  data(iris)\n")
  cat("  result <- rf_train(iris, 'Species')\n")
  cat("  print(result$performance)\n\n")

  cat("Documentation:\n")
  cat("  ?rf_train\n")
  cat("  ?rf_soil_analysis\n\n")
}

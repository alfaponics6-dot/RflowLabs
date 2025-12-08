################################################################################
# FIX NAMESPACE - Run this to export Random Forest functions
################################################################################

cat("\n=== Fixing NAMESPACE to Export Random Forest Functions ===\n\n")

# Set working directory
setwd("C:/Users/carly/Downloads/Rflow worked version 3/Rflow")
cat("Working directory:", getwd(), "\n\n")

# Install roxygen2 if needed
if (!require("roxygen2", quietly = TRUE)) {
  cat("Installing roxygen2...\n")
  install.packages("roxygen2")
}

# Generate documentation and NAMESPACE
cat("Generating documentation with roxygen2...\n")
roxygen2::roxygenize()

cat("\n✓ NAMESPACE updated!\n")
cat("✓ Documentation generated!\n\n")

# Reinstall the package
cat("Reinstalling Rflow...\n")
devtools::install()

cat("\n=== FIXED! ===\n\n")

cat("Now try:\n")
cat("library(Rflow)\n")
cat("data(iris)\n")
cat("result <- rf_train(iris, 'Species')\n")
cat("print(result$performance)\n\n")

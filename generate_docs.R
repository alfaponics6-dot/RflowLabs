#!/usr/bin/env Rscript
# Generate documentation and NAMESPACE

setwd("C:/Users/carly/Downloads/Rflow worked version 3/Rflow")
cat("Generating documentation...\n")

if (!require("roxygen2", quietly = TRUE)) {
  install.packages("roxygen2", repos = "https://cran.r-project.org")
}

roxygen2::roxygenize()
cat("Done!\n")

################################################################################
# LOAD AND TEST - Random Forest Agriculture Features
#
# INSTRUCTIONS:
# 1. Open RStudio
# 2. Open this file (LOAD_AND_TEST.R)
# 3. Select all (Ctrl+A) and run (Ctrl+Enter)
#
################################################################################

cat("\n")
cat("================================================================================\n")
cat("RFLOW - RANDOM FOREST AGRICULTURE - LOAD AND TEST\n")
cat("================================================================================\n\n")

# Set working directory to package root
setwd("C:/Users/carly/Downloads/Rflow worked version 3/Rflow")
cat("Working directory:", getwd(), "\n\n")

# Step 1: Install required packages
cat("STEP 1: Installing required packages...\n")
cat("----------------------------------------\n")

packages <- c("devtools", "roxygen2", "randomForest", "ggplot2")
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cran.r-project.org")
    library(pkg, character.only = TRUE)
  } else {
    cat("✓", pkg, "\n")
  }
}

cat("\n")

# Step 2: Generate documentation and update NAMESPACE
cat("STEP 2: Generating documentation...\n")
cat("----------------------------------------\n")

tryCatch({
  roxygen2::roxygenize()
  cat("✓ Documentation generated\n")
  cat("✓ NAMESPACE updated\n")
}, error = function(e) {
  cat("Warning:", e$message, "\n")
})

cat("\n")

# Step 3: Load package with devtools
cat("STEP 3: Loading package with devtools::load_all()...\n")
cat("----------------------------------------\n")

devtools::load_all()
cat("✓ Package loaded!\n\n")

# Step 4: Verify functions are available
cat("STEP 4: Verifying functions...\n")
cat("----------------------------------------\n")

functions_list <- c(
  "rf_train",            # NEW: General purpose!
  "rf_soil_analysis",
  "rf_poultry_fish",
  "rf_agronomy",
  "generate_ag_data",
  "plot_rf_importance",
  "plot_rf_predictions"
)

for (func in functions_list) {
  if (exists(func)) {
    cat("✓", func, "\n")
  } else {
    cat("✗", func, "NOT FOUND\n")
  }
}

cat("\n")

# Step 5: Quick functionality test
cat("STEP 5: Running quick tests...\n")
cat("----------------------------------------\n\n")

cat("Test 1: Soil Fertility Classification\n")
cat("--------------------------------------\n")
soil_data <- generate_ag_data("soil", n = 150)
cat("Generated", nrow(soil_data), "soil samples\n")

soil_model <- rf_soil_analysis(
  data = soil_data,
  target = "fertility",
  task_type = "classification",
  ntree = 200,
  seed = 123
)

cat("\n\nTest 2: Egg Production Forecasting\n")
cat("--------------------------------------\n")
poultry_data <- generate_ag_data("poultry", n = 150)
cat("Generated", nrow(poultry_data), "poultry records\n")

egg_model <- rf_poultry_fish(
  data = poultry_data,
  target = "egg_production",
  farm_type = "poultry",
  ntree = 200,
  seed = 123
)

cat("\n\nTest 3: Fish Growth Prediction\n")
cat("--------------------------------------\n")
fish_data <- generate_ag_data("fish", n = 120)
cat("Generated", nrow(fish_data), "fish records\n")

fish_model <- rf_poultry_fish(
  data = fish_data,
  target = "weight_gain_g",
  farm_type = "fish",
  ntree = 200,
  seed = 123
)

cat("\n\nTest 4: Disease Classification\n")
cat("--------------------------------------\n")
disease_data <- generate_ag_data("disease", n = 200)
cat("Generated", nrow(disease_data), "disease records\n")

disease_model <- rf_agronomy(
  data = disease_data,
  target = "disease",
  task_type = "classification",
  ntree = 200,
  seed = 123
)

cat("\n\nTest 5: Yield Prediction\n")
cat("--------------------------------------\n")
yield_data <- generate_ag_data("yield", n = 150)
cat("Generated", nrow(yield_data), "yield records\n")

yield_model <- rf_agronomy(
  data = yield_data,
  target = "yield_kg_ha",
  task_type = "regression",
  ntree = 200,
  seed = 123
)

cat("\n\nTest 6: General Purpose rf_train() with Iris\n")
cat("--------------------------------------\n")
data(iris)
cat("Using built-in iris dataset (", nrow(iris), " samples)\n", sep = "")

iris_model <- rf_train(
  data = iris,
  target = "Species",
  ntree = 200,
  seed = 123
)

cat("\n\nTest 7: General Purpose rf_train() with mtcars\n")
cat("--------------------------------------\n")
data(mtcars)
cat("Using built-in mtcars dataset (", nrow(mtcars), " samples)\n", sep = "")

mtcars_model <- rf_train(
  data = mtcars,
  target = "mpg",
  task_type = "regression",
  ntree = 200,
  seed = 123,
  verbose = FALSE
)
cat("Model trained successfully!\n")
cat("R-squared:", round(mtcars_model$performance$r_squared, 3), "\n")

cat("\n\n")
cat("================================================================================\n")
cat("SUCCESS! ALL FUNCTIONS WORKING ✓\n")
cat("================================================================================\n\n")

cat("SUMMARY OF RESULTS:\n")
cat("-------------------\n")
cat("Agriculture Functions:\n")
cat("  Soil Fertility:     ", round(soil_model$performance$accuracy * 100, 1), "% accuracy\n", sep = "")
cat("  Egg Production:     R² = ", round(egg_model$performance$r_squared, 3), "\n", sep = "")
cat("  Fish Growth:        R² = ", round(fish_model$performance$r_squared, 3), "\n", sep = "")
cat("  Disease Class:      ", round(disease_model$performance$accuracy * 100, 1), "% accuracy\n", sep = "")
cat("  Yield Prediction:   R² = ", round(yield_model$performance$r_squared, 3), "\n", sep = "")
cat("\nGeneral Purpose rf_train():\n")
cat("  Iris (classify):    ", round(iris_model$performance$accuracy * 100, 1), "% accuracy\n", sep = "")
cat("  mtcars (predict):   R² = ", round(mtcars_model$performance$r_squared, 3), "\n\n", sep = "")

# Create visualizations
cat("Creating visualizations...\n")
cat("----------------------------------------\n")

# Soil importance
cat("\n1. Plotting soil fertility variable importance...\n")
p1 <- plot_rf_importance(soil_model, top_n = 8)
print(p1)
readline(prompt = "Press [enter] to see next plot...")

# Egg production predictions
cat("\n2. Plotting egg production predictions vs actual...\n")
p2 <- plot_rf_predictions(egg_model)
print(p2)
readline(prompt = "Press [enter] to see next plot...")

# Disease importance
cat("\n3. Plotting disease classification importance...\n")
p3 <- plot_rf_importance(disease_model, top_n = 8)
print(p3)
readline(prompt = "Press [enter] to see next plot...")

# Yield predictions
cat("\n4. Plotting yield predictions vs actual...\n")
p4 <- plot_rf_predictions(yield_model)
print(p4)

cat("\n\n")
cat("================================================================================\n")
cat("TESTING COMPLETE!\n")
cat("================================================================================\n\n")

cat("You can now use these functions:\n\n")

cat("# NEW! General purpose - works with ANY dataset:\n")
cat("my_data <- read.csv('your_data.csv')\n")
cat("result <- rf_train(my_data, target = 'outcome')  # Auto-detects task type!\n")
cat("result <- rf_train(data = iris, target = 'Species')\n")
cat("result <- rf_train(data = mtcars, target = 'mpg', task_type = 'regression')\n\n")

cat("# Agriculture-specific functions:\n")
cat("soil_data <- generate_ag_data('soil', n = 200)\n")
cat("result <- rf_soil_analysis(soil_data, 'fertility', 'classification')\n\n")

cat("poultry_data <- generate_ag_data('poultry', n = 200)\n")
cat("result <- rf_poultry_fish(poultry_data, 'egg_production', 'poultry')\n\n")

cat("disease_data <- generate_ag_data('disease', n = 200)\n")
cat("result <- rf_agronomy(disease_data, 'disease', 'classification')\n\n")

cat("# Visualize:\n")
cat("plot_rf_importance(result)\n")
cat("plot_rf_predictions(result)  # for regression models\n\n")

cat("# Make predictions:\n")
cat("predictions <- predict(result$model, newdata = your_new_data)\n\n")

cat("For full examples, run:\n")
cat("source('examples/random_forest_agriculture_demo.R')\n\n")

cat("Documentation:\n")
cat("- Quick start: RANDOM_FOREST_QUICKSTART.md\n")
cat("- Full guide:  RANDOM_FOREST_AGRICULTURE.md\n\n")

cat("Happy modeling! 🌾🐓🐟\n\n")

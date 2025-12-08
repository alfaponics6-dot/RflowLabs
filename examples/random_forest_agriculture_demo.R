################################################################################
# Rflow - Random Forest for Agriculture Analytics
# Comprehensive Demo Script
################################################################################

# This script demonstrates all Random Forest agriculture functions in Rflow
# Author: Carly Chery
# Date: 2024

# Install required packages (if needed)
# install.packages(c("randomForest", "ggplot2"))

library(Rflow)

# Set a seed for reproducibility
set.seed(123)

################################################################################
# PART 1: SOIL ANALYSIS
################################################################################

cat("\n")
cat("================================================================================\n")
cat("PART 1: SOIL FERTILITY CLASSIFICATION\n")
cat("================================================================================\n\n")

# Generate example soil data
soil_data <- generate_ag_data("soil", n = 200)

cat("Dataset overview:\n")
print(head(soil_data))
cat("\n")

# Train Random Forest for soil fertility classification
soil_result <- rf_soil_analysis(
  data = soil_data,
  target = "fertility",
  task_type = "classification",
  ntree = 500,
  importance = TRUE,
  test_size = 0.2,
  seed = 123
)

# Plot variable importance
cat("\nCreating variable importance plot...\n")
importance_plot <- plot_rf_importance(soil_result, top_n = 8)
print(importance_plot)

# Make predictions on new soil samples
cat("\n--- Predicting Soil Fertility for New Samples ---\n")
new_soil_samples <- data.frame(
  pH = c(5.2, 6.8, 7.5),
  nitrogen = c(18, 45, 62),
  phosphorus = c(12, 28, 48),
  potassium = c(80, 220, 310),
  organic_matter = c(1.8, 4.2, 6.5),
  cec = c(8, 18, 28),
  texture_sand = c(45, 35, 25),
  texture_clay = c(15, 25, 35)
)

predictions <- predict(soil_result$model, newdata = new_soil_samples)
cat("\nPredictions for new soil samples:\n")
print(data.frame(
  Sample = 1:3,
  pH = new_soil_samples$pH,
  Nitrogen = new_soil_samples$nitrogen,
  Predicted_Fertility = predictions
))

################################################################################
# PART 2: NPK PREDICTION (REGRESSION)
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("PART 2: NITROGEN PREDICTION (Regression)\n")
cat("================================================================================\n\n")

# Train Random Forest for nitrogen prediction
nitrogen_result <- rf_soil_analysis(
  data = soil_data,
  target = "nitrogen",
  task_type = "regression",
  ntree = 500,
  importance = TRUE,
  test_size = 0.2
)

# Plot predictions vs actual
cat("\nCreating predictions plot...\n")
pred_plot <- plot_rf_predictions(nitrogen_result)
print(pred_plot)

################################################################################
# PART 3: POULTRY FARMING - EGG PRODUCTION
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("PART 3: EGG PRODUCTION FORECASTING\n")
cat("================================================================================\n\n")

# Generate poultry farm data
poultry_data <- generate_ag_data("poultry", n = 250)

cat("Poultry dataset overview:\n")
print(head(poultry_data))
cat("\n")

# Train model for egg production
egg_result <- rf_poultry_fish(
  data = poultry_data,
  target = "egg_production",
  farm_type = "poultry",
  ntree = 500,
  importance = TRUE
)

# Plot variable importance
cat("\nIdentifying key factors for egg production...\n")
egg_importance <- plot_rf_importance(egg_result, top_n = 6)
print(egg_importance)

# Optimize egg production scenario
cat("\n--- Optimizing Egg Production ---\n")
optimal_conditions <- data.frame(
  hen_age_weeks = 35,          # Peak laying age
  temperature_c = 21,          # Optimal temperature
  humidity_pct = 65,           # Optimal humidity
  feed_protein_pct = 17,       # High protein
  light_hours = 16,            # Extended light
  flock_size = 3000,
  feed_intake_g = 115
)

predicted_production <- predict(egg_result$model, newdata = optimal_conditions)
cat("Predicted egg production under optimal conditions:", round(predicted_production), "eggs\n")

################################################################################
# PART 4: FISH FARMING - GROWTH PREDICTION
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("PART 4: FISH GROWTH PREDICTION\n")
cat("================================================================================\n\n")

# Generate fish farm data
fish_data <- generate_ag_data("fish", n = 180)

cat("Fish farm dataset overview:\n")
print(head(fish_data))
cat("\n")

# Train model for fish growth
fish_result <- rf_poultry_fish(
  data = fish_data,
  target = "weight_gain_g",
  farm_type = "fish",
  ntree = 500,
  importance = TRUE
)

# Visualize results
cat("\nPlotting predictions vs actual growth...\n")
fish_pred_plot <- plot_rf_predictions(fish_result)
print(fish_pred_plot)

# What drives fish growth?
cat("\nKey factors for fish growth:\n")
fish_importance <- plot_rf_importance(fish_result)
print(fish_importance)

# Test different water temperatures
cat("\n--- Testing Impact of Water Temperature ---\n")
temp_scenarios <- data.frame(
  water_temp_c = seq(22, 30, by = 2),
  dissolved_oxygen_mg = 6.5,
  pH = 7.5,
  feed_rate_pct = 3.0,
  stocking_density = 100,
  ammonia_mg = 0.05,
  nitrite_mg = 0.02
)

growth_predictions <- predict(fish_result$model, newdata = temp_scenarios)
cat("\nPredicted growth at different temperatures:\n")
print(data.frame(
  Temperature = temp_scenarios$water_temp_c,
  Predicted_Growth_g = round(growth_predictions, 1)
))

################################################################################
# PART 5: CROP DISEASE CLASSIFICATION
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("PART 5: CROP DISEASE CLASSIFICATION\n")
cat("================================================================================\n\n")

# Generate disease data
disease_data <- generate_ag_data("disease", n = 300)

cat("Disease dataset overview:\n")
print(table(disease_data$disease))
cat("\n")

# Train disease classifier
disease_result <- rf_agronomy(
  data = disease_data,
  target = "disease",
  task_type = "classification",
  ntree = 800,
  importance = TRUE
)

# Environmental factors linked to disease
cat("\nEnvironmental factors associated with disease:\n")
disease_importance <- plot_rf_importance(disease_result, top_n = 6)
print(disease_importance)

# Predict disease risk under different conditions
cat("\n--- Disease Risk Assessment ---\n")
field_conditions <- data.frame(
  leaf_temp_c = c(23, 26, 28),
  humidity_pct = c(60, 85, 95),
  rainfall_mm = c(2, 12, 25),
  leaf_wetness_hours = c(2, 8, 12),
  plant_age_days = c(60, 60, 60),
  nitrogen_ppm = c(50, 50, 50),
  canopy_density = c(0.6, 0.75, 0.85)
)

disease_predictions <- predict(disease_result$model, newdata = field_conditions)
cat("\nDisease predictions for different conditions:\n")
print(data.frame(
  Scenario = c("Low Risk", "Medium Risk", "High Risk"),
  Humidity = field_conditions$humidity_pct,
  Rainfall = field_conditions$rainfall_mm,
  Leaf_Wetness = field_conditions$leaf_wetness_hours,
  Predicted_Disease = disease_predictions
))

################################################################################
# PART 6: YIELD PREDICTION
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("PART 6: CROP YIELD PREDICTION\n")
cat("================================================================================\n\n")

# Generate yield data
yield_data <- generate_ag_data("yield", n = 200)

cat("Yield dataset overview:\n")
print(summary(yield_data$yield_kg_ha))
cat("\n")

# Train yield prediction model
yield_result <- rf_agronomy(
  data = yield_data,
  target = "yield_kg_ha",
  task_type = "regression",
  ntree = 500,
  importance = TRUE
)

# Visualize predictions
cat("\nPlotting yield predictions...\n")
yield_pred_plot <- plot_rf_predictions(yield_result)
print(yield_pred_plot)

# What drives yield?
cat("\nKey drivers of crop yield:\n")
yield_importance <- plot_rf_importance(yield_result)
print(yield_importance)

# Scenario analysis for yield optimization
cat("\n--- Yield Optimization Scenarios ---\n")
scenarios <- data.frame(
  Scenario = c("Low Input", "Standard", "High Input", "Optimal"),
  rainfall_mm = c(600, 800, 1000, 850),
  temperature_avg_c = c(26, 24, 22, 24),
  solar_radiation_mj = c(18, 20, 22, 22),
  fertilizer_kg_ha = c(100, 150, 200, 180),
  soil_moisture_pct = c(20, 25, 30, 28),
  growth_days = c(100, 120, 140, 120),
  planting_density = c(40000, 60000, 80000, 60000)
)

predicted_yields <- predict(yield_result$model, newdata = scenarios[, -1])
scenarios$Predicted_Yield_kg_ha <- round(predicted_yields, 0)

cat("\nYield predictions for different management scenarios:\n")
print(scenarios[, c("Scenario", "fertilizer_kg_ha", "rainfall_mm", "Predicted_Yield_kg_ha")])

# Calculate economic returns (assuming $0.20/kg)
price_per_kg <- 0.20
scenarios$Revenue_USD_ha <- scenarios$Predicted_Yield_kg_ha * price_per_kg
scenarios$Fertilizer_Cost_USD_ha <- scenarios$fertilizer_kg_ha * 1.50  # $1.50/kg fertilizer
scenarios$Net_Return_USD_ha <- scenarios$Revenue_USD_ha - scenarios$Fertilizer_Cost_USD_ha

cat("\nEconomic analysis:\n")
print(scenarios[, c("Scenario", "Revenue_USD_ha", "Fertilizer_Cost_USD_ha", "Net_Return_USD_ha")])

################################################################################
# PART 7: MODEL COMPARISON
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("PART 7: MODEL PERFORMANCE SUMMARY\n")
cat("================================================================================\n\n")

# Compile all results
cat("Classification Models:\n")
cat("----------------------\n")
cat("Soil Fertility Accuracy:", round(soil_result$performance$accuracy * 100, 2), "%\n")
cat("Disease Classification Accuracy:", round(disease_result$performance$accuracy * 100, 2), "%\n\n")

cat("Regression Models:\n")
cat("------------------\n")
cat("Nitrogen Prediction R²:", round(nitrogen_result$performance$r_squared, 3), "\n")
cat("Egg Production R²:", round(egg_result$performance$r_squared, 3), "\n")
cat("Fish Growth R²:", round(fish_result$performance$r_squared, 3), "\n")
cat("Yield Prediction R²:", round(yield_result$performance$r_squared, 3), "\n\n")

################################################################################
# PART 8: SAVING MODELS FOR DEPLOYMENT
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("PART 8: SAVING MODELS FOR PRODUCTION USE\n")
cat("================================================================================\n\n")

# Create directory for models
if (!dir.exists("rf_models")) {
  dir.create("rf_models")
  cat("Created directory: rf_models/\n")
}

# Save all models
saveRDS(soil_result$model, "rf_models/soil_fertility_model.rds")
saveRDS(nitrogen_result$model, "rf_models/nitrogen_prediction_model.rds")
saveRDS(egg_result$model, "rf_models/egg_production_model.rds")
saveRDS(fish_result$model, "rf_models/fish_growth_model.rds")
saveRDS(disease_result$model, "rf_models/disease_classifier_model.rds")
saveRDS(yield_result$model, "rf_models/yield_prediction_model.rds")

cat("\nAll models saved to rf_models/ directory\n\n")

cat("To load a model later:\n")
cat("  model <- readRDS('rf_models/soil_fertility_model.rds')\n")
cat("  prediction <- predict(model, newdata = your_new_data)\n\n")

################################################################################
# DEMO COMPLETE
################################################################################

cat("================================================================================\n")
cat("DEMO COMPLETE!\n")
cat("================================================================================\n\n")

cat("You have successfully:\n")
cat("  ✓ Classified soil fertility\n")
cat("  ✓ Predicted soil nitrogen levels\n")
cat("  ✓ Forecasted egg production\n")
cat("  ✓ Predicted fish growth\n")
cat("  ✓ Classified crop diseases\n")
cat("  ✓ Predicted crop yields\n")
cat("  ✓ Saved all models for deployment\n\n")

cat("Next steps:\n")
cat("  1. Try these functions with your own agriculture data\n")
cat("  2. Experiment with different parameters (ntree, mtry)\n")
cat("  3. Perform cross-validation for robust estimates\n")
cat("  4. Deploy models in production environments\n\n")

cat("For more information:\n")
cat("  - See RANDOM_FOREST_AGRICULTURE.md\n")
cat("  - Visit: https://github.com/carlychery2001/RflowLabs\n")
cat("  - Email: cchery@earth.ac.cr\n\n")

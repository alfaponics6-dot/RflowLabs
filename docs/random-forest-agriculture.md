# Random Forest for Agriculture Analytics

Rflow now includes comprehensive Random Forest functionality specifically designed for agriculture analytics. This feature enables data-driven decision making for soil management, livestock farming, and crop production.

## Features

### 1. Soil Analysis (`rf_soil_analysis`)
Apply Random Forest for soil-related predictions:
- Soil fertility classification (Low/Medium/High)
- NPK (Nitrogen, Phosphorus, Potassium) prediction
- Soil type mapping
- pH prediction
- Organic matter estimation
- Cation Exchange Capacity (CEC) analysis

### 2. Poultry & Fish Farming (`rf_poultry_fish`)
Optimize livestock production with ML predictions:
- Egg production forecasting
- Fish growth prediction
- Feed optimization
- Feed conversion ratio analysis
- Environmental factor impact assessment

### 3. Agronomy Applications (`rf_agronomy`)
Improve crop management with predictive modeling:
- Disease classification (Rust, Blight, Mildew, Mosaic, etc.)
- Yield prediction
- Weather-driven crop modeling
- Growth stage prediction
- Environmental stress detection

### 4. Visualization Tools
- Variable importance plots
- Predictions vs actual scatter plots
- Confusion matrices for classification
- Performance metrics dashboards

## Installation

The Random Forest features are now built into Rflow. You'll need to install the required dependencies:

```r
# Install dependencies
install.packages(c("randomForest", "ggplot2"))

# Or install all suggested packages
install.packages("Rflow", dependencies = TRUE)
```

## Quick Start

### Example 1: Soil Fertility Classification

```r
library(Rflow)

# Generate example soil data
soil_data <- generate_ag_data("soil", n = 200)

# Train Random Forest model
result <- rf_soil_analysis(
  data = soil_data,
  target = "fertility",
  task_type = "classification",
  ntree = 500,
  importance = TRUE
)

# View results
print(result$performance)

# Plot variable importance
plot_rf_importance(result, top_n = 8)

# Make predictions on new soil samples
new_soil <- data.frame(
  pH = 6.8,
  nitrogen = 45,
  phosphorus = 28,
  potassium = 220,
  organic_matter = 4.2,
  cec = 18,
  texture_sand = 35,
  texture_clay = 25
)

prediction <- predict(result$model, newdata = new_soil)
print(paste("Predicted fertility:", prediction))
```

### Example 2: Egg Production Forecasting

```r
# Generate poultry farm data
poultry_data <- generate_ag_data("poultry", n = 250)

# Train model
result <- rf_poultry_fish(
  data = poultry_data,
  target = "egg_production",
  farm_type = "poultry",
  ntree = 500
)

# View performance
cat("RMSE:", result$performance$rmse, "\n")
cat("R-squared:", result$performance$r_squared, "\n")

# Plot predictions vs actual
plot_rf_predictions(result)

# Optimize production: What factors matter most?
plot_rf_importance(result, top_n = 6)
```

### Example 3: Fish Growth Prediction

```r
# Generate fish farm data
fish_data <- generate_ag_data("fish", n = 180)

# Train model
result <- rf_poultry_fish(
  data = fish_data,
  target = "weight_gain_g",
  farm_type = "fish",
  ntree = 500
)

# View results
print(result$performance)

# Identify key factors for fish growth
plot_rf_importance(result)

# Predict growth for different conditions
new_conditions <- data.frame(
  water_temp_c = 27,
  dissolved_oxygen_mg = 6.5,
  pH = 7.8,
  feed_rate_pct = 3.2,
  stocking_density = 100,
  ammonia_mg = 0.05,
  nitrite_mg = 0.02
)

predicted_growth <- predict(result$model, newdata = new_conditions)
print(paste("Predicted weight gain:", round(predicted_growth, 1), "grams"))
```

### Example 4: Crop Disease Classification

```r
# Generate disease data
disease_data <- generate_ag_data("disease", n = 300)

# Train classifier
result <- rf_agronomy(
  data = disease_data,
  target = "disease",
  task_type = "classification",
  ntree = 800
)

# View accuracy
print(result$performance$confusion_matrix)
print(paste("Overall accuracy:", round(result$performance$accuracy * 100, 2), "%"))

# Identify environmental factors linked to disease
plot_rf_importance(result, top_n = 6)

# Predict disease for current field conditions
current_conditions <- data.frame(
  leaf_temp_c = 26,
  humidity_pct = 85,
  rainfall_mm = 12,
  leaf_wetness_hours = 8,
  plant_age_days = 60,
  nitrogen_ppm = 55,
  canopy_density = 0.75
)

prediction <- predict(result$model, newdata = current_conditions)
print(paste("Predicted disease:", prediction))
```

### Example 5: Yield Prediction

```r
# Generate yield data
yield_data <- generate_ag_data("yield", n = 200)

# Train yield prediction model
result <- rf_agronomy(
  data = yield_data,
  target = "yield_kg_ha",
  task_type = "regression",
  ntree = 500
)

# View performance
cat("Model Performance:\n")
cat("RMSE:", round(result$performance$rmse, 2), "kg/ha\n")
cat("R-squared:", round(result$performance$r_squared, 3), "\n")
cat("MAE:", round(result$performance$mae, 2), "kg/ha\n")

# Visualize predictions
plot_rf_predictions(result)

# What drives yield?
plot_rf_importance(result)

# Forecast yield for next season
next_season <- data.frame(
  rainfall_mm = 850,
  temperature_avg_c = 25,
  solar_radiation_mj = 22,
  fertilizer_kg_ha = 180,
  soil_moisture_pct = 28,
  growth_days = 120,
  planting_density = 60000
)

predicted_yield <- predict(result$model, newdata = next_season)
print(paste("Predicted yield:", round(predicted_yield, 0), "kg/ha"))
```

## Using Your Own Data

### Data Requirements

All functions require:
1. A data frame with observations (rows) and variables (columns)
2. A target variable to predict
3. Predictor variables (features)

Example data structure for soil analysis:
```r
my_soil_data <- data.frame(
  fertility = factor(c("Low", "Medium", "High", ...)),  # Target (classification)
  pH = c(5.8, 6.5, 7.2, ...),                           # Predictor
  nitrogen = c(25, 42, 58, ...),                        # Predictor
  phosphorus = c(18, 32, 44, ...),                      # Predictor
  # ... more predictors
)
```

### Loading Your Data

```r
# From CSV
my_data <- read.csv("path/to/your/data.csv")

# From Excel
library(readxl)
my_data <- read_excel("path/to/your/data.xlsx")

# From database
library(DBI)
con <- dbConnect(RSQLite::SQLite(), "path/to/database.db")
my_data <- dbGetQuery(con, "SELECT * FROM agriculture_data")
```

### Training on Your Data

```r
# Example: Your own soil analysis
result <- rf_soil_analysis(
  data = my_data,
  target = "your_target_column",
  predictors = c("feature1", "feature2", "feature3"),  # Optional: specify features
  task_type = "classification",  # or "regression"
  ntree = 500,
  test_size = 0.2  # 80% train, 20% test
)
```

## Advanced Usage

### Hyperparameter Tuning

```r
# Test different number of trees
results <- list()
for (n in c(100, 300, 500, 800, 1000)) {
  results[[as.character(n)]] <- rf_soil_analysis(
    data = soil_data,
    target = "fertility",
    task_type = "classification",
    ntree = n
  )
}

# Compare performance
sapply(results, function(x) x$performance$accuracy)
```

### Cross-Validation

```r
# Manual k-fold cross-validation
k <- 5
folds <- sample(rep(1:k, length.out = nrow(data)))
cv_results <- list()

for (i in 1:k) {
  test_idx <- which(folds == i)
  train_data <- data[-test_idx, ]
  test_data <- data[test_idx, ]

  # Train on this fold
  model <- randomForest::randomForest(
    target ~ .,
    data = train_data,
    ntree = 500
  )

  # Test on this fold
  preds <- predict(model, newdata = test_data)
  cv_results[[i]] <- list(predictions = preds, actual = test_data$target)
}
```

### Feature Engineering

```r
# Create interaction terms
soil_data$NPK_ratio <- soil_data$nitrogen / (soil_data$phosphorus + soil_data$potassium)
soil_data$pH_N_interaction <- soil_data$pH * soil_data$nitrogen

# Use engineered features
result <- rf_soil_analysis(
  data = soil_data,
  target = "fertility",
  predictors = c("pH", "nitrogen", "NPK_ratio", "pH_N_interaction"),
  task_type = "classification"
)
```

## Model Performance Metrics

### Classification Metrics
- **Accuracy**: Overall correct predictions
- **OOB Error**: Out-of-bag error estimate
- **Confusion Matrix**: Detailed class-by-class performance
- **Precision/Recall/F1**: Per-class metrics

### Regression Metrics
- **RMSE**: Root Mean Squared Error (lower is better)
- **MAE**: Mean Absolute Error (lower is better)
- **R-squared**: Proportion of variance explained (higher is better)
- **Variance Explained**: OOB R-squared estimate

## Best Practices

### 1. Data Preparation
- Remove missing values or impute them
- Check for outliers
- Ensure sufficient sample size (n > 100 recommended)
- Balance classes for classification tasks

### 2. Model Training
- Start with default parameters
- Increase `ntree` for more stable results (500-1000)
- Use `importance = TRUE` to understand feature contributions
- Set a seed for reproducibility

### 3. Model Evaluation
- Always use a test set (20-30% of data)
- Check if model is overfitting (training vs test performance)
- Examine variable importance plots
- Validate predictions with domain knowledge

### 4. Deployment
- Save your model: `saveRDS(result$model, "my_rf_model.rds")`
- Load for predictions: `model <- readRDS("my_rf_model.rds")`
- Document your features and their units
- Monitor model performance over time

## Troubleshooting

### "Package 'randomForest' is required"
```r
install.packages("randomForest")
```

### "Target variable not found"
Check column names: `names(your_data)`

### Poor model performance
- Increase sample size
- Add more relevant features
- Check data quality
- Try different `ntree` values
- Consider feature engineering

### Imbalanced classes
```r
# Use stratified sampling
library(caret)
train_idx <- createDataPartition(data$target, p = 0.8, list = FALSE)
```

## Integration with Rflow AI Assistant

You can use these functions interactively through Rflow's chat interface:

```
You: "Load my soil data and classify fertility using Random Forest"
Rflow: [Executes rf_soil_analysis and shows results]

You: "Show me which soil properties are most important"
Rflow: [Creates variable importance plot]

You: "Predict egg production for next week given current conditions"
Rflow: [Uses rf_poultry_fish to make forecast]
```

## Examples by Use Case

### Precision Agriculture
- Soil fertility mapping for variable rate fertilization
- Yield prediction for harvest planning
- Disease early warning systems

### Farm Management
- Egg production optimization
- Fish feeding schedules
- Environmental control automation

### Research Applications
- Climate change impact on crops
- Variety selection recommendations
- Sustainable farming practices evaluation

## References

- Breiman, L. (2001). Random Forests. Machine Learning, 45(1), 5-32.
- Liaw, A., & Wiener, M. (2002). Classification and Regression by randomForest. R News, 2(3), 18-22.

## Support

For questions or issues:
- GitHub Issues: https://github.com/alfaponics6-dot/RflowLabs/issues
- Email: cchery@earth.ac.cr

## Citation

If you use Rflow's Random Forest features in your research, please cite:

```
Chery, C. (2024). Rflow: Professional AI Assistant for RStudio with Agriculture Analytics.
R package version 1.0.0. https://github.com/alfaponics6-dot/RflowLabs
```

---

**Built for agriculture data science**

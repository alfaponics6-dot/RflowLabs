# Random Forest Agriculture - Quick Start Guide

## Installation

1. **Update NAMESPACE** (required for first-time use):
```r
# Install roxygen2 if needed
install.packages("roxygen2")

# Navigate to package directory and regenerate documentation
setwd("path/to/your/RflowLabs")
roxygen2::roxygenize()
```

2. **Install Dependencies**:
```r
install.packages(c("randomForest", "ggplot2"))
```

3. **Load Rflow**:
```r
library(Rflow)
```

## 5-Minute Examples

### Example 0: ANY Dataset (20 seconds) - NEW!
```r
# Works with iris, mtcars, or YOUR data!
data(iris)
result <- rf_train(data = iris, target = "Species")
plot_rf_importance(result)

# Or with your own data
my_data <- read.csv("your_data.csv")
result <- rf_train(my_data, target = "outcome")  # Auto-detects!
```

### Example 1: Soil Fertility (30 seconds)
```r
# Generate data
soil <- generate_ag_data("soil", n = 150)

# Train model
result <- rf_soil_analysis(soil, target = "fertility", task_type = "classification")

# View importance
plot_rf_importance(result)
```

### Example 2: Egg Production (30 seconds)
```r
# Generate data
poultry <- generate_ag_data("poultry", n = 200)

# Train model
result <- rf_poultry_fish(poultry, target = "egg_production", farm_type = "poultry")

# View predictions
plot_rf_predictions(result)
```

### Example 3: Disease Classification (30 seconds)
```r
# Generate data
disease <- generate_ag_data("disease", n = 250)

# Train model
result <- rf_agronomy(disease, target = "disease", task_type = "classification")

# Check accuracy
print(result$performance$accuracy)
```

## Using Your Own Data

```r
# Load your CSV
my_data <- read.csv("path/to/your/data.csv")

# Train on your data
result <- rf_soil_analysis(
  data = my_data,
  target = "your_target_column",
  task_type = "classification"  # or "regression"
)

# Make predictions
new_data <- data.frame(...)  # your new observations
predictions <- predict(result$model, newdata = new_data)
```

## Run Complete Demo

```r
# Run the full demo script
source("examples/random_forest_agriculture_demo.R")
```

## Function Summary

| Function | Purpose | Output |
|----------|---------|--------|
| `rf_train()` | **ANY dataset** - general purpose | Classification or Regression |
| `rf_soil_analysis()` | Soil fertility, NPK prediction | Classification or Regression |
| `rf_poultry_fish()` | Egg production, fish growth | Regression |
| `rf_agronomy()` | Disease, yield prediction | Classification or Regression |
| `generate_ag_data()` | Create example datasets | Data frame |
| `plot_rf_importance()` | Variable importance plot | ggplot2 object |
| `plot_rf_predictions()` | Predictions vs actual plot | ggplot2 object |

## Common Parameters

- `data`: Your data frame
- `target`: Column name to predict
- `task_type`: "classification" or "regression"
- `ntree`: Number of trees (default: 500)
- `importance`: Calculate variable importance (default: TRUE)
- `test_size`: Proportion for testing (default: 0.2)

## Getting Help

```r
# View function documentation
?rf_soil_analysis
?rf_poultry_fish
?rf_agronomy

# View full guide
file.show("docs/random-forest-agriculture.md")

# Run examples
file.show("examples/random_forest_agriculture_demo.R")
```

## Troubleshooting

**Error: "Package 'randomForest' is required"**
```r
install.packages("randomForest")
```

**Error: "could not find function 'rf_soil_analysis'"**
```r
# Regenerate NAMESPACE
roxygen2::roxygenize()
# Reload package
detach("package:Rflow", unload = TRUE)
library(Rflow)
```

**Poor model performance?**
- Increase sample size (n > 100)
- Add more relevant features
- Increase ntree (try 800-1000)
- Check for missing values: `sum(is.na(data))`

## Next Steps

1. **Using ANY data?** Read [random-forest-any-data.md](random-forest-any-data.md)
2. **Agriculture focus?** Read [random-forest-agriculture.md](random-forest-agriculture.md)
3. Run example demos:
   - `source("examples/rf_any_dataset_demo.R")` - General examples
   - `source("examples/random_forest_agriculture_demo.R")` - Agriculture
4. Try with your own data
5. Share feedback: cchery@earth.ac.cr

---

**Happy modeling!**

# Using Random Forest with ANY Dataset

Yes! The Random Forest functions in Rflow can be trained on **ANY dataset**, not just agriculture data. This guide shows you how.

## Quick Answer

```r
# Works with ANY data!
library(Rflow)

# Your data
my_data <- read.csv("your_data.csv")

# Train model - it's that simple!
result <- rf_train(
  data = my_data,
  target = "your_target_column"
  # That's it! Auto-detects classification vs regression
)

# Or be explicit
result <- rf_train(
  data = my_data,
  target = "outcome",
  task_type = "classification",  # or "regression"
  ntree = 500
)
```

## Available Functions

### 1. `rf_train()` - General Purpose (NEW!)
**Use for: ANY dataset**
- Auto-detects classification vs regression
- Works with any tabular data
- Simplest interface

### 2. Agriculture-Specific Functions
These work with **any data** too, just with domain-specific parameter names:
- `rf_soil_analysis()` - Any classification/regression task
- `rf_poultry_fish()` - Any regression task
- `rf_agronomy()` - Any classification/regression task

## Examples with Different Data Types

### Example 1: Built-in R Datasets

#### Iris Classification
```r
data(iris)
head(iris)

# Train model
result <- rf_train(
  data = iris,
  target = "Species"  # Auto-detects: classification
)

# View results
print(result$performance)
plot_rf_importance(result)
```

#### mtcars Regression
```r
data(mtcars)

# Predict miles per gallon
result <- rf_train(
  data = mtcars,
  target = "mpg",
  task_type = "regression"
)

plot_rf_predictions(result)
```

### Example 2: Business Data

#### Sales Forecasting
```r
# Your sales data
sales <- data.frame(
  revenue = c(50000, 75000, 60000, 90000, 85000, 120000),
  marketing_spend = c(5000, 8000, 6000, 10000, 9000, 12000),
  season = factor(c("Q1", "Q2", "Q3", "Q4", "Q1", "Q2")),
  employee_count = c(10, 12, 11, 15, 14, 18),
  region = factor(c("North", "South", "North", "West", "East", "South")),
  online_traffic = c(1000, 1500, 1200, 2000, 1800, 2500)
)

# Train model
result <- rf_train(
  data = sales,
  target = "revenue",
  task_type = "regression",
  ntree = 500
)

# Make predictions for next quarter
new_quarter <- data.frame(
  marketing_spend = 11000,
  season = factor("Q3", levels = levels(sales$season)),
  employee_count = 16,
  region = factor("North", levels = levels(sales$region)),
  online_traffic = 2200
)

predicted_revenue <- predict(result$model, newdata = new_quarter)
cat("Predicted revenue:", round(predicted_revenue), "\n")
```

#### Customer Churn Classification
```r
# Load your customer data
customers <- read.csv("customer_churn.csv")

# Train churn predictor
result <- rf_train(
  data = customers,
  target = "churned",  # Yes/No or 1/0
  task_type = "classification",
  ntree = 800
)

# Which factors drive churn?
plot_rf_importance(result, top_n = 10)
```

### Example 3: Medical/Healthcare Data

```r
# Patient diagnosis data
medical_data <- read.csv("patient_data.csv")
# Columns: age, blood_pressure, cholesterol, glucose, bmi, diagnosis

# Train diagnostic model
result <- rf_train(
  data = medical_data,
  target = "diagnosis",
  predictors = c("age", "blood_pressure", "cholesterol", "glucose", "bmi"),
  task_type = "classification"
)

# Check accuracy
cat("Diagnostic accuracy:", round(result$performance$accuracy * 100, 2), "%\n")

# Confusion matrix
print(result$performance$confusion_matrix)
```

### Example 4: Financial Data

#### Stock Price Prediction
```r
# Historical stock data
stock_data <- read.csv("stock_history.csv")

result <- rf_train(
  data = stock_data,
  target = "close_price",
  predictors = c("open_price", "high", "low", "volume", "market_cap"),
  task_type = "regression",
  ntree = 1000
)
```

#### Credit Risk Classification
```r
# Loan application data
loans <- read.csv("loan_applications.csv")

result <- rf_train(
  data = loans,
  target = "default",  # Yes/No
  task_type = "classification"
)

# Feature importance for risk assessment
plot_rf_importance(result)
```

### Example 5: Education Data

```r
# Student performance data
students <- read.csv("student_grades.csv")

# Predict final grade
result <- rf_train(
  data = students,
  target = "final_grade",
  predictors = c("attendance", "homework_avg", "midterm_score",
                 "participation", "study_hours"),
  task_type = "regression"
)

plot_rf_predictions(result)
```

### Example 6: E-commerce

```r
# Product recommendation
products <- read.csv("product_sales.csv")

result <- rf_train(
  data = products,
  target = "category",  # Electronics, Clothing, Books, etc.
  task_type = "classification"
)
```

### Example 7: Real Estate

```r
# House price prediction
houses <- read.csv("housing_data.csv")

result <- rf_train(
  data = houses,
  target = "price",
  predictors = c("bedrooms", "bathrooms", "sqft", "location", "year_built"),
  task_type = "regression",
  ntree = 800
)
```

## Using Agriculture Functions with Non-Agriculture Data

The agriculture functions work with **any data** - they're just named for agriculture use cases:

```r
# rf_soil_analysis works for ANY classification/regression!

# Example: Classify customer satisfaction (Low/Medium/High)
customer_data <- data.frame(
  satisfaction = factor(c("Low", "Medium", "High", ...)),
  response_time = c(...),
  resolution_rate = c(...),
  support_quality = c(...)
)

result <- rf_soil_analysis(
  data = customer_data,
  target = "satisfaction",
  task_type = "classification"
)
```

## Data Requirements

Your data must be:

### For Any Function
1. **A data frame** - rows = observations, columns = variables
2. **Target variable** - What you want to predict (must be a column name)
3. **Predictor variables** - Features used for prediction

### Data Structure Example
```r
# Good structure
my_data <- data.frame(
  target_column = c(...),      # What to predict
  feature_1 = c(...),          # Predictor
  feature_2 = c(...),          # Predictor
  feature_3 = c(...)           # Predictor
)

# Classification: target should be factor or character
# Regression: target should be numeric
```

### Handling Missing Data
```r
# Check for missing values
sum(is.na(my_data))

# Remove rows with missing values
my_data_clean <- na.omit(my_data)

# Or impute missing values
my_data$feature[is.na(my_data$feature)] <- median(my_data$feature, na.rm = TRUE)
```

## Loading Data from Different Sources

### CSV Files
```r
data <- read.csv("data.csv")
data <- read.csv("data.csv", stringsAsFactors = TRUE)  # For classification
```

### Excel Files
```r
library(readxl)
data <- read_excel("data.xlsx")
data <- read_excel("data.xlsx", sheet = "Sheet1")
```

### Databases
```r
library(DBI)
con <- dbConnect(RSQLite::SQLite(), "database.db")
data <- dbGetQuery(con, "SELECT * FROM my_table")
dbDisconnect(con)
```

### Web URLs
```r
url <- "https://example.com/data.csv"
data <- read.csv(url)
```

### Other Formats
```r
# TSV
data <- read.delim("data.tsv")

# JSON
library(jsonlite)
data <- fromJSON("data.json")

# RData
load("data.RData")
```

## Complete Workflow Example

```r
library(Rflow)

# 1. Load your data
my_data <- read.csv("your_data.csv")

# 2. Explore it
head(my_data)
str(my_data)
summary(my_data)

# 3. Check for missing values
sum(is.na(my_data))

# 4. Clean if needed
my_data <- na.omit(my_data)

# 5. Train Random Forest
result <- rf_train(
  data = my_data,
  target = "outcome_variable",
  task_type = "classification",  # or "regression"
  ntree = 500,
  test_size = 0.2,
  seed = 123
)

# 6. Evaluate performance
print(result$performance)

# 7. Visualize
plot_rf_importance(result, top_n = 10)
if (result$task_type == "regression") {
  plot_rf_predictions(result)
}

# 8. Make predictions on new data
new_data <- read.csv("new_data.csv")
predictions <- predict(result$model, newdata = new_data)

# 9. Save model for later
saveRDS(result$model, "my_trained_model.rds")

# 10. Load and use later
model <- readRDS("my_trained_model.rds")
predictions <- predict(model, newdata = future_data)
```

## Advanced: Custom Predictor Selection

```r
# Only use specific predictors
result <- rf_train(
  data = my_data,
  target = "outcome",
  predictors = c("var1", "var2", "var3"),  # Specify which to use
  task_type = "classification"
)

# Programmatically select predictors
numeric_vars <- names(my_data)[sapply(my_data, is.numeric)]
result <- rf_train(
  data = my_data,
  target = "outcome",
  predictors = setdiff(numeric_vars, "outcome")
)
```

## Hyperparameter Tuning

```r
# Test different configurations
results <- list()

for (n_trees in c(100, 300, 500, 1000)) {
  for (m_try in c(2, 3, 5)) {
    key <- paste0("trees_", n_trees, "_mtry_", m_try)
    results[[key]] <- rf_train(
      data = my_data,
      target = "outcome",
      ntree = n_trees,
      mtry = m_try,
      verbose = FALSE
    )
  }
}

# Compare results
performance <- sapply(results, function(x) {
  if (x$task_type == "classification") {
    x$performance$accuracy
  } else {
    x$performance$r_squared
  }
})

best_model <- names(which.max(performance))
cat("Best configuration:", best_model, "\n")
```

## Cross-Validation

```r
# K-fold cross-validation
library(caret)

# Create folds
set.seed(123)
folds <- createFolds(my_data$target, k = 5)

cv_results <- lapply(folds, function(test_idx) {
  train_data <- my_data[-test_idx, ]
  test_data <- my_data[test_idx, ]

  model <- randomForest::randomForest(
    target ~ .,
    data = train_data,
    ntree = 500
  )

  predictions <- predict(model, newdata = test_data)
  actual <- test_data$target

  # Return accuracy or RMSE
  if (is.factor(actual)) {
    mean(predictions == actual)  # Accuracy
  } else {
    sqrt(mean((predictions - actual)^2))  # RMSE
  }
})

cat("Cross-validation results:\n")
print(unlist(cv_results))
cat("Mean:", mean(unlist(cv_results)), "\n")
```

## Real-World Use Cases

| Domain | Task | Target Variable | Predictors |
|--------|------|-----------------|------------|
| Business | Sales forecast | revenue | marketing, season, region |
| Healthcare | Disease diagnosis | diagnosis | symptoms, vitals, tests |
| Finance | Loan default | default_flag | income, credit_score, debt |
| E-commerce | Purchase prediction | will_buy | browsing_time, cart_value |
| Education | Grade prediction | final_grade | attendance, assignments |
| Manufacturing | Quality control | defect | temperature, pressure, speed |
| Real Estate | Price prediction | price | location, size, amenities |
| HR | Employee attrition | will_leave | salary, satisfaction, tenure |

## FAQs

**Q: Can I use categorical predictors?**
A: Yes! Random Forest handles categorical variables automatically.

**Q: What if I have text data?**
A: Convert to factors or numeric features first. Example:
```r
data$category <- as.factor(data$text_column)
```

**Q: How many samples do I need?**
A: Minimum 50-100, but 200+ recommended for reliable results.

**Q: What about imbalanced classes?**
A: Use `sampsize` parameter in randomForest for stratified sampling.

**Q: Can I use date/time variables?**
A: Convert to numeric features first:
```r
data$year <- as.numeric(format(data$date, "%Y"))
data$month <- as.numeric(format(data$date, "%m"))
```

## Summary

**YES! Random Forest in Rflow works with ANY dataset:**

✅ Business data (sales, customers, products)
✅ Medical data (diagnosis, treatment outcomes)
✅ Financial data (stock prices, credit risk)
✅ Education data (student performance)
✅ E-commerce data (purchases, recommendations)
✅ Manufacturing data (quality control)
✅ Any CSV, Excel, database, or R data frame
✅ Built-in R datasets (iris, mtcars, etc.)

**Just follow 3 steps:**
1. Load your data into a data frame
2. Call `rf_train(data, target)`
3. Evaluate and use your model!

---

For agriculture-specific features, see [random-forest-agriculture.md](random-forest-agriculture.md)

For quick start, see [random-forest-quickstart.md](random-forest-quickstart.md)

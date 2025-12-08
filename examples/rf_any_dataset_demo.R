################################################################################
# Random Forest - Works with ANY Dataset!
# Demonstration using Built-in R Datasets
################################################################################

cat("\n")
cat("================================================================================\n")
cat("RANDOM FOREST WORKS WITH ANY DATASET - DEMO\n")
cat("================================================================================\n\n")

# Load Rflow (assumes you've run devtools::load_all())
# library(Rflow)

cat("This demo shows Random Forest working with:\n")
cat("  1. Iris (classification)\n")
cat("  2. mtcars (regression)\n")
cat("  3. Titanic survival (classification)\n")
cat("  4. ChickWeight (regression)\n")
cat("  5. Your custom data!\n\n")

################################################################################
# EXAMPLE 1: IRIS CLASSIFICATION
################################################################################

cat("================================================================================\n")
cat("EXAMPLE 1: IRIS FLOWER CLASSIFICATION\n")
cat("================================================================================\n\n")

data(iris)
cat("Dataset: iris (classic machine learning dataset)\n")
cat("Task: Classify flower species based on petal/sepal measurements\n\n")

cat("Data preview:\n")
print(head(iris, 3))
cat("\n")

# Train model
iris_result <- rf_train(
  data = iris,
  target = "Species",
  task_type = "classification",
  ntree = 300,
  seed = 123
)

cat("\nVisualize feature importance...\n")
iris_importance <- plot_rf_importance(iris_result, top_n = 4)
print(iris_importance)

# Make prediction on new flower
cat("\n--- Predicting Species for New Flower ---\n")
new_flower <- data.frame(
  Sepal.Length = 6.5,
  Sepal.Width = 3.0,
  Petal.Length = 5.5,
  Petal.Width = 1.8
)

prediction <- predict(iris_result$model, newdata = new_flower)
cat("Predicted species:", as.character(prediction), "\n\n")

readline(prompt = "Press [enter] to continue to next example...")

################################################################################
# EXAMPLE 2: MTCARS MPG PREDICTION
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("EXAMPLE 2: CAR FUEL EFFICIENCY PREDICTION\n")
cat("================================================================================\n\n")

data(mtcars)
cat("Dataset: mtcars (Motor Trend car data)\n")
cat("Task: Predict miles per gallon (MPG) from car characteristics\n\n")

cat("Data preview:\n")
print(head(mtcars, 3))
cat("\n")

# Train model
mtcars_result <- rf_train(
  data = mtcars,
  target = "mpg",
  task_type = "regression",
  ntree = 300,
  seed = 123
)

cat("\nVisualize predictions vs actual...\n")
mtcars_plot <- plot_rf_predictions(mtcars_result)
print(mtcars_plot)

# Predict MPG for a custom car
cat("\n--- Predicting MPG for Custom Car ---\n")
custom_car <- data.frame(
  cyl = 6,
  disp = 200,
  hp = 150,
  drat = 3.5,
  wt = 3.2,
  qsec = 17,
  vs = 1,
  am = 1,
  gear = 4,
  carb = 2
)

predicted_mpg <- predict(mtcars_result$model, newdata = custom_car)
cat("Predicted MPG:", round(predicted_mpg, 2), "\n\n")

readline(prompt = "Press [enter] to continue to next example...")

################################################################################
# EXAMPLE 3: TITANIC SURVIVAL PREDICTION
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("EXAMPLE 3: TITANIC SURVIVAL CLASSIFICATION\n")
cat("================================================================================\n\n")

# Create Titanic dataset
titanic <- as.data.frame(Titanic)
# Expand frequency table to individual records
titanic_expanded <- titanic[rep(row.names(titanic), titanic$Freq), 1:4]
rownames(titanic_expanded) <- NULL

cat("Dataset: Titanic passenger data\n")
cat("Task: Predict survival based on class, sex, and age\n\n")

cat("Data preview:\n")
print(head(titanic_expanded, 5))
cat("\nTotal passengers:", nrow(titanic_expanded), "\n\n")

# Train model
titanic_result <- rf_train(
  data = titanic_expanded,
  target = "Survived",
  task_type = "classification",
  ntree = 500,
  seed = 123
)

cat("\nWhich factors most affected survival?\n")
titanic_importance <- plot_rf_importance(titanic_result)
print(titanic_importance)

# Predict survival for different passengers
cat("\n--- Survival Predictions for Different Passengers ---\n")
passengers <- data.frame(
  Class = factor(c("1st", "3rd", "2nd"), levels = levels(titanic_expanded$Class)),
  Sex = factor(c("Female", "Male", "Child"), levels = levels(titanic_expanded$Sex)),
  Age = factor(c("Adult", "Adult", "Child"), levels = levels(titanic_expanded$Age))
)

survival_pred <- predict(titanic_result$model, newdata = passengers)
result_df <- cbind(passengers, Predicted_Survival = survival_pred)
print(result_df)

cat("\n")
readline(prompt = "Press [enter] to continue to next example...")

################################################################################
# EXAMPLE 4: CHICKWEIGHT GROWTH PREDICTION
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("EXAMPLE 4: CHICK WEIGHT GROWTH PREDICTION\n")
cat("================================================================================\n\n")

data(ChickWeight)
cat("Dataset: ChickWeight (chick growth experiment)\n")
cat("Task: Predict chick weight from time and diet\n\n")

cat("Data preview:\n")
print(head(ChickWeight, 5))
cat("\n")

# Train model
chick_result <- rf_train(
  data = ChickWeight,
  target = "weight",
  predictors = c("Time", "Diet"),
  task_type = "regression",
  ntree = 300,
  seed = 123
)

cat("\nVisualize predictions...\n")
chick_plot <- plot_rf_predictions(chick_result)
print(chick_plot)

# Predict weight at different times
cat("\n--- Weight Predictions for Different Diets at Day 15 ---\n")
day_15 <- data.frame(
  Time = rep(15, 4),
  Diet = factor(1:4, levels = levels(ChickWeight$Diet))
)

predicted_weights <- predict(chick_result$model, newdata = day_15)
print(data.frame(
  Diet = 1:4,
  Predicted_Weight = round(predicted_weights, 1)
))

cat("\n")
readline(prompt = "Press [enter] for summary...")

################################################################################
# SUMMARY
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("SUMMARY - RANDOM FOREST WORKS WITH ANY DATA!\n")
cat("================================================================================\n\n")

cat("We successfully trained Random Forest on:\n\n")

cat("1. IRIS (Classification)\n")
cat("   - 3 species, 4 features\n")
cat("   - Accuracy:", round(iris_result$performance$accuracy * 100, 1), "%\n\n")

cat("2. MTCARS (Regression)\n")
cat("   - Predict MPG from 10 car features\n")
cat("   - R-squared:", round(mtcars_result$performance$r_squared, 3), "\n\n")

cat("3. TITANIC (Classification)\n")
cat("   - Survival prediction, 3 features\n")
cat("   - Accuracy:", round(titanic_result$performance$accuracy * 100, 1), "%\n\n")

cat("4. CHICKWEIGHT (Regression)\n")
cat("   - Growth prediction, 2 features\n")
cat("   - R-squared:", round(chick_result$performance$r_squared, 3), "\n\n")

cat("================================================================================\n")
cat("YOUR TURN!\n")
cat("================================================================================\n\n")

cat("Use Random Forest with YOUR data:\n\n")

cat("# Load your data\n")
cat("my_data <- read.csv('your_data.csv')\n\n")

cat("# Train model (auto-detects classification vs regression)\n")
cat("result <- rf_train(\n")
cat("  data = my_data,\n")
cat("  target = 'your_target_column'\n")
cat(")\n\n")

cat("# Or be specific\n")
cat("result <- rf_train(\n")
cat("  data = my_data,\n")
cat("  target = 'outcome',\n")
cat("  task_type = 'classification',  # or 'regression'\n")
cat("  ntree = 500\n")
cat(")\n\n")

cat("# Visualize\n")
cat("plot_rf_importance(result)\n")
cat("plot_rf_predictions(result)  # for regression\n\n")

cat("# Make predictions\n")
cat("predictions <- predict(result$model, newdata = new_data)\n\n")

cat("Data types that work:\n")
cat("  ✓ CSV files (read.csv)\n")
cat("  ✓ Excel files (readxl::read_excel)\n")
cat("  ✓ Databases (DBI)\n")
cat("  ✓ Built-in datasets (data())\n")
cat("  ✓ Any data frame!\n\n")

cat("Applications:\n")
cat("  ✓ Business: sales, customers, products\n")
cat("  ✓ Healthcare: diagnosis, treatment\n")
cat("  ✓ Finance: stocks, credit risk\n")
cat("  ✓ Education: grades, performance\n")
cat("  ✓ E-commerce: purchases, churn\n")
cat("  ✓ Manufacturing: quality control\n")
cat("  ✓ Agriculture: crops, livestock, soil\n")
cat("  ✓ ANY tabular data!\n\n")

cat("See RANDOM_FOREST_ANY_DATA.md for complete guide!\n\n")

cat("================================================================================\n")
cat("DEMO COMPLETE!\n")
cat("================================================================================\n\n")

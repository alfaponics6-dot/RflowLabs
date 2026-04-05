#' Random Forest for Agriculture Analytics and General Use
#'
#' @description
#' A comprehensive suite of Random Forest functions designed specifically for
#' agriculture analytics. Includes specialized tools for soil analysis,
#' poultry/fish farming, and agronomy applications. Also includes a general-purpose
#' Random Forest trainer that works with ANY dataset.
#'
#' @name random-forest-agriculture
NULL

#' General Purpose Random Forest Model
#'
#' @description
#' Train a Random Forest model on ANY dataset for classification or regression.
#' This is a flexible, easy-to-use wrapper around randomForest that works with
#' any tabular data - not just agriculture data.
#'
#' @param data A data frame containing your data
#' @param target Character string specifying the target variable (column name)
#' @param predictors Character vector of predictor variable names. If NULL,
#'   all variables except target are used.
#' @param task_type Character: "classification" or "regression". If NULL, will
#'   auto-detect based on target variable type (factor = classification).
#' @param ntree Number of trees to grow (default: 500)
#' @param mtry Number of variables randomly sampled at each split. If NULL,
#'   uses sqrt(p) for classification or p/3 for regression.
#' @param importance Should variable importance be assessed? (default: TRUE)
#' @param test_size Proportion of data for testing (default: 0.2)
#' @param seed Random seed for reproducibility (default: 123)
#' @param verbose Show progress messages? (default: TRUE)
#'
#' @return A list containing:
#'   \item{model}{The trained Random Forest model}
#'   \item{predictions}{Predictions on test set}
#'   \item{actual}{Actual values from test set}
#'   \item{performance}{Model performance metrics}
#'   \item{importance}{Variable importance scores}
#'   \item{test_data}{Test dataset used for evaluation}
#'   \item{task_type}{Classification or regression}
#'   \item{target}{Target variable name}
#'   \item{predictors}{Predictor variable names}
#'
#' @examples
#' \dontrun{
#' # Example 1: Iris classification
#' data(iris)
#' result <- rf_train(
#'   data = iris,
#'   target = "Species",
#'   task_type = "classification"
#' )
#' plot_rf_importance(result)
#'
#' # Example 2: mtcars regression
#' data(mtcars)
#' result <- rf_train(
#'   data = mtcars,
#'   target = "mpg",
#'   task_type = "regression"
#' )
#' plot_rf_predictions(result)
#'
#' # Example 3: Custom business data
#' sales_data <- read.csv("sales_data.csv")
#' result <- rf_train(
#'   data = sales_data,
#'   target = "revenue",
#'   predictors = c("marketing_spend", "season", "region", "product_type"),
#'   task_type = "regression",
#'   ntree = 1000
#' )
#'
#' # Example 4: Medical diagnosis
#' medical_data <- read.csv("patient_data.csv")
#' result <- rf_train(
#'   data = medical_data,
#'   target = "diagnosis",
#'   task_type = "classification"
#' )
#' print(result$performance)
#'
#' # Example 5: Auto-detect task type
#' result <- rf_train(data = your_data, target = "outcome")  # Auto-detects!
#' }
#'
#' @export
rf_train <- function(data,
                     target,
                     predictors = NULL,
                     task_type = NULL,
                     ntree = 500,
                     mtry = NULL,
                     importance = TRUE,
                     test_size = 0.2,
                     seed = 123,
                     verbose = TRUE) {

  # Check randomForest package
  if (!requireNamespace("randomForest", quietly = TRUE)) {
    stop("Package 'randomForest' is required. Install it with: install.packages('randomForest')")
  }

  # Validate target exists
  if (!(target %in% names(data))) {
    stop("Target variable '", target, "' not found in data. Available columns: ",
         paste(names(data), collapse = ", "))
  }

  # Auto-detect task type if not specified
  if (is.null(task_type)) {
    if (is.factor(data[[target]]) || is.character(data[[target]])) {
      task_type <- "classification"
      if (verbose) cat("Auto-detected task type: classification\n")
    } else {
      task_type <- "regression"
      if (verbose) cat("Auto-detected task type: regression\n")
    }
  } else {
    task_type <- match.arg(task_type, c("classification", "regression"))
  }

  # Convert character target to factor for classification
  if (task_type == "classification" && is.character(data[[target]])) {
    data[[target]] <- as.factor(data[[target]])
  }

  # Set seed
  withr::local_seed(seed)

  # Select predictors
  if (is.null(predictors)) {
    predictors <- setdiff(names(data), target)
    # For regression, use only numeric predictors by default
    if (task_type == "regression") {
      numeric_cols <- sapply(data[predictors], is.numeric)
      predictors <- predictors[numeric_cols]
      if (length(predictors) == 0) {
        stop("No numeric predictors found for regression. Please specify predictors manually.")
      }
    }
  }

  if (verbose) {
    cat("\n=== Training Random Forest Model ===\n")
    cat("Task:       ", task_type, "\n")
    cat("Target:     ", target, "\n")
    cat("Predictors: ", length(predictors), "\n")
    if (length(predictors) <= 10) {
      cat("            ", paste(predictors, collapse = ", "), "\n")
    }
  }

  # Create formula
  formula_obj <- as.formula(paste(target, "~", paste(predictors, collapse = " + ")))

  # Split data
  n <- nrow(data)
  train_idx <- sample(1:n, size = floor((1 - test_size) * n))
  train_data <- data[train_idx, ]
  test_data <- data[-train_idx, ]

  if (verbose) {
    cat("Training:   ", nrow(train_data), " samples\n")
    cat("Testing:    ", nrow(test_data), " samples\n")
  }

  # Set mtry default
  if (is.null(mtry)) {
    mtry <- if (task_type == "classification") {
      floor(sqrt(length(predictors)))
    } else {
      max(floor(length(predictors) / 3), 1)
    }
  }

  if (verbose) {
    cat("Trees:      ", ntree, "\n")
    cat("mtry:       ", mtry, "\n\n")
  }

  # Train model
  rf_model <- randomForest::randomForest(
    formula = formula_obj,
    data = train_data,
    ntree = ntree,
    mtry = mtry,
    importance = importance
  )

  # Make predictions
  predictions <- predict(rf_model, newdata = test_data)
  actual <- test_data[[target]]

  # Calculate performance
  if (task_type == "classification") {
    conf_matrix <- table(Predicted = predictions, Actual = actual)
    accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)

    performance <- list(
      accuracy = accuracy,
      confusion_matrix = conf_matrix,
      oob_error = tail(rf_model$err.rate[, "OOB"], 1)
    )

    if (verbose) {
      cat("=== Classification Results ===\n")
      cat("Accuracy:  ", round(accuracy * 100, 2), "%\n", sep = "")
      cat("OOB Error: ", round(performance$oob_error * 100, 2), "%\n\n", sep = "")
      cat("Confusion Matrix:\n")
      print(conf_matrix)
      cat("\n")
    }

  } else {
    mse <- mean((predictions - actual)^2)
    rmse <- sqrt(mse)
    mae <- mean(abs(predictions - actual))
    r_squared <- 1 - (sum((actual - predictions)^2) / sum((actual - mean(actual))^2))

    performance <- list(
      mse = mse,
      rmse = rmse,
      mae = mae,
      r_squared = r_squared,
      variance_explained = rf_model$rsq[length(rf_model$rsq)]
    )

    if (verbose) {
      cat("=== Regression Results ===\n")
      cat("RMSE:              ", round(rmse, 4), "\n", sep = "")
      cat("MAE:               ", round(mae, 4), "\n", sep = "")
      cat("R-squared:         ", round(r_squared, 4), "\n", sep = "")
      cat("Variance Explained:", round(performance$variance_explained, 4), "\n\n", sep = "")
    }
  }

  # Variable importance
  importance_scores <- NULL
  if (importance) {
    importance_scores <- randomForest::importance(rf_model)
    if (verbose) {
      cat("Top 5 Most Important Variables:\n")
      if (task_type == "classification") {
        top_vars <- head(importance_scores[order(-importance_scores[, "MeanDecreaseGini"]), ], 5)
      } else {
        top_vars <- head(importance_scores[order(-importance_scores[, "%IncMSE"]), ], 5)
      }
      print(top_vars)
      cat("\n")
    }
  }

  # Return results
  result <- list(
    model = rf_model,
    predictions = predictions,
    actual = actual,
    performance = performance,
    importance = importance_scores,
    test_data = test_data,
    task_type = task_type,
    target = target,
    predictors = predictors
  )

  class(result) <- c("rf_model", "rf_general")
  return(result)
}

#' Random Forest for Soil Analysis
#'
#' @description
#' Apply Random Forest for soil-related predictions including fertility
#' classification, NPK prediction, soil type mapping, pH prediction, and
#' organic matter estimation.
#'
#' @param data A data frame containing soil analysis data
#' @param target Character string specifying the target variable
#' @param predictors Character vector of predictor variable names. If NULL,
#'   all numeric variables except target are used.
#' @param task_type Character: "classification" or "regression"
#' @param ntree Number of trees to grow (default: 500)
#' @param mtry Number of variables randomly sampled at each split (default: sqrt(p) for classification, p/3 for regression)
#' @param importance Should variable importance be assessed? (default: TRUE)
#' @param test_size Proportion of data for testing (default: 0.2)
#' @param seed Random seed for reproducibility (default: 123)
#'
#' @return A list containing:
#'   \item{model}{The trained Random Forest model}
#'   \item{predictions}{Predictions on test set}
#'   \item{performance}{Model performance metrics}
#'   \item{importance}{Variable importance scores}
#'   \item{confusion_matrix}{Confusion matrix (for classification)}
#'   \item{plot_data}{Data for visualization}
#'
#' @examples
#' \dontrun{
#' # Soil fertility classification
#' soil_data <- data.frame(
#'   fertility = factor(rep(c("Low", "Medium", "High"), each = 50)),
#'   pH = rnorm(150, mean = c(5.5, 6.5, 7.5), sd = 0.5),
#'   nitrogen = rnorm(150, mean = c(20, 40, 60), sd = 5),
#'   phosphorus = rnorm(150, mean = c(15, 30, 45), sd = 5),
#'   potassium = rnorm(150, mean = c(100, 200, 300), sd = 30),
#'   organic_matter = rnorm(150, mean = c(2, 4, 6), sd = 0.5)
#' )
#'
#' result <- rf_soil_analysis(
#'   data = soil_data,
#'   target = "fertility",
#'   task_type = "classification"
#' )
#'
#' # NPK prediction (regression)
#' result_npk <- rf_soil_analysis(
#'   data = soil_data,
#'   target = "nitrogen",
#'   task_type = "regression"
#' )
#' }
#'
#' @export
rf_soil_analysis <- function(data,
                              target,
                              predictors = NULL,
                              task_type = c("classification", "regression"),
                              ntree = 500,
                              mtry = NULL,
                              importance = TRUE,
                              test_size = 0.2,
                              seed = 123) {

  # Validate inputs
  task_type <- match.arg(task_type)
  if (!requireNamespace("randomForest", quietly = TRUE)) {
    stop("Package 'randomForest' is required. Install it with: install.packages('randomForest')")
  }

  if (!(target %in% names(data))) {
    stop("Target variable '", target, "' not found in data")
  }

  # Set seed
  withr::local_seed(seed)

  # Select predictors
  if (is.null(predictors)) {
    predictors <- setdiff(names(data), target)
    # Remove non-numeric for regression
    if (task_type == "regression") {
      predictors <- names(data)[sapply(data[predictors], is.numeric)]
      predictors <- setdiff(predictors, target)
    }
  }

  # Create formula
  formula_obj <- as.formula(paste(target, "~", paste(predictors, collapse = " + ")))

  # Split data
  n <- nrow(data)
  train_idx <- sample(1:n, size = floor((1 - test_size) * n))
  train_data <- data[train_idx, ]
  test_data <- data[-train_idx, ]

  # Set mtry default
  if (is.null(mtry)) {
    mtry <- if (task_type == "classification") {
      floor(sqrt(length(predictors)))
    } else {
      max(floor(length(predictors) / 3), 1)
    }
  }

  # Train model
  cat("\n=== Training Random Forest for Soil Analysis ===\n")
  cat("Task:", task_type, "\n")
  cat("Target:", target, "\n")
  cat("Features:", length(predictors), "\n")
  cat("Training samples:", nrow(train_data), "\n")
  cat("Test samples:", nrow(test_data), "\n")
  cat("Trees:", ntree, "\n")
  cat("mtry:", mtry, "\n\n")

  rf_model <- randomForest::randomForest(
    formula = formula_obj,
    data = train_data,
    ntree = ntree,
    mtry = mtry,
    importance = importance
  )

  # Make predictions
  predictions <- predict(rf_model, newdata = test_data)

  # Calculate performance
  if (task_type == "classification") {
    actual <- test_data[[target]]
    conf_matrix <- table(Predicted = predictions, Actual = actual)
    accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)

    performance <- list(
      accuracy = accuracy,
      confusion_matrix = conf_matrix,
      oob_error = tail(rf_model$err.rate[, "OOB"], 1)
    )

    cat("Classification Results:\n")
    cat("Accuracy:", round(accuracy * 100, 2), "%\n")
    cat("OOB Error:", round(performance$oob_error * 100, 2), "%\n\n")
    print(conf_matrix)

  } else {
    actual <- test_data[[target]]
    mse <- mean((predictions - actual)^2)
    rmse <- sqrt(mse)
    mae <- mean(abs(predictions - actual))
    r_squared <- 1 - (sum((actual - predictions)^2) / sum((actual - mean(actual))^2))

    performance <- list(
      mse = mse,
      rmse = rmse,
      mae = mae,
      r_squared = r_squared,
      variance_explained = rf_model$rsq[length(rf_model$rsq)]
    )

    cat("Regression Results:\n")
    cat("RMSE:", round(rmse, 3), "\n")
    cat("MAE:", round(mae, 3), "\n")
    cat("R-squared:", round(r_squared, 3), "\n")
    cat("Variance Explained:", round(performance$variance_explained, 3), "\n\n")
  }

  # Variable importance
  importance_scores <- NULL
  if (importance) {
    importance_scores <- randomForest::importance(rf_model)
    cat("Top 5 Most Important Variables:\n")
    if (task_type == "classification") {
      top_vars <- head(importance_scores[order(-importance_scores[, "MeanDecreaseGini"]), ], 5)
    } else {
      top_vars <- head(importance_scores[order(-importance_scores[, "%IncMSE"]), ], 5)
    }
    print(top_vars)
  }

  # Return results
  result <- list(
    model = rf_model,
    predictions = predictions,
    actual = test_data[[target]],
    performance = performance,
    importance = importance_scores,
    test_data = test_data,
    task_type = task_type,
    target = target,
    predictors = predictors
  )

  class(result) <- c("rf_soil_analysis", "rf_agriculture")
  return(result)
}


#' Random Forest for Poultry and Fish Farming
#'
#' @description
#' Apply Random Forest for livestock predictions including egg production
#' forecasting, fish growth prediction, and feed optimization.
#'
#' @param data A data frame containing farm data
#' @param target Character string specifying the target variable
#' @param predictors Character vector of predictor variable names. If NULL,
#'   all numeric variables except target are used.
#' @param farm_type Character: "poultry" or "fish" (affects default parameters)
#' @param ntree Number of trees to grow (default: 500)
#' @param importance Should variable importance be assessed? (default: TRUE)
#' @param test_size Proportion of data for testing (default: 0.2)
#' @param seed Random seed for reproducibility (default: 123)
#'
#' @return A list containing model results and predictions
#'
#' @examples
#' \dontrun{
#' # Egg production forecasting
#' poultry_data <- data.frame(
#'   egg_production = rpois(200, lambda = 250),
#'   hen_age_weeks = sample(20:80, 200, replace = TRUE),
#'   temperature = rnorm(200, mean = 22, sd = 3),
#'   humidity = rnorm(200, mean = 60, sd = 10),
#'   feed_protein_pct = rnorm(200, mean = 16, sd = 1),
#'   light_hours = rnorm(200, mean = 14, sd = 1),
#'   flock_size = sample(1000:5000, 200, replace = TRUE)
#' )
#'
#' result <- rf_poultry_fish(
#'   data = poultry_data,
#'   target = "egg_production",
#'   farm_type = "poultry"
#' )
#'
#' # Fish growth prediction
#' fish_data <- data.frame(
#'   weight_gain_g = rnorm(150, mean = 50, sd = 10),
#'   water_temp = rnorm(150, mean = 26, sd = 2),
#'   dissolved_oxygen = rnorm(150, mean = 6, sd = 1),
#'   pH = rnorm(150, mean = 7.5, sd = 0.5),
#'   feed_rate_pct = rnorm(150, mean = 3, sd = 0.5),
#'   stocking_density = sample(50:150, 150, replace = TRUE)
#' )
#'
#' result_fish <- rf_poultry_fish(
#'   data = fish_data,
#'   target = "weight_gain_g",
#'   farm_type = "fish"
#' )
#' }
#'
#' @export
rf_poultry_fish <- function(data,
                            target,
                            predictors = NULL,
                            farm_type = c("poultry", "fish"),
                            ntree = 500,
                            importance = TRUE,
                            test_size = 0.2,
                            seed = 123) {

  farm_type <- match.arg(farm_type)

  if (!requireNamespace("randomForest", quietly = TRUE)) {
    stop("Package 'randomForest' is required. Install it with: install.packages('randomForest')")
  }

  if (!(target %in% names(data))) {
    stop("Target variable '", target, "' not found in data")
  }

  withr::local_seed(seed)

  # Select predictors
  if (is.null(predictors)) {
    predictors <- setdiff(names(data), target)
    numeric_vars <- names(data)[sapply(data, is.numeric)]
    predictors <- intersect(predictors, numeric_vars)
  }

  # Create formula
  formula_obj <- as.formula(paste(target, "~", paste(predictors, collapse = " + ")))

  # Split data
  n <- nrow(data)
  train_idx <- sample(1:n, size = floor((1 - test_size) * n))
  train_data <- data[train_idx, ]
  test_data <- data[-train_idx, ]

  # Train model
  cat("\n=== Random Forest for", toupper(farm_type), "Farming ===\n")
  cat("Target:", target, "\n")
  cat("Features:", length(predictors), "\n")
  cat("Training samples:", nrow(train_data), "\n")
  cat("Test samples:", nrow(test_data), "\n\n")

  rf_model <- randomForest::randomForest(
    formula = formula_obj,
    data = train_data,
    ntree = ntree,
    importance = importance
  )

  # Predictions
  predictions <- predict(rf_model, newdata = test_data)
  actual <- test_data[[target]]

  # Performance metrics
  mse <- mean((predictions - actual)^2)
  rmse <- sqrt(mse)
  mae <- mean(abs(predictions - actual))
  r_squared <- 1 - (sum((actual - predictions)^2) / sum((actual - mean(actual))^2))
  nonzero <- actual != 0
  if (any(nonzero)) {
    mape <- mean(abs((actual[nonzero] - predictions[nonzero]) / actual[nonzero])) * 100
  } else {
    mape <- NA_real_
  }

  performance <- list(
    rmse = rmse,
    mae = mae,
    r_squared = r_squared,
    mape = mape,
    variance_explained = rf_model$rsq[length(rf_model$rsq)]
  )

  cat("Performance Metrics:\n")
  cat("RMSE:", round(rmse, 3), "\n")
  cat("MAE:", round(mae, 3), "\n")
  cat("R-squared:", round(r_squared, 3), "\n")
  cat("MAPE:", round(mape, 2), "%\n")
  cat("Variance Explained:", round(performance$variance_explained, 3), "\n\n")

  # Variable importance
  importance_scores <- NULL
  if (importance) {
    importance_scores <- randomForest::importance(rf_model)
    cat("Top Important Variables for", target, ":\n")
    top_vars <- head(importance_scores[order(-importance_scores[, "%IncMSE"]), ], 5)
    print(top_vars)
  }

  result <- list(
    model = rf_model,
    predictions = predictions,
    actual = actual,
    performance = performance,
    importance = importance_scores,
    test_data = test_data,
    farm_type = farm_type,
    target = target,
    predictors = predictors
  )

  class(result) <- c("rf_poultry_fish", "rf_agriculture")
  return(result)
}


#' Random Forest for Agronomy Applications
#'
#' @description
#' Apply Random Forest for crop-related predictions including disease
#' classification, yield prediction, and weather-driven crop modeling.
#'
#' @param data A data frame containing crop/agronomy data
#' @param target Character string specifying the target variable
#' @param predictors Character vector of predictor variable names
#' @param task_type Character: "classification" (disease), "regression" (yield), or "weather_model"
#' @param ntree Number of trees to grow (default: 500)
#' @param importance Should variable importance be assessed? (default: TRUE)
#' @param test_size Proportion of data for testing (default: 0.2)
#' @param seed Random seed for reproducibility (default: 123)
#'
#' @return A list containing model results and predictions
#'
#' @examples
#' \dontrun{
#' # Disease classification
#' disease_data <- data.frame(
#'   disease = factor(sample(c("Healthy", "Rust", "Blight", "Mildew"), 200, replace = TRUE)),
#'   leaf_temp = rnorm(200, mean = 25, sd = 3),
#'   humidity = rnorm(200, mean = 70, sd = 15),
#'   rainfall_mm = rexp(200, rate = 0.1),
#'   leaf_wetness_hours = sample(0:12, 200, replace = TRUE),
#'   plant_age_days = sample(30:120, 200, replace = TRUE),
#'   nitrogen_level = rnorm(200, mean = 50, sd = 10)
#' )
#'
#' result <- rf_agronomy(
#'   data = disease_data,
#'   target = "disease",
#'   task_type = "classification"
#' )
#'
#' # Yield prediction
#' yield_data <- data.frame(
#'   yield_kg_ha = rnorm(180, mean = 5000, sd = 800),
#'   rainfall_mm = rnorm(180, mean = 800, sd = 200),
#'   temperature_avg = rnorm(180, mean = 24, sd = 3),
#'   solar_radiation = rnorm(180, mean = 20, sd = 3),
#'   fertilizer_kg_ha = rnorm(180, mean = 150, sd = 30),
#'   soil_moisture = rnorm(180, mean = 25, sd = 5),
#'   growth_days = sample(90:150, 180, replace = TRUE)
#' )
#'
#' result_yield <- rf_agronomy(
#'   data = yield_data,
#'   target = "yield_kg_ha",
#'   task_type = "regression"
#' )
#' }
#'
#' @export
rf_agronomy <- function(data,
                        target,
                        predictors = NULL,
                        task_type = c("classification", "regression", "weather_model"),
                        ntree = 500,
                        importance = TRUE,
                        test_size = 0.2,
                        seed = 123) {

  task_type <- match.arg(task_type)

  if (!requireNamespace("randomForest", quietly = TRUE)) {
    stop("Package 'randomForest' is required. Install it with: install.packages('randomForest')")
  }

  if (!(target %in% names(data))) {
    stop("Target variable '", target, "' not found in data")
  }

  withr::local_seed(seed)

  # Select predictors
  if (is.null(predictors)) {
    predictors <- setdiff(names(data), target)
    if (task_type %in% c("regression", "weather_model")) {
      numeric_vars <- names(data)[sapply(data, is.numeric)]
      predictors <- intersect(predictors, numeric_vars)
    }
  }

  # Create formula
  formula_obj <- as.formula(paste(target, "~", paste(predictors, collapse = " + ")))

  # Split data
  n <- nrow(data)
  train_idx <- sample(1:n, size = floor((1 - test_size) * n))
  train_data <- data[train_idx, ]
  test_data <- data[-train_idx, ]

  # Train model
  cat("\n=== Random Forest for Agronomy ===\n")
  cat("Application:", task_type, "\n")
  cat("Target:", target, "\n")
  cat("Features:", length(predictors), "\n")
  cat("Training samples:", nrow(train_data), "\n")
  cat("Test samples:", nrow(test_data), "\n\n")

  rf_model <- randomForest::randomForest(
    formula = formula_obj,
    data = train_data,
    ntree = ntree,
    importance = importance
  )

  # Predictions
  predictions <- predict(rf_model, newdata = test_data)
  actual <- test_data[[target]]

  # Calculate performance
  if (task_type == "classification") {
    conf_matrix <- table(Predicted = predictions, Actual = actual)
    accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)

    # Per-class metrics
    precision_recall <- lapply(levels(actual), function(class) {
      tp <- conf_matrix[class, class]
      fp <- sum(conf_matrix[class, ]) - tp
      fn <- sum(conf_matrix[, class]) - tp

      precision <- if (tp + fp > 0) tp / (tp + fp) else 0
      recall <- if (tp + fn > 0) tp / (tp + fn) else 0
      f1 <- if (precision + recall > 0) 2 * (precision * recall) / (precision + recall) else 0

      c(precision = precision, recall = recall, f1 = f1)
    })
    names(precision_recall) <- levels(actual)

    performance <- list(
      accuracy = accuracy,
      confusion_matrix = conf_matrix,
      class_metrics = precision_recall,
      oob_error = tail(rf_model$err.rate[, "OOB"], 1)
    )

    cat("Disease Classification Results:\n")
    cat("Accuracy:", round(accuracy * 100, 2), "%\n")
    cat("OOB Error:", round(performance$oob_error * 100, 2), "%\n\n")
    cat("Confusion Matrix:\n")
    print(conf_matrix)
    cat("\n")

  } else {
    mse <- mean((predictions - actual)^2)
    rmse <- sqrt(mse)
    mae <- mean(abs(predictions - actual))
    r_squared <- 1 - (sum((actual - predictions)^2) / sum((actual - mean(actual))^2))

    performance <- list(
      rmse = rmse,
      mae = mae,
      r_squared = r_squared,
      variance_explained = rf_model$rsq[length(rf_model$rsq)]
    )

    cat("Yield/Weather Model Results:\n")
    cat("RMSE:", round(rmse, 3), "\n")
    cat("MAE:", round(mae, 3), "\n")
    cat("R-squared:", round(r_squared, 3), "\n")
    cat("Variance Explained:", round(performance$variance_explained, 3), "\n\n")
  }

  # Variable importance
  importance_scores <- NULL
  if (importance) {
    importance_scores <- randomForest::importance(rf_model)
    cat("Top Important Variables:\n")
    if (task_type == "classification") {
      top_vars <- head(importance_scores[order(-importance_scores[, "MeanDecreaseGini"]), ], 5)
    } else {
      top_vars <- head(importance_scores[order(-importance_scores[, "%IncMSE"]), ], 5)
    }
    print(top_vars)
  }

  result <- list(
    model = rf_model,
    predictions = predictions,
    actual = actual,
    performance = performance,
    importance = importance_scores,
    test_data = test_data,
    task_type = task_type,
    target = target,
    predictors = predictors
  )

  class(result) <- c("rf_agronomy", "rf_agriculture")
  return(result)
}


#' Plot Variable Importance for Agriculture Random Forest
#'
#' @description
#' Create a publication-ready variable importance plot for Random Forest models
#'
#' @param rf_result Result object from rf_soil_analysis, rf_poultry_fish, or rf_agronomy
#' @param top_n Number of top variables to display (default: 10)
#' @param color Color for bars (default: "#2E7D32" agriculture green)
#'
#' @return A ggplot2 object
#'
#' @export
plot_rf_importance <- function(rf_result, top_n = 10, color = "#2E7D32") {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Install it with: install.packages('ggplot2')")
  }

  if (is.null(rf_result$importance)) {
    stop("Importance scores not available in model. Set importance=TRUE when training.")
  }

  importance_df <- as.data.frame(rf_result$importance)

  # Select appropriate importance measure
  if (rf_result$task_type == "classification") {
    importance_df$Importance <- importance_df$MeanDecreaseGini
    ylab <- "Mean Decrease in Gini"
  } else {
    importance_df$Importance <- importance_df$`%IncMSE`
    ylab <- "% Increase in MSE"
  }

  importance_df$Variable <- rownames(importance_df)
  importance_df <- importance_df[order(-importance_df$Importance), ]
  importance_df <- head(importance_df, top_n)
  importance_df$Variable <- factor(importance_df$Variable,
                                    levels = importance_df$Variable[order(importance_df$Importance)])

  p <- ggplot2::ggplot(importance_df, ggplot2::aes(x = Importance, y = Variable)) +
    ggplot2::geom_bar(stat = "identity", fill = color) +
    ggplot2::labs(
      title = paste("Variable Importance -", rf_result$target),
      x = ylab,
      y = ""
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      axis.text = ggplot2::element_text(size = 11),
      axis.title = ggplot2::element_text(size = 12)
    )

  return(p)
}


#' Plot Predictions vs Actual for Agriculture Random Forest
#'
#' @description
#' Create a scatter plot comparing predictions to actual values (regression only)
#'
#' @param rf_result Result object from rf_soil_analysis, rf_poultry_fish, or rf_agronomy
#' @param color Point color (default: "#1976D2" blue)
#'
#' @return A ggplot2 object
#'
#' @export
plot_rf_predictions <- function(rf_result, color = "#1976D2") {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Install it with: install.packages('ggplot2')")
  }

  if (rf_result$task_type == "classification") {
    stop("This plot is only for regression tasks. Use confusion matrix for classification.")
  }

  plot_data <- data.frame(
    Actual = rf_result$actual,
    Predicted = rf_result$predictions
  )

  r_squared <- rf_result$performance$r_squared
  rmse <- rf_result$performance$rmse

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = Actual, y = Predicted)) +
    ggplot2::geom_point(color = color, alpha = 0.6, size = 3) +
    ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red", linewidth = 1) +
    ggplot2::labs(
      title = paste("Random Forest Predictions -", rf_result$target),
      subtitle = sprintf("R² = %.3f, RMSE = %.3f", r_squared, rmse),
      x = "Actual Values",
      y = "Predicted Values"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(size = 12),
      axis.text = ggplot2::element_text(size = 11),
      axis.title = ggplot2::element_text(size = 12)
    )

  return(p)
}


#' Generate Agriculture Example Dataset
#'
#' @description
#' Create example datasets for testing Random Forest agriculture functions
#'
#' @param type Character: "soil", "poultry", "fish", "disease", or "yield"
#' @param n Number of observations (default: 150)
#' @param seed Random seed (default: 123)
#'
#' @return A data frame with example agriculture data
#'
#' @examples
#' \dontrun{
#' # Generate soil data
#' soil_data <- generate_ag_data("soil", n = 200)
#'
#' # Generate poultry data
#' poultry_data <- generate_ag_data("poultry", n = 150)
#' }
#'
#' @export
generate_ag_data <- function(type = c("soil", "poultry", "fish", "disease", "yield"),
                             n = 150,
                             seed = 123) {

  type <- match.arg(type)
  withr::local_seed(seed)

  if (type == "soil") {
    fertility_levels <- factor(rep(c("Low", "Medium", "High"), length.out = n))
    pH_means <- c(5.5, 6.5, 7.5)[as.numeric(fertility_levels)]
    N_means <- c(20, 40, 60)[as.numeric(fertility_levels)]

    data.frame(
      fertility = fertility_levels,
      pH = rnorm(n, mean = pH_means, sd = 0.5),
      nitrogen = rnorm(n, mean = N_means, sd = 5),
      phosphorus = rnorm(n, mean = N_means * 0.6, sd = 4),
      potassium = rnorm(n, mean = N_means * 4, sd = 20),
      organic_matter = rnorm(n, mean = as.numeric(fertility_levels) * 1.5, sd = 0.5),
      cec = rnorm(n, mean = as.numeric(fertility_levels) * 10, sd = 2),
      texture_sand = runif(n, 20, 60),
      texture_clay = runif(n, 10, 40)
    )

  } else if (type == "poultry") {
    data.frame(
      egg_production = rpois(n, lambda = 250 - sample(0:100, n, replace = TRUE)),
      hen_age_weeks = sample(20:80, n, replace = TRUE),
      temperature_c = rnorm(n, mean = 22, sd = 3),
      humidity_pct = rnorm(n, mean = 60, sd = 10),
      feed_protein_pct = rnorm(n, mean = 16, sd = 1),
      light_hours = rnorm(n, mean = 14, sd = 1),
      flock_size = sample(1000:5000, n, replace = TRUE),
      feed_intake_g = rnorm(n, mean = 110, sd = 10)
    )

  } else if (type == "fish") {
    data.frame(
      weight_gain_g = rnorm(n, mean = 50, sd = 10),
      water_temp_c = rnorm(n, mean = 26, sd = 2),
      dissolved_oxygen_mg = rnorm(n, mean = 6, sd = 1),
      pH = rnorm(n, mean = 7.5, sd = 0.5),
      feed_rate_pct = rnorm(n, mean = 3, sd = 0.5),
      stocking_density = sample(50:150, n, replace = TRUE),
      ammonia_mg = rexp(n, rate = 2),
      nitrite_mg = rexp(n, rate = 3)
    )

  } else if (type == "disease") {
    data.frame(
      disease = factor(sample(c("Healthy", "Rust", "Blight", "Mildew", "Mosaic"),
                             n, replace = TRUE,
                             prob = c(0.4, 0.2, 0.15, 0.15, 0.1))),
      leaf_temp_c = rnorm(n, mean = 25, sd = 3),
      humidity_pct = rnorm(n, mean = 70, sd = 15),
      rainfall_mm = rexp(n, rate = 0.05),
      leaf_wetness_hours = sample(0:12, n, replace = TRUE),
      plant_age_days = sample(30:120, n, replace = TRUE),
      nitrogen_ppm = rnorm(n, mean = 50, sd = 10),
      canopy_density = runif(n, 0.3, 0.9)
    )

  } else if (type == "yield") {
    temp_effect <- rnorm(n, mean = 24, sd = 3)
    rain_effect <- rnorm(n, mean = 800, sd = 200)

    data.frame(
      yield_kg_ha = 3000 + temp_effect * 80 + rain_effect * 2 + rnorm(n, sd = 400),
      rainfall_mm = rain_effect,
      temperature_avg_c = temp_effect,
      solar_radiation_mj = rnorm(n, mean = 20, sd = 3),
      fertilizer_kg_ha = rnorm(n, mean = 150, sd = 30),
      soil_moisture_pct = rnorm(n, mean = 25, sd = 5),
      growth_days = sample(90:150, n, replace = TRUE),
      planting_density = sample(4:8, n, replace = TRUE) * 10000
    )
  }
}

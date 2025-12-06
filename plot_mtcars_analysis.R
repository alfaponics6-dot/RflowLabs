# mtcars Analysis and Visualization
# Publication-quality plots of the mtcars dataset

# Load required libraries
library(ggplot2)
library(dplyr)
library(ggrepel)

# Load mtcars data
data(mtcars)

# Add car names as a column for labeling
mtcars$car_name <- rownames(mtcars)

# Create factors for better visualization
mtcars$cyl_factor <- factor(mtcars$cyl, labels = paste(c(4, 6, 8), "cyl"))
mtcars$am_factor <- factor(mtcars$am, labels = c("Automatic", "Manual"))

# Main scatter plot: MPG vs Weight, colored by cylinders
main_plot <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point(aes(color = cyl_factor, size = hp), alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "darkblue", alpha = 0.3) +
  geom_text_repel(aes(label = car_name), 
                  size = 3, 
                  box.padding = 0.5,
                  point.padding = 0.3,
                  max.overlaps = 10) +
  scale_color_viridis_d(name = "Engine") +
  scale_size_continuous(name = "Horsepower", 
                       range = c(2, 8),
                       guide = guide_legend(override.aes = list(alpha = 1))) +
  labs(
    title = "Motor Trend Car Road Tests (1974)",
    subtitle = "Relationship between Weight, Fuel Economy, and Engine Specifications",
    x = "Weight (1000 lbs)",
    y = "Miles per Gallon (MPG)",
    caption = "Source: Motor Trend Magazine (1974). Point size indicates horsepower."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    plot.caption = element_text(size = 10, hjust = 0),
    legend.position = "right",
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "gray80", fill = NA, size = 0.5)
  )

# Print the plot
print(main_plot)

# Display summary statistics
cat("\n=== MTCARS SUMMARY ===\n")
cat("Dataset contains", nrow(mtcars), "cars with", ncol(mtcars)-3, "original variables\n")
cat("\nKey Statistics:\n")
cat("MPG range:", min(mtcars$mpg), "-", max(mtcars$mpg), "\n")
cat("Weight range:", min(mtcars$wt), "-", max(mtcars$wt), "thousand lbs\n")
cat("Horsepower range:", min(mtcars$hp), "-", max(mtcars$hp), "hp\n")
cat("Cylinder distribution:", table(mtcars$cyl), "\n")
cat("Transmission:", table(mtcars$am_factor), "\n")

# Calculate correlation
correlation <- cor(mtcars$wt, mtcars$mpg)
cat("Correlation between weight and MPG:", round(correlation, 3), "\n")

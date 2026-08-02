#' @keywords internal
#' @importFrom grDevices dev.cur dev.list dev.off png
#' @importFrom stats as.formula predict rexp rnorm rpois runif
#' @importFrom utils capture.output head read.csv read.delim str tail
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

# Non-standard-evaluation column names used inside ggplot2::aes() in the
# plot_rf_* functions; declared here to satisfy R CMD check.
utils::globalVariables(c("Importance", "Variable", "Actual", "Predicted"))

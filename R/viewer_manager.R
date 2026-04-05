#' Viewer Manager - Keep Rflow in Viewer, send other content to browser
#'
#' @description
#' Intercepts viewer calls and redirects them to browser when Rflow is active.
#' This allows Rflow to stay in the Viewer while maps, plots, and other content
#' open in the browser automatically.

# Store Rflow's viewer state
.rflow_env <- new.env(parent = emptyenv())
.rflow_env$is_active <- FALSE
.rflow_env$original_viewer <- NULL

#' Activate Rflow Viewer Protection
#' 
#' @description
#' Redirects viewer content to browser while Rflow is running
#' 
#' @keywords internal
activate_rflow_viewer <- function() {
  # Store original viewer function
  if (is.null(.rflow_env$original_viewer)) {
    .rflow_env$original_viewer <- getOption("viewer")
  }
  
  # Set custom viewer that redirects to browser
  options(viewer = function(url, height = NULL) {
    if (.rflow_env$is_active) {
      # Rflow is active, send other content to browser
      message("[VIEW] Opening in browser (Rflow is using the Viewer)")
      
      # Open directly in browser
      # Note: Toolbar feature disabled due to browser security restrictions
      # Users can use browser's built-in tools: Print to PDF, Screenshot, etc.
      utils::browseURL(url)
    } else {
      # Rflow not active, use original viewer
      if (!is.null(.rflow_env$original_viewer)) {
        .rflow_env$original_viewer(url, height)
      } else {
        # Fallback to RStudio viewer
        rstudioapi::viewer(url)
      }
    }
  })
  
  .rflow_env$is_active <- TRUE
  cat("[OK] Rflow Viewer protection activated\n")
  cat("[VIEW] Maps and plots will open in browser\n")
}

#' Deactivate Rflow Viewer Protection
#' 
#' @description
#' Restores normal viewer behavior
#' 
#' @keywords internal
deactivate_rflow_viewer <- function() {
  # Restore original viewer
  if (!is.null(.rflow_env$original_viewer)) {
    options(viewer = .rflow_env$original_viewer)
  }
  
  .rflow_env$is_active <- FALSE
  cat("[OK] Rflow Viewer protection deactivated\n")
  cat("[VIEW] Viewer restored to normal behavior\n")
}

#' Check if Rflow Viewer is Active
#' 
#' @return Logical indicating if Rflow is protecting the viewer
#' @export
is_rflow_viewer_active <- function() {
  .rflow_env$is_active
}

#' Manually Open Content in Browser
#' 
#' @description
#' Force content to open in browser instead of viewer
#' 
#' @param content Content to display (htmlwidget, ggplot, etc.)
#' @export
#' 
#' @examples
#' \dontrun{
#' library(leaflet)
#' map <- leaflet() %>% addTiles()
#' open_in_browser(map)
#' }
open_in_browser <- function(content) {
  # Create temp HTML file
  temp_file <- tempfile(fileext = ".html")
  
  # Handle different content types
  if (inherits(content, "htmlwidget")) {
    if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
      stop("htmlwidgets package required. Install with: install.packages('htmlwidgets')")
    }
    htmlwidgets::saveWidget(content, temp_file, selfcontained = TRUE)
  } else if (inherits(content, "ggplot")) {
    # Save ggplot as HTML via plotly
    if (!requireNamespace("plotly", quietly = TRUE)) {
      stop("plotly package required to open ggplot in browser. Install with: install.packages('plotly')")
    }
    if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
      stop("htmlwidgets package required. Install with: install.packages('htmlwidgets')")
    }
    p <- plotly::ggplotly(content)
    htmlwidgets::saveWidget(p, temp_file, selfcontained = TRUE)
  } else if (inherits(content, "shiny.tag.list") || inherits(content, "shiny.tag")) {
    # HTML content
    htmltools::save_html(content, temp_file)
  } else {
    stop("Unsupported content type. Supported: htmlwidget, ggplot, HTML")
  }
  
  # Open in browser
  utils::browseURL(temp_file)
  invisible(temp_file)
}

# ---------------------------------------------------------------------------
# MCP tool registry + execution bridge
#
# MCP_TOOLS  — JSON-Schema definitions consumed by mcp_handle_tools_list()
# mcp_execute_tool() — dispatcher that calls the underlying R functions
#
# All tool execution is wrapped in capture.output() so that any print()/cat()
# inside user code or internal helpers cannot corrupt the JSON-RPC stream on
# stdout.  Logging always goes to message() → stderr.
# ---------------------------------------------------------------------------

# Persistent execution environment for run_r_code (shared across calls)
.mcp_exec_env <- new.env(parent = .GlobalEnv)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

mcp_ok  <- function(text) list(text = as.character(text), is_error = FALSE)
mcp_err <- function(text) list(text = as.character(text), is_error = TRUE)

# Convert any R value to a plain text string for MCP responses
mcp_to_text <- function(x) {
  if (is.null(x))        return("(null)")
  if (is.character(x))   return(paste(x, collapse = "\n"))
  paste(utils::capture.output(print(x)), collapse = "\n")
}

# ---------------------------------------------------------------------------
# Tool schema definitions (JSON Schema, serialised by jsonlite)
# I() on single-element vectors prevents auto-unboxing to a scalar
# ---------------------------------------------------------------------------

MCP_TOOLS <- list(

  list(
    name        = "run_r_code",
    description = paste(
      "Execute R code and return all output.",
      "Captures printed output, messages, warnings, and errors.",
      "Plots are saved to a temporary PNG and the path is returned.",
      "Set persist=true to run in the global environment."
    ),
    inputSchema = list(
      type       = "object",
      properties = list(
        code    = list(type = "string",  description = "R code to execute"),
        persist = list(type = "boolean", description = "Run in global env (default false)",
                       default = FALSE)
      ),
      required = I(c("code"))
    )
  ),

  list(
    name        = "read_text_file",
    description = "Read the full contents of a text file and return them as a string.",
    inputSchema = list(
      type       = "object",
      properties = list(
        path = list(type = "string", description = "Absolute or relative path to the file")
      ),
      required = I(c("path"))
    )
  ),

  list(
    name        = "write_text_file",
    description = "Write (or overwrite) a text file. Parent directories are created automatically.",
    inputSchema = list(
      type       = "object",
      properties = list(
        path    = list(type = "string", description = "Path to write to"),
        content = list(type = "string", description = "Text content to write")
      ),
      required = I(c("path", "content"))
    )
  ),

  list(
    name        = "analyze_file",
    description = paste(
      "Analyze a file and return a summary of its contents.",
      "Supports: CSV, TSV, Excel, JSON, RDS, RData, R scripts, PDF,",
      "Word documents, images, shapefiles, and plain text."
    ),
    inputSchema = list(
      type       = "object",
      properties = list(
        file_path = list(type = "string", description = "Path to the file to analyze")
      ),
      required = I(c("file_path"))
    )
  ),

  list(
    name        = "run_command",
    description = "Execute a system shell command and return its output.",
    inputSchema = list(
      type       = "object",
      properties = list(
        command     = list(type = "string", description = "Shell command to run"),
        working_dir = list(type = "string", description = "Working directory (optional)")
      ),
      required = I(c("command"))
    )
  ),

  list(
    name        = "create_directory",
    description = "Create a directory, including any missing parent directories.",
    inputSchema = list(
      type       = "object",
      properties = list(
        path      = list(type = "string",  description = "Directory path to create"),
        recursive = list(type = "boolean", description = "Create parents too (default true)",
                         default = TRUE)
      ),
      required = I(c("path"))
    )
  ),

  list(
    name        = "delete_path",
    description = "Delete a file or directory. Requires recursive=true to delete non-empty directories.",
    inputSchema = list(
      type       = "object",
      properties = list(
        path      = list(type = "string",  description = "Path to delete"),
        recursive = list(type = "boolean", description = "Delete contents recursively (default false)",
                         default = FALSE)
      ),
      required = I(c("path"))
    )
  ),

  list(
    name        = "copy_path",
    description = "Copy a file or directory to a new location.",
    inputSchema = list(
      type       = "object",
      properties = list(
        from      = list(type = "string",  description = "Source path"),
        to        = list(type = "string",  description = "Destination path"),
        overwrite = list(type = "boolean", description = "Overwrite if exists (default false)",
                         default = FALSE)
      ),
      required = I(c("from", "to"))
    )
  ),

  list(
    name        = "move_path",
    description = "Move or rename a file or directory.",
    inputSchema = list(
      type       = "object",
      properties = list(
        from = list(type = "string", description = "Source path"),
        to   = list(type = "string", description = "Destination path")
      ),
      required = I(c("from", "to"))
    )
  ),

  list(
    name        = "list_directory",
    description = "List the contents of a directory with type and size information.",
    inputSchema = list(
      type       = "object",
      properties = list(
        path      = list(type = "string",  description = "Directory to list (default: current directory)"),
        pattern   = list(type = "string",  description = "Glob/regex filter pattern (e.g. '*.R')"),
        recursive = list(type = "boolean", description = "List subdirectories recursively (default false)",
                         default = FALSE)
      )
    )
  ),

  list(
    name        = "search_r_source",
    description = "Search the R interpreter C/R source code by regex pattern. Returns matching lines with context.",
    inputSchema = list(
      type       = "object",
      properties = list(
        pattern = list(type = "string", description = "Regex pattern to search for"),
        path    = list(type = "string", description = "Subdirectory to limit search (main, library, include)")
      ),
      required = I(c("pattern"))
    )
  ),

  list(
    name        = "get_r_internals_info",
    description = paste(
      "Return documentation about R internals (architecture, memory, evaluation,",
      "parser, graphics, common bugs). topic can be: architecture, memory,",
      "evaluation, parser, graphics, common_bugs, or all."
    ),
    inputSchema = list(
      type       = "object",
      properties = list(
        topic = list(type = "string", description = "Topic to retrieve (default: all)", default = "all")
      )
    )
  ),

  list(
    name        = "find_r_function",
    description = "Find where an R function is implemented in the R source (C or R level).",
    inputSchema = list(
      type       = "object",
      properties = list(
        func_name = list(type = "string", description = "Name of the R function to locate")
      ),
      required = I(c("func_name"))
    )
  ),

  list(
    name        = "rf_train",
    description = paste(
      "Train a Random Forest model on any R data frame.",
      "data_expr is an R expression string that evaluates to a data frame",
      "(e.g. 'iris', 'read.csv(\"data.csv\")').",
      "Returns performance metrics and variable importance."
    ),
    inputSchema = list(
      type       = "object",
      properties = list(
        data_expr = list(type = "string", description = "R expression evaluating to a data frame (e.g. 'iris')"),
        target    = list(type = "string", description = "Name of the target/response column"),
        task_type = list(type = "string", description = "classification or regression (auto-detected if omitted)",
                         enum = list("classification", "regression"))
      ),
      required = I(c("data_expr", "target"))
    )
  ),

  list(
    name        = "get_workspace_context",
    description = "Return the full Rflow workspace context: current folder, open files, folder structure.",
    inputSchema = list(
      type       = "object",
      properties = list()
    )
  ),

  list(
    name        = "get_workspace_summary",
    description = "Return a concise human-readable summary of the current Rflow workspace.",
    inputSchema = list(
      type       = "object",
      properties = list()
    )
  )
)

# ---------------------------------------------------------------------------
# Main dispatcher
# ---------------------------------------------------------------------------

mcp_execute_tool <- function(name, args) {
  switch(name,
    "run_r_code"            = mcp_tool_run_r_code(args),
    "read_text_file"        = mcp_tool_read_text_file(args),
    "write_text_file"       = mcp_tool_write_text_file(args),
    "analyze_file"          = mcp_tool_analyze_file(args),
    "run_command"           = mcp_tool_run_command(args),
    "create_directory"      = mcp_tool_create_directory(args),
    "delete_path"           = mcp_tool_delete_path(args),
    "copy_path"             = mcp_tool_copy_path(args),
    "move_path"             = mcp_tool_move_path(args),
    "list_directory"        = mcp_tool_list_directory(args),
    "search_r_source"       = mcp_tool_search_r_source(args),
    "get_r_internals_info"  = mcp_tool_get_r_internals_info(args),
    "find_r_function"       = mcp_tool_find_r_function(args),
    "rf_train"              = mcp_tool_rf_train(args),
    "get_workspace_context" = mcp_tool_get_workspace_context(args),
    "get_workspace_summary" = mcp_tool_get_workspace_summary(args),
    mcp_err(paste("Unknown tool:", name))
  )
}

# ---------------------------------------------------------------------------
# Individual tool implementations
# ---------------------------------------------------------------------------

mcp_tool_run_r_code <- function(args) {
  code    <- args$code
  persist <- isTRUE(args$persist)

  if (is.null(code) || !nzchar(trimws(code)))
    return(mcp_err("'code' is required"))

  exec_env  <- if (persist) .GlobalEnv else .mcp_exec_env
  messages  <- character()
  warnings  <- character()
  error_msg <- NULL

  # Open a temp PNG so any plots go to a file, not a GUI window
  tmp_plot <- tempfile(fileext = ".png")
  plot_dev <- NULL
  tryCatch({
    grDevices::png(tmp_plot, width = 800L, height = 600L)
    plot_dev <- grDevices::dev.cur()
  }, error = function(e)
    message("[Rflow MCP] PNG device unavailable: ", conditionMessage(e))
  )

  output_lines <- utils::capture.output({
    result_vis <- tryCatch(
      withCallingHandlers(
        withVisible(eval(parse(text = code), envir = exec_env)),
        message = function(m) {
          messages <<- c(messages, trimws(conditionMessage(m)))
          invokeRestart("muffleMessage")
        },
        warning = function(w) {
          warnings <<- c(warnings, trimws(conditionMessage(w)))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) {
        error_msg <<- conditionMessage(e)
        list(value = NULL, visible = FALSE)
      }
    )
    if (!is.null(result_vis) &&
        isTRUE(result_vis$visible) &&
        !is.null(result_vis$value))
      print(result_vis$value)
  })

  # Close the PNG device and check if a plot was actually drawn
  plot_note <- NULL
  if (!is.null(plot_dev)) {
    if (plot_dev %in% grDevices::dev.list())
      tryCatch(grDevices::dev.off(plot_dev), error = function(e) NULL)
    if (file.exists(tmp_plot) && file.info(tmp_plot)$size > 2000L) {
      plot_note <- paste0("Plot saved: ", tmp_plot)
    } else {
      unlink(tmp_plot)
    }
  }

  if (!is.null(error_msg))
    return(mcp_err(paste0("Error: ", error_msg)))

  parts <- output_lines
  if (length(messages) > 0L) parts <- c(parts, "", "Messages:", messages)
  if (length(warnings) > 0L) parts <- c(parts, "", "Warnings:", warnings)
  if (!is.null(plot_note))   parts <- c(parts, "", plot_note)

  text <- paste(parts, collapse = "\n")
  if (!nzchar(trimws(text))) text <- "(no output)"
  mcp_ok(text)
}

mcp_tool_read_text_file <- function(args) {
  path <- args$path
  if (!file.exists(path)) return(mcp_err(paste("File not found:", path)))
  content <- tryCatch(
    paste(readLines(path, warn = FALSE), collapse = "\n"),
    error = function(e) mcp_err(paste("Error reading:", conditionMessage(e)))
  )
  if (is.list(content)) return(content)
  mcp_ok(content)
}

mcp_tool_write_text_file <- function(args) {
  path    <- args$path
  content <- args$content
  tryCatch({
    dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
    writeLines(content, path)
    mcp_ok(paste("Written:", path))
  }, error = function(e) mcp_err(paste("Error writing:", conditionMessage(e))))
}

mcp_tool_analyze_file <- function(args) {
  file_path <- args$file_path
  if (!file.exists(file_path)) return(mcp_err(paste("File not found:", file_path)))

  ext <- tolower(tools::file_ext(file_path))

  result <- tryCatch(
    switch(ext,
      "xlsx" = , "xls"              = analyze_excel(file_path),
      "csv"                          = analyze_csv(file_path),
      "tsv"                          = analyze_tsv(file_path),
      "rds"                          = analyze_rds(file_path),
      "rdata" = , "rda"             = analyze_rdata(file_path),
      "json"                         = analyze_json(file_path),
      "shp"                          = analyze_shapefile(file_path),
      "geojson"                      = analyze_geojson(file_path),
      "png" = , "jpg" = , "jpeg" = ,
      "gif" = , "bmp" = , "tiff" = ,
      "webp"                         = analyze_image(file_path),
      "pdf"                          = analyze_pdf(file_path),
      "docx" = , "doc"              = analyze_document(file_path),
      "txt" = , "log" = , "md"      = analyze_text(file_path),
      "r" = , "rmd"                 = analyze_r_file(file_path),
      {
        info <- file.info(file_path)
        paste0("File:     ", basename(file_path), "\n",
               "Size:     ", info$size, " bytes\n",
               "Modified: ", format(info$mtime), "\n",
               "Type:     .", ext)
      }
    ),
    error = function(e) paste("Error analyzing file:", conditionMessage(e))
  )

  mcp_ok(mcp_to_text(result))
}

mcp_tool_run_command <- function(args) {
  command     <- args$command
  working_dir <- args$working_dir
  tryCatch({
    if (!is.null(working_dir) && dir.exists(working_dir)) {
      old_wd <- getwd()
      on.exit(setwd(old_wd))
      setwd(working_dir)
    }
    output <- system(command, intern = TRUE, show.output.on.console = FALSE)
    mcp_ok(paste(output, collapse = "\n"))
  }, error = function(e) mcp_err(paste("Error:", conditionMessage(e))))
}

mcp_tool_create_directory <- function(args) {
  path      <- args$path
  recursive <- if (is.null(args$recursive)) TRUE else isTRUE(args$recursive)
  tryCatch({
    dir.create(path, showWarnings = FALSE, recursive = recursive)
    if (!dir.exists(path)) return(mcp_err(paste("Failed to create:", path)))
    mcp_ok(paste("Directory created:", path))
  }, error = function(e) mcp_err(paste("Error:", conditionMessage(e))))
}

mcp_tool_delete_path <- function(args) {
  path      <- args$path
  recursive <- isTRUE(args$recursive)
  if (!file.exists(path) && !dir.exists(path))
    return(mcp_err(paste("Path not found:", path)))
  tryCatch({
    unlink(path, recursive = recursive)
    mcp_ok(paste("Deleted:", path))
  }, error = function(e) mcp_err(paste("Error:", conditionMessage(e))))
}

mcp_tool_copy_path <- function(args) {
  from      <- args$from
  to        <- args$to
  overwrite <- isTRUE(args$overwrite)
  if (!file.exists(from) && !dir.exists(from))
    return(mcp_err(paste("Source not found:", from)))
  tryCatch({
    dir.create(dirname(to), showWarnings = FALSE, recursive = TRUE)
    file.copy(from, to, overwrite = overwrite, recursive = TRUE)
    mcp_ok(paste("Copied:", from, "->", to))
  }, error = function(e) mcp_err(paste("Error:", conditionMessage(e))))
}

mcp_tool_move_path <- function(args) {
  from <- args$from
  to   <- args$to
  tryCatch({
    dir.create(dirname(to), showWarnings = FALSE, recursive = TRUE)
    file.rename(from, to)
    mcp_ok(paste("Moved:", from, "->", to))
  }, error = function(e) mcp_err(paste("Error:", conditionMessage(e))))
}

mcp_tool_list_directory <- function(args) {
  path      <- if (is.null(args$path)) "." else args$path
  pattern   <- args$pattern
  recursive <- isTRUE(args$recursive)
  tryCatch({
    files <- list.files(path, pattern = pattern, full.names = TRUE,
                        recursive = recursive, include.dirs = TRUE)
    if (length(files) == 0L) return(mcp_ok("(empty)"))
    info  <- file.info(files)
    lines <- sprintf("%-6s  %-12s  %s",
                     ifelse(info$isdir, "[DIR]", "[FILE]"),
                     ifelse(info$isdir, "", format(info$size, big.mark = ",")),
                     basename(files))
    mcp_ok(paste(lines, collapse = "\n"))
  }, error = function(e) mcp_err(paste("Error:", conditionMessage(e))))
}

mcp_tool_search_r_source <- function(args) {
  pattern <- args$pattern
  path    <- args$path
  tryCatch(
    mcp_ok(mcp_to_text(search_r_source(pattern = pattern, path = path))),
    error = function(e) mcp_err(paste("Error:", conditionMessage(e)))
  )
}

mcp_tool_get_r_internals_info <- function(args) {
  topic <- if (is.null(args$topic)) "all" else args$topic
  tryCatch(
    mcp_ok(mcp_to_text(get_r_internals_info(topic = topic))),
    error = function(e) mcp_err(paste("Error:", conditionMessage(e)))
  )
}

mcp_tool_find_r_function <- function(args) {
  func_name <- args$func_name
  tryCatch(
    mcp_ok(mcp_to_text(find_r_function(func_name = func_name))),
    error = function(e) mcp_err(paste("Error:", conditionMessage(e)))
  )
}

mcp_tool_rf_train <- function(args) {
  data_expr <- args$data_expr
  target    <- args$target
  task_type <- args$task_type   # may be NULL → auto-detect

  if (is.null(data_expr) || is.null(target))
    return(mcp_err("'data_expr' and 'target' are required"))

  # Evaluate the data expression
  data_val  <- NULL
  eval_err  <- NULL
  tryCatch(
    { data_val <- eval(parse(text = data_expr), envir = .GlobalEnv) },
    error = function(e) { eval_err <<- conditionMessage(e) }
  )
  if (!is.null(eval_err))
    return(mcp_err(paste("Error evaluating data_expr:", eval_err)))
  if (!is.data.frame(data_val))
    return(mcp_err(paste("data_expr must evaluate to a data frame, got:",
                         class(data_val)[1L])))

  output_lines <- utils::capture.output({
    tryCatch({
      result <- rf_train(data = data_val, target = target,
                         task_type = task_type, verbose = TRUE)
      cat("\n--- Results ---\n")
      cat("Task:       ", result$task_type, "\n")
      cat("Target:     ", result$target, "\n")
      cat("Predictors: ", paste(result$predictors, collapse = ", "), "\n\n")
      cat("Performance:\n")
      print(result$performance)
      if (!is.null(result$importance) && (is.data.frame(result$importance) ||
                                           is.matrix(result$importance))) {
        cat("\nTop Variable Importance (up to 10):\n")
        print(utils::head(result$importance, 10L))
      }
    }, error = function(e) cat("Error:", conditionMessage(e), "\n"))
  })

  mcp_ok(paste(output_lines, collapse = "\n"))
}

mcp_tool_get_workspace_context <- function(args) {
  tryCatch({
    ctx  <- get_workspace_context()
    text <- paste(utils::capture.output(utils::str(ctx)), collapse = "\n")
    mcp_ok(text)
  }, error = function(e) mcp_err(paste("Error:", conditionMessage(e))))
}

mcp_tool_get_workspace_summary <- function(args) {
  tryCatch(
    mcp_ok(mcp_to_text(get_workspace_summary())),
    error = function(e) mcp_err(paste("Error:", conditionMessage(e)))
  )
}

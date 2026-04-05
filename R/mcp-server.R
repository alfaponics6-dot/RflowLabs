#' Start the Rflow MCP Server
#'
#' Starts a Model Context Protocol server that exposes all Rflow tools via
#' JSON-RPC 2.0 over stdin/stdout.  Claude Code (and any other MCP-compatible
#' client) can call all 16 R tools without an API key.
#'
#' Add to your project's \code{.mcp.json}:
#' \preformatted{
#' {
#'   "mcpServers": {
#'     "rflow": {
#'       "command": "Rscript",
#'       "args": ["-e", "Rflow::start_mcp_server()"]
#'     }
#'   }
#' }
#' }
#'
#' @export
start_mcp_server <- function() {
  message("[Rflow MCP] Server v", utils::packageVersion("Rflow"), " starting")
  mcp_server_loop()
}

# ---------------------------------------------------------------------------
# Main JSON-RPC loop
# ---------------------------------------------------------------------------

mcp_server_loop <- function() {
  con <- file("stdin", open = "r")
  on.exit(try(close(con), silent = TRUE))

  while (TRUE) {
    line <- tryCatch(
      readLines(con, n = 1L, warn = FALSE),
      error = function(e) NULL
    )

    if (is.null(line) || length(line) == 0L) break   # EOF — client disconnected

    line <- trimws(line)
    if (!nzchar(line)) next

    request <- tryCatch(
      jsonlite::fromJSON(line, simplifyVector = FALSE),
      error = function(e) {
        mcp_send_error(NULL, -32700L, paste("Parse error:", conditionMessage(e)))
        NULL
      }
    )
    if (is.null(request)) next

    id     <- request$id      # NULL for notifications
    method <- request$method
    params <- request$params

    tryCatch({
      response_result <- switch(
        method,
        "initialize"  = mcp_handle_initialize(params),
        "initialized" = NULL,          # notification — no response
        "ping"        = list(),
        "tools/list"  = mcp_handle_tools_list(),
        "tools/call"  = mcp_handle_tools_call(params),
        {
          if (!is.null(id))
            mcp_send_error(id, -32601L, paste("Method not found:", method))
          NULL
        }
      )

      if (!is.null(id) && !is.null(response_result))
        mcp_send_response(id, response_result)

    }, error = function(e) {
      message("[Rflow MCP] Error in '", method, "': ", conditionMessage(e))
      if (!is.null(id))
        mcp_send_error(id, -32603L, paste("Internal error:", conditionMessage(e)))
    })
  }

  message("[Rflow MCP] Server stopped.")
}

# ---------------------------------------------------------------------------
# Low-level send helpers  (all JSON goes to stdout; logs go to stderr)
# ---------------------------------------------------------------------------

mcp_send_response <- function(id, result) {
  out <- jsonlite::toJSON(
    list(jsonrpc = "2.0", id = id, result = result),
    auto_unbox = TRUE, null = "null", digits = 15
  )
  cat(out, "\n", sep = "")
  flush(stdout())
}

mcp_send_error <- function(id, code, msg) {
  out <- jsonlite::toJSON(
    list(jsonrpc = "2.0", id = id,
         error  = list(code = code, message = msg)),
    auto_unbox = TRUE, null = "null"
  )
  cat(out, "\n", sep = "")
  flush(stdout())
}

# ---------------------------------------------------------------------------
# Request handlers
# ---------------------------------------------------------------------------

mcp_handle_initialize <- function(params) {
  list(
    protocolVersion = "2024-11-05",
    capabilities    = list(tools = list()),
    serverInfo      = list(
      name    = "rflow",
      version = as.character(utils::packageVersion("Rflow"))
    )
  )
}

mcp_handle_tools_list <- function() {
  list(tools = MCP_TOOLS)
}

mcp_handle_tools_call <- function(params) {
  name <- params$name
  args <- if (is.null(params$arguments)) list() else params$arguments

  message("[Rflow MCP] tool: ", name)

  out <- tryCatch(
    mcp_execute_tool(name, args),
    error = function(e)
      list(text = paste("Internal error:", conditionMessage(e)), is_error = TRUE)
  )

  list(
    content = list(list(type = "text", text = out$text)),
    isError = isTRUE(out$is_error)
  )
}

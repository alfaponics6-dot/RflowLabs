# mcptools session tool for RflowLabs
# ---------------------------------------------------------------------------
# Exposes a `run_r_code` tool that executes R code in the user's live,
# interactive R/RStudio session (the one that called mcptools::mcp_session()).
# mcptools serialises this tool's function and runs it inside that session, so
# assignments persist in the global environment, plots draw to the RStudio
# Plots pane, and printed/console output is returned to the assistant.
#
# Register it with the MCP server (in your MCP client config):
#   Rscript -e "mcptools::mcp_server(tools = '<abs path>/session_tools.R')"
# Then, in the R/RStudio session you want to drive:
#   mcptools::mcp_session()
#
# Sourced by mcptools via source(file, local = TRUE)$value, so the file must
# end by returning the list of ellmer tools.

.rflow_run_r_code <- function(code) {
  messages <- character()
  warnings <- character()
  err <- NULL

  output <- utils::capture.output(
    withCallingHandlers(
      tryCatch({
        res <- withVisible(eval(parse(text = code), envir = globalenv()))
        if (isTRUE(res$visible) && !is.null(res$value)) print(res$value)
      }, error = function(e) err <<- conditionMessage(e)),
      message = function(m) {
        messages <<- c(messages, conditionMessage(m))
        invokeRestart("muffleMessage")
      },
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  )

  parts <- output
  if (length(messages) > 0L) parts <- c(parts, "", "Messages:", trimws(messages))
  if (length(warnings) > 0L) parts <- c(parts, "", "Warnings:", trimws(warnings))
  if (!is.null(err))         parts <- c(parts, "", paste("Error:", err))

  text <- paste(parts, collapse = "\n")
  if (!nzchar(trimws(text))) text <- "(code ran in session; no printed output)"
  text
}
# Detach from the sourcing environment so the function serialises cleanly to
# the session process (it only needs base + utils, referenced explicitly).
environment(.rflow_run_r_code) <- baseenv()

list(
  ellmer::tool(
    .rflow_run_r_code,
    description = paste(
      "Execute R code in the user's live, interactive R/RStudio session.",
      "Code runs in the global environment, so variables you create persist",
      "across calls, plots render in the RStudio Plots pane, and printed",
      "console output is returned. Prefer this whenever the user wants results",
      "to appear in their RStudio session."
    ),
    arguments = list(
      code = ellmer::type_string("R code to evaluate in the session")
    ),
    name = "run_r_code"
  )
)

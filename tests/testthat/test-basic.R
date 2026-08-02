# Basic package + MCP protocol surface.
# Rflow is an MCP server (v2.0.0 removed the old Shiny UI), so these tests
# exercise the exported API and the JSON-RPC handlers rather than the
# now-deleted Shiny/session functions.

test_that("package loads and exports its public API", {
  expect_true("Rflow" %in% loadedNamespaces())

  exported <- c(
    "start_mcp_server",
    "rf_train", "rf_soil_analysis", "rf_poultry_fish", "rf_agronomy",
    "plot_rf_importance", "plot_rf_predictions", "generate_ag_data",
    "search_r_source", "get_r_internals_info", "find_r_function",
    "get_workspace_context", "get_workspace_summary", "workspace_status",
    "clear_workspace", "open_file", "open_folder", "close_file"
  )
  for (fn in exported) {
    expect_true(exists(fn, mode = "function"), info = fn)
  }
})

test_that("MCP tool registry defines 16 well-formed tools", {
  tools <- Rflow:::MCP_TOOLS
  expect_type(tools, "list")
  expect_length(tools, 16)

  for (tool in tools) {
    expect_true(is.character(tool$name) && nzchar(tool$name))
    expect_true(is.character(tool$description) && nzchar(tool$description))
    expect_false(is.null(tool$inputSchema))
    expect_equal(tool$inputSchema$type, "object")
  }

  # Tool names must be unique.
  names_advertised <- vapply(tools, function(tool) tool$name, character(1))
  expect_equal(anyDuplicated(names_advertised), 0L)
  expect_true(all(c("run_r_code", "rf_train", "analyze_file") %in% names_advertised))
})

test_that("initialize handshake reports server identity", {
  res <- Rflow:::mcp_handle_initialize(list())
  expect_equal(res$serverInfo$name, "rflow")
  expect_equal(res$protocolVersion, "2024-11-05")
  expect_true(nzchar(res$serverInfo$version))
})

test_that("tools/list returns the full registry", {
  res <- Rflow:::mcp_handle_tools_list()
  expect_length(res$tools, 16)
})

# Regression tests for MCP JSON serialisation: jsonlite renders an empty
# list() as [], but the MCP schema requires {} for empty objects. A [] here
# makes compliant clients (e.g. Claude Code) reject the handshake / tool list.
test_that("initialize capabilities.tools serialises as a JSON object, not []", {
  json <- as.character(jsonlite::toJSON(
    Rflow:::mcp_handle_initialize(list()), auto_unbox = TRUE, null = "null"))
  expect_true(grepl('"tools":{', json, fixed = TRUE))
  expect_false(grepl('"tools":[', json, fixed = TRUE))
})

test_that("no tool inputSchema.properties serialises as an empty array", {
  json <- as.character(jsonlite::toJSON(
    Rflow:::mcp_handle_tools_list(), auto_unbox = TRUE, null = "null"))
  expect_false(grepl('"properties":[]', json, fixed = TRUE))
})

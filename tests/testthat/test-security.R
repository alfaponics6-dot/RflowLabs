# Safety / robustness of the MCP execution bridge.
# The server exposes R code execution and filesystem tools over JSON-RPC, so
# the contract that matters is: errors are captured and returned as tool
# errors (never crashing the server or leaking onto the stdout stream), and
# unknown/invalid calls are rejected.

test_that("run_r_code executes code and returns captured output", {
  out <- Rflow:::mcp_execute_tool("run_r_code", list(code = "cat(2 + 2)"))
  expect_false(isTRUE(out$is_error))
  expect_match(out$text, "4")
})

test_that("run_r_code turns R errors into tool errors, not exceptions", {
  out <- Rflow:::mcp_execute_tool("run_r_code", list(code = "stop('boom')"))
  expect_true(isTRUE(out$is_error))
  expect_match(out$text, "boom")
})

test_that("run_r_code rejects empty or blank code", {
  expect_true(isTRUE(Rflow:::mcp_execute_tool("run_r_code", list(code = "   "))$is_error))
  expect_true(isTRUE(Rflow:::mcp_execute_tool("run_r_code", list())$is_error))
})

test_that("unknown tools are rejected, not dispatched", {
  out <- Rflow:::mcp_execute_tool("definitely_not_a_tool", list())
  expect_true(isTRUE(out$is_error))
  expect_match(out$text, "Unknown tool")
})

test_that("tools/call wraps results in the MCP content envelope", {
  res <- Rflow:::mcp_handle_tools_call(
    list(name = "run_r_code", arguments = list(code = "print(41 + 1)"))
  )
  expect_false(isTRUE(res$isError))
  expect_equal(res$content[[1]]$type, "text")
  expect_match(res$content[[1]]$text, "42")
})

test_that("tools/call surfaces tool errors via isError", {
  res <- Rflow:::mcp_handle_tools_call(list(name = "nope", arguments = list()))
  expect_true(isTRUE(res$isError))
})

test_that("read_text_file on a missing path returns an error, not a crash", {
  out <- Rflow:::mcp_execute_tool("read_text_file", list(path = "no_such_file_xyz.txt"))
  expect_true(isTRUE(out$is_error))
  expect_match(out$text, "not found", ignore.case = TRUE)
})

test_that("delete_path on a missing path is refused (no destructive side effect)", {
  out <- Rflow:::mcp_execute_tool("delete_path", list(path = "no_such_path_xyz_should_not_exist"))
  expect_true(isTRUE(out$is_error))
  expect_match(out$text, "not found", ignore.case = TRUE)
})

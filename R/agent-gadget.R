# =============================================================================
# RflowLabs: an agentic Claude Code assistant as a Shiny gadget, wired to
# your LIVE RStudio session via a non-blocking file bridge.
#
#   source("C:/Users/carly/RStudioAgent/rstudio_agent.R")
#   start_agent()                  # operates in getwd()
#   start_rflowlabs("C:/path")     # or a project folder
#
# The agent (Claude Code CLI, your subscription, no API key) drives, but its
# run_r_code executes in YOUR R session: plots -> Plots pane, vars -> Environment.
# Full autonomy (--dangerously-skip-permissions). SVG icon system (no emojis).
# Requires: shiny, processx, later, jsonlite (+ rstudioapi inside RStudio).
# =============================================================================

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || (is.character(a) && !nzchar(a[1]))) b else a

.agent_env <- new.env(parent = emptyenv())
.agent_env$bridge_dir    <- NULL
.agent_env$bridge_script <- NULL
.agent_env$mcp_config    <- NULL

# ---- Embedded bridge MCP server (queues code; the gadget runs it in-session) -
.bridge_server_code <- r"--(
suppressWarnings(suppressMessages(library(jsonlite)))
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || (is.character(a) && !nzchar(a[1]))) b else a
BRIDGE <- Sys.getenv("AGENT_BRIDGE_DIR"); if (!nzchar(BRIDGE)) BRIDGE <- file.path(tempdir(), "rstudio_agent_bridge")
dir.create(BRIDGE, showWarnings = FALSE, recursive = TRUE)
send <- function(o) { cat(jsonlite::toJSON(o, auto_unbox = TRUE, null = "null", digits = 15), "\n", sep = ""); flush(stdout()) }
TOOLS <- list(list(name = "run_r_code",
  description = "Execute R code in the user's LIVE RStudio session. Plots render in the RStudio Plots pane, variables persist in the Environment, printed output is returned. Use this for ALL R execution and plotting.",
  inputSchema = list(type = "object", properties = list(code = list(type = "string", description = "R code to run")), required = I("code"))))
.seq <- 0L
run_in_session <- function(code) {
  .seq <<- .seq + 1L
  id <- paste0(as.integer(Sys.time()), "-", .seq, "-", sample.int(1e6, 1))
  reqf <- file.path(BRIDGE, paste0("req-", id, ".json")); respf <- file.path(BRIDGE, paste0("resp-", id, ".json"))
  tmp <- paste0(reqf, ".tmp"); writeLines(jsonlite::toJSON(list(id = id, code = code), auto_unbox = TRUE), tmp); file.rename(tmp, reqf)
  t0 <- Sys.time()
  repeat {
    if (file.exists(respf)) { r <- tryCatch(jsonlite::fromJSON(respf), error = function(e) NULL); unlink(respf)
      if (is.null(r)) return(list(text = "(bridge: unreadable response)", is_error = TRUE))
      return(list(text = r$text %||% "", is_error = isTRUE(r$is_error))) }
    # Long timeout: the gadget evaluates on the single R thread, so a genuine
    # long computation blocks the UI but must not be reported as a timeout.
    if (as.numeric(difftime(Sys.time(), t0, units = "secs")) > 3600) { unlink(reqf); return(list(text = "(bridge: timed out after 1h - is the RflowLabs gadget still running?)", is_error = TRUE)) }
    Sys.sleep(0.08)
  }
}
con <- file("stdin", open = "r")
repeat {
  line <- tryCatch(readLines(con, n = 1L, warn = FALSE), error = function(e) NULL)
  if (is.null(line) || length(line) == 0L) break
  line <- trimws(line); if (!nzchar(line)) next
  req <- tryCatch(jsonlite::fromJSON(line, simplifyVector = FALSE), error = function(e) NULL); if (is.null(req)) next
  id <- req$id; method <- req$method
  if (identical(method, "initialize")) send(list(jsonrpc = "2.0", id = id, result = list(protocolVersion = "2024-11-05", capabilities = list(tools = list(listChanged = FALSE)), serverInfo = list(name = "rstudio_bridge", version = "1.0"))))
  else if (identical(method, "tools/list")) send(list(jsonrpc = "2.0", id = id, result = list(tools = TOOLS)))
  else if (identical(method, "tools/call")) {
    nm <- req$params$name; args <- req$params$arguments %||% list()
    if (identical(nm, "run_r_code")) { out <- tryCatch(run_in_session(args$code %||% ""), error = function(e) list(text = paste("Bridge error:", conditionMessage(e)), is_error = TRUE))
      send(list(jsonrpc = "2.0", id = id, result = list(content = list(list(type = "text", text = out$text)), isError = isTRUE(out$is_error)))) }
    else send(list(jsonrpc = "2.0", id = id, result = list(content = list(list(type = "text", text = paste("Unknown tool:", nm))), isError = TRUE)))
  } else if (!is.null(id)) send(list(jsonrpc = "2.0", id = id, error = list(code = -32601, message = "Method not found")))
}
)--"

# ---- SVG icon system (Lucide-style, stroke = currentColor) ------------------
.icons <- list(
  logo      = '<path d="M12 8V4H8"/><rect width="16" height="12" x="4" y="8" rx="2"/><path d="M2 14h2"/><path d="M20 14h2"/><path d="M15 13v2"/><path d="M9 13v2"/>',
  send      = '<path d="m22 2-7 20-4-9-9-4Z"/><path d="M22 2 11 13"/>',
  plus      = '<path d="M5 12h14"/><path d="M12 5v14"/>',
  stop      = '<rect width="14" height="14" x="5" y="5" rx="2"/>',
  save      = '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/>',
  close     = '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
  pencil    = '<path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/>',
  book      = '<path d="M12 7v14"/><path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"/>',
  terminal  = '<polyline points="4 17 10 11 4 5"/><line x1="12" x2="20" y1="19" y2="19"/>',
  search    = '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  globe     = '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/>',
  checklist = '<path d="m3 17 2 2 4-4"/><path d="m3 7 2 2 4-4"/><path d="M13 6h8"/><path d="M13 12h8"/><path d="M13 18h8"/>',
  bot       = '<path d="M12 8V4H8"/><rect width="16" height="12" x="4" y="8" rx="2"/><path d="M2 14h2"/><path d="M20 14h2"/><path d="M15 13v2"/><path d="M9 13v2"/>',
  wrench    = '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
  sparkles  = '<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"/>',
  folder    = '<path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z"/>',
  check     = '<path d="M20 6 9 17l-5-5"/>',
  copy      = '<rect width="14" height="14" x="8" y="8" rx="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>',
  insert    = '<path d="M12 3v12"/><path d="m8 11 4 4 4-4"/><path d="M8 5H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-4"/>',
  chart     = '<path d="M3 3v16a2 2 0 0 0 2 2h16"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>',
  trend     = '<polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/>',
  bug       = '<path d="m8 2 1.88 1.88"/><path d="M14.12 3.88 16 2"/><path d="M9 7.13v-1a3.003 3.003 0 1 1 6 0v1"/><path d="M12 20c-3.3 0-6-2.7-6-6v-3a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v3c0 3.3-2.7 6-6 6"/><path d="M12 20v-9"/><path d="M6.53 9C4.6 8.8 3 7.1 3 5"/><path d="M6 13H2"/><path d="M3 21c0-2.1 1.7-3.9 3.8-4"/><path d="M20.97 5c0 2.1-1.6 3.8-3.5 4"/><path d="M22 13h-4"/><path d="M17.2 17c2.1.1 3.8 1.9 3.8 4"/>',
  eraser    = '<path d="m7 21-4.3-4.3c-1-1-1-2.5 0-3.4l9.6-9.6c1-1 2.5-1 3.4 0l5.6 5.6c1 1 1 2.5 0 3.4L13 21"/><path d="M22 21H7"/><path d="m5 11 9 9"/>',
  filetext  = '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/>'
)

ic <- function(name, size = 14, cls = "") {
  shiny::HTML(sprintf(
    '<svg class="ic %s" width="%d" height="%d" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">%s</svg>',
    cls, size, size, .icons[[name]] %||% .icons$wrench))
}

# ---- Auth pre-flight --------------------------------------------------------
agent_check_auth <- function(claude, interactive_login = TRUE) {
  get_status <- function() tryCatch({
    out <- processx::run(claude, c("auth", "status"), timeout = 15, error_on_status = FALSE)
    jsonlite::fromJSON(out$stdout)
  }, error = function(e) NULL)
  st <- get_status()
  if (isTRUE(st$loggedIn)) return(list(ok = TRUE, email = st$email %||% NULL, method = st$authMethod %||% NULL))
  if (!interactive_login) return(list(ok = FALSE))
  message("Not signed in to Claude. Opening your browser to sign in...")
  message("(complete the sign-in in the browser; this window will wait)")
  tryCatch(processx::run(claude, c("auth", "login", "--claudeai"), timeout = 300, error_on_status = FALSE),
           error = function(e) NULL)
  st <- get_status()
  if (isTRUE(st$loggedIn)) return(list(ok = TRUE, email = st$email %||% NULL, method = st$authMethod %||% NULL))
  list(ok = FALSE)
}

# ---- Locate the native claude.exe (never the .cmd shim) ---------------------
agent_find_claude <- function() {
  if (.Platform$OS.type == "windows") {
    exe <- Sys.glob(file.path(Sys.getenv("APPDATA"), "Claude", "claude-code", "*", "claude.exe")); exe <- exe[file.exists(exe)]
    if (length(exe) > 0) { v <- numeric_version(basename(dirname(exe)), strict = FALSE); ok <- !is.na(v)
      if (any(ok)) return((exe[ok])[v[ok] == max(v[ok])][[1]]); return(exe[[1]]) }
  }
  p <- Sys.which("claude"); if (nzchar(p) && !grepl("\\.cmd$", p, ignore.case = TRUE)) return(unname(p))
  for (c in c(file.path(Sys.getenv("APPDATA"), "npm", "claude"), "/usr/local/bin/claude", "/usr/bin/claude")) if (file.exists(c)) return(c)
  NULL
}

agent_tool_icon <- function(name) switch(name %||% "",
  "Write" = "pencil", "Edit" = "pencil", "MultiEdit" = "pencil", "NotebookEdit" = "pencil",
  "Read" = "book", "Bash" = "terminal", "Glob" = "search", "Grep" = "search",
  "WebFetch" = "globe", "WebSearch" = "globe", "TodoWrite" = "checklist", "Task" = "bot", "wrench")

agent_tool_summary <- function(name, input) {
  input <- input %||% list(); fp <- input$file_path %||% input$path %||% input$notebook_path %||% ""
  base <- if (nzchar(fp)) basename(fp) else ""
  switch(name %||% "tool",
    "Write" = paste("Write", base), "Edit" = paste("Edit", base), "MultiEdit" = paste("Edit", base), "NotebookEdit" = paste("Edit", base),
    "Read" = paste("Read", base), "Bash" = paste0("Run: ", substr(gsub("\\s+", " ", input$command %||% ""), 1, 90)),
    "Glob" = paste("Find", input$pattern %||% ""), "Grep" = paste("Grep", input$pattern %||% ""),
    "WebFetch" = paste("Fetch", input$url %||% ""), "WebSearch" = paste("Search", input$query %||% ""),
    "TodoWrite" = "Update plan", "Task" = paste("Subagent:", substr(input$description %||% "", 1, 60)), name %||% "tool")
}

agent_phase_label <- function(kind, tool = NULL) {
  if (identical(kind, "thinking")) return("thinking")
  if (identical(kind, "assistant")) return("writing reply")
  if (identical(kind, "tool_use")) {
    if (tool %in% c("Write", "Edit", "MultiEdit", "NotebookEdit")) return("editing files")
    if (tool %in% c("Read", "Glob", "Grep")) return("reading project")
    if (tool %in% c("WebFetch", "WebSearch")) return("searching the web")
    return("using tools")
  }
  "agent working"
}

# Parse one stream-json line. With --include-partial-messages we receive
# token-level deltas (stream_event -> content_block_*), so text/thinking are
# streamed live via stream_start/stream_delta/stream_stop and the complete
# `assistant` event is used ONLY for tool_use (its text was already streamed).
agent_parse_event <- function(line) {
  e <- tryCatch(jsonlite::fromJSON(line, simplifyVector = FALSE), error = function(err) NULL)
  if (is.null(e) || is.null(e$type)) return(list())
  out <- list()
  if (e$type == "system" && identical(e$subtype, "init"))
    out <- list(list(kind = "system", session_id = e$session_id, text = sprintf("session started \u00b7 %s", e$model %||% "")))
  else if (e$type == "stream_event") {
    ev <- e$event %||% list(); et <- ev$type %||% ""
    if (identical(et, "message_start")) out <- list(list(kind = "msg_boundary"))
    else if (identical(et, "content_block_start")) {
      bt <- (ev$content_block %||% list())$type %||% ""
      if (bt %in% c("text", "thinking")) out <- list(list(kind = "stream_start", block = bt))
    } else if (identical(et, "content_block_delta")) {
      d <- ev$delta %||% list(); dt <- d$type %||% ""
      if (identical(dt, "text_delta")) { tx <- d$text %||% ""; if (nzchar(tx)) out <- list(list(kind = "stream_delta", text = tx)) }
      else if (identical(dt, "thinking_delta")) { tx <- d$thinking %||% ""; if (nzchar(tx)) out <- list(list(kind = "stream_delta", text = tx, thinking = TRUE)) }
    } else if (identical(et, "content_block_stop")) {
      out <- list(list(kind = "stream_stop"))
    }
  }
  else if (e$type == "assistant") for (b in (e$message$content %||% list())) {
    # text was streamed via deltas -> render tool_use here, and emit the full
    # text as a fallback the server uses ONLY if no deltas streamed (CLI drift).
    if (identical(b$type, "tool_use") && !grepl("run_r_code$", b$name %||% ""))
      out <- c(out, list(list(kind = "tool_use", id = b$id, tool = b$name, icon = agent_tool_icon(b$name), summary = agent_tool_summary(b$name, b$input),
                              path = b$input$file_path %||% b$input$notebook_path %||% NULL)))
    else if (identical(b$type, "text")) { t <- b$text %||% ""; if (nzchar(trimws(t))) out <- c(out, list(list(kind = "assistant_fallback", text = t))) }
  }
  else if (e$type == "result")
    out <- list(list(kind = "result", session_id = e$session_id, is_error = isTRUE(e$is_error), cost = e$total_cost_usd %||% 0,
                     text = if (isTRUE(e$is_error)) paste("Error:", e$result %||% "unknown") else NULL))
  out
}

# 140 whimsical status words (Claude Code style). Rotated client-side.
.agent_words <- unique(c(
  "Caramelizing","Simmering","Marinating","Percolating","Brewing","Whisking","Saut\u00e9ing","Braising","Fermenting","Proofing",
  "Kneading","Reducing","Deglazing","Emulsifying","Blanching","Poaching","Zesting","Basting","Frosting","Tenderizing",
  "Cogitating","Ruminating","Pondering","Musing","Mulling","Deliberating","Contemplating","Noodling","Puzzling","Cerebrating",
  "Ideating","Brainstorming","Reckoning","Theorizing","Hypothesizing","Extrapolating","Interpolating","Calibrating","Reticulating","Synthesizing",
  "Catalyzing","Distilling","Crystallizing","Titrating","Quantizing","Vectorizing","Computing","Processing","Booping","Wibbling",
  "Flibbertigibbeting","Bamboozling","Discombobulating","Hornswoggling","Frolicking","Gallivanting","Cavorting","Dilly-dallying","Bumbling","Doodling",
  "Faffing about","Wombling","Skedaddling","Kerfuffling","Bimbling","Whirligigging","Brambling","Snoozling","Doing hard yakka","Giving it a burl",
  "Having a squiz","Going gangbusters","Fossicking","Bushwhacking","Beavering away","Grafting","Conjuring","Enchanting","Divining","Transmuting",
  "Manifesting","Incanting","Bewitching","Summoning","Alchemizing","Spellbinding","Charming","Bedazzling","Germinating","Sprouting",
  "Blossoming","Photosynthesizing","Burgeoning","Pollinating","Composting","Ripening","Compiling","Refactoring","Debugging","Yak-shaving",
  "Bikeshedding","Recursing","Untangling","Wrangling","Parsing","Bootstrapping","Linting","Rubber-ducking","Defragging","Reindexing",
  "Schlepping","Hustling","Trundling","Moseying","Sauntering","Puttering","Tinkering","Plodding","Toiling","Grinding",
  "Grokking","Forging","Whittling","Weaving","Sculpting","Tempering","Soldering","Chiseling","Polishing","Finessing",
  "Marshalling","Orchestrating","Choreographing","Massaging","Spinning up","Rustling up","Piecing together","Warming up","Concocting","Vibing"))

# ---- Run one agent turn, streaming events -----------------------------------
agent_run <- function(prompt, project_dir, model = "sonnet", session_id = NULL,
                      on_message = function(m) {}, on_done = function(sid, err) {}) {
  claude <- agent_find_claude()
  if (is.null(claude)) { on_message(list(kind = "result", is_error = TRUE, text = "Claude Code CLI not found.")); on_done(session_id, TRUE); return(NULL) }

  mcp_config <- .agent_env$mcp_config
  if (is.null(mcp_config) || !file.exists(mcp_config)) {
    rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
    if (.Platform$OS.type == "windows") rscript <- utils::shortPathName(rscript)
    cfg <- list(mcpServers = list(rstudio_bridge = list(command = rscript, args = list(.agent_env$bridge_script),
                                                        env = list(AGENT_BRIDGE_DIR = .agent_env$bridge_dir))))
    mcp_config <- tempfile(fileext = ".json"); writeLines(jsonlite::toJSON(cfg, auto_unbox = TRUE), mcp_config)
  }

  sys_prompt <- paste(
    "You are an autonomous coding assistant running inside the user's RStudio session.",
    "To execute ANY R code or produce plots, you MUST use the mcp__rstudio_bridge__run_r_code tool.",
    "It runs in the user's LIVE R session, so plots appear in the RStudio Plots pane and variables persist in the Environment pane.",
    "PLOTS: always render plots directly in the Plots pane by creating/printing them inside run_r_code.",
    "NEVER save plots to image files (no ggsave, png(), pdf()) unless the user explicitly asks for a file.",
    "FILES: when the user wants a script or document, create it with Write/Edit (it opens automatically in their editor);",
    "for one-off analysis just run the code directly with run_r_code instead of writing a script first.",
    "NEVER run R via Bash/Rscript.")

  args <- c("-p", prompt, "--output-format", "stream-json", "--verbose", "--include-partial-messages",
            "--dangerously-skip-permissions",
            "--model", model, "--mcp-config", mcp_config, "--strict-mcp-config", "--append-system-prompt", sys_prompt)
  if (!is.null(session_id) && nzchar(session_id)) args <- c(args, "--resume", session_id)

  old_key <- Sys.getenv("ANTHROPIC_API_KEY", unset = NA); if (!is.na(old_key)) Sys.unsetenv("ANTHROPIC_API_KEY")
  proc <- tryCatch(processx::process$new(claude, args = args, stdout = "|", stderr = "|", wd = project_dir), error = function(e) NULL)
  if (!is.na(old_key)) Sys.setenv(ANTHROPIC_API_KEY = old_key)
  if (is.null(proc)) { on_message(list(kind = "result", is_error = TRUE, text = "Failed to start Claude Code.")); on_done(session_id, TRUE); return(NULL) }

  st <- new.env(parent = emptyenv()); st$sid <- session_id; st$err <- FALSE; st$stderr <- character()
  handle <- function(ln) { if (!nzchar(trimws(ln))) return(); for (m in agent_parse_event(ln)) { if (!is.null(m$session_id)) st$sid <- m$session_id; if (identical(m$kind, "result") && isTRUE(m$is_error)) st$err <- TRUE; on_message(m) } }
  drain_err <- function() { el <- tryCatch(proc$read_error_lines(), error = function(e) character()); if (length(el)) st$stderr <- utils::tail(c(st$stderr, el), 200) }
  poll <- function() {
    drain_err()  # keep the stderr pipe empty so the CLI can't block on a full pipe
    for (ln in tryCatch(proc$read_output_lines(), error = function(e) character())) handle(ln)
    if (proc$is_alive()) later::later(poll, 0.12)
    else { drain_err(); for (ln in tryCatch(proc$read_output_lines(), error = function(e) character())) handle(ln)
      status <- tryCatch(proc$get_exit_status(), error = function(e) NA_integer_)
      if (!st$err && !is.na(status) && status != 0) {
        et <- paste(st$stderr, collapse = "\n")
        if (nzchar(trimws(et))) on_message(list(kind = "result", is_error = TRUE, text = paste("Error:", substr(et, 1, 1500))))
      }
      on_done(st$sid, st$err) }
  }
  later::later(poll, 0.1); invisible(proc)
}

# ---- Execute code in the live session ---------------------------------------
agent_capture_eval <- function(code) {
  messages <- character(); warnings <- character(); err <- NULL
  output <- utils::capture.output(withCallingHandlers(tryCatch({
    res <- withVisible(eval(parse(text = code), envir = globalenv()))
    if (isTRUE(res$visible) && !is.null(res$value)) print(res$value)
  }, error = function(e) err <<- conditionMessage(e)),
    message = function(m) { messages <<- c(messages, conditionMessage(m)); invokeRestart("muffleMessage") },
    warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }))
  parts <- output
  if (length(messages)) parts <- c(parts, "", "Messages:", trimws(messages))
  if (length(warnings)) parts <- c(parts, "", "Warnings:", trimws(warnings))
  if (!is.null(err)) parts <- c(parts, "", paste("Error:", err))
  text <- paste(parts, collapse = "\n"); if (!nzchar(trimws(text))) text <- "(ran in session; no printed output)"
  list(text = text, is_error = !is.null(err))
}

snap_files <- function(wd) {
  if (is.null(wd) || !dir.exists(wd)) return(stats::setNames(numeric(), character()))
  fs <- utils::head(list.files(wd, recursive = TRUE, full.names = TRUE), 5000)
  info <- file.info(fs)
  stats::setNames(as.numeric(info$mtime), fs)
}

purge_queue <- function() {
  bd <- .agent_env$bridge_dir
  if (!is.null(bd) && dir.exists(bd)) {
    ff <- list.files(bd, pattern = "^(req|resp)-", full.names = TRUE)
    if (length(ff)) suppressWarnings(unlink(ff))
  }
}

# ---- CSS --------------------------------------------------------------------
.agent_css <- r"--(
:root{
  --bg:#0a0c10; --bg2:#0d1017; --surface:#12161f; --surface2:#171c26;
  --border:#1e242f; --border2:#2a3140;
  --text:#e8ecf2; --muted:#8a93a3; --faint:#4c5568;
  --accent:#4d8dff; --accent2:#2563eb;
  --ok:#34c07c; --warn:#e0a13c; --err:#ef5b58; --purple:#a97ff5;
}
*{box-sizing:border-box}
body{background:var(--bg);color:var(--text);font-family:'Inter','Segoe UI Variable Text','Segoe UI',system-ui,sans-serif;margin:0;font-size:13px}
::-webkit-scrollbar{width:8px;height:8px}
::-webkit-scrollbar-thumb{background:#252c39;border-radius:8px}
::-webkit-scrollbar-thumb:hover{background:#303948}
::-webkit-scrollbar-track{background:transparent}
.ic{vertical-align:-2px;flex-shrink:0}
.fullcode{position:absolute;left:-9999px;top:0;width:1px;height:1px;opacity:0}
#agentwrap{display:flex;flex-direction:column;height:100vh;background:linear-gradient(180deg,var(--bg2),var(--bg) 140px)}
#agenthead{padding:10px 14px;border-bottom:1px solid var(--border);display:flex;gap:8px;align-items:center;flex-wrap:wrap}
.brand{display:flex;align-items:center;gap:8px;font-weight:650;font-size:14px;letter-spacing:.2px;white-space:nowrap}
.brandaccent{color:var(--accent);margin-left:-6px}
.brand .logo{display:flex;align-items:center;justify-content:center;width:26px;height:26px;border-radius:8px;background:linear-gradient(135deg,var(--accent),#7c5cff);color:#fff}
#agenthead .grow{flex:1}
#agenthead .form-group,#agenthead .shiny-input-container{margin:0!important;width:auto!important}
#wd{background:var(--surface);border:1px solid var(--border);color:var(--muted);border-radius:8px;padding:5px 10px;font-size:12px;height:30px;width:220px;transition:border-color .2s}
#wd:focus{border-color:var(--border2);outline:none;color:var(--text)}
select#model{background:var(--surface);border:1px solid var(--border);color:var(--text);border-radius:8px;height:30px;padding:0 8px;font-size:12px;appearance:auto;cursor:pointer}
select#model:focus{outline:none;border-color:var(--border2)}
.ibtn,.ibtn:focus{display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;border-radius:8px;background:var(--surface);border:1px solid var(--border);color:var(--muted);cursor:pointer;padding:0;transition:all .15s}
.ibtn:hover{color:var(--text);border-color:var(--border2);background:var(--surface2)}
.ibtn.danger:hover{color:var(--err);border-color:#5c2b2b}
#chatscroll{flex:1;overflow-y:auto;padding:14px 16px}
@keyframes slideIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}
@keyframes pulse{0%,100%{opacity:.35}50%{opacity:1}}
@keyframes spin{to{transform:rotate(360deg)}}
@keyframes shimmer{0%{background-position:-200% 0}100%{background-position:200% 0}}
@keyframes blink{0%,80%,100%{opacity:.15}40%{opacity:1}}
.msg{margin:10px 0;max-width:94%;line-height:1.55;animation:slideIn .28s cubic-bezier(.2,.7,.3,1)}
.msg.user{margin-left:auto;background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;border-radius:14px 14px 4px 14px;padding:9px 13px;white-space:pre-wrap;box-shadow:0 2px 8px rgba(37,99,235,.25)}
.msg.assistant{background:var(--surface);border:1px solid var(--border);border-radius:14px 14px 14px 4px;padding:10px 13px;white-space:pre-wrap;box-shadow:0 1px 3px rgba(0,0,0,.3)}
.msg.thinking{color:var(--faint);font-style:italic;font-size:12px;padding:2px 6px;display:flex;gap:6px;align-items:flex-start}
.msg.thinking .ic{margin-top:2px;color:var(--faint)}
.msg.system{color:var(--faint);font-size:11px;text-align:center;animation:none}
.card{border-radius:10px;padding:8px 11px;border:1px solid var(--border);background:var(--surface);box-shadow:0 1px 3px rgba(0,0,0,.25)}
.msg.toolcard{display:flex;align-items:center;gap:9px;font-size:12.5px;color:var(--text)}
.tic{display:flex;align-items:center;justify-content:center;width:24px;height:24px;border-radius:7px;background:rgba(77,141,255,.12);color:var(--accent);flex-shrink:0}
.msg.runcard{position:relative;overflow:hidden;transition:border-color .4s;border-color:rgba(224,161,60,.35)}
.msg.runcard.running::after{content:'';position:absolute;inset:0;pointer-events:none;background:linear-gradient(100deg,transparent 30%,rgba(224,161,60,.08) 50%,transparent 70%);background-size:200% 100%;animation:shimmer 1.4s linear infinite}
.msg.runcard.done{border-color:rgba(52,192,124,.35)}
.msg.runcard.err{border-color:rgba(239,91,88,.4)}
.msg.runcard.cancelled{border-color:var(--border2);opacity:.6}
.rchead{display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;gap:8px}
.lbl{display:inline-flex;align-items:center;gap:7px;font-size:11px;font-weight:600;color:var(--warn)}
.runcard.done .lbl{color:var(--ok)}
.runcard.err .lbl{color:var(--err)}
.runcard.cancelled .lbl{color:var(--muted)}
.lbl-ic{display:inline-flex;align-items:center}
.runcard pre{margin:0;color:#cdd5e0;font-family:'Cascadia Code',Consolas,monospace;font-size:12px;white-space:pre-wrap;max-height:220px;overflow:auto;background:var(--bg2);border-radius:8px;padding:8px 10px;border:1px solid var(--border)}
.spinner{display:inline-block;width:11px;height:11px;border:2px solid var(--warn);border-top-color:transparent;border-radius:50%;animation:spin .7s linear infinite}
.rcbtns{display:flex;gap:5px;flex-shrink:0}
.mini{display:inline-flex;align-items:center;gap:5px;background:var(--surface2);border:1px solid var(--border);color:var(--muted);font-size:10.5px;border-radius:6px;padding:3px 8px;cursor:pointer;transition:all .15s}
.mini:hover{color:var(--text);border-color:var(--border2)}
.msg.runout pre{margin:0;color:var(--muted);font-family:'Cascadia Code',Consolas,monospace;font-size:12px;white-space:pre-wrap;max-height:200px;overflow:auto;background:var(--bg2);border-radius:8px;padding:8px 10px;border:1px solid var(--border)}
.msg.runout.err pre{color:var(--err)}
.msg.filecard{border-color:rgba(169,127,245,.3)}
.filecard .lbl{color:var(--purple);margin-bottom:5px}
.flink{display:inline-flex;align-items:center;gap:5px;color:var(--muted);cursor:pointer;margin:2px 12px 2px 0;font-size:12px;transition:color .15s}
.flink:hover{color:var(--purple)}
.msg.result{display:flex;align-items:center;gap:6px;color:var(--ok);font-size:11px;animation:none}
.msg.result.err{color:var(--err)}
.typing{display:flex;gap:4px;padding:8px 12px}
.typing span{width:6px;height:6px;background:var(--muted);border-radius:50%;animation:blink 1.2s infinite}
.typing span:nth-child(2){animation-delay:.2s}
.typing span:nth-child(3){animation-delay:.4s}
@keyframes caretblink{0%,50%{opacity:1}51%,100%{opacity:0}}
.pill{background:rgba(224,161,60,.08);border:1px solid rgba(224,161,60,.35);color:var(--warn);font-size:11px;font-weight:550;border-radius:99px;padding:4px 12px;display:inline-flex;gap:6px;align-items:center;white-space:nowrap}
.pdot{width:6px;height:6px;border-radius:50%;background:var(--warn);animation:pulse 1s infinite}
.pilltext{min-width:70px}
.pilltime{opacity:.65;font-variant-numeric:tabular-nums}
.msg.streaming .sttext{white-space:pre-wrap}
.caret{display:inline-block;width:2px;height:1.05em;background:var(--accent);margin-left:2px;vertical-align:-3px;border-radius:1px;animation:caretblink 1.05s step-end infinite}
.msg.thinking.streaming{align-items:flex-start}
#qarow{display:flex;gap:6px;padding:8px 16px 0;flex-wrap:wrap}
.qa{display:inline-flex;align-items:center;gap:6px;background:var(--surface);border:1px solid var(--border);color:var(--muted);font-size:11.5px;border-radius:99px;padding:5px 12px;cursor:pointer;transition:all .18s}
.qa:hover{color:var(--accent);border-color:rgba(77,141,255,.5);transform:translateY(-1px);box-shadow:0 3px 10px rgba(0,0,0,.3)}
#agentfoot{padding:10px 16px 12px}
#agentfoot .form-group,#agentfoot .shiny-input-container{margin:0;width:100%}
.inputshell{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:6px 8px 6px 12px;transition:border-color .2s,box-shadow .2s}
.inputshell:focus-within{border-color:rgba(77,141,255,.6);box-shadow:0 0 0 3px rgba(77,141,255,.12)}
#msg{width:100%;background:transparent;color:var(--text);border:none;padding:6px 4px;resize:none;font-family:inherit;font-size:13px}
#msg:focus{outline:none}
.footrow{display:flex;align-items:center;gap:10px;margin-top:2px}
#statsbar{color:var(--faint);font-size:11px;flex:1}
.sendbtn,.sendbtn:focus{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;border-radius:10px;border:none;background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;cursor:pointer;padding:0;transition:transform .15s,opacity .2s,box-shadow .2s;box-shadow:0 2px 8px rgba(37,99,235,.35)}
.sendbtn:hover{transform:translateY(-1px);box-shadow:0 4px 14px rgba(37,99,235,.45)}
.sendbtn.disabled{opacity:.4;pointer-events:none}
.shiny-notification{background:var(--surface2);color:var(--text);border:1px solid var(--border2);border-radius:10px}
)--"

# ---- JS ---------------------------------------------------------------------
.agent_js <- r"--(
window.__agentBusy=false;
window.agentSend=function(){
  if(window.__agentBusy)return;
  var ta=document.getElementById('msg');if(!ta)return;
  var t=ta.value;if(!t||!t.trim())return;
  Shiny.setInputValue('msg_submit',{text:t,n:(window.__agn=(window.__agn||0)+1)},{priority:'event'});
};
(function(){
  var ta=document.getElementById('msg');
  ta.addEventListener('keydown',function(e){
    if(e.key==='Enter'&&!e.shiftKey&&!e.isComposing){e.preventDefault();window.agentSend();}
  });
  var sc=document.getElementById('chatscroll');
  new MutationObserver(function(){
    // only autoscroll if the user is already near the bottom
    if(sc.scrollHeight-sc.scrollTop-sc.clientHeight<140)sc.scrollTop=sc.scrollHeight;
  }).observe(sc,{childList:true,subtree:true});
})();
window.agentQA=function(t){var ta=document.getElementById('msg');ta.value=t;ta.dispatchEvent(new Event('input',{bubbles:true}));ta.focus();};
window.agentCopy=function(btn){
  var card=btn.closest('.runcard');
  var fc=card&&card.querySelector('.fullcode');
  var pre=card&&card.querySelector('pre');
  var t=fc?fc.value:(pre?pre.textContent:'');
  var done=function(okv){var lb=btn.querySelector('.btxt');if(lb){var o=lb.textContent;lb.textContent=okv?'copied':'copy failed';setTimeout(function(){lb.textContent=o;},1300);}};
  if(navigator.clipboard&&navigator.clipboard.writeText){
    navigator.clipboard.writeText(t).then(function(){done(true);},function(){fallback();});
  }else{fallback();}
  function fallback(){try{var x=document.createElement('textarea');x.value=t;document.body.appendChild(x);x.select();var okv=document.execCommand('copy');document.body.removeChild(x);done(okv);}catch(e){done(false);}}
};
function agentArr(a){return Array.isArray(a)?a:[];}
// Whimsical status pill: rotate a random word every ~2.8s + live elapsed timer.
window.__pillTimers=[];
window.__pillStart=function(){
  var p=document.getElementById('statuspill');if(!p)return;
  var words=window.__agentWords||["Working"];var t0=Date.now();
  p.style.display='inline-flex';
  var setw=function(){var w=p.querySelector('.pilltext');if(w)w.textContent=words[Math.floor(Math.random()*words.length)]+'u2026';};
  var sett=function(){var e=p.querySelector('.pilltime');if(e)e.textContent=Math.floor((Date.now()-t0)/1000)+'s';};
  setw();sett();
  window.__pillTimers.forEach(clearInterval);
  window.__pillTimers=[setInterval(setw,2800),setInterval(sett,1000)];
};
window.__pillStop=function(){
  var p=document.getElementById('statuspill');if(p)p.style.display='none';
  window.__pillTimers.forEach(clearInterval);window.__pillTimers=[];
};
Shiny.addCustomMessageHandler('agent-busy',function(x){
  window.__agentBusy=!!x.busy;var b=document.getElementById('send');
  if(b){if(x.busy)b.classList.add('disabled');else b.classList.remove('disabled');}
  if(x.busy)window.__pillStart();else window.__pillStop();
});
// Token-by-token streaming into a live card.
Shiny.addCustomMessageHandler('agent-append',function(x){
  var el=document.getElementById(x.id);if(!el)return;var t=el.querySelector('.sttext');if(t)t.textContent+=x.text;
});
Shiny.addCustomMessageHandler('agent-streamstop',function(x){
  var el=document.getElementById(x.id);if(!el)return;el.classList.remove('streaming');
  var c=el.querySelector('.caret');if(c)c.remove();
});
Shiny.addCustomMessageHandler('agent-setclass',function(x){
  var el=document.getElementById(x.id);if(!el)return;
  agentArr(x.remove).forEach(function(c){el.classList.remove(c);});
  agentArr(x.add).forEach(function(c){el.classList.add(c);});
  if(x.lbl){var l=el.querySelector('.lbl-t');if(l)l.textContent=x.lbl;}
  if(x.ic){var i=el.querySelector('.lbl-ic');if(i)i.innerHTML=x.ic;}
});
Shiny.addCustomMessageHandler('agent-clear',function(x){var el=document.getElementById('chatlog');if(el)el.innerHTML='';});
Shiny.addCustomMessageHandler('agent-cancel-running',function(x){
  document.querySelectorAll('.runcard.running').forEach(function(el){
    el.classList.remove('running');el.classList.add('cancelled');
    var t=el.querySelector('.lbl-t');if(t)t.textContent='cancelled';
    var i=el.querySelector('.lbl-ic');if(i)i.innerHTML='';
    var sp=el.querySelector('.spinner');if(sp)sp.remove();
  });
  document.querySelectorAll('.msg.streaming').forEach(function(el){
    el.classList.remove('streaming');var c=el.querySelector('.caret');if(c)c.remove();
  });
});
)--"

.qa_prompts <- list(
  list(icon = "chart",    label = "Analyze data",     text = "Look at the data frames in my environment with ls() and give me a concise summary and 3 insights about the most interesting one. If the environment is empty, say so and suggest a dataset."),
  list(icon = "trend",    label = "Plot",             text = "Create one insightful, well-labeled plot from the data in my environment (use mtcars if it is empty). Render it in the Plots pane and explain what it shows in 2 sentences."),
  list(icon = "bug",      label = "Debug last error", text = "Run geterrmessage() and, if useful, traceback() in my session. Diagnose the most recent error and fix it or tell me exactly what to change."),
  list(icon = "eraser",   label = "Tidy workspace",   text = "List the objects in my environment with sizes. Identify obvious temporary or duplicate objects, remove ONLY clearly disposable ones, and report exactly what you removed and kept."),
  list(icon = "filetext", label = "Explain project",  text = "List the files in the working directory, read the most important ones briefly, and explain what this project does in a short paragraph."))

# ---- UI ---------------------------------------------------------------------
agent_app_ui <- function(project_dir, model) {
  choices <- c("Sonnet" = "sonnet", "Opus" = "opus", "Haiku" = "haiku", "Fable 5" = "claude-fable-5")
  if (!(model %in% choices)) choices <- c(stats::setNames(model, model), choices)
  shiny::tagList(
    shiny::tags$head(shiny::tags$style(shiny::HTML(.agent_css))),
    shiny::tags$div(id = "agentwrap",
      shiny::tags$div(id = "agenthead",
        shiny::tags$span(class = "brand", shiny::tags$span(class = "logo", ic("logo", 15)),
          "Rflow", shiny::tags$span(class = "brandaccent", "Labs")),
        shiny::div(shiny::textInput("wd", NULL, value = project_dir)),
        shiny::tags$span(class = "grow"),
        shiny::tags$span(class = "pill", id = "statuspill", style = "display:none",
          shiny::tags$span(class = "pdot"),
          shiny::tags$span(class = "pilltext"),
          shiny::tags$span(class = "pilltime")),
        shiny::selectInput("model", NULL, choices, selected = model, selectize = FALSE, width = "100px"),
        shiny::actionButton("newchat",  label = ic("plus", 15),  class = "ibtn", title = "New conversation"),
        shiny::actionButton("stop",     label = ic("stop", 13),  class = "ibtn", title = "Stop current run"),
        shiny::actionButton("savechat", label = ic("save", 15),  class = "ibtn", title = "Save transcript"),
        shiny::actionButton("closeapp", label = ic("close", 15), class = "ibtn danger", title = "Close")),
      shiny::tags$div(id = "chatscroll",
        shiny::tags$div(id = "chatlog"),
        shiny::uiOutput("typing")),
      shiny::tags$div(id = "qarow",
        lapply(.qa_prompts, function(q) shiny::tags$button(class = "qa",
          onclick = paste0("agentQA(", jsonlite::toJSON(q$text, auto_unbox = TRUE), ")"),
          ic(q$icon, 13), q$label))),
      shiny::tags$div(id = "agentfoot",
        shiny::tags$div(class = "inputshell",
          shiny::textAreaInput("msg", NULL, value = "", rows = 3, width = "100%",
            placeholder = "Ask the agent to build, analyze, or plot\u2026  (Enter to send, Shift+Enter for newline)")),
        shiny::tags$div(class = "footrow",
          shiny::tags$span(id = "statsbar", shiny::uiOutput("stats", inline = TRUE)),
          shiny::actionButton("send", label = ic("send", 16), class = "sendbtn", title = "Send", onclick = "window.agentSend()")))),
    shiny::tags$script(shiny::HTML(paste0("window.__agentWords=", jsonlite::toJSON(.agent_words, auto_unbox = TRUE), ";"))),
    shiny::tags$script(shiny::HTML(.agent_js)))
}

.render_message <- function(m, dom_id, idx) {
  k <- m$kind
  if (k == "user") shiny::tags$div(id = dom_id, class = "msg user", m$text)
  else if (k == "assistant") shiny::tags$div(id = dom_id, class = "msg assistant", m$text)
  else if (k == "thinking") shiny::tags$div(id = dom_id, class = "msg thinking", ic("sparkles", 13), shiny::tags$span(substr(m$text, 1, 400)))
  else if (k == "stream_text") shiny::tags$div(id = dom_id, class = "msg assistant streaming",
    shiny::tags$span(class = "sttext"), shiny::tags$span(class = "caret"))
  else if (k == "stream_think") shiny::tags$div(id = dom_id, class = "msg thinking streaming",
    ic("sparkles", 13), shiny::tags$span(class = "sttext"), shiny::tags$span(class = "caret"))
  else if (k == "system") shiny::tags$div(id = dom_id, class = "msg system", m$text)
  else if (k == "tool_use") shiny::tags$div(id = dom_id, class = "msg card toolcard",
    shiny::tags$span(class = "tic", ic(m$icon %||% "wrench", 13)), shiny::tags$span(m$summary))
  else if (k == "run_code") shiny::tags$div(id = dom_id, class = "msg card runcard running",
    shiny::tags$div(class = "rchead",
      shiny::tags$span(class = "lbl",
        shiny::tags$span(class = "lbl-ic", shiny::tags$span(class = "spinner")),
        shiny::tags$span(class = "lbl-t", "running in your RStudio session")),
      shiny::tags$span(class = "rcbtns",
        shiny::tags$button(class = "mini", onclick = "agentCopy(this)", ic("copy", 11), shiny::tags$span(class = "btxt", "copy")),
        shiny::tags$button(class = "mini",
          onclick = sprintf("Shiny.setInputValue('insert_code',%d,{priority:'event'})", idx),
          ic("insert", 11), shiny::tags$span(class = "btxt", "to editor")))),
    shiny::tags$textarea(class = "fullcode", `aria-hidden` = "true", tabindex = "-1", m$code),
    shiny::tags$pre(substr(m$code, 1, 4000)))
  else if (k == "run_result") { if (!nzchar(trimws(m$text %||% ""))) return(NULL)
    shiny::tags$div(id = dom_id, class = paste("msg runout", if (isTRUE(m$is_error)) "err" else ""), shiny::tags$pre(substr(m$text, 1, 1500))) }
  else if (k == "files") shiny::tags$div(id = dom_id, class = "msg card filecard",
    shiny::tags$div(class = "lbl", ic("folder", 12), paste0("Files changed (", length(m$files), ")")),
    lapply(m$files, function(f) shiny::tags$span(class = "flink", title = f,
      onclick = paste0("Shiny.setInputValue('open_file',", jsonlite::toJSON(f, auto_unbox = TRUE), ",{priority:'event'})"),
      ic("filetext", 11), basename(f))))
  else if (k == "result") shiny::tags$div(id = dom_id, class = paste("msg result", if (isTRUE(m$is_error)) "err" else ""),
    ic(if (isTRUE(m$is_error)) "close" else "check", 12),
    shiny::tags$span(m$text %||% sprintf("done \u00b7 $%.4f", m$cost %||% 0)))
  else NULL
}

# ---- Server -----------------------------------------------------------------
agent_app_server <- function(input, output, session) {
  messages  <- shiny::reactiveVal(list())
  sid       <- shiny::reactiveVal(NULL)
  streaming <- shiny::reactiveVal(FALSE)
  phase     <- shiny::reactiveVal("")
  cur_proc  <- shiny::reactiveVal(NULL)
  gen       <- shiny::reactiveVal(0L)          # turn generation; stale callbacks are ignored
  total_cost<- shiny::reactiveVal(0)
  turns     <- shiny::reactiveVal(0L)
  last_dur  <- shiny::reactiveVal(NULL)
  turn_t0   <- shiny::reactiveVal(NULL)
  turn_snap <- shiny::reactiveVal(NULL)
  turn_wd   <- shiny::reactiveVal(NULL)
  turn_written <- shiny::reactiveVal(character())
  srv <- new.env(parent = emptyenv()); srv$proc <- NULL   # plain mirror for session-end cleanup
  srv$stream_id <- NULL; srv$stream_idx <- NULL; srv$stream_txt <- ""; srv$stream_final <- "assistant"
  srv$streamed_this_msg <- FALSE

  # Finalize an open streamed card: persist its text into messages() (so Save
  # captures it) and stop the caret. Shared by stream_stop, process-death
  # (on_done) and user abort so a stream is never left dangling.
  finalize_stream <- function(send_stop = TRUE) {
    if (is.null(srv$stream_id)) return(invisible())
    idx <- srv$stream_idx; ms <- shiny::isolate(messages())
    if (!is.null(idx) && idx >= 1 && idx <= length(ms)) { ms[[idx]]$kind <- srv$stream_final; ms[[idx]]$text <- srv$stream_txt; messages(ms) }
    if (send_stop) try(session$sendCustomMessage("agent-streamstop", list(id = srv$stream_id)), silent = TRUE)
    srv$stream_id <- NULL; srv$stream_idx <- NULL; srv$stream_txt <- ""
  }

  set_proc <- function(p) { srv$proc <- p; cur_proc(p) }

  ui_append <- function(m) {
    ms <- c(shiny::isolate(messages()), list(m)); messages(ms)
    idx <- length(ms); id <- paste0("am-", idx)
    ui <- .render_message(m, id, idx)
    if (!is.null(ui)) tryCatch(shiny::insertUI("#chatlog", "beforeEnd", ui = ui, immediate = TRUE, session = session),
                               error = function(e) NULL)
    id
  }

  # Cancel the current turn: invalidate its callbacks, kill the CLI, purge the
  # queue so no already-written run_r_code request executes after the abort.
  abort_turn <- function(notify_cancel = TRUE) {
    gen(shiny::isolate(gen()) + 1L)
    p <- srv$proc; if (!is.null(p) && inherits(p, "process") && p$is_alive()) try(p$kill(), silent = TRUE)
    purge_queue()
    finalize_stream(send_stop = FALSE)   # persist any partial reply; caret stripped by agent-cancel-running
    set_proc(NULL); streaming(FALSE); phase("")
    if (notify_cancel) try(session$sendCustomMessage("agent-cancel-running", list(ok = TRUE)), silent = TRUE)
  }

  # Bridge poller: run queued agent code in THIS session. Split-phase so the
  # animated "running" card renders before the (blocking) eval starts. Guarded
  # by generation + streaming so aborted/orphaned requests never execute.
  active <- TRUE
  session$onSessionEnded(function() {
    active <<- FALSE
    try({ p <- srv$proc; if (!is.null(p) && inherits(p, "process") && p$is_alive()) p$kill() }, silent = TRUE)
    try(purge_queue(), silent = TRUE)
  })
  process_bridge <- function() {
    if (!active) return()
    reschedule <- TRUE
    tryCatch({
      bd <- .agent_env$bridge_dir
      if (!is.null(bd) && dir.exists(bd)) {
        reqs <- list.files(bd, pattern = "^req-.*\\.json$", full.names = TRUE)
        if (length(reqs)) {
          if (!isTRUE(shiny::isolate(streaming()))) {
            suppressWarnings(unlink(reqs))     # no active turn -> orphaned requests, drop
          } else {
            rf <- reqs[order(file.info(reqs)$mtime)][1]
            r <- tryCatch(jsonlite::fromJSON(rf), error = function(e) NULL); suppressWarnings(unlink(rf))
            if (!is.null(r)) {
              g <- shiny::isolate(gen())
              dom_id <- shiny::withReactiveDomain(session, shiny::isolate({
                phase("running R in your session")
                ui_append(list(kind = "run_code", code = r$code))
              }))
              reschedule <- FALSE
              later::later(function() {
                tryCatch({
                  if (!active || !identical(shiny::isolate(gen()), g)) return()  # aborted/superseded -> skip
                  res <- tryCatch(agent_capture_eval(r$code),
                                  error = function(e) list(text = paste("Bridge eval error:", conditionMessage(e)), is_error = TRUE))
                  shiny::withReactiveDomain(session, shiny::isolate({
                    ok <- !isTRUE(res$is_error)
                    session$sendCustomMessage("agent-setclass", list(id = dom_id,
                      remove = list("running"), add = list(if (ok) "done" else "err"),
                      lbl = if (ok) "ran in your RStudio session" else "error in your RStudio session",
                      ic = as.character(ic(if (ok) "check" else "close", 12))))
                    if (nzchar(trimws(res$text)) && !identical(res$text, "(ran in session; no printed output)"))
                      ui_append(list(kind = "run_result", text = res$text, is_error = res$is_error))
                    phase("agent working")
                  }))
                  respf <- file.path(bd, paste0("resp-", r$id, ".json")); tmp <- paste0(respf, ".tmp")
                  writeLines(jsonlite::toJSON(list(id = r$id, text = res$text, is_error = res$is_error), auto_unbox = TRUE), tmp)
                  file.rename(tmp, respf)
                }, error = function(e) NULL)
                if (active) later::later(process_bridge, 0.1)   # always keep the poller alive
              }, delay = 0.15)
            }
          }
        }
      }
    }, error = function(e) NULL)
    if (reschedule && active) later::later(process_bridge, 0.2)
  }
  later::later(process_bridge, 0.4)

  shiny::observeEvent(input$msg_submit, {
    txt <- trimws((input$msg_submit$text) %||% "")
    if (!nzchar(txt) || isTRUE(streaming())) return()
    g <- shiny::isolate(gen()) + 1L; gen(g)              # start a new generation
    srv$stream_id <- NULL; srv$stream_idx <- NULL; srv$stream_txt <- ""; srv$streamed_this_msg <- FALSE
    ui_append(list(kind = "user", text = txt))
    session$sendInputMessage("msg", list(value = ""))
    streaming(TRUE); phase("starting agent")
    wd <- input$wd %||% getwd()
    turn_wd(wd); turn_t0(Sys.time()); turn_snap(snap_files(wd)); turn_written(character())
    dom <- shiny::getDefaultReactiveDomain()
    p <- agent_run(prompt = txt, project_dir = wd, model = input$model %||% "sonnet", session_id = sid(),
      on_message = function(m) shiny::withReactiveDomain(dom, shiny::isolate({
        if (!identical(gen(), g)) return()               # stale turn -> ignore
        if (!is.null(m$session_id)) sid(m$session_id)
        k <- m$kind
        if (identical(k, "msg_boundary")) {
          srv$streamed_this_msg <- FALSE
        } else if (identical(k, "stream_start")) {
          card <- if (identical(m$block, "thinking")) "stream_think" else "stream_text"
          srv$stream_final <- if (identical(m$block, "thinking")) "thinking" else "assistant"
          srv$stream_id <- ui_append(list(kind = card)); srv$stream_idx <- length(messages()); srv$stream_txt <- ""
        } else if (identical(k, "stream_delta")) {
          if (!isTRUE(m$thinking)) srv$streamed_this_msg <- TRUE
          if (!is.null(srv$stream_id)) {
            srv$stream_txt <- paste0(srv$stream_txt, m$text)
            session$sendCustomMessage("agent-append", list(id = srv$stream_id, text = m$text))
          }
        } else if (identical(k, "stream_stop")) {
          finalize_stream(send_stop = TRUE)
        } else if (identical(k, "assistant_fallback")) {
          if (!isTRUE(srv$streamed_this_msg)) ui_append(list(kind = "assistant", text = m$text))  # deltas never came
        } else if (identical(k, "result")) {
          if (!is.null(m$cost) && is.numeric(m$cost)) total_cost(total_cost() + m$cost)
          ui_append(m)                                   # success -> "done / $cost", error -> message
        } else {
          if (identical(k, "tool_use") && !is.null(m$path) &&
              m$tool %in% c("Write", "Edit", "MultiEdit", "NotebookEdit"))
            turn_written(unique(c(turn_written(), m$path)))
          ui_append(m)
        }
      })),
      on_done = function(s, err) shiny::withReactiveDomain(dom, shiny::isolate({
        if (!identical(gen(), g)) return()               # stale/aborted turn -> ignore
        finalize_stream(send_stop = TRUE)                # finalize any stream left open by process death
        if (!is.null(s)) sid(s)
        t0 <- turn_t0(); if (!is.null(t0)) last_dur(round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1))
        turns(turns() + 1L)
        ns <- snap_files(turn_wd()); os <- turn_snap() %||% stats::setNames(numeric(), character())
        created <- setdiff(names(ns), names(os))
        common <- intersect(names(ns), names(os))
        modified <- common[ns[common] > os[common] + 0.5]
        ch <- unique(c(created, modified))
        ch <- ch[!grepl("^rflowlabs_chat_", basename(ch))]     # never surface our own transcripts
        if (length(ch)) ui_append(list(kind = "files", files = utils::head(ch, 12)))
        # Auto-open code/doc files the agent wrote/edited (not data dumps or transcripts).
        tw <- turn_written()
        if (length(tw)) tw <- vapply(tw, function(f) if (file.exists(f)) f else file.path(turn_wd() %||% ".", f), character(1), USE.NAMES = FALSE)
        openable <- c("r", "rmd", "qmd", "md", "txt", "py", "sql", "json", "yaml", "yml")
        cand <- unique(c(tw, ch)); cand <- cand[file.exists(cand)]
        if (length(cand)) {
          sz <- file.info(cand)$size
          cand <- cand[tolower(tools::file_ext(cand)) %in% openable &
                       !grepl("^rflowlabs_chat_", basename(cand)) & !is.na(sz) & sz < 2e6]
        }
        if (length(cand) && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
          for (f in utils::head(cand, 5)) tryCatch(rstudioapi::navigateToFile(f), error = function(e) NULL)
        streaming(FALSE); phase(""); set_proc(NULL)
      })))
    set_proc(p)
  })

  shiny::observeEvent(input$stop, {
    was <- isTRUE(shiny::isolate(streaming()))
    abort_turn()
    if (was) ui_append(list(kind = "system", text = "stopped"))
  })

  shiny::observeEvent(input$newchat, {
    abort_turn()
    sid(NULL); messages(list()); total_cost(0); turns(0L); last_dur(NULL)
    session$sendCustomMessage("agent-clear", list(ok = TRUE))
  })

  shiny::observeEvent(input$closeapp, {
    abort_turn(notify_cancel = FALSE)
    active <<- FALSE
    shiny::stopApp()
  })

  shiny::observeEvent(input$savechat, {
    ms <- shiny::isolate(messages()); if (!length(ms)) { shiny::showNotification("Nothing to save yet", type = "warning"); return() }
    wd <- input$wd %||% getwd()
    stem <- file.path(wd, format(Sys.time(), "rflowlabs_chat_%Y%m%d-%H%M%S"))
    k <- 1L; while (file.exists(paste0(stem, ".md")) && k < 100L) { stem <- paste0(stem, "-", k); k <- k + 1L }
    md <- c("# RflowLabs transcript", paste0("_", format(Sys.time(), "%Y-%m-%d %H:%M"), "_"), "")
    code_all <- character()
    for (m in ms) {
      if (m$kind == "user") md <- c(md, paste0("## You: ", m$text), "")
      else if (m$kind == "assistant") md <- c(md, m$text, "")
      else if (m$kind == "tool_use") md <- c(md, paste0("- ", m$summary))
      else if (m$kind == "run_code") { md <- c(md, "", "```r", m$code, "```"); code_all <- c(code_all, m$code, "") }
      else if (m$kind == "run_result") md <- c(md, "```", substr(m$text, 1, 2000), "```", "")
      else if (m$kind == "files") md <- c(md, paste0("**Files changed:** ", paste(basename(m$files), collapse = ", ")), "")
      else if (m$kind %in% c("stream_text", "stream_think")) { if (nzchar(m$text %||% "")) md <- c(md, m$text, "") }  # unfinalized stream fallback
    }
    ok <- tryCatch({ writeLines(md, paste0(stem, ".md")); TRUE }, error = function(e) FALSE)
    rok <- if (ok && length(code_all)) tryCatch({ writeLines(code_all, paste0(stem, ".R")); TRUE }, error = function(e) FALSE) else FALSE
    if (ok) {
      shiny::showNotification(paste0("Saved ", basename(stem), ".md", if (rok) " + .R"), type = "message")
      if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
        tryCatch(rstudioapi::navigateToFile(paste0(stem, ".md")), error = function(e) NULL)
    } else shiny::showNotification("Could not write transcript (check the working directory)", type = "error")
  })

  shiny::observeEvent(input$insert_code, {
    i <- suppressWarnings(as.integer(input$insert_code))
    ms <- shiny::isolate(messages())
    if (!is.na(i) && i >= 1 && i <= length(ms) && identical(ms[[i]]$kind, "run_code")) {
      code <- ms[[i]]$code; done <- FALSE
      if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
        done <- tryCatch({ rstudioapi::insertText(text = paste0(code, "\n")); TRUE }, error = function(e) FALSE)
        if (!done) done <- tryCatch({ rstudioapi::sendToConsole(code, execute = FALSE); TRUE }, error = function(e) FALSE)
      }
      shiny::showNotification(if (done) "Inserted into RStudio" else "rstudioapi unavailable", type = if (done) "message" else "warning")
    }
  })

  shiny::observeEvent(input$open_file, {
    f <- input$open_file
    if (is.character(f) && file.exists(f) && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
      tryCatch(rstudioapi::navigateToFile(f), error = function(e) shiny::showNotification("Could not open file", type = "warning"))
  })

  # Reflect streaming state to the client (disables Send + Enter while working).
  shiny::observe({ session$sendCustomMessage("agent-busy", list(busy = isTRUE(streaming()))) })

  output$typing <- shiny::renderUI({
    if (isTRUE(streaming())) shiny::tags$div(class = "typing", shiny::tags$span(), shiny::tags$span(), shiny::tags$span())
  })
  output$stats <- shiny::renderUI({
    parts <- c(sprintf("$%s", formatC(total_cost(), format = "f", digits = 4)), paste0(turns(), " turn", if (turns() != 1L) "s"))
    if (!is.null(last_dur())) parts <- c(parts, paste0("last ", last_dur(), "s"))
    shiny::HTML(paste(parts, collapse = " \u00b7 "))
  })
}

# ---- Launcher ---------------------------------------------------------------
#' Launch the RflowLabs agentic coding assistant in RStudio
#'
#' Opens the RflowLabs Shiny gadget: an agentic coding assistant that runs on your
#' Claude Code subscription (no API key) and executes the agent's R in your live
#' RStudio session, so plots render in the Plots pane and objects appear in the
#' Environment while code and output stream into the gadget. `start_rflowlabs()`
#' is an alias for `start_agent()`.
#'
#' Requires the Claude Code CLI installed and logged in, plus the suggested
#' packages shiny, processx, and later (install with
#' `install.packages(c("shiny", "processx", "later"))`).
#'
#' @param project_dir Working directory for file operations (default `getwd()`).
#' @param model One of "sonnet" (default), "opus", "haiku", or a full model id
#'   (e.g. "claude-fable-5").
#' @param browser Open in an external browser instead of the RStudio viewer pane.
#' @return Invisible; called for the side effect of running the gadget.
#' @examples
#' \dontrun{
#' start_rflowlabs()
#' }
#' @export
start_agent <- function(project_dir = getwd(), model = "sonnet", browser = FALSE) {
  for (pkg in c("shiny", "processx", "later", "jsonlite"))
    if (!requireNamespace(pkg, quietly = TRUE)) stop("Package '", pkg, "' is required. install.packages('", pkg, "')")
  claude <- agent_find_claude()
  if (is.null(claude)) { message("Claude Code CLI not found. Install it, then retry."); return(invisible(FALSE)) }

  auth <- agent_check_auth(claude)
  if (!isTRUE(auth$ok)) {
    message("Sign-in was not completed. Run 'claude' in any terminal, finish /login, then relaunch.")
    return(invisible(FALSE))
  }
  message("Signed in as ", auth$email %||% "(account)", if (!is.null(auth$method)) paste0(" \u00b7 ", auth$method))

  .agent_env$bridge_dir <- file.path(tempdir(), paste0("rflowlabs_bridge_", as.integer(Sys.time())))
  dir.create(.agent_env$bridge_dir, showWarnings = FALSE, recursive = TRUE)
  .agent_env$bridge_script <- file.path(.agent_env$bridge_dir, "bridge_server.R")
  writeLines(.bridge_server_code, .agent_env$bridge_script)
  # Stable per-session MCP config (avoids a temp file per turn).
  rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
  if (.Platform$OS.type == "windows") rscript <- utils::shortPathName(rscript)
  cfg <- list(mcpServers = list(rstudio_bridge = list(command = rscript, args = list(.agent_env$bridge_script),
                                                      env = list(AGENT_BRIDGE_DIR = .agent_env$bridge_dir))))
  .agent_env$mcp_config <- file.path(.agent_env$bridge_dir, "mcp_config.json")
  writeLines(jsonlite::toJSON(cfg, auto_unbox = TRUE), .agent_env$mcp_config)

  message("RflowLabs \u2192 ", normalizePath(project_dir, mustWork = FALSE), "  (model: ", model, ")")
  message("The agent's R runs in THIS session: plots \u2192 Plots pane, vars \u2192 Environment.")
  viewer <- if (browser || !requireNamespace("rstudioapi", quietly = TRUE) || !rstudioapi::isAvailable()) shiny::browserViewer() else shiny::paneViewer(minHeight = 600)
  shiny::runGadget(agent_app_ui(normalizePath(project_dir, mustWork = FALSE), model), agent_app_server, viewer = viewer)
}

#' @rdname start_agent
#' @export
start_rflowlabs <- start_agent

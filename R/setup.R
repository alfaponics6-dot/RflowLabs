# Setup Claude client
setup_client <- function(client = NULL, call = rlang::caller_env()) {
  if (!is.null(client)) {
    if (inherits(client, "Chat")) {
      return(client)
    }
  }
  
  # Create Claude client
  setup_claude_client()
}

setup_claude_client <- function() {
  # Get API key from environment
  api_key <- Sys.getenv("ANTHROPIC_API_KEY", "")

  if (nchar(api_key) == 0) {
    stop(
      "Claude API key not found!\n\n",
      "Please set your Anthropic API key:\n",
      "  Sys.setenv(ANTHROPIC_API_KEY = \"your-claude-api-key\")\n\n",
      "Get your API key from: https://console.anthropic.com/\n"
    )
  }

  # Create client with Claude Sonnet 4.5
  # ellmer 0.4.0+ requires credentials as a function that returns the API key
  # This ensures the key is available even in background jobs
  client <- ellmer::chat_anthropic(
    model = "claude-sonnet-4-5",
    credentials = function() api_key
  )
  options(rflow.client = client)
  return(client)
}


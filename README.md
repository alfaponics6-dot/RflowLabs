<div align="center">

<img src="images/logo.png" width="200" alt="Rflow Logo">

# Rflow — MCP Server and R Toolkit for Claude Code

**Rflow** is an MCP (Model Context Protocol) server that gives Claude Code direct access to R. Drop a `.mcp.json` in your project and Claude Code gains 16 R tools — code execution, file analysis, Random Forest ML, R internals search, and more. No API key needed.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![R Version](https://img.shields.io/badge/R-%E2%89%A5%204.0.0-blue)](https://www.r-project.org/)
[![GitHub Stars](https://img.shields.io/github/stars/alfaponics6-dot/RflowLabs?style=social)](https://github.com/alfaponics6-dot/RflowLabs/stargazers)

</div>

## Features

### Core Capabilities
- **MCP Server** - 16 R tools exposed to Claude Code via JSON-RPC over stdin/stdout
- **R Code Execution** - Run any R code, capture output, plots saved automatically
- **File Analysis** - CSV, Excel, JSON, RDS, PDF, images, shapefiles, and more
- **R Internals Mastery** - Direct access to R 4.5.2 source code for deep understanding
- **Random Forest ML** - Train models on any dataset; specialized tools for agriculture
- **Workspace Management** - Folder/file context shared with Claude Code
- **No API Key** - Works with any Claude Code plan including Max subscriptions

## Installation

### Method 1: Direct Download (Recommended)

If you get GitHub API errors, use this method (100% reliable):

```r
# Includes automatic devtools installation
if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools"); options(timeout = 300); download.file("https://github.com/alfaponics6-dot/RflowLabs/archive/refs/heads/main.zip", "Rflow.zip", mode = "wb"); unzip("Rflow.zip"); devtools::install("RflowLabs-main")
```

Or if you prefer multi-line (copy ALL lines):

```r
# Auto-install devtools if needed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

options(timeout = 300)  # Extends timeout to 5 minutes
download.file(
  "https://github.com/alfaponics6-dot/RflowLabs/archive/refs/heads/main.zip",
  "Rflow.zip",
  mode = "wb"
)
unzip("Rflow.zip")
devtools::install("RflowLabs-main")
```

### Method 2: Standard GitHub Install

```r
# Auto-install remotes if needed
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# Set timeout and install from GitHub
options(timeout = 300)
remotes::install_github("alfaponics6-dot/RflowLabs")

# If the above fails, try different download method:
options(download.file.method = "wininet")
remotes::install_github("alfaponics6-dot/RflowLabs")
```

**Having issues?** See [INSTALL.md](INSTALL.md) for permanent solutions.

### Install Specific Version

```r
# Install v1.0.0 specifically
remotes::install_github("alfaponics6-dot/RflowLabs@v1.0.0")

# Install latest release (recommended for stability)
remotes::install_github("alfaponics6-dot/RflowLabs@*release")

# Install development version (main branch)
remotes::install_github("alfaponics6-dot/RflowLabs@main")
```

### Update Rflow

To update to the latest version:

```r
# Reinstall from GitHub
remotes::install_github("alfaponics6-dot/RflowLabs")
```

### Troubleshooting Installation

If installation fails:

```r
# Try with dependencies
remotes::install_github("alfaponics6-dot/RflowLabs", dependencies = TRUE)

# Or force reinstall
remotes::install_github("alfaponics6-dot/RflowLabs", force = TRUE)
```

## Quick Start

### With Claude Code (Recommended)

**1. Create `.mcp.json` in your project root:**
```json
{
  "mcpServers": {
    "rflow": {
      "command": "Rscript",
      "args": ["-e", "Rflow::start_mcp_server()"]
    }
  }
}
```

**2. Start Claude Code in that folder** — it auto-detects the file and loads all 16 R tools. Done.


## Usage Examples

Once `.mcp.json` is in your project root and Claude Code is open, just ask naturally:

```
"Run summary(lm(mpg ~ wt + cyl, data = mtcars)) and show me the results"
"Read the file data/results.csv and tell me what's in it"
"Train a Random Forest on iris to predict Species"
"Search the R source code for how do_subset is implemented"
"List all R files in the current directory"
"Create a directory called output and write a CSV there"
```

Claude Code dispatches each request to the correct Rflow tool automatically.

## Random Forest for Agriculture Analytics

Rflow includes specialized Random Forest machine learning tools designed for agriculture applications.

### Soil Analysis
```r
# Classify soil fertility (Low/Medium/High)
soil_data <- generate_ag_data("soil", n = 200)
result <- rf_soil_analysis(
  data = soil_data,
  target = "fertility",
  task_type = "classification"
)

# Predict NPK levels
npk_result <- rf_soil_analysis(
  data = soil_data,
  target = "nitrogen",
  task_type = "regression"
)
```

### Poultry and Fish Farming
```r
# Forecast egg production
poultry_data <- generate_ag_data("poultry", n = 250)
egg_result <- rf_poultry_fish(
  data = poultry_data,
  target = "egg_production",
  farm_type = "poultry"
)

# Predict fish growth
fish_data <- generate_ag_data("fish", n = 180)
fish_result <- rf_poultry_fish(
  data = fish_data,
  target = "weight_gain_g",
  farm_type = "fish"
)
```

### Crop and Disease Management
```r
# Classify crop diseases
disease_data <- generate_ag_data("disease", n = 300)
disease_result <- rf_agronomy(
  data = disease_data,
  target = "disease",
  task_type = "classification"
)

# Predict crop yield
yield_data <- generate_ag_data("yield", n = 200)
yield_result <- rf_agronomy(
  data = yield_data,
  target = "yield_kg_ha",
  task_type = "regression"
)
```

### Visualization Tools
```r
# Plot variable importance
plot_rf_importance(result, top_n = 8)

# Plot predictions vs actual
plot_rf_predictions(result)
```

**See [docs/random-forest-agriculture.md](docs/random-forest-agriculture.md) for complete documentation and examples.**

## MCP Server — Use Rflow from Claude Code (No API Key)

Rflow includes a full **Model Context Protocol (MCP) server** that exposes all 16 R tools directly to Claude Code. Users on a Claude Max subscription can use every Rflow capability without ever setting up an Anthropic API key.

### Setup (2 steps)

**Step 1 — Create `.mcp.json` in your project root:**

```json
{
  "mcpServers": {
    "rflow": {
      "command": "Rscript",
      "args": ["-e", "Rflow::start_mcp_server()"]
    }
  }
}
```

**Step 2 — Start Claude Code in that folder.** It auto-discovers `.mcp.json` and loads all tools.

That's it. Claude Code now has full access to R through Rflow.

### How it works

```
Claude Code  <--stdin/stdout JSON-RPC-->  Rscript -e "Rflow::start_mcp_server()"
                                                   |
                                         Rflow R tools execute directly
                                         (run R code, analyze files, RF, etc.)
```

### 16 Available MCP Tools

#### Code Execution

| Tool | Parameters | Description |
|------|-----------|-------------|
| `run_r_code` | `code`, `persist` | Execute any R code. Output, messages, warnings all captured. Plots saved to a temp PNG automatically. Set `persist=true` to run in the global environment. |

#### File Operations

| Tool | Parameters | Description |
|------|-----------|-------------|
| `read_text_file` | `path` | Read the full contents of any text file |
| `write_text_file` | `path`, `content` | Write or overwrite a file; parent directories created automatically |
| `analyze_file` | `file_path` | Smart file analysis — CSV, Excel, JSON, RDS, RData, R scripts, PDF, Word, images, shapefiles, and plain text |

#### File System

| Tool | Parameters | Description |
|------|-----------|-------------|
| `run_command` | `command`, `working_dir` | Execute a shell command and return its output |
| `create_directory` | `path`, `recursive` | Create a directory (and parents if needed) |
| `delete_path` | `path`, `recursive` | Delete a file or directory |
| `copy_path` | `from`, `to`, `overwrite` | Copy a file or directory |
| `move_path` | `from`, `to` | Move or rename a file or directory |
| `list_directory` | `path`, `pattern`, `recursive` | List directory contents with type and size info |

#### R Internals

| Tool | Parameters | Description |
|------|-----------|-------------|
| `search_r_source` | `pattern`, `path` | Regex search through R 4.5.2 C/R source code |
| `get_r_internals_info` | `topic` | Documentation on R internals: `architecture`, `memory`, `evaluation`, `parser`, `graphics`, `common_bugs`, or `all` |
| `find_r_function` | `func_name` | Locate where an R function is implemented (C or R level) |

#### Machine Learning

| Tool | Parameters | Description |
|------|-----------|-------------|
| `rf_train` | `data_expr`, `target`, `task_type` | Train a Random Forest on any dataset. `data_expr` is an R expression string like `"iris"` or `"read.csv('data.csv')"`. Returns performance metrics and variable importance. |

#### Workspace

| Tool | Parameters | Description |
|------|-----------|-------------|
| `get_workspace_context` | — | Full workspace context: current folder, open files, folder structure |
| `get_workspace_summary` | — | Concise human-readable workspace summary |

### Example: Train a model from Claude Code

Once `.mcp.json` is in place, just ask Claude Code:

```
"Train a Random Forest on iris to predict Species"
"Read and summarize the file analysis_results.csv"
"Run this R code: summary(lm(mpg ~ wt + cyl, data = mtcars))"
"Search the R source for how do_subset is implemented"
```

Claude Code dispatches to Rflow automatically — no copy-pasting, no switching apps.

---



## R Internals Mastery

Rflow has **direct access to R 4.5.2 source code** for unprecedented deep knowledge:

### What This Means
- **Search R source code** - Find exact implementations in C
- **Understand R internals** - Know how R actually works
- **Debug at source level** - See what R does under the hood
- **Explain edge cases** - Backed by actual R implementation
- **Performance insights** - Understand from algorithm level

### Key Capabilities
- **3 specialized tools** - search_r_source(), get_r_internals_info(), find_r_function()
- **180MB source code** - Complete R 4.5.2 interpreter and libraries
- **Instant search** - Regex search through all C and R source files
- **Built-in knowledge** - Documentation on SEXP types, GC, evaluation, parsing

### Example Questions It Can Answer
- "How does lazy evaluation actually work?" (shows PROMSXP in eval.c)
- "Why is my loop slow?" (explains allocVector() and copy-on-modify)
- "Why does 0.1 + 0.2 != 0.3?" (shows IEEE 754 in arithmetic.c)
- "How does the $ operator work?" (finds do_subset in subscript.c)

**See [docs/r-internals-guide.md](docs/r-internals-guide.md) for complete documentation.**


## Technical Details

### Architecture
- **Transport**: JSON-RPC 2.0 over stdin/stdout
- **Entry point**: `Rscript -e "Rflow::start_mcp_server()"`
- **Tools**: 16 tools registered with full JSON Schema definitions
- **Execution**: Tools run directly in the MCP server's R process
- **Graphics**: Plots captured to temp PNG files automatically

## Requirements

- **R >= 4.0**
- **Claude Code** (any plan, including Max)
- **R Packages** (auto-installed): cli, jsonlite, rappdirs, rlang, rstudioapi, stats, tools, utils

## Troubleshooting

### MCP server not detected
- Make sure `.mcp.json` is in the **project root** (same folder Claude Code opens)
- Verify Rflow is installed: `library(Rflow)` in R should work without errors
- Try running `Rscript -e "Rflow::start_mcp_server()"` manually — any startup error will print to the console

### Tool returns an error
- The error message is returned as the tool result — Claude Code will show it
- Run the same code in a plain R session to debug directly

## Best Practices

1. **Use `run_r_code` with `persist=true`** to build up objects across calls
2. **Use `analyze_file`** before working with a dataset — it loads the data into R automatically
3. **Plots are saved to temp files** — ask Claude Code to show you the path or copy it somewhere
4. **Use `get_workspace_summary`** to orient Claude Code to your project structure

## Resources

- [Claude Code](https://claude.ai/code)
- [ggplot2 Documentation](https://ggplot2.tidyverse.org/)
- [tidyverse Website](https://www.tidyverse.org/)
- [R for Data Science](https://r4ds.had.co.nz/)

## Support Development

Rflow is free and open source. If it saves you time or helps your research, please consider supporting its development:

- **Star this repository** - Help others discover Rflow
- **Zelle**: `cchery@earth.ac.cr`
- **Cash App**: `$CarlyCHERY0`
- **Report bugs** - Help improve Rflow
- **Spread the word** - Share with colleagues

## Contributing

Contributions are welcome! Please feel free to:
- [Report bugs](https://github.com/alfaponics6-dot/RflowLabs/issues)
- [Request features](https://github.com/alfaponics6-dot/RflowLabs/issues)
- Submit pull requests

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

<table>
<tr>
<td align="center">
<a href="https://github.com/alfaponics6-dot">
<img src="images/profile.png" width="150" style="border-radius: 50%;" alt="Carly Chery"/>
<br />
<sub><b>Carly Chery</b></sub>
</a>
<br />
<a href="mailto:cchery@earth.ac.cr">Email</a> |
<a href="https://github.com/alfaponics6-dot">GitHub</a>
</td>
</tr>
</table>

## Acknowledgments

- Built for [Claude Code](https://claude.ai/code) by Anthropic
- Uses the [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) standard

---

**Built for the R community**

**MCP Server for Claude Code | 16 R Tools | R 4.5.2 Source Code | No API Key Required**

**[Report Bug](https://github.com/alfaponics6-dot/RflowLabs/issues) | [Request Feature](https://github.com/alfaponics6-dot/RflowLabs/issues) | [View on GitHub](https://github.com/alfaponics6-dot/RflowLabs)**

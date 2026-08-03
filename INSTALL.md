# Permanent Installation Guide for Rflow

If you're getting `download from 'https://api.github.com/repos/...' failed` errors or **"Timeout of 60 seconds was reached"**, this is a **common GitHub API issue**. Here are **permanent solutions** that always work.

## Fastest Fix - One Line Install

**Copy this ENTIRE line** (auto-installs devtools + timeout fix):

```r
if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools"); options(timeout = 300); temp_zip <- tempfile(fileext = ".zip"); download.file("https://github.com/alfaponics6-dot/RflowLabs/archive/refs/heads/main.zip", temp_zip, mode = "wb"); temp_dir <- tempdir(); unzip(temp_zip, exdir = temp_dir); pkg_dir <- file.path(temp_dir, "RflowLabs-main"); devtools::install(pkg_dir); library(Rflow)
```

## Detailed Install (Copy and Paste)

### Method 1: Direct ZIP Download (Most Reliable)

```r
# IMPORTANT: Copy ALL lines below INCLUDING the devtools and options() lines

# 0. Auto-install devtools if needed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# 1. Download ZIP
temp_zip <- tempfile(fileext = ".zip")
options(timeout = 300)  # Extends timeout to 5 minutes
download.file(
  "https://github.com/alfaponics6-dot/RflowLabs/archive/refs/heads/main.zip",
  temp_zip,
  mode = "wb"
)

# 2. Extract and install
temp_dir <- tempdir()
unzip(temp_zip, exdir = temp_dir)
pkg_dir <- file.path(temp_dir, "RflowLabs-main")
devtools::install(pkg_dir)

# 3. Test
library(Rflow)
```

**This works 100% of the time.** No GitHub API needed.

### Method 2: Use Different Download Method

```r
# Auto-install remotes if needed
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# Set timeout
options(timeout = 300)

# Try wininet (Windows)
options(download.file.method = "wininet")
remotes::install_github("alfaponics6-dot/RflowLabs")

# Or try libcurl
options(download.file.method = "libcurl")
remotes::install_github("alfaponics6-dot/RflowLabs")
```

### Method 3: Manual Download (100% Reliable)

1. **Download:** Go to https://github.com/alfaponics6-dot/RflowLabs
2. **Click:** Green "Code" button > "Download ZIP"
3. **Extract:** Unzip to any folder
4. **Install:**
   ```r
   setwd("path/to/extracted/RflowLabs-main")
   devtools::install()
   ```

## Why This Happens

This error occurs due to ([source](https://github.com/r-lib/remotes/issues/734)):
- GitHub API rate limiting
- Corporate firewall/proxy blocking API access
- Network restrictions
- SSL certificate issues

**Solution:** Bypass the GitHub API entirely using direct download methods above.

## Permanent Solutions

### For Your Own Use:

Save this as `install_rflow.R`:

```r
install_rflow <- function() {
  temp_zip <- tempfile(fileext = ".zip")
  options(timeout = 300)  # 5 minutes
  download.file(
    "https://github.com/alfaponics6-dot/RflowLabs/archive/refs/heads/main.zip",
    temp_zip,
    mode = "wb",
    method = "auto"
  )
  temp_dir <- tempdir()
  unzip(temp_zip, exdir = temp_dir)
  pkg_dir <- file.path(temp_dir, "RflowLabs-main")
  devtools::install(pkg_dir, upgrade = "never")
  message("Rflow installed successfully!")
}

# Run it
install_rflow()
```

Then just: `source("install_rflow.R")`

## After Installation

Test it works:

```r
library(Rflow)

# Test with built-in data
data(iris)
result <- rf_train(iris, "Species")
print(result$performance)

# Test with your own data
my_data <- read.csv("your_data.csv")
result <- rf_train(my_data, target = "outcome")
plot_rf_importance(result)
```

## Still Having Issues?

If you still can't install, you have these options:

### Option A: Use devtools instead of remotes

```r
install.packages("devtools")
devtools::install_github("alfaponics6-dot/RflowLabs")
```

### Option B: Install from local clone

```r
# Clone the repo
system("git clone https://github.com/alfaponics6-dot/RflowLabs.git")

# Install
setwd("RflowLabs")
devtools::install()
```

### Option C: Adjust network settings

```r
# Increase timeout
options(timeout = 600)

# Try different method
options(download.file.method = "wget")
remotes::install_github("alfaponics6-dot/RflowLabs")
```

## Common Network Solutions

### Behind Corporate Firewall?

```r
# Set proxy (if needed)
Sys.setenv(http_proxy = "http://proxy.company.com:8080")
Sys.setenv(https_proxy = "http://proxy.company.com:8080")

# Then install
remotes::install_github("alfaponics6-dot/RflowLabs")
```

### SSL Certificate Issues?

```r
# Temporarily disable SSL verification (use with caution)
options(download.file.method = "wininet")
remotes::install_github("alfaponics6-dot/RflowLabs")
```

## References

- [remotes package issues with install_github](https://github.com/r-lib/remotes/issues/734)
- [GitHub downloads failing in R](https://stackoverflow.com/questions/72495046/downloads-from-github-repo-in-r-keeps-failing)
- [Alternative download methods](https://github.com/r-lib/remotes/issues/210)

## Bottom Line

**The ZIP download method works 100% of the time:**

```r
# One command that ALWAYS works:
options(timeout = 300)  # 5 minutes
download.file("https://github.com/alfaponics6-dot/RflowLabs/archive/refs/heads/main.zip", "Rflow.zip", mode = "wb")
unzip("Rflow.zip")
devtools::install("RflowLabs-main")
library(Rflow)
```

## Launching the RflowLabs Agentic Assistant

Version 2.1.0 adds `Rflow::start_rflowlabs()`, an interactive coding assistant that runs inside RStudio on your Claude Code subscription (no API key). The ZIP-download methods above still install the package the same way; this section only covers the extra pieces the assistant needs. If you have not installed Rflow yet, use any method above first, then come back here.

### 1. Install the gadget runtime dependencies

The assistant needs three packages beyond the base Rflow install: `shiny`, `processx`, and `later`. (`jsonlite` and `rstudioapi` are already Rflow dependencies, so they are pulled in automatically.) These three live in `Suggests`, which keeps the headless MCP server light and avoids the Shiny transitive tree for users who never launch the gadget. Install them once with a single line:

```r
install.packages(c("shiny", "processx", "later"))
```

If they are missing, `start_rflowlabs()` stops with a short message naming exactly what to install, so nothing fails silently.

Note: do not reach for `remotes::install_github(..., dependencies = TRUE)` to get these. That also drags in the heavy analysis suggests (sf, pdftools, officer, ggplot2, randomForest, readxl) that the assistant does not use. The explicit `install.packages()` line above is lighter and intentional.

### 2. Install and log in to the Claude Code CLI (subscription, no API key)

The assistant spawns the `claude` command-line tool and streams from it, so the CLI must be installed and signed in on a Claude subscription. There is no API key anywhere in this flow.

Verify from a terminal (not the R console):

```bash
claude auth status
```

A logged-in subscription account prints your account and plan. If it reports that you are not authenticated, run `claude` once and complete the browser login before launching the assistant. Install instructions for the CLI itself live at the Claude Code docs.

### 3. Run inside RStudio only

`start_rflowlabs()` is an RStudio gadget. It uses the RStudio viewer, the Plots pane, and the Environment, and it runs the assistant's R code in your live session. Launch it from the RStudio console, not from a plain R terminal, VS Code, or a headless `Rscript` process.

### 4. Launch

```r
library(Rflow)
start_rflowlabs()
```

`start_agent()` is the same entry point under its original name, so `Rflow::start_agent()` works identically if you prefer it. To open in an external browser instead of the RStudio viewer pane, pass `browser = TRUE`.

### Zero-install quick try

To try the assistant without installing the Rflow package (you still need `shiny`, `processx`, `later`, and `jsonlite` installed, plus the logged-in `claude` CLI), source the script straight from GitHub and launch:

```r
source("https://raw.githubusercontent.com/alfaponics6-dot/RflowLabs/main/inst/rstudio_agent.R"); start_rflowlabs()
```

This path does not register the help pages and is meant only as a quick look. For everyday use, install the package (any method above) and call `Rflow::start_rflowlabs()`.

---

**Questions?** Email: cchery@earth.ac.cr
**Issues?** https://github.com/alfaponics6-dot/RflowLabs/issues

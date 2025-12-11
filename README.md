<div align="center">

<img src="images/logo.png" width="200" alt="Rflow Logo">

# Rflow - Professional AI Assistant for RStudio

**Rflow** is an advanced AI coding assistant that lives inside RStudio. Get expert help with R programming, data analysis, visualization, and statistical modeling through a clean, professional chat interface.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![R Version](https://img.shields.io/badge/R-%E2%89%A5%204.0.0-blue)](https://www.r-project.org/)
[![GitHub Stars](https://img.shields.io/github/stars/carlychery2001/RflowLabs?style=social)](https://github.com/carlychery2001/RflowLabs/stargazers)

</div>

## ✨ Features

### 🎯 Core Capabilities
- **AI-Powered Analysis** - Claude Sonnet 4.5 with 1730+ expert training prompts
- **R Internals Mastery** - Direct access to R 4.5.2 source code for deep understanding
- **Publication-Level Plots** - 220 prompts dedicated to creating perfect visualizations
- **Direct R Integration** - Execute code, read/write files, inspect environment
- **Real-Time Streaming** - Fast, smooth responses with terminal-style events
- **Smart Data Loading** - One-click CSV/Excel upload and auto-load
- **Error Recovery** - Automatic retry logic, graceful timeout handling
- **Agriculture Analytics** - Random Forest ML for soil, livestock, and crop predictions

### 🚀 Performance
- **100+ chars/sec streaming** - 5x faster than before
- **Optimized rendering** - Cached renders, batched updates
- **Reliable connections** - 3x retry with exponential backoff
- **5-minute timeout** - No more infinite hangs

### 🎨 User Interface
- **Clean Flat Design** - Professional #0066FF blue theme
- **Terminal-Style Events** - Multiple progress indicators with checkmarks
- **Quick Action Buttons** - Load Data, Analyze, Plot, Model, Debug, Optimize
- **Syntax Highlighting** - Beautiful code blocks
- **Dark/Light Mode** - Toggle between themes

## 📦 Installation

### Method 1: Direct Download (Recommended - Always Works!)

If you get GitHub API errors, use this method (100% reliable):

```r
# ⚠️ COPY ALL LINES BELOW - Don't skip the options() line! ⚠️
options(timeout = 300); download.file("https://github.com/carlychery2001/RflowLabs/archive/refs/heads/main.zip", "Rflow.zip", mode = "wb"); unzip("Rflow.zip"); devtools::install("RflowLabs-main")
```

Or if you prefer multi-line (copy ALL lines including options):

```r
options(timeout = 300)  # ← CRITICAL: Must include this line!
download.file(
  "https://github.com/carlychery2001/RflowLabs/archive/refs/heads/main.zip",
  "Rflow.zip",
  mode = "wb"
)
unzip("Rflow.zip")
devtools::install("RflowLabs-main")
```

### Method 2: Standard GitHub Install

```r
# Install remotes (if needed)
install.packages("remotes")

# Install Rflow from GitHub
remotes::install_github("carlychery2001/RflowLabs")

# If the above fails, try:
options(download.file.method = "wininet")
remotes::install_github("carlychery2001/RflowLabs")
```

**Having issues?** See [INSTALL.md](INSTALL.md) for permanent solutions.

### Install Specific Version

```r
# Install v1.0.0 specifically
remotes::install_github("carlychery2001/RflowLabs@v1.0.0")

# Install latest release (recommended for stability)
remotes::install_github("carlychery2001/RflowLabs@*release")

# Install development version (main branch)
remotes::install_github("carlychery2001/RflowLabs@main")
```

### Update Rflow

To update to the latest version:

```r
# Reinstall from GitHub
remotes::install_github("carlychery2001/RflowLabs")
```

### Troubleshooting Installation

If installation fails:

```r
# Try with dependencies
remotes::install_github("carlychery2001/RflowLabs", dependencies = TRUE)

# Or force reinstall
remotes::install_github("carlychery2001/RflowLabs", force = TRUE)
```

## 🚀 Quick Start

### 1. Get Your API Key

Get your Claude API key from [Anthropic Console](https://console.anthropic.com/)

### 2. Set Up API Key

**Option A: For Current Session Only**
```r
# Set your API key (required)
Sys.setenv(ANTHROPIC_API_KEY = "sk-ant-api03-your-key-here")

# Verify it's set
Sys.getenv("ANTHROPIC_API_KEY")
```

**Option B: Permanent Setup (Recommended)**
```r
# Edit your .Renviron file
usethis::edit_r_environ()

# Add this line (replace with your actual key):
# ANTHROPIC_API_KEY=sk-ant-api03-your-key-here

# Save and restart R
```

### 3. Launch Rflow

```r
# Load the package
library(Rflow)

# Start Rflow in RStudio viewer
start_rflow()

# Or open in browser (if viewer is busy with maps/plots)
start_rflow(launch_in = "browser")
```

### 4. Stop Rflow

```r
# When you're done
stop_rflow()
```

## 💡 Usage Examples

### Load and Analyze Data

1. Click the **📎 paperclip** icon to attach your CSV/Excel file
2. Click **"Load Data"** button
3. Rflow will automatically:
   - Load the file into `my_data` variable
   - Show structure and summary
   - Check for missing values
   - Display first rows

### Create Publication Plots

```
You: "Create a publication-ready scatter plot of mpg vs wt from mtcars"

Rflow will:
✓ Load mtcars dataset
✓ Create ggplot2 visualization
✓ Apply professional theme
✓ Add proper labels and titles
✓ Use color-blind safe palette
✓ Export as 300 DPI PNG
```

### Build Statistical Models

```
You: "Build a linear regression model for mpg"

Rflow will:
✓ Check data availability
✓ Build lm() model
✓ Show diagnostics plots
✓ Report R², p-values, coefficients
✓ Interpret results
✓ Save script for reproducibility
```

### Debug Code

1. Paste your code or error message
2. Click **"Debug Code"** button
3. Rflow identifies issues and provides fixes

### Optimize Performance

Click **"Optimize"** to get suggestions for:
- Vectorization
- data.table/dplyr improvements
- Parallel processing
- Memory efficiency

## 🌾 Random Forest for Agriculture Analytics

Rflow now includes specialized Random Forest machine learning tools designed specifically for agriculture applications:

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

### Poultry & Fish Farming
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

### Crop & Disease Management
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

**See [RANDOM_FOREST_AGRICULTURE.md](RANDOM_FOREST_AGRICULTURE.md) for complete documentation and examples.**

## 🎓 Key Commands

### Quick Actions
- **Load Data** - Upload and load CSV/Excel files
- **Analyze Data** - EDA with summary statistics and plots
- **Create Plot** - Publication-ready ggplot2 visualizations
- **Build Model** - Statistical modeling with diagnostics
- **Debug Code** - Error detection and fixes
- **Optimize** - Performance improvements

### Chat Commands
```
"Load mtcars and show me a summary"
"Create a box plot of mpg by cylinder"
"Build a logistic regression for species prediction"
"Debug this error: Error in x$y : $ operator is invalid for atomic vectors"
"Optimize this loop: for(i in 1:nrow(df)) {...}"
```

## 🔧 Advanced Features

### Workspace Management
- Rflow automatically detects your working directory
- Shows available datasets in environment
- Saves all scripts to your project folder
- Never uses temp directories

### Session Persistence
- Chat history saved to SQLite database
- Resume conversations across sessions
- Export/import chat sessions

### Error Handling
- Automatic retry on network failures (3 attempts)
- Graceful timeout after 5 minutes
- Helpful error messages with suggestions
- Partial responses shown on interruption

## 📊 Expert Training

Rflow is powered by **1730 comprehensive training prompts**:

- **Foundation (1-1000)** - Core R, tidyverse, ggplot2, debugging
- **High-Performance (1001-1100)** - data.table, arrow, polars
- **Visualization (1101-1200)** - plotly, leaflet, gganimate
- **Statistics (1201-1300)** - Bayesian, ML, deep learning
- **Programming (1301-1400)** - OOP, rlang, async
- **Shiny (1401-1510)** - Modules, testing, deployment
- **Publication Plots (1511-1730)** - Perfect plots every time!

## 🔬 R Internals Mastery

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

**See R_INTERNALS_GUIDE.md for complete documentation**

## 🎨 Publication Plotting Expertise

220 dedicated prompts ensure every plot is publication-ready:

### ggplot2 Excellence (60 prompts)
- Professional themes (theme_minimal, theme_bw)
- Color-blind safe palettes (viridis, ColorBrewer)
- Proper DPI exports (300-600)
- Perfect axis labels with units

### Statistical Plots (40 prompts)
- Error bars and confidence intervals
- Q-Q plots and diagnostics
- Correlation matrices
- Forest plots and meta-analysis

### Professional Formatting (40 prompts)
- Consistent fonts (Arial, Helvetica)
- Scientific notation
- Decimal alignment
- Accessibility compliance

### Advanced Types (40 prompts)
- Manhattan plots, volcano plots
- Heatmaps with dendrograms
- Network graphs
- Time series visualizations

## 🛠️ Technical Details

### Architecture
- **Frontend**: Shiny with custom CSS/JavaScript
- **Backend**: R with socket-based tool execution
- **AI**: Claude Sonnet 4.5 via Anthropic API
- **Database**: SQLite for chat persistence
- **Tools**: ellmer for LLM integration

### Performance Optimizations
- 100ms update intervals (vs 15ms) for smoother streaming
- 50-character batching (vs 5) for efficiency
- Render caching to avoid redundant processing
- 5000-character buffers for better throughput

### Reliability Features
- 3x retry with exponential backoff (2s, 4s, 8s)
- 5-minute timeout protection
- Chunked tool calls (<100 lines per file)
- Graceful error handling with helpful messages

## 📝 Requirements

- **R >= 4.0**
- **RStudio**
- **Anthropic API key**
- **R Packages** (auto-installed):
  - shiny
  - ellmer
  - DBI
  - RSQLite
  - httr2
  - cli
  - glue
  - jsonlite

## 💰 Billing

You pay Anthropic directly based on API usage:
- **Claude Sonnet 4.5**: ~$3 per million tokens
- Typical chat: $0.01-0.05 per interaction
- See [Anthropic Pricing](https://www.anthropic.com/pricing)

## 🐛 Troubleshooting

### "API key not found"
```r
# Set your key
Sys.setenv(ANTHROPIC_API_KEY = "your-key")

# Verify
Sys.getenv("ANTHROPIC_API_KEY")
```

### "HTTP 401 Unauthorized" or "invalid x-api-key"

**Most common cause:** Hidden whitespace or formatting characters in your API key

```r
# ❌ WRONG - May include hidden characters from copy/paste
Sys.setenv(ANTHROPIC_API_KEY = " sk-ant-api03-...")  # Leading space

# ✅ CORRECT - Clean, direct assignment
Sys.setenv(ANTHROPIC_API_KEY = "sk-ant-api03-...")
```

**Solution:**
1. Get a fresh API key from https://console.anthropic.com/settings/keys
2. Copy it carefully (avoid selecting extra spaces)
3. Set it using `Sys.setenv()` directly - don't paste from colored console output
4. Verify it's clean: `cat(Sys.getenv("ANTHROPIC_API_KEY"))`

**If still failing:**
- Check that billing is configured in your Anthropic account
- Verify you haven't exceeded API rate limits
- Ensure the API key hasn't been revoked

### "Stream interrupted"
- Check internet connection
- Break request into smaller parts
- Rflow will auto-retry 3 times

### "No data found"
- Load data first: `data(mtcars)` or upload CSV
- Use "Load Data" quick action button

### App won't start
```r
# Restart Rflow
stop_rflow()
start_rflow()

# Check for errors in R console
```

## 🎯 Best Practices

1. **Start small** - Load data first, then analyze step-by-step
2. **Use quick actions** - Faster than typing full prompts
3. **Save scripts** - Rflow auto-saves, but review and organize
4. **Check data** - Always verify loaded datasets before modeling
5. **Export plots** - Save publication figures at 300+ DPI

## 📚 Resources

- [Anthropic API Docs](https://docs.anthropic.com/)
- [ggplot2 Documentation](https://ggplot2.tidyverse.org/)
- [tidyverse Website](https://www.tidyverse.org/)
- [R for Data Science](https://r4ds.had.co.nz/)

## 💝 Support Development

Rflow is free and open source. If it saves you time or helps your research/work, please consider supporting its development:

- ⭐ **Star this repository** - Help others discover Rflow
- 💵 **Zelle**: `cchery@earth.ac.cr`
- 💰 **Cash App**: `$CarlyCHERY0`
- 🐛 **Report bugs** - Help improve Rflow
- 🤝 **Spread the word** - Share with colleagues

Your support keeps Rflow maintained and improved. Thank you! 🙏

## 🤝 Contributing

Contributions are welcome! Please feel free to:
- [Report bugs](https://github.com/carlychery2001/RflowLabs/issues)
- [Request features](https://github.com/carlychery2001/RflowLabs/issues)
- Submit pull requests

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 👤 Author

<table>
<tr>
<td align="center">
<a href="https://github.com/carlychery2001">
<img src="images/profile.png" width="150" style="border-radius: 50%;" alt="Carly Chery"/>
<br />
<sub><b>Carly Chery</b></sub>
</a>
<br />
<a href="mailto:cchery@earth.ac.cr">📧 Email</a> •
<a href="https://github.com/carlychery2001">💻 GitHub</a>
</td>
</tr>
</table>

## 🙏 Acknowledgments

- Powered by [Claude Sonnet 4.5](https://www.anthropic.com/claude) from Anthropic
- Built with [shinychat](https://github.com/posit-dev/shinychat)
- Uses [ellmer](https://github.com/tidyverse/ellmer) for LLM integration

---

**Built with ❤️ for the R community**

**Powered by Claude Sonnet 4.5 | 1730 Expert Prompts | R 4.5.2 Source Code | Master-Level R Knowledge**

**[Report Bug](https://github.com/carlychery2001/RflowLabs/issues) | [Request Feature](https://github.com/carlychery2001/RflowLabs/issues) | [View on GitHub](https://github.com/carlychery2001/RflowLabs)**

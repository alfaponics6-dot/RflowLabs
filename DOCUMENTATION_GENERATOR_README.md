# Rflow Academic Documentation Generator

This Python script generates a professional academic-level Word document for the Rflow project.

## Features

The generated document includes:

✓ **Professional title page** with Rflow logo
✓ **Abstract** with keywords
✓ **Table of contents**
✓ **9 comprehensive chapters**:
  1. Introduction (Background, Motivation, Objectives)
  2. System Architecture (Overview, Frontend, Backend, AI Integration)
  3. Core Features (AI Analysis, R Internals, Plots, Integration)
  4. Technical Implementation (Tools, Performance, Reliability)
  5. Use Cases and Applications
  6. Performance Evaluation
  7. Installation and Setup
  8. Discussion
  9. Conclusion and Future Work

✓ **References** section
✓ **2 appendices** (Quick Start Guide, API Reference)
✓ **Acknowledgments**
✓ **~25+ pages** of academic content
✓ **Professional formatting** (Times New Roman, proper headings, justified text)

## Installation

### Step 1: Install Python (if not already installed)

Download from: https://www.python.org/downloads/

### Step 2: Install required package

Open Command Prompt or PowerShell in this directory and run:

```bash
pip install python-docx
```

Or install from requirements file:

```bash
pip install -r requirements.txt
```

## Usage

### Run the script:

```bash
python generate_academic_report.py
```

### Output:

The script will create a file named:
```
Rflow_Academic_Documentation_YYYYMMDD.docx
```

Where YYYYMMDD is today's date (e.g., `Rflow_Academic_Documentation_20250104.docx`)

## What Gets Generated

The document is formatted for academic submission with:

- **Title Page**: Centered logo, project title, version, date, author info
- **Professional Colors**: Headings in #0066FF (Rflow blue)
- **Standard Fonts**: Times New Roman 12pt for body, 11pt for references
- **Justified Text**: Academic-style paragraph alignment
- **Proper Citations**: Reference list formatted
- **Appendices**: Quick start guide and API reference

## Customization

To customize the document, edit `generate_academic_report.py`:

- Change colors: Modify `RGBColor(0, 102, 255)` values
- Add sections: Use `add_heading_with_style()` and `add_formatted_paragraph()`
- Change fonts: Modify `font.name` properties
- Adjust spacing: Change `Inches()` values

## Troubleshooting

### Error: "No module named 'docx'"
**Solution**: Install python-docx: `pip install python-docx`

### Error: "logo.png not found"
**Solution**: Make sure `images/logo.png` exists in the Rflow directory

### Document doesn't open
**Solution**: Make sure you have Microsoft Word or LibreOffice installed

## Requirements

- Python 3.6 or higher
- python-docx package
- images/logo.png file (included in repo)

## Author

**Carly Chery**
Email: cchery@earth.ac.cr
GitHub: https://github.com/carlychery2001/RflowLabs

---

**Generated with ❤️ for academic publication**

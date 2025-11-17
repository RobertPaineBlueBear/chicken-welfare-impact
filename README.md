# Chicken Welfare Impact Calculator

Calculate the animal welfare impact of chicken-containing foods.

## Setup

1. Place your FNDDS data file in `data/raw/`
2. Update the filename in `scripts/01_load_data.R`
3. Run the R pipeline:
```r
   source("scripts/01_load_data.R")
   source("scripts/02_calculate_impacts.R")
   source("scripts/03_export_json.R")
```
4. Open `website/index.html` in your browser

## Project Structure

- `data/raw/` - Original FNDDS data
- `data/processed/` - Intermediate R data files
- `scripts/` - R processing scripts
- `output/` - JSON output for website
- `website/` - Web application files

## Data Sources

- FNDDS 2021-2023
- Faunalytics Impact Methodology
- Welfare Footprint Project
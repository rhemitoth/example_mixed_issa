# example_mixed_issa

This repository contains example code for running an integrated Step Selection Analysis (iSSA) with mixed effects.

## Required Packages

Before running the code, ensure the following R packages are installed:

- `terra`  
- `tidyverse`  
- `lubridate`  
- `amt`  
- `parallel`  
- `glmmTMB`

You can install any missing packages with the following code:

```
required_packages <- c("terra", "lubridate", "tidyverse", "amt", "parallel", "glmmTMB")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))
```

## How to Run the Analysis

1. **Generate used and available steps**  
   Run `used_avail_prewolf.R` to create the dataset of used and available steps.  
   - This script sources `GPS_Data_Summary.R` to retrieve individual IDs from the pre-wolf period.  
   - Output: an `.RData` file containing the used and available steps.

2. **Extract covariates**  
   Run `extract_covariates.R` to extract covariate values at the used and available step locations.  
   - Input: the `.RData` file generated in Step 1.  
   - This script sources `Load_NDVI.R` (for NDVI data) and `Load_Human_Settlement.R` (for human settlement data).  
   - Output: an `.RData` file with covariates added.

3. **Fit mixed-effects iSSA models**  
   Run `model_fitting.R` to fit the models.  
   - Input: the `.RData` file from Step 2.

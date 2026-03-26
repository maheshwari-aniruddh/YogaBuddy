# Testing Script Implementation Plan

## Goal Description
Create a script `test_archive.py` to load the trained model (saved by `research3.py`) and evaluate its performance on a separate dataset located in `archive/yes` and `archive/no`.

## User Review Required
> [!NOTE]
> The `test_archive.py` script will be designed to find the specific model file generated today (e.g., `model_2025-12-23.h5`).

## Proposed Changes
### New Script
#### [NEW] [test_archive.py](file:///Users/aniruddhmodi/Downloads/Research/test_archive.py)
- **Imports**: `tensorflow`, `numpy`, `cv2`, `skimage`, `sklearn` (same as training).
- **Functions**: Reuse preprocessing functions from `research3.py`:
    - `crop_image_based_on_threshold`
    - `load_images_from_folder`
    - `extract_hog_features_batch`
    - `extract_lbp_features_batch`
- **Logic**:
    1.  Define paths: `archive/yes` and `archive/no`.
    2.  Load data and labels (1 for yes, 0 for no).
    3.  Preprocess (resize, normalize).
    4.  Extract features (HOG, LBP).
    5.  Load correct model file (`model_YYYY-MM-DD.h5`).
    6.  Evaluate using `model.evaluate()` or manual prediction + metrics (Accuracy, Precision, Recall, F1, Confusion Matrix).
    7.  Print detailed report.

## Verification Plan
### Automated Tests
- Run `python3 test_archive.py` after the main training script finishes.

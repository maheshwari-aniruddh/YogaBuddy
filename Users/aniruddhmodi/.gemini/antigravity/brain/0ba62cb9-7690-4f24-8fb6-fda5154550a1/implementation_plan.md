# Implementation Plan: Optimize Ablation Experiments for M2 Pro

This plan addresses the user requests to optimize the existing ablation study for M2 Pro (Apple Silicon), add comprehensive training/validation metrics, and enable SHAP analysis for feature importance comparison.

## User Review Required
> [!IMPORTANT]
> I will be enabling the `COMBINED` mode in `run_ablation.sh` to answer the user's specific question about "which of the two feature extraction methods... helps most". This will add execution time but is necessary for the comparative SHAP analysis.

## Proposed Changes

### Research Code
#### [MODIFY] [research_ablation.py](file:///Users/aniruddhmodi/Downloads/Research/research_ablation.py)
- **Metrics**: Added Precision, Recall, and F1 for training set.
- **SHAP Fix**: Switched from `GradientExplainer` (broken in Keras 3) to `shap.KernelExplainer` (model-agnostic).
- **Callbacks**: Synchronized `ReduceLROnPlateau` and `EarlyStopping` parameters with `research3.py` for consistency.

#### [MODIFY] [research3.py](file:///Users/aniruddhmodi/Downloads/Research/research3.py)
- **SHAP**: Appended SHAP extraction code using `KernelExplainer` to the end of the script to enable feature importance analysis for the Combined model.

### Script Wrapper
#### [MODIFY] [run_ablation.sh](file:///Users/aniruddhmodi/Downloads/Research/run_ablation.sh)
- **Combined Mode**: Changed the 3rd experiment step to run `python3 research3.py` instead of `research_ablation.py --mode COMBINED`, as per user request to use the "research 3" code for the combined model.

## Verification Plan
1.  **Automated Execution**: The `run_ablation.sh` script is currently running all three experiments.
2.  **Monitoring**: Periodic checks of `nohup.out` to track ETA and catch potential SHAP errors.
3.  **Output Validation**: Verify generation of `shap_values_*.pkl` and `shap_*.png` files.

## Colab Migration Strategy
To address SHAP analysis requests efficiently, I created specialized notebooks:
- **Research_Ablation_Colab_FINAL.ipynb**: Runs *only* the Combined experiment. It aggregates Shapley values to produce a direct "HOG vs LBP" importance ratio, skipping pixel-level heatmaps to focus on feature contribution.

# Skip Final Training Optimization Plan

## Goal Description
The user requested to run only 5 folds of cross-validation and skip the subsequent "training on full dataset" phase. This change optimizes the runtime by removing a redundant training pass, trusting the cross-validation models for feature importance analysis.

## Proposed Changes

### Research Codebase
#### [MODIFY] [research_ablation.py](file:///Users/aniruddhmodi/Downloads/Research/research_ablation.py)
- **Remove/Comment Out**: The section `TRAINING FINAL MODEL ON FULL DATASET` which trained a fresh model on all data for 50 epochs.
- **Reuse Model**: Instead of training a new model, reuse the model instance from the last iteration of the Cross-Validation loop (Fold 5).
- **Adapt SHAP**: Ensure the SHAP analysis uses this reused model.

## Verification Plan
### Automated Tests
- **Run LBP Experiment**: The `run_ablation.sh` script will automatically trigger the LBP run.
- **Check Logs**: Verify in `lbp_training.log` that the "SKIPPING FINAL MODEL TRAINING" message appears and SHAP plots are still generated.

### Manual Verification
- Observe the runtime. The LBP experiment should finish immediately after the 5th fold without the extra ~40 minute training block.

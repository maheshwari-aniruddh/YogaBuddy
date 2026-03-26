# Google Colab Migration Plan

## Objective
Migrate the existing ablation study and research experiments to Google Colab for faster execution on NVIDIA GPUs.

## Steps
1.  **Consolidate Code**: Create a single `.ipynb` notebook that contains:
    *   Setup cells (mounting Drive, installing dependencies).
    *   Data loading verification (handling paths).
    *   The core logic from `research_ablation.py` (HOG/LBP modes).
    *   The core logic from `research3.py` (Combined mode).
2.  **Handle Data**: Provide clear instructions on how to structure the `thousand_image` dataset (e.g., zip it and upload).
3.  **Dependencies**: Ensure `shap` and other libraries are pip-installed in the notebook.
4.  **Execution**: Run the notebook to verify (locally) or provide it to the user.

## Notebook Structure
- **Cell 1**: Installation (`!pip install shap`)
- **Cell 2**: Imports & Drive Mount
- **Cell 3**: Dataset Unzipping & Path Setup
- **Cell 4**: Helper Functions (Image Loading, Feature Extraction)
- **Cell 5**: Experiment 1 (HOG) Class/Function
- **Cell 6**: Experiment 2 (LBP) Class/Function
- **Cell 7**: Experiment 3 (Combined) - Logic from `research3.py`
- **Cell 8**: Main Execution Block (Runner)

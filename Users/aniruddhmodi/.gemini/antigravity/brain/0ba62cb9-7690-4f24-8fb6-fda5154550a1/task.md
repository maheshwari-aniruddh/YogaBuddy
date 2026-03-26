- [ ] Synchronize `research_ablation.py` with `research3.py`
    - [x] Print ETA after each epoch
    - [x] Add SHAP (KernelExplainer) to `research3.py`
    - [ ] Implement "Balanced Architecture" to force LBP importance
    - [x] Create `research3_balanced.py` with equalized projections (128-dim)
    - [x] Configure Modality Dropout (High on HOG/Image, Low on LBP)
    - [-] Train and Verify (Deferred by User request for Ablation)

- [/] Run Full Ablation Metrics (HOG/LBP/Combined) - No SHAP
    - [/] Training HOG...
    - [ ] Training LBP...
    - [ ] Training Combined...
    - [ ] Generate Accuracy Comparison Table Analysis (HOG vs LBP) - Result: HOG is ~978x more important (Meta-SHAP verified)
    - [x] Run Batch SHAP on all .h5 models (Table Generated)
    
- [x] Migrate to Google Colab
    - [x] Zip `thousand_image` dataset
    - [x] Create `Research_Ablation_Colab.ipynb` (Full Suite)
    - [x] Create `Research_Ablation_Colab_FINAL.ipynb` (Combined Only + HOG vs LBP SHAP)
    - [x] Provide instructions for upload and execution

- [x] Answer User Questions (Slowness & Exactness)

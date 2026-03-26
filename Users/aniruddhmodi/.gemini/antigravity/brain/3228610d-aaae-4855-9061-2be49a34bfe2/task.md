# EfficientNet-B0 Ablation Study on BT-MRI Dataset

- [x] Explore project structure and dataset
- [x] Install dependencies (torch, torchvision, timm, scikit-image, etc.)
- [x] Write implementation plan for ablation study
- [x] Implement `main.py` with ablation study (4 configs, 20% data, save models with labels)
- [x] Refactor `predict.py` to gracefully handle OOD (hiding confidence, etc.)
- [x] Evaluate updated `predict.py` on test images (`image copy 3.png`, `image copy 5.png`)
- [x] Create `eval_new_dataset.py` and run on "Brain Cancer - MRI dataset"
- [x] Implement robust preprocessing (CLAHE) across all scripts (`main.py`, `eval*.py`, `predict.py`)
- [x] Add CLAHE to the `raw_transforms` so HOG and GLCM extract features from normalized lighting
- [x] Hashed, deduplicated, and combined the 7k and 10k datasets into a single 23k image master dataset
- [x] Refactored all evaluation and inference scripts to use EfficientNet-B3 and 300x300 images
- [x] Combine BT-MRI Dataset, 7k, and 10k datasets into one training pool
- [x] Retrain `efficientnet_b3` models from scratch on CLAHE-normalized, combined 23k data
- [x] Recompute OOD statistics (`ood_stats.pt`) on CLAHE-normalized B3 features
- [x] Evaluate `efficientnet_b3_hog_aug` on the 17-class independent holdout dataset

# Super Dataset & Outlier Exposure

- [x] Run `build_super_dataset.py` to merge everything and create the 5th `Unknown_OOD` class
- [x] Update `main.py` configuration to use 5 classes and `Super_Dataset`
- [x] Update `eval.py` and `predict.py` to natively support the `Unknown_OOD` class
- [x] Retrain `efficientnet_b3_hog_aug` on the massive new dataset
- [x] Evaluate the new Super Model to prove robustness
- [x] Research novelty of hybrid approach (CNN + HOG + GLCM + Outlier Exposure)
- [x] Final project wrap-up and documentation

# Data Leakage Fix

- [x] Modify `eval_new_dataset.py` to filter out training images by hash
- [x] Re-run honest evaluation on unseen-only images
- [x] Update walkthrough with corrected metrics

# NLM Ablation Experiment

- [/] Train 2x EfficientNet-B0 on noisy dataset (with/without NLM), test on 25% holdout

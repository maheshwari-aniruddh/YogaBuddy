# Task: Restore Missing Hybrid Training Script

- [x] Search for existing training script with LBP <!-- id: 0 -->
- [ ] Create implementation plan for `cnn_hog_lbp.py` <!-- id: 1 -->
- [x] Implement `cnn_hog_lbp.py` <!-- id: 2 -->
    - [x] Import LBP feature extraction from `prediction.py`
    - [x] Modify model architecture to accept 3 inputs (Image, HOG, LBP)
    - [x] Update data loading to compute LBP features
- [x] Verify the new training script runs <!-- id: 3 -->
- [x] Configure `cnn_hog_lbp.py` for `brd_2.0 copy` and MPS <!-- id: 4 -->
- [x] Install `tensorflow-metal` <!-- id: 5 -->
- [/] Run training (50 epochs, 5 folds) on GPU (MPS) <!-- id: 6 -->
    - [x] Fold 1 Complete (Val Acc: ~97%)
    - [/] Fold 2 In Progress
- [x] Compare pixel values of `thousand_image` vs `brd_2.0` (0 overlaps) <!-- id: 7 -->
- [x] Create validation script `validate_on_thousand.py` <!-- id: 8 -->
- [/] Run validation script (waiting for model) <!-- id: 9 -->

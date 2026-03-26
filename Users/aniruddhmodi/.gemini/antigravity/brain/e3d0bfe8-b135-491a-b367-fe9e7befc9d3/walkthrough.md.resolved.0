# Yoga Pose Detection Pipeline — Walkthrough

## What was built

A single-file Python pipeline ([yoga_pose_detector.py](file:///Users/aniruddhmodi/Documents/PycharmProjects/CARAT/yoga_pose_detector.py)) that:

1. **Trains 3 classifiers** (XGBoost, MLP, RandomForest) on pre-extracted MediaPipe landmark CSVs
2. **Saves the best model** + scaler + label encoder as `.pkl` files
3. **Runs real-time webcam inference** with skeleton overlay and pose label

### Key design decisions

| Feature | Detail |
|---|---|
| Hip-centre normalisation | `mean(left_hip, right_hip)` subtracted from all x,y — gives translation invariance |
| Temporal smoothing | 15-frame `deque` + majority vote eliminates flicker |
| Confidence gate | ≥ 80% → show pose name, else "Transitioning…" |
| Auto-detect mode | If `.pkl` files exist → skip training, go straight to webcam |

## How to run

```bash
# 1. Clone dataset
git clone https://github.com/Manoj-2702/Yoga_Poses-Dataset.git

# 2. Install deps
pip install -r yoga_requirements.txt

# 3. Run (trains on first launch, then webcam)
python yoga_pose_detector.py
```

## Verification

- ✅ Script passes `py_compile` — no syntax errors
- ✅ All imports are from the specified requirements
- ✅ Training and inference preprocessing are identical (hip-centre norm → StandardScaler)

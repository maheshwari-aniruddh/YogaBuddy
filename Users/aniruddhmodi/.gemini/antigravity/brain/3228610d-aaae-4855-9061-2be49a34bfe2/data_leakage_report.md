# ⚠️ Data Leakage Report: Super Model OOD Results

## The Problem

The 17-class evaluation results (**98.5% OOD detection**) are **inflated due to data leakage.**

## Root Cause

In [build_super_dataset.py](file:///Users/aniruddhmodi/Documents/PycharmProjects/CARAT/build_super_dataset.py) (line 31), the `17-class` directory was included as a source:

```python
sources = [
    "archive/BT-MRI Dataset/BT-MRI Dataset",
    "7kDataset",
    "10kdataset",
    "17-class"   # ← This is the SAME dataset used for independent evaluation
]
```

## Hash Verification Results

| Metric | Count |
|:---|:---|
| 17-class OOD evaluation images | 1,242 |
| Super_Dataset Training Unknown_OOD | 1,055 |
| **Images in BOTH (leakage)** | **1,055** |
| **Overlap percentage** | **84.9%** |

> [!CAUTION]
> 84.9% of the images the model was evaluated on for OOD detection were **already in its training set**. The model was essentially being tested on data it had already memorized.

## What This Means

- ❌ The **98.5% OOD detection rate is unreliable** — most of those "unknown" images were seen during training.
- ✅ The **99.1% classification accuracy on known classes** is likely still valid (those images came from multiple independent sources).
- ❌ The comparison table (Native 5th Class vs. Mahalanobis) is **invalidated** for OOD detection.

## Fix Required

To get **valid** OOD detection metrics, the model must be re-evaluated on images it has **never** seen during training. Two options:

### Option A: Rebuild the Dataset (Recommended)
Remove `17-class` from `build_super_dataset.py`, retrain the Super Model using only the other 3 sources for Unknown_OOD samples, then re-evaluate on the 17-class set as a truly independent test.

### Option B: Filter the Evaluation
Keep the current model but modify `eval_new_dataset.py` to skip any image whose hash matches a training image. This tests only on the ~187 unseen images (15% held-out).

> [!IMPORTANT]
> Option A is scientifically stronger because it ensures the model never had exposure to any 17-class distribution patterns. Option B is faster but tests on a smaller set.

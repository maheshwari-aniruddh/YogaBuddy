# NLM Preprocessing Integration Plan

## Goal Description
The objective is to integrate Non-Local Means (NLM) denoising as a preprocessing stage across the entire modeling pipeline. This includes the main training script (`main.py`) and all inference-related scripts, ensuring that NLM is applied consistently before feature extraction (HOG/GLCM) and model inference.

## Proposed Changes

### 1. Update Core Transformation Utilities
Across all relevant scripts, we need to introduce the `ApplyNLM` class and ensure the necessary imports are present:
```python
from skimage.restoration import denoise_nl_means, estimate_sigma

class ApplyNLM:
    """Apply Non-Local Means denoising to a PIL image."""
    def __call__(self, img):
        img_np = np.array(img).astype(np.float64) / 255.0
        sigma_est = np.mean(estimate_sigma(img_np, channel_axis=-1))
        denoised = denoise_nl_means(
            img_np, h=1.2 * sigma_est, fast_mode=True,
            patch_size=5, patch_distance=6, channel_axis=-1
        )
        denoised_uint8 = (np.clip(denoised, 0, 1) * 255).astype(np.uint8)
        return Image.fromarray(denoised_uint8)
```

### 2. Update Training Script (`main.py`)
- Add `ApplyNLM()` to the beginning of `train_transforms`, `test_transforms`, and `raw_transforms`.
- This ensures that both the CNN backbone and the engineered features (HOG/GLCM) receive the NLM-denoised image.
- Retrain the "massive super model" by running `python main.py` and capturing the newly generated/cached features. Note that the existing feature cache should be cleared or renamed since the images will now be modified by NLM before feature extraction.

### 3. Update Inference Scripts
Apply `ApplyNLM()` as the first step in the transformation pipeline for the following scripts:
- `predict.py`
- `predict_batch.py`
- `eval.py`
- `eval_new_dataset.py`
- `eval_ood.py`
- `compute_ood_stats.py`
- `shap_analysis.py`
- `shap_analysis_hog.py`
- `eval_clean_noisy_model.py`

## User Review Required
> [!IMPORTANT]
> - By applying NLM denoising the feature caching mechanism in `main.py` needs to store new features since the input images to HOG/GLCM will change. I will modify the cache key (e.g., adding `_nlm` to the cache filename) so it naturally computes new features.
> - The training of `main.py` can be quite long. I will initiate the training run as requested. Do you want me to wait for it to finish, or just start the process?

## Verification Plan

### Automated Tests
- Run one of the inference scripts (`predict.py` with a sample image) to ensure the NLM preprocessing runs without errors and outputs a valid prediction.
- Run `eval.py` on a small subset (or just verify it starts correctly) to check batch processing.

### Manual Verification
- The user can review the plots and metrics outputted by `main.py` (e.g., `ablation_results.png`) after training completes to verify performance.

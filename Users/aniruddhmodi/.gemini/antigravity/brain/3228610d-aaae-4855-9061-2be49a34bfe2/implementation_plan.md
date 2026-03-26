# Improving Generalization: Super-Dataset Construction

The goal is to prevent the model from memorizing the specific MRI machines (domain shift) and instead force it to learn actual biological tumor features. This will make the model perform well "in general" on *any* dataset. 

To achieve this, we will build a massive, highly diverse dataset that includes both the original 23k images and the new 17-class image variations. We will also introduce **Outlier Exposure (OE)** by explicitly training the model on what an "Unknown" tumor looks like.

## Proposed Changes

### 1. Re-combine Datasets (`build_super_dataset.py`)
We will create a new script to perfectly merge the 23k dataset with the 17-class dataset.

*   **Known Classes (4):** Images of Glioma, Meningioma, No-tumor, and Pituitary from the `17-class` folder will be merged into their respective folders in the `Combined_Dataset`. This forces the model to learn that a Glioma can look like it came from *either* type of MRI scanner.
*   **Outlier Class (1):** We will create a brand new 5th class called `Unknown_OOD`. All images from the 9 abnormal folders in the `17-class` dataset (like Schwannomas, Neurocitomas, etc.) will be moved here. 

### 2. Update Model Architecture (`main.py`)
*   Change the model output heads from `4` classes to `5` classes.
*   The model will be trained to strictly predict `Unknown_OOD` when it sees something weird, rather than forcing a guess or relying on the flawed Mahalanobis distance.

### 3. Update Evaluation & Inference (`predict.py`, `eval.py`)
*   Update evaluation scripts to expect 5 classes.
*   If the model's top prediction is `Unknown_OOD`, the system will automatically flag the image as an anomaly/OOD and refuse to classify it as a standard tumor.

## Verification Plan

### Automated Tests
1.  Run the dataset combining script and verify the image counts perfectly match the sum of their parts minus duplicates.
2.  Retrain the `efficientnet_b3_hog_aug` model on this new 5-class dataset.
3.  Re-run `eval_new_dataset.py` to prove that the model's accuracy on the seen *and* unseen scanner styles has stabilized.

### Manual Verification
*   We will check the confusion matrix to ensure that the actual `OOD` images are successfully being swept into the 5th `Unknown_OOD` category without needing complex probability distance math.

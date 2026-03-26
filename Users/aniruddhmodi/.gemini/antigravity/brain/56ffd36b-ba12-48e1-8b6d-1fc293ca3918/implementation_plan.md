# specific instructions on how to run the test so another agent can run the test.
# Trash Detection Implementation Plan

## Goal
Train a YOLOv8 classification model using the local "garbage-dataset".

## Proposed Changes

### Data Preparation
#### [NEW] [split_data.py](file:///Users/aniruddhmodi/Documents/PycharmProjects/trash_detect/split_data.py)
- Create a script to split the existing `garbage-dataset` into a standard YOLO classification format:
  ```
  dataset_split/
  |-- train/
  |   |-- battery/
  |   |-- ...
  |-- val/
  |   |-- battery/
  |   |-- ...
  |-- test/
  |   |-- battery/
  |   |-- ...
  ```
- Split ratio: 70% Train, 20% Val, 10% Test.

### Training Logic
#### [MODIFY] [train.py](file:///Users/aniruddhmodi/Documents/PycharmProjects/trash_detect/train.py)
- Implement YOLOv8 training using `ultralytics` library.
- Load pre-trained `yolov8n-cls.pt` (nano classification model) for speed, or `yolov8s-cls.pt`.
- Point to the newly created `dataset_split` directory.
- Set epochs (e.g., 10-20 for initial testing, user can increase).

## Verification Plan

### Automated Tests
- Run `split_data.py` and verify directory structure using `ls -R dataset_split | grep ":$" | head`.
- Run `train.py` for 1 epoch to ensure pipeline works.
- Run a prediction on a sample image:
  ```bash
  yolo classify predict model=runs/classify/train/weights/best.pt source=dataset_split/test/battery/battery_1.jpg
  ```

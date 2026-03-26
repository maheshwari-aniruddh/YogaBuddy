# Model Training Optimization

- [x] Analyze current implementation bottlenecks
- [x] Configure `NUM_WORKERS` for improved data loading throughput
- [x] Implement offline preprocessing pipeline
    - [x] Create `offline_preprocess.py` using multiprocessing
    - [x] Point `main.py` to preprocessed dataset directories
    - [x] Remove redundant dynamic preprocessing from `main.py`
- [/] Verify offline preprocessing success
    - [x] Resolve missing `PyWavelets` dependency
    - [/] Monitor `offline_preprocess.py` execution (~47% complete, variance in speed noted)
- [/] Resume model training and verify performance/consistency (Queued after preprocessing)

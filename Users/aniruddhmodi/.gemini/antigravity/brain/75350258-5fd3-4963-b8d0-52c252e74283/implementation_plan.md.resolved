# Revert ML Optimizations

The user has requested to undo the M2 Pro-specific changes added to speed up ML training. These changes include reverting batch size, image dimensions, dataloader workers, learning rate schedulers, model compilation, mixed precision and transfer learning tweaks.

## Proposed Changes

### main.py
- Revert `IMG_SIZE` from 300 to 224.
- Revert `BATCH_SIZE` from 64 to 32.
- Revert `NUM_WORKERS` from 4 to 0.
- Remove `persistent_workers=True` and `prefetch_factor=2` from all `DataLoader` initializations.
- Revert `timm.create_model("efficientnet_b3", ...)` to `"efficientnet_b0"`.
- Revert `{"label": "efficientnet_b3_super", ...}` to `efficientnet_b0_super`.
- Remove `torch.compile(model)` logic.
- Remove `OneCycleLR` learning rate scheduler and its usage (`scheduler.step()`).
- Revert `non_blocking=True` when transferring tensors to device.

### eval.py
- Revert `IMG_SIZE` from 300 to 224.
- Revert `BATCH_SIZE` from 16 to default (likely 16, just ensure consistency).
- Revert `NUM_WORKERS` from 4 to 0.
- Revert `timm.create_model("efficientnet_b3", ...)` to `"efficientnet_b0"`.
- Revert `{"label": "efficientnet_b3_super", ...}` to `efficientnet_b0_super`.
- Remove `persistent_workers=True` and `prefetch_factor=2` from all `DataLoader` initializations.
- Revert `non_blocking=True` when transferring tensors to device.

### test_dl.py / test_forward.py
- These files appear to be temporary scripts created to test the M2 optimizations before running the full training loop. They will be deleted.

## Verification Plan
1. Run `python main.py` for a brief period to ensure the training loop starts successfully without runtime errors on the original parameters.
2. Ensure no compiler or memory leakage warnings appear (due to removed optimizations).

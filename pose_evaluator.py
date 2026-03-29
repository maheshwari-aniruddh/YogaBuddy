import os
import numpy as np
import pickle
import cv2
from sklearn.metrics import classification_report, confusion_matrix
from tqdm import tqdm
from pose_detector import PoseDetector
from utils.angles import get_angle_features
import config


class PoseEvaluator:

    def __init__(self, model_path: str = None):
        self.detector = PoseDetector()
        self.model_path = model_path or os.path.join(config.MODELS_DIR, "pose_classifier.pkl")
        self.classifier = None
        self.scaler = None
        self.label_to_pose = {}
        self._load_model()

    def _load_model(self):
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(f"No model found at {self.model_path}. Train first.")
        with open(self.model_path, "rb") as f:
            data = pickle.load(f)
        self.classifier = data["classifier"]
        self.scaler = data["scaler"]
        self.label_to_pose = data["label_to_pose"]
        print(f"✅ Loaded model: {len(self.label_to_pose)} pose classes")

    def evaluate_on_split(self, split: str = "valid") -> dict:
        split_dir = os.path.join(config.DATASET_ROOT, split)
        if not os.path.exists(split_dir):
            raise FileNotFoundError(f"Split directory not found: {split_dir}")

        y_true = []
        y_pred = []
        per_pose_stats = {}

        pose_to_label = {v: k for k, v in self.label_to_pose.items()}
        poses_to_eval = [p for p in config.TOP_POSES if p in pose_to_label]

        for pose_name in tqdm(poses_to_eval, desc=f"Evaluating [{split}]", unit="pose"):
            pose_dir = os.path.join(split_dir, pose_name)
            if not os.path.exists(pose_dir):
                continue
            label = pose_to_label[pose_name]
            image_files = [
                f for f in os.listdir(pose_dir)
                if f.lower().endswith((".jpg", ".jpeg", ".png"))
            ][:50]

            correct = 0
            total = 0
            for img_file in image_files:
                img_path = os.path.join(pose_dir, img_file)
                try:
                    image = cv2.imread(img_path)
                    if image is None:
                        continue
                    keypoints = self.detector.detect_pose(image)
                    if keypoints is None:
                        continue
                    features = get_angle_features(keypoints).reshape(1, -1)
                    features_scaled = self.scaler.transform(features)
                    pred_label = self.classifier.predict(features_scaled)[0]
                    y_true.append(label)
                    y_pred.append(pred_label)
                    if pred_label == label:
                        correct += 1
                    total += 1
                except Exception:
                    continue

            if total > 0:
                per_pose_stats[pose_name] = {
                    "accuracy": correct / total,
                    "correct": correct,
                    "total": total,
                }

        results = {
            "split": split,
            "per_pose": per_pose_stats,
            "y_true": y_true,
            "y_pred": y_pred,
        }
        return results

    def print_report(self, results: dict):
        split = results["split"]
        per_pose = results["per_pose"]
        y_true = results["y_true"]
        y_pred = results["y_pred"]

        print(f"\n{'='*60}")
        print(f"  Evaluation Report — {split.upper()} split")
        print(f"{'='*60}")

        sorted_poses = sorted(per_pose.items(), key=lambda x: x[1]["accuracy"])
        print("\n📉 Worst performing poses:")
        for name, stats in sorted_poses[:5]:
            print(f"  {name[:40]:<40} {stats['accuracy']*100:.1f}%  ({stats['correct']}/{stats['total']})")

        print("\n📈 Best performing poses:")
        for name, stats in sorted_poses[-5:]:
            print(f"  {name[:40]:<40} {stats['accuracy']*100:.1f}%  ({stats['correct']}/{stats['total']})")

        overall = sum(1 for t, p in zip(y_true, y_pred) if t == p) / max(len(y_true), 1)
        print(f"\n🎯 Overall accuracy: {overall*100:.2f}%  ({len(y_true)} samples)")
        print(f"{'='*60}\n")

    def worst_poses(self, results: dict, n: int = 10) -> list:
        per_pose = results["per_pose"]
        sorted_poses = sorted(per_pose.items(), key=lambda x: x[1]["accuracy"])
        return [name for name, _ in sorted_poses[:n]]


if __name__ == "__main__":
    evaluator = PoseEvaluator()
    results = evaluator.evaluate_on_split("valid")
    evaluator.print_report(results)
    print("Worst poses to focus on:", evaluator.worst_poses(results))

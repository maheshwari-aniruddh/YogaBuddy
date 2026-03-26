# Brainstorm: Geometry-Based Pose Detection (No Classifiers)

Machine learning classifiers (like KNN or MLP) can struggle with yoga poses because:
1. They require massive, perfectly balanced datasets to generalize well to different body types and camera angles.
2. They treat the entire body as a single feature vector, meaning one noisy keypoint (e.g., an occluded ankle) can wreck the entire classification.
3. They are essentially "black boxes"—it's hard to debug *why* a pose was misclassified.

Instead of ML, we can use a **Heuristic Rule-Based Engine (Geometric Matching)**. Since MediaPipe already provides highly accurate 3D joint coordinates, we can mathematically define what a pose "looks like".

## The Concept

Every yoga pose can be defined by a set of **critical geometric constraints**.

For example, **Tree Pose (Vrksasana)**:
1. **Constraint 1 (Standing Leg):** One leg must be straight (Knee angle ~180°).
2. **Constraint 2 (Bent Leg):** The other leg must be bent (Knee angle < 90°).
3. **Constraint 3 (Foot Placement):** The ankle of the bent leg must be vertically higher than the knee of the standing leg, and horizontally close to the standing leg's inner thigh.
4. **Constraint 4 (Torso):** Shoulders and hips must form a roughly vertical rectangle (Torso angle ~90° relative to ground).
5. **Constraint 5 (Arms - Optional):** Hands touching above head or at chest (Wrist distance < threshold).

### The "Fuzzy Logic" Scoring System

Instead of a binary "yes/no," we score how well the user matches each constraint.

1. **Calculate Joint Angles & Distances**: Extract 2D/3D angles (elbows, knees, hips, shoulders) and normalized distances (e.g., Euclidean distance between left wrist and right wrist, normalized by shoulder width so it works for all body sizes).
2. **Define Pose Templates (JSON)**: Create a strict definition for every pose.
   ```json
   {
     "pose": "tree_pose",
     "rules": [
       {"type": "angle", "joint": "standing_knee", "target": 180, "tolerance": 15, "weight": 2.0},
       {"type": "angle", "joint": "bent_knee", "max": 90, "weight": 1.5},
       {"type": "relation", "compare": ["bent_ankle_y", "standing_knee_y"], "condition": "<", "weight": 2.0},
       {"type": "relation", "compare": ["distance(left_wrist, right_wrist)"], "condition": "<", "threshold": 0.2, "weight": 1.0}
     ]
   }
   ```
3. **Continuous Scoring**: As frames come in, evaluate the rules. If the user satisfies a constraint perfectly, they get `1.0 * weight`. If they are slightly off (within tolerance), they get a partial score (e.g., `0.8 * weight`). If they are way off, `0.0`.
4. **Thresholding**: If the total normalized score for a pose template exceeds, say, `85%`, the system locks in that pose.

## Advantages over ML Classifiers

1. **Zero Training Data Needed**: You don't need thousands of images to teach the system what a "Downward Dog" is. You just write the mathematical definition of it.
2. **Explainability & Instant Feedback**: Because you are checking specific rules, the system *inherently knows exactly what the user is doing wrong*. If the score is low because Constraint #2 failed, the app can instantly say: "Bend your left knee more."
3. **Robustness to Occlusion**: If a rule isn't marked as "critical" (e.g., finger placement), MediaPipe losing track of a hand won't completely fail the detection, unlike an MLP which expects an exact 20-feature input array.
4. **Orientation Agnostic**: By calculating angles relative to the body (e.g., spine relative to hips, rather than relative to the camera frame), the detection works whether the user is facing the camera or sideways.

## Implementation Steps for YogaBuddy

1. **Rule Engine Module**: Create a `geometric_detector.py` that parses JSON rulesets and iterates over MediaPipe keypoints.
2. **Define the Core Poses**: Manually construct the constraint JSON for the ~10 most important yoga poses.
3. **Replace `pose_classifier`**: In `yoga_api_server.py`, swap out the MLP classifier call with `geometric_detector.match_pose(keypoints)`.
4. **Direct Integration with Form Corrector**: Since the Rule Engine already calculates the exact angular deviations to determine *if* it's the pose, the `form_corrector.py` logic becomes entirely redundant—the detection and the correction happen in the exact same mathematical step.

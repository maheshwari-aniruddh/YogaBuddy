"""
Ball Trajectory Analysis Module
Detects and tracks tennis ball trajectory using computer vision
Uses YOLOv8 model for accurate ball detection
"""

import cv2
import numpy as np
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from pathlib import Path
from scipy.spatial.distance import euclidean
from scipy.ndimage import gaussian_filter1d
from ultralytics import YOLO


@dataclass
class BallPosition:
    """Represents ball position at a single frame"""
    x: float  # Normalized x coordinate (0-1)
    y: float  # Normalized y coordinate (0-1)
    confidence: float  # Detection confidence (0-1)
    frame_number: int
    timestamp: float
    radius: Optional[float] = None  # Estimated ball radius in pixels


@dataclass
class BallTrajectory:
    """Complete ball trajectory across video"""
    positions: List[BallPosition]
    has_ball: bool = False
    contact_frame: Optional[int] = None  # Frame where ball contacts racket
    contact_position: Optional[Tuple[float, float]] = None
    toss_peak: Optional[BallPosition] = None  # Highest point of toss (for serves)
    toss_start: Optional[int] = None  # Frame where toss begins
    correlation: Optional[Dict] = None  # Correlation with pose data


class BallTracker:
    """
    Detects and tracks tennis ball trajectory using YOLOv8 model
    Uses trained YOLOv8 model for accurate ball detection
    """
    
    # Model path - use the newly trained model
    MODEL_PATH = Path("backend/tennis_ball_models/yolov8_tennis_ball/weights/best.pt")
    
    def __init__(self, model_path: Optional[str] = None):
        """
        Initialize ball tracker with YOLOv8 model
        
        Args:
            model_path: Optional path to YOLOv8 model. If not provided, uses default trained model.
        """
        # Determine model path
        if model_path:
            model_path_obj = Path(model_path)
        else:
            model_path_obj = self.MODEL_PATH
        
        # Load YOLO model
        if model_path_obj.exists():
            try:
                self.model = YOLO(str(model_path_obj))
                print(f"✅ Loaded ball tracking model from {model_path_obj}")
            except Exception as e:
                print(f"⚠️ Failed to load YOLO model: {e}")
                self.model = None
        else:
            print(f"⚠️ Model not found at {model_path_obj}. Ball tracking will be disabled.")
            self.model = None
        
        self.tracker = None  # Could use cv2.TrackerCSRT_create() for advanced tracking
    
    def detect_ball_in_frame(self, frame: np.ndarray) -> Optional[BallPosition]:
        """
        Detect ball in a single frame using YOLOv8 model with strict filtering
        
        Args:
            frame: Input frame (BGR format)
        
        Returns:
            BallPosition if detected, None otherwise
        """
        if self.model is None:
            return None
        
        h, w = frame.shape[:2]
        min_dimension = min(h, w)
        
        # Run YOLO prediction
        try:
            # Increased confidence threshold to reduce false positives
            results = self.model.predict(frame, conf=0.35, verbose=False)[0]
            
            # Find best ball detection (highest confidence)
            best_box = None
            best_confidence = 0.0
            
            for box in results.boxes:
                # Get class ID and confidence
                conf = float(box.conf[0])
                
                # Get bounding box coordinates
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                
                # Calculate dimensions
                width = x2 - x1
                height = y2 - y1
                
                # Filter 1: Aspect Ratio Check
                # Tennis balls are round, so box should be roughly square
                aspect_ratio = width / height if height > 0 else 0
                if not (0.6 <= aspect_ratio <= 1.6):
                    continue
                
                # Filter 2: Size Check (relative to frame size)
                # Ball shouldn't be too huge (e.g., a yellow shirt) or too tiny (noise)
                # Max radius: ~5% of min frame dimension
                # Min radius: ~0.2% of min frame dimension
                radius = max(width, height) / 2
                relative_radius = radius / min_dimension
                
                if not (0.002 <= relative_radius <= 0.05):
                    continue
                
                if conf > best_confidence:
                    best_confidence = conf
                    best_box = (x1, y1, x2, y2)
            
            if best_box is None:
                return None
            
            # Calculate center and size
            x1, y1, x2, y2 = best_box
            cx = (x1 + x2) / 2
            cy = (y1 + y2) / 2
            width = x2 - x1
            height = y2 - y1
            radius = max(width, height) / 2
            
            # Normalize coordinates
            x_norm = cx / w
            y_norm = cy / h
            
            return BallPosition(
                x=x_norm,
                y=y_norm,
                confidence=best_confidence,
                frame_number=-1,  # Will be set by caller
                timestamp=0.0,  # Will be set by caller
                radius=radius
            )
        except Exception as e:
            print(f"Error in YOLO detection: {e}")
            return None
    
    def track_ball_in_video(self, video_path: str, fps: Optional[float] = None) -> BallTrajectory:
        """
        Track ball trajectory throughout entire video
        
        Args:
            video_path: Path to video file
            fps: Video FPS (optional, will be detected if not provided)
        
        Returns:
            BallTrajectory with all detected positions
        """
        cap = cv2.VideoCapture(video_path)
        
        if not cap.isOpened():
            raise ValueError(f"Could not open video: {video_path}")
        
        video_fps = fps or cap.get(cv2.CAP_PROP_FPS)
        if video_fps <= 0:
            video_fps = 30.0  # Default
        
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        positions = []
        frame_number = 0
        
        # Use Kalman filter for smooth tracking
        kalman = cv2.KalmanFilter(4, 2)  # 4 state (x, y, vx, vy), 2 measurement (x, y)
        kalman.transitionMatrix = np.array([[1, 0, 1, 0],
                                           [0, 1, 0, 1],
                                           [0, 0, 1, 0],
                                           [0, 0, 0, 1]], np.float32)
        kalman.measurementMatrix = np.array([[1, 0, 0, 0],
                                            [0, 1, 0, 0]], np.float32)
        kalman.processNoiseCov = 0.03 * np.eye(4, dtype=np.float32)
        kalman.measurementNoiseCov = 0.1 * np.eye(2, dtype=np.float32)
        
        last_detected_pos = None
        
        from tqdm import tqdm
        
        with tqdm(total=total_frames, desc="Tracking ball") as pbar:
            while cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    break
                
                timestamp = frame_number / video_fps
                
                # Detect ball
                ball_pos = self.detect_ball_in_frame(frame)
                
                # Use Kalman filter for prediction
                if ball_pos is None and last_detected_pos is not None:
                    # Predict position when ball not detected
                    prediction = kalman.predict()
                    predicted_x = float(prediction[0][0])
                    predicted_y = float(prediction[1][0])
                    ball_pos = BallPosition(
                        x=predicted_x / frame_width,
                        y=predicted_y / frame_height,
                        confidence=0.3,  # Lower confidence for predictions
                        frame_number=frame_number,
                        timestamp=timestamp,
                        radius=last_detected_pos.radius
                    )
                elif ball_pos is not None:
                    # Update with measurement
                    measurement = np.array([[ball_pos.x * frame_width],
                                          [ball_pos.y * frame_height]], np.float32)
                    kalman.correct(measurement)
                    last_detected_pos = ball_pos
                    ball_pos.frame_number = frame_number
                    ball_pos.timestamp = timestamp
                
                if ball_pos:
                    positions.append(ball_pos)
                
                frame_number += 1
                pbar.update(1)
        
        cap.release()
        
        # Smooth trajectory
        if positions:
            positions = self._smooth_trajectory(positions)
            
            # Detect contact point and toss peak
            contact_frame, contact_pos = self._detect_contact_point(positions)
            toss_peak = self._detect_toss_peak(positions)
            toss_start = self._detect_toss_start(positions)
            
            return BallTrajectory(
                positions=positions,
                has_ball=True,
                contact_frame=contact_frame,
                contact_position=contact_pos,
                toss_peak=toss_peak,
                toss_start=toss_start
            )
        else:
            return BallTrajectory(
                positions=[],
                has_ball=False
            )
    
    def _smooth_trajectory(self, positions: List[BallPosition]) -> List[BallPosition]:
        """Smooth trajectory using Gaussian filter"""
        if len(positions) < 3:
            return positions
        
        x_coords = [p.x for p in positions]
        y_coords = [p.y for p in positions]
        
        # Smooth with Gaussian filter
        x_smooth = gaussian_filter1d(x_coords, sigma=1.0)
        y_smooth = gaussian_filter1d(y_coords, sigma=1.0)
        
        smoothed = []
        for i, pos in enumerate(positions):
            smoothed_pos = BallPosition(
                x=x_smooth[i],
                y=y_smooth[i],
                confidence=pos.confidence,
                frame_number=pos.frame_number,
                timestamp=pos.timestamp,
                radius=pos.radius
            )
            smoothed.append(smoothed_pos)
        
        return smoothed
    
    def _detect_contact_point(self, positions: List[BallPosition]) -> Tuple[Optional[int], Optional[Tuple[float, float]]]:
        """
        Detect contact point where ball is near racket/hand
        
        Uses heuristics:
        - Ball is at lowest Y position (highest in frame)
        - Ball velocity changes significantly
        - Ball is in expected contact zone
        """
        if len(positions) < 5:
            return None, None
        
        # Find minimum Y (ball at contact is typically at top of frame, lowest normalized Y)
        min_y_idx = 0
        min_y = positions[0].y
        
        for i, pos in enumerate(positions):
            if pos.y < min_y:
                min_y = pos.y
                min_y_idx = i
        
        contact_pos = positions[min_y_idx]
        
        # Validate: check if ball is in reasonable contact zone (middle to upper part)
        if 0.1 < contact_pos.y < 0.5:  # Normalized coordinates
            return contact_pos.frame_number, (contact_pos.x, contact_pos.y)
        
        return None, None
    
    def _detect_toss_peak(self, positions: List[BallPosition]) -> Optional[BallPosition]:
        """Detect peak of toss (for serves) - highest point in trajectory"""
        if not positions:
            return None
        
        # Find maximum Y (highest point = lowest normalized Y since Y increases downward)
        max_y_idx = 0
        max_y = positions[0].y
        
        for i, pos in enumerate(positions):
            # For toss peak, we want the point where ball reaches maximum height
            # In image coordinates, this is minimum Y value
            if pos.y < max_y:  # Lower Y = higher in frame = higher in air
                max_y = pos.y
                max_y_idx = i
        
        return positions[max_y_idx]
    
    def _detect_toss_start(self, positions: List[BallPosition]) -> Optional[int]:
        """Detect when toss begins (sudden upward movement)"""
        if len(positions) < 10:
            return None
        
        # Find first significant upward movement
        for i in range(5, len(positions)):
            if i < 2:
                continue
            
            # Calculate velocity
            dy = positions[i-2].y - positions[i].y  # Negative dy = upward movement
            
            if dy > 0.02:  # Significant upward movement
                return positions[i].frame_number
        
        return positions[0].frame_number if positions else None
    
    def draw_ball_trajectory(self,
                           frame: np.ndarray,
                           trajectory: BallTrajectory,
                           frame_number: int,
                           color: Tuple[int, int, int] = (0, 255, 255),  # Yellow
                           thickness: int = 2) -> np.ndarray:
        """
        Draw ball trajectory on frame
        
        Args:
            frame: Input frame
            trajectory: Ball trajectory
            frame_number: Current frame number
            color: BGR color for trajectory
            thickness: Line thickness
        
        Returns:
            Frame with ball trajectory overlay
        """
        h, w = frame.shape[:2]
        
        if not trajectory.has_ball or not trajectory.positions:
            return frame
        
        # Draw trajectory up to current frame
        points_to_draw = [p for p in trajectory.positions if p.frame_number <= frame_number]
        
        if len(points_to_draw) < 2:
            return frame
        
        # Convert to pixel coordinates and draw path
        points_pixels = []
        for pos in points_to_draw:
            px = int(pos.x * w)
            py = int(pos.y * h)
            points_pixels.append((px, py))
        
        # Draw trajectory path
        for i in range(len(points_pixels) - 1):
            pt1 = points_pixels[i]
            pt2 = points_pixels[i + 1]
            cv2.line(frame, pt1, pt2, color, thickness)
        
        # Draw current ball position
        current_pos = next((p for p in reversed(points_to_draw) if p.frame_number == frame_number), None)
        if current_pos:
            cx = int(current_pos.x * w)
            cy = int(current_pos.y * h)
            radius = int(current_pos.radius) if current_pos.radius else 5
            cv2.circle(frame, (cx, cy), radius, color, -1)
            cv2.circle(frame, (cx, cy), radius, (255, 255, 255), 2)
        
        # Draw contact point
        if trajectory.contact_frame and trajectory.contact_position:
            contact_x = int(trajectory.contact_position[0] * w)
            contact_y = int(trajectory.contact_position[1] * h)
            cv2.circle(frame, (contact_x, contact_y), 8, (0, 0, 255), 2)  # Red circle for contact
            cv2.putText(frame, "Contact", (contact_x + 10, contact_y),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
        
        # Draw toss peak (for serves)
        if trajectory.toss_peak:
            peak_x = int(trajectory.toss_peak.x * w)
            peak_y = int(trajectory.toss_peak.y * h)
            cv2.circle(frame, (peak_x, peak_y), 6, (255, 0, 255), 2)  # Magenta for peak
        
        return frame
    
    def correlate_with_pose(self,
                           ball_trajectory: BallTrajectory,
                           contact_frame: int,
                           wrist_position: Optional[Tuple[float, float]]) -> Dict:
        """
        Correlate ball position with pose at contact
        
        Args:
            ball_trajectory: Ball trajectory
            contact_frame: Frame number of contact
            wrist_position: Wrist position (x, y normalized) at contact
        
        Returns:
            Dictionary with correlation metrics
        """
        correlation = {
            'ball_detected_at_contact': False,
            'ball_contact_position': None,
            'wrist_position': wrist_position,
            'distance_at_contact': None,
            'toss_quality': None
        }
        
        if not ball_trajectory.has_ball:
            return correlation
        
        # Find ball position at contact frame
        ball_at_contact = next(
            (p for p in ball_trajectory.positions if p.frame_number == contact_frame),
            None
        )
        
        if ball_at_contact:
            correlation['ball_detected_at_contact'] = True
            correlation['ball_contact_position'] = (ball_at_contact.x, ball_at_contact.y)
            
            if wrist_position:
                # Calculate distance between ball and wrist at contact
                distance = euclidean(
                    [ball_at_contact.x, ball_at_contact.y],
                    list(wrist_position)
                )
                correlation['distance_at_contact'] = distance
        
        # Analyze toss quality (for serves)
        if ball_trajectory.toss_peak and ball_trajectory.toss_start:
            toss_height = ball_trajectory.toss_start - ball_trajectory.toss_peak.y if ball_trajectory.toss_peak else 0
            
            if toss_height > 0.1:
                correlation['toss_quality'] = 'good'
            elif toss_height > 0.05:
                correlation['toss_quality'] = 'moderate'
            else:
                correlation['toss_quality'] = 'low'
        
        return correlation


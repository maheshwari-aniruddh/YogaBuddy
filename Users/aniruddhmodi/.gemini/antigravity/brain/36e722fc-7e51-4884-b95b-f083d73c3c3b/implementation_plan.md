# OneBreath "Beefy & Cool" Upgrade Plan

## Goal Description
Enhance the existing `YogaSessionPage` to provide a more immersive, "high-tech" (beefy) and visually stunning (cool) experience. This involves transforming the debug stats into a "JARVIS-style" HUD, adding dynamic background effects, and improving success feedback.

## User Review Required
> [!NOTE]
> This plan focuses heavily on visual and UX changes. The core backend logic remains untouched to ensure stability.

## Proposed Changes

### Frontend Components

#### [NEW] [HUDOverlay.tsx](file:///Users/aniruddhmodi/Documents/PycharmProjects/Yogabuddy/one-breath-app/src/components/HUDOverlay.tsx)
- Create a new component to display real-time statistics (Pose Confidence, Angle Similarity, Stability) as a transparent, high-tech overlay on top of the video feed.
- Use neon colors (Cyan/Green/Red) and "tech" fonts (Monospace) to give it a futuristic feel.
- Display "Lock On" animations when the user is in the correct pose.

#### [MODIFY] [YogaSessionPage.tsx](file:///Users/aniruddhmodi/Documents/PycharmProjects/Yogabuddy/one-breath-app/src/components/YogaSessionPage.tsx)
- **Background**: Replace static image with a dynamic, animated gradient that shifts based on session state.
- **Integration**: Replace the existing "Debug Info" panel with the new `HUDOverlay`.
- **Feedback**: Enhance the feedback text with "glitch" or "typewriter" effects.
- **Success**: Add a full-screen "Pulse" effect when a pose is successfully held.
- **Form Correction**: Implement AR lines overlay on video feed to show misalignment.

### Smart Features (Backend & Frontend)

#### [NEW] [AICoach.tsx](file:///Users/aniruddhmodi/Documents/PycharmProjects/Yogabuddy/one-breath-app/src/components/AICoach.tsx)
- A component that listens to pose data and generates specific verbal/text corrections.
- *Logic*: Compare `debugInfo.angle_similarity` and specific joint positions to predefined "correct" vectors.
- *Output*: Text-to-Speech (TTS) prompts like "Straighten your right leg" instead of generic feedback.

#### [MODIFY] [yoga_api_server.py](file:///Users/aniruddhmodi/Documents/PycharmProjects/Yogabuddy/yoga_api_server.py)
- Update socket emission to include granular joint errors (e.g., "knee_angle_off_by_15_deg").

#### [MODIFY] [index.css](file:///Users/aniruddhmodi/Documents/PycharmProjects/Yogabuddy/one-breath-app/src/index.css)
- Add new animations: `scanline`, `hud-flicker`, `pulse-success`.
- Add utility classes for glassmorphism with neon borders.

## Verification Plan

### Manual Verification
1.  **Start the App**: Run `./start_all_servers.sh` (or just the frontend to test UI).
2.  **Navigate to Session**: Go to "Practice" -> "Start Session" (or skip to session page).
3.  **Check Visuals**:
    -   Verify the background is animating.
    -   Verify the HUD appears over the video feed (or placeholder).
    -   Verify the stats update in real-time (mock data if camera not active).
4.  **Simulate Success**: Wait for the timer to finish and verify the "Success" animation triggers.

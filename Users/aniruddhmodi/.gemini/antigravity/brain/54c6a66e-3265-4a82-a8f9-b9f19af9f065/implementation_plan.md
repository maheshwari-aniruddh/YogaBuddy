# Implementation Plan - Phase 3: Visual Updates & Cleanup

## Goal
Enhance user experience with visual updates, implement requested UI changes (Swipe to Save), and ensure code cleanliness by removing legacy dependencies.

## Completed Changes
- **FaceID**: Implemented and Verified.
- **UI Updates**:
    - [x] **Swipe to Save**: Replaced standard button with `SwipeToSaveWidget`.
    - [x] **Microphone Alignment**: Fixed overlap in `TodayScreen`.
    - [x] **Star Button**: Restored accidentally removed button.
- **Code Cleanup**:
    - [x] **Firebase Removal**: Removed `Firebase.initializeApp`, `Firestore` usage in `FeedbackScreen`, and deleted `firestore_service.dart`.
    - [x] **Settings Fix**: Updated `SettingsScreen` to use `AuthService` instead of `FirebaseAuth`.

- **Functional Changes**:
    - [x] **Microphone Toggle**: Changed from hold-to-record to tap-to-toggle.
    - [x] **Email Feedback**: Feedback now launches email with pre-filled content.

## Verification Plan

### Manual Verification
#### 1. Visual Inspection
- [ ] Check `TodayScreen` layout.
- [ ] Verify Microphone is centered and not overlapping.
- [ ] Verify Star button is present and works.
- [ ] Verify Swipe to Save widget looks correct.

#### 2. Functional Testing
- [ ] Swipe to Save: Ensure it triggers save (Haptic feedback + SnackBar).
- [ ] Feedback: Submit feedback, ensure it opens Email app.
- [ ] Microphone: Tap to start, tap to stop. Verify recording works.
- [ ] Settings: Logout/Login flow (ensuring `AuthService` works).

#### 3. Data Persistence
- [ ] Create entry, save, restart app. Verify entry persists (Google Drive).

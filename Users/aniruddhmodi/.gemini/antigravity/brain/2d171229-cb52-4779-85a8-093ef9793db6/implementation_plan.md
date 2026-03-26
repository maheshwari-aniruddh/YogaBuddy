# Google Drive Refactor & UI Enhancements

The goal is to replace Firebase Storage/Firestore with Google Drive for data persistence, update specific UI text ("Swipe Up" -> "Swipe Down"), and overhaul the audio recording user interface and functionality.

## User Review Required
> [!IMPORTANT]
> This is a major architectural change. Moving from Firebase to Google Drive will result in **data loss for existing entries** unless a migration script is written (not included in this plan). The app will effectively start fresh for the user.

> [!WARNING]
> Google Drive API requires restricted scopes. Ensure the Google Cloud Console project has the Drive API enabled and the OAuth consent screen is configured for `https://www.googleapis.com/auth/drive.file`.

## Proposed Changes

### UI Updates
#### [MODIFY] [today_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/today_screen.dart)
- Change "Swipe up" text to "Swipe down".
- Refactor `_buildActionsPage` to rearrange media buttons:
    - Group "Photo" and "Video" buttons in a centered Row.
    - Place "Audio" recording widget below them, centered.

### Recording Feature Overhaul
#### [MODIFY] [audio_player_widget.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/widgets/audio_player_widget.dart)
- Address playback issues (ensure duration is loaded correctly).
- Add explicit "Re-record" button/icon which triggers delete + notify parent.

#### [MODIFY] [today_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/today_screen.dart)
- The logic for "re-record" is already handled by `onDelete` (setting file to null), which shows the recorder again. This flow is correct, so the focus will be on the UI layout and ensure playback works.

### Google Drive Integration
#### [MODIFY] [pubspec.yaml](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/pubspec.yaml)
- Add `googleapis` and `extension_google_sign_in_as_googleapis_auth` (or handle auth headers manually).

#### [NEW] [lib/services/drive_service.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/drive_service.dart)
- Create `DriveService` class.
- Implement `init(GoogleSignInAccount user)` to set up the authenticated client.
- Implement methods:
    - `uploadFile(File file, String filename)`
    - `downloadFile(String fileId)`
    - `listFiles()`
    - `saveJournalEntry(JournalEntry entry)` (upload as JSON)
    - `getJournalEntries()`

#### [MODIFY] [lib/services/store.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/store.dart)
- Replace `Firestore` and `FirebaseStorage` references with `DriveService`.
- Update `saveEntry` and `loadEntries` to use Drive.

#### [MODIFY] [lib/screens/login_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/login_screen.dart)
- Update `GoogleSignIn` scopes to include `DriveApi.driveFileScope`.
- Initialize `DriveService` upon successful sign-in.

## Verification Plan

### Automated Tests
- None specific for this UI/Integration task.

### Manual Verification
1.  **UI Text**: Verify "Swipe down" text is visible on the last page of the daily flow.
2.  **Recording UI**:
    - Verify Photo/Video buttons are side-by-side.
    - Verify Audio Recorder is below them and centered.
    - Record a clip -> Verify Player appears.
    - Play clip -> Verify sound and slider movement.
    - Delete clip -> Verify Recorder reappears.
3.  **Google Drive**:
    - Sign out and Sign In again (to grant new permissions).
    - Save a journal entry with text and media.
    - App uninstall/reinstall (simulated by clearing data).
    - Login -> Verify entry is loaded from Drive.

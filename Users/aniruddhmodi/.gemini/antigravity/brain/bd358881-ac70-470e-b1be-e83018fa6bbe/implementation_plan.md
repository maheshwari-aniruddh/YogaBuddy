# App Updates Implementation Plan

## User Review Required
> [!IMPORTANT]
> **Demo Login (Reviewer Mode)**: I will add a "Reviewer Login" button (hidden or subtle, or explicit as requested) on the Login Screen.
> When logging in as `user01` with `appleBest`, the app will enter a **Local Only Mode**.
> - **Google Drive Sync** will be **DISABLED** for this user.
> - Data will be stored only on the device.
> - This ensures Apple Reviewers can test the app functionality without needing a real Google Account.

## Proposed Changes

### Feature: Demo Login

#### [MODIFY] [login_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/login_screen.dart)
- Add a text button "Sign in with Username/Password".
- Show a dialog asking for Username/Password.
- Verify `user01` / `appleBest`.
- On success, trigger a "Demo Mode" login.

#### [MODIFY] [auth_service.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/auth_service.dart)
- Add a `signInAsDemoUser()` method.
- Return a mock `GoogleSignInAccount` object (or a wrapper) or update state to indicate `isDemoUser`.
- Actually, since `GoogleSignInAccount` is hard to mock directly without a library, I might need to make `currentUser` nullable or abstract it.
- **Better approach**: Add a boolean `isDemoUser` to `AuthService` (or `Store`).
- If `isDemoUser`, return a fake user object.

#### [MODIFY] [store.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/store.dart)
- Update `initialize` to handle a `null` Google User (if in demo mode) or a "Demo User".
- In `saveEntry`, `uploadToDrive`, `downloadMedia`: check if `isDemoUser`.
    - If `isDemoUser`, **skip** Drive uploads/downloads.
    - Just save/read from local file system.

#### [MODIFY] [auth_wrapper.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/auth_wrapper.dart)
- Update logic to accept the Demo User state.

## Verification Plan
1.  **Demo Login**:
    - Tap "Sign in with Username".
    - specific credentials `user01`/`appleBest`.
    - Verify app opens Main Screen.
2.  **Functionality**:
    - Create an entry.
    - Verify it saves (locally).
    - Verify "Swipe to Save" works.
    - Verify no crash on "Drive Upload".
3.  **Logout**:
    - Verify logout returns to Login Screen.

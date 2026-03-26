# Implementation Plan - Launch Readiness

Implement critical features for App Store launch: Onboarding, Biometrics, and polish.

## User Review Required

> [!NOTE]
> Ensure you have FaceID/TouchID configured on your simulator/device to test Biometrics.

## Proposed Changes

### Dependencies
#### [MODIFY] [pubspec.yaml](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/pubspec.yaml)
- Add `local_auth`.
- Add `introduction_screen` (optional, or build custom to save size/complexity). *Decision: Build custom lightweight onboarding.*

### Feature 1: Onboarding
#### [NEW] [onboarding_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/onboarding_screen.dart)
- 3 slides: Welcome, "30 Seconds" concept, Privacy/Biometrics.
- Save flag `isFirstLaunch` to `SharedPreferences`.

#### [MODIFY] [auth_wrapper.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/auth_wrapper.dart)
- Check `isFirstLaunch` before showing `LoginScreen`.

### Feature 2: Biometrics
#### [NEW] [biometric_service.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/biometric_service.dart)
- Methods: `authenticate()`, `canCheckBiometrics()`.

#### [MODIFY] [settings_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/settings_screen.dart)
- Add toggle for "App Lock".

#### [MODIFY] [main.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/main.dart)
- Use `AppLifecycleListener` to prompt bio-auth on resume (if enabled).

### Feature 3: Cloud Sync
#### [MODIFY] [store.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/store.dart)
- *Verification*: Ensure `FirestoreService` is called on save.
- Add "Last Synced" timestamp logic if missing.

### Feature 4: Haptics & Sound
#### [MODIFY] [today_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/today_screen.dart)
- Add `HapticFeedback.heavyImpact()` on save.
- Add success sound (using `audioplayers` already in pubspec).

## Verification Plan

### Automated Tests
- Run `flutter test` (if applicable).

### Manual Verification
- **Onboarding**: Re-install app (or clear cache) and verify screens.
- **Biometrics**: Enable in settings, background app, resume -> should see prompt.
- **Sync**: Add entry on one emulator, check Firestore console or another emulator.
- **Haptics**: Save entry -> feel vibration.

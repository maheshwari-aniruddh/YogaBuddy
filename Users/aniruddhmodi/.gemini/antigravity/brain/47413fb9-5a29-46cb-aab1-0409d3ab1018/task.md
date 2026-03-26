# App Store Rejection Fixes

## Fix 1: Sign in with Apple (Guideline 4.8)
- [x] Add `sign_in_with_apple` package to `pubspec.yaml`
- [x] Add Sign in with Apple entitlement to `Runner.entitlements`
- [x] Add `signInWithApple()` method to `auth_service.dart`
- [x] Add Apple sign-in button to `login_screen.dart`
- [x] Update `auth_wrapper.dart` to handle Apple sign-in users

## Fix 2: iPad Export Data Bug (Guideline 2.1a)
- [x] Fix `_getSharePosition` in `settings_screen.dart` to use `GlobalKey`-based positioning

## Fix 3: Account Deletion (Guideline 5.1.1v)
- [x] Add `deleteAccount()` method to `auth_service.dart`
- [x] Add `clearAllData()` method to `store.dart`
- [x] Add "Delete Account" UI section in `settings_screen.dart` with confirmation dialog

## Verification
- [x] Run `flutter pub get` — dependencies resolved
- [x] Run `flutter analyze` — 0 errors, 0 warnings

## Part 3: Android Release & Play Store
- [x] Generate signed Android App Bundle (.aab)
- [x] Fix Android launch crash (Package Name mismatch)
- [/] Fix Google Sign-In "Error 10" (SHA-1 fingerprint)
- [/] Verify biometric authentication on OnePlus device
- [ ] Submit to Play Console Internal Testing

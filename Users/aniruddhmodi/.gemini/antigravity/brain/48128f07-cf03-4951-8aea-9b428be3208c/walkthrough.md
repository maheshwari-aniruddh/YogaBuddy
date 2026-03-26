# App Store Review Fixes — Walkthrough

## Changes Made

### 1. Sign in with Apple (Guideline 4.8) ✅
**File:** [login_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/login_screen.dart)

- Moved Apple Sign-In button **above** Google Sign-In so it's the primary CTA (per Apple HIG)
- Both buttons are now hidden during loading state
- `Platform.isIOS` guard retained so the Apple button only shows on iOS

render_diffs(file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/login_screen.dart)

### 2. Export Data iPad Bug (Guideline 2.1a) ✅
**File:** [settings_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/settings_screen.dart)

- Renamed `_getSharePositionFromKey` → `_getSafeSharePosition` 
- Now returns a **non-null `Rect`** with a fallback to screen center when the GlobalKey's render object is unavailable
- This prevents the iPad share sheet popover from appearing at an invalid position and getting cut off

render_diffs(file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/settings_screen.dart)

### 3. Account Deletion (Guideline 5.1.1v) ✅
**Already implemented** — no changes needed. The feature exists at: **Settings → Account → Delete Account**, with a full confirmation dialog requiring the user to type \"DELETE\".

## Verification
- `dart analyze` passed on both modified files — 0 errors, only pre-existing info-level warnings

## Before Resubmitting

> [!IMPORTANT]
> 1. Verify **Sign in with Apple** capability is enabled in [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers) for your App ID
> 2. Test the Export Data button on **iPad simulator** to confirm the share sheet appears correctly
> 3. In your App Review reply, mention that account deletion is at **Settings → Account → Delete Account**

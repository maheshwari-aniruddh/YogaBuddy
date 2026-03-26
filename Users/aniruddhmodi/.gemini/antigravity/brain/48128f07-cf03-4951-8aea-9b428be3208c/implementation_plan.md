# Fix App Store Review Rejections

Three issues were raised by Apple's review team. After investigating the codebase, **all three features are already implemented** — but each needs a fix to pass review.

## Proposed Changes

### 1. Sign in with Apple (Guideline 4.8)

The `signInWithApple()` method exists in `auth_service.dart` and the Apple button is in `login_screen.dart`. However, the button is **conditionally shown with `Platform.isIOS`**, which should work. The likely issue is that Apple's reviewer may not have recognized it, or the capability wasn't enabled in App Store Connect.

#### [MODIFY] [login_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/login_screen.dart)

- Move the Apple Sign-In button **above** the Google button so it's the most prominent option (Apple prefers this per their HIG)
- Remove the `Platform.isIOS` guard — the `sign_in_with_apple` package already handles platform checks internally, and having the guard may cause issues in review builds

> [!IMPORTANT]
> You should also verify that the **"Sign in with Apple"** capability is enabled in your App Store Connect > Certificates, Identifiers & Profiles > your App ID. The entitlements file looks correct, but the capability must also be enabled on the Apple Developer portal side.

---

### 2. Export Data iPad Bug (Guideline 2.1a)

The `_exportData()` method uses `Share.shareXFiles` with `sharePositionOrigin` derived from the button's `GlobalKey`. On iPad, `Share.shareXFiles` presents a `UIActivityViewController` as a popover — if `sharePositionOrigin` is `null` or incorrect, the popover can appear at the wrong position or get cut off.

**Root cause:** The `_buildSettingsTile` widget passes `key` as a widget `Key`, but `GlobalKey` needs to be attached to the rendered widget's context to work. The current code passes `key` as a named parameter to `ListTile`, but `ListTile`'s `key` parameter is the widget `Key` — this should work. However, the issue is likely that the popover rect is being calculated relative to the screen origin and may produce a position that causes the iOS share sheet to clip.

#### [MODIFY] [settings_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/settings_screen.dart)

- Wrap the Export Data and Export PDF `ListTile` widgets with a `Builder` widget that uses a dedicated `GlobalKey` to ensure reliable position calculation
- Add a fallback `Rect` centered on screen if the key-based position returns `null`
- Constrain the share sheet position to be within safe screen bounds on iPad

---

### 3. Account Deletion (Guideline 5.1.1v)

The Delete Account feature is already fully implemented with a confirmation dialog that requires typing "DELETE". The reviewer may have missed it — it's at the bottom of the settings screen under the "Account" section.

#### [MODIFY] [settings_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/settings_screen.dart)

- Make the "Delete Account" option more visible by adding a distinct red-tinted section card
- Add a descriptive subtitle that explicitly says "Permanently remove your account and all data"

> [!TIP]
> In your reply to App Review, point them to **Settings tab → Account section → Delete Account**. They may have simply missed it during review.

---

## Verification Plan

### Manual Verification (User)
1. **Sign in with Apple**: On the login screen, verify the Apple Sign-In button appears prominently above the Google button. Tap it and confirm the Apple Sign-In flow works end-to-end
2. **Export Data on iPad**: Run the app on the iPad simulator, go to Settings → Export Data, tap it, and verify the share sheet appears correctly without being cut off
3. **Account Deletion**: Go to Settings → scroll to the Account section → verify "Delete Account" is clearly visible

---
description: Deploy app to TestFlight
---

# Deploying Roze to TestFlight

This workflow guides you through building and uploading your app to TestFlight.

## Prerequisites
1. **Apple Developer Account**: Ensure you have a paid Apple Developer account.
2. **App Record**: Ensure an app record exists in [App Store Connect](https://appstoreconnect.apple.com/apps) with Bundle ID `com.aniruddhmodi.roze`.

## Steps

### 1. Build the IPA
Run the following command in your terminal to create the iOS archive:
```bash
flutter build ipa
```
This will create an `.xcarchive` and an `.ipa` file. The output path will be displayed at the end (usually `build/ios/archive/Runner.xcarchive`).

### 2. Upload to App Store Connect
There are two ways to upload:

#### Option A: Using Xcode (Recommended)
1. Open the ios folder in Xcode: `open ios/Runner.xcworkspace`
2. Go to **Window > Organizer**.
3. Select the latest **Roze** archive (Version 1.0.0+2).
4. Click **Distribute App**.
5. Select **TestFlight & App Store** -> **Next**.
6. Select **Upload** -> **Next**.
7. Keep default distribution options -> **Next**.
8. Select **Automatically manage signing** -> **Next**.
9. Click **Upload**.

#### Option B: Using Transporter App
1. Download the **Transporter** app from the Mac App Store.
2. Open Transporter and sign in.
3. Drag and drop the `build/ios/ipa/Roze.ipa` file (you might need to find where `flutter build ipa` put it, usually `build/ios/ipa/Apps/Roze.ipa` or similar).

### 3. Release in TestFlight
1. Go to [App Store Connect](https://appstoreconnect.apple.com/).
2. Select **My Apps** > **Roze**.
3. Go to **TestFlight** tab.
4. Wait for the build to finish "Processing".
5. Once ready, click **Manage** next to Missing Compliance (select "No" for encryption usually, unless you added specific crypto).
6. Add **Internal Testing** group or specific testers.

## Troubleshooting
- **Build Number usage**: If it says build number exists, create a new build with `version: 1.0.0+3` in `pubspec.yaml`.
- **Signing Errors**: Ensure your Team ID `748WBK4F46` is selected in Xcode Signing & Capabilities.

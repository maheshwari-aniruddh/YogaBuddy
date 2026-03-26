# Production Setup Walkthrough

I have updated the "Roze" app to move away from a "test" environment to a "legit" production-ready configuration.

## Changes Made

### 1. Code Cleanup
I removed the "dummy" Firestore collection reading code from `main.dart` to ensure a clean, production-standard initialization.
render_diffs(file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/main.dart)

### 2. Android Configuration
I've prepared the Android build files to support the Google Services plugin and aligned the `applicationId` with your Firebase project (`com.example.the30secJournal`).

-   **Settings**: Added Google Services plugin management.
    render_diffs(file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/android/settings.gradle.kts)
-   **App Build**: Applied the plugin and matched the package name.
    render_diffs(file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/android/app/build.gradle.kts)

### 3. iOS Verification
I verified that the iOS project is already correctly configured with the bundle ID `com.example.the30secJournal`, matching your existing `GoogleService-Info.plist`.

## Final Steps for You

To complete the "legit" setup, please follow these last items:

### ✅ Apply Security Rules
Ensure you have pasted the rules I provided earlier into:
-   [Firestore Rules](https://console.firebase.google.com/u/0/project/sec-journal/firestore/rules)
-   [Storage Rules](https://console.firebase.google.com/project/sec-journal/storage/rules)

### ✅ Add Android Config File
Download `google-services.json` from the Firebase Console and place it in this directory:
`android/app/google-services.json`

### ✅ Enable Authentication
In the Firebase Console, go to **Authentication > Sign-in method** and enable **Google** and **Email/Password**.

> [!IMPORTANT]
> Once these steps are done, your app will be fully secure and ready for real users!

---

## Fix 4: Android Launch Crash (ClassNotFoundException)

The app builds but crashes immediately on Android because the package name in `MainActivity.kt` doesn't match the project's namespace.

### Proposed Changes

#### [MODIFY] [MainActivity.kt](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/android/app/src/main/kotlin/com/example/the_30sec_journal/MainActivity.kt)
- Change `package com.roze.journal` to `package com.example.the30secJournal` to match the project's namespace.

---

## Fix 5: Google Sign-In "Error 10"

Google Sign-In fails in release mode because the release SHA-1 fingerprint is missing from the Firebase project.

### Proposed Changes

#### [ADD] SHA-1 Fingerprint to Firebase Console
- SHA-1: `5E:57:10:F7:07:75:76:6A:CE:0D:B9:A6:C8:BC:4F:4B:8C:8F:2F:06`
- Location: Firebase Console > Project Settings > General > Your apps > Android app > SHA certificate fingerprints

#### [MODIFY] [google-services.json](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/android/app/google-services.json)
- Replace with the updated version from Firebase Console.

---

## Verification Plan & Usage Instructions

To get your app ready for the Google Play Store and test it on your physical Android device, we need to complete the Android signing process.

## Proposed Changes

### 1. Keystore Generation (Manual Step)
You must generate a digital signature file (keystore). Run this in your terminal:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*(Remember the password you set during this step!)*

### [NEW] [key.properties](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/android/key.properties)
Create a file at `android/key.properties` that contains the path to your keystore and the passwords you just set:
```properties
storePassword=<YOUR_PASSWORD>
keyPassword=<YOUR_PASSWORD>
keyAlias=upload
storeFile=/Users/aniruddhmodi/upload-keystore.jks
```

### [MODIFY] [build.gradle](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/android/app/build.gradle.kts)
Configure Gradle to use the `key.properties` file for the `release` build type by adding the `signingConfigs` block.

## Verification Plan & Usage Instructions

### Building the Release App Bundle (for Play Store)
Once the setup above is complete, you build the final `.aab` file by running:
```bash
flutter build appbundle --release
```
The file will be output to: `build/app/outputs/bundle/release/app-release.aab`. This is the file you upload to the Google Play Console.

### Testing Locally on Your Android Phone
To test the exact release build on your physical Android phone:
1. Enable **Developer Options** on your phone (Tap "Build Number" 7 times in Settings > About Phone).
2. Enable **USB Debugging** inside Developer Options.
3. Plug your phone into your Mac via USB.
4. Accept the debugging prompt on the phone screen.
5. Run the following command in your terminal to install and launch the release version:
```bash
flutter run --release
```

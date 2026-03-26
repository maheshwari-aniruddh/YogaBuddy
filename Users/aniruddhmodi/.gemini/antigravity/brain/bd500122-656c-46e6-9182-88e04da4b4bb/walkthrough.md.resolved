# TestFlight Upload Walkthrough

The iOS archive has been rebuilt with **debug symbols enabled** to fix the "Upload Symbols Failed" error.

## Archive Location
`build/ios/archive/Runner.xcarchive`

## Steps to Upload
1. Open the archive in Xcode:
   ```bash
   open build/ios/archive/Runner.xcarchive
   ```
   (I have already run this for you).

2. In the **Organizer** window:
   - Select the latest build (check the timestamp).
   - Click **"Distribute App"**.
   - Select **"TestFlight & App Store"**.
   - Follow the prompts. Xcode should now find the dSYMs since we forced their generation in the `Podfile`.

## Troubleshooting
- If errors persist, try "Clean Build Folder" in Xcode (Product > Clean Build Folder) and archive again from within Xcode next time.

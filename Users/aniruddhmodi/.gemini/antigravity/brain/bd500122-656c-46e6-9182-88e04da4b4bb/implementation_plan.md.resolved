# Fix dSYM Upload Errors

## User Review Required
> [!NOTE]
> The previous fix didn't fully resolve the issue. I am adding more strict build settings to explicitely generate and keep debug symbols.

## Proposed Changes
### Configuration
#### [MODIFY] [ios/Podfile](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/ios/Podfile)
- Update `post_install` hook to include:
    - `GCC_GENERATE_DEBUGGING_SYMBOLS` = `YES`
    - `STRIP_INSTALLED_PRODUCT` = `NO` (to prevent stripping symbols prematurely)
    - `COPY_PHASE_STRIP` = `NO`
    - `widen` the scope of changes to ensure they apply correctly.

### Build Process
- Run `pod cache clean --all` (manually via command) to ensure no bad binaries are reused.
- Clean and rebuild.

## Verification Plan
### Automated Tests
- None.

### Manual Verification
- Rebuild archive.
- Open archive and verify `dSYMs` folder contains the files for `openssl_grpc.framework` etc.

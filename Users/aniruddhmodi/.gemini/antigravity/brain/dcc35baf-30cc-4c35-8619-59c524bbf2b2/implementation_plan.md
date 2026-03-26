# Offline Reliability Implementation Plan

## Goal
Ensure users "never lose data" by implementing a robust local backup system. Currently, authenticated users rely solely on Google Drive. If the upload fails, data is lost on app restart. We will ensure all data is persisted locally first.

## User Review Required
> [!IMPORTANT]
> This change introduces a `journal_cache.json` file on the user's device. This file acts as a local mirror of their Drive data.

## Proposed Changes

### [Store Service](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/store.dart)

#### [MODIFY] [store.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/store.dart)
1.  **Add `_saveToCache()`:** Writes `_entries` to `journal_cache.json`.
2.  **Add `_loadFromCache()`:** Loads `_entries` from `journal_cache.json` and merges them.
3.  **Update `save()`:** Always call `_saveToCache()` *before* attempting Drive upload.
4.  **Update `initialize()`:** Call `_loadFromCache()` immediately so the user sees data instantly, then attempt to sync with Drive.

## Verification Plan

### Manual Verification
1.  **Offline Save Test:**
    *   Turn off WiFi/Internet on the device.
    *   Create a journal entry.
    *   Restart the app (still offline).
    *   Verify the entry is still there (loaded from cache).
2.  **Sync Test:**
    *   Turn on WiFi.
    *   Create an entry.
    *   Check Google Drive (Verify JSON file exists).
    *   Check local filesystem (Verify `journal_cache.json` contains the entry).

# Implementation Walkthrough (Phases 1-4)

We have successfully implemented the first 4 major features of the app revamp. Here is a detailed breakdown of the changes:

## Phase 1: Core Data Model & Migration
The app previously used the entry date as the unique identifier, which limited it to one entry per day. We overhauled the foundation to support multiple entries:
- **UUIDs**: Added a unique `id` field using the `uuid` package to every `JournalEntry`.
- **Media Support**: Replaced the single `photoPath` string with `List<String> photos` to support multiple images per entry.
- **Migration Engine**: Wrote a robust backward-compatibility layer in `JournalEntry.fromJson` and `Store._loadData`. When users update the app, any legacy single-entry formats are automatically converted to the new multi-entry format with generated UUIDs and migrated media lists without data loss.

## Phase 2: Today Screen UI & Multiple Entries
We preserved the familiar vertical swiping gesture while introducing timeline capabilities:
- **Timeline View**: The `TodayScreen` now defaults to a scrollable `_buildTimelineView` showing a card chronological list of all entries recorded on the selected day.
- **New Entry Flow**: Added a "New Entry" floating action button. Tapping this seamlessly switches the UI into the classic swipeable editor to record a new journal entry for that day.
- **Auto-save Updates**: Modified the background auto-save mechanism to pass the entry's UUID. This ensures real-time edits update the specific entry instead of creating duplicates.

## Phase 3: Rich Text Formatting
Entries can now be beautifully formatted.
- **MarkdownToolbar**: Created a new `MarkdownToolbar` widget that docks above the keyboard. It injects Bold (`**`), Italic (`*`), Bullet (`-`), List (`1.`), and Quote (`>`) formatting into the text fields.
- **Markdown Rendering**: Integrated the `flutter_markdown` package. We updated the summary cards in `TodayScreen` and the detailed views in `CalendarScreen` to render the user's input using `MarkdownBody` instead of plain raw text.

## Phase 4: Advanced Search & Filtering
We rebuilt the search experience to handle granular filtering alongside text queries.
- **Filter Chips**: Added horizontal scrolling filter chips directly beneath the search bar on the `SearchScreen`.
- **Advanced Logic**: Updated the core `Store.search` method. You can now toggle combinations of filters:
  - Specific Moods (1-5 Emoji ratings)
  - Content Types (Has Photo, Video, or Audio)
  - Bookmarks (Starred only)
- **Real-time Engine**: The search engine instantly evaluates text queries combined with any active filter chips to dynamically update the results list.

## Phase 5: iOS Home Screen Widget
A beautiful SwiftUI widget that lives on the user's home screen.
- **Streak Counter**: Large, bold number showing the user's current journaling streak with a fire emoji.
- **New Entry Button**: A pink capsule button that opens the app directly to create a new entry.
- **Dynamic Messaging**: Shows "Captured today! 🌸" if the user has journaled, or "Have you journaled today?" if not.
- **Data Sync**: `Store.dart` pushes streak + status to the widget's shared App Group UserDefaults every time an entry is saved or deleted.
- **Warm Gradient Design**: Matches the Roze app aesthetic with soft pinks and greens.

### Files Modified/Created
| File | Action |
|------|--------|
| [HomeScreenWidget.swift](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/ios/HomeScreenWidget/HomeScreenWidget.swift) | SwiftUI widget code |
| [Runner.entitlements](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/ios/Runner/Runner.entitlements) | Added App Group |
| [HomeScreenWidgetExtension.entitlements](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/ios/HomeScreenWidget/HomeScreenWidgetExtension.entitlements) | New entitlements |
| [store.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/store.dart) | `_updateHomeWidgets()` |
| [main.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/main.dart) | `HomeWidget.setAppGroupId` |

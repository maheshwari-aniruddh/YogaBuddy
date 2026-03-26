# 5 Major Features Implementation

## Phase 1: Core Data Model & Migration
- [x] Add `uuid` package
- [x] Add `id` to `JournalEntry`
- [x] Change `photoPath` to `List<String> photos` in `JournalEntry`
- [x] Write migration logic in `JournalEntry.fromJson` for old data
- [x] Ensure `Store` correctly handles saving/loading the new format without data loss

## Phase 2: Today Screen UI & Multiple Entries
- [x] Update `TodayScreen` summary to show a timeline of today's entries
- [x] Add "New Entry" FAB/button to trigger the swiping editor
- [x] Update the swipe editor to insert/update the specific entry ID
- [x] Update media preview strips to handle `List<String> photos`

## Phase 3: Rich Text Formatting
- [x] Add `flutter_markdown` package
- [x] Create a formatting toolbar for the text fields (Bold, Italic, List)
- [x] Render entry summaries using `MarkdownBody`

## Phase 4: Advanced Search & Filtering
- [x] Add `mood` filter (1-5 rating) UI and logic
- [x] Add `hasMedia` checkbox filters (Photo/Audio/Video)
- [x] Add `isStarred` toggle filter
- [x] Update `Store.search` to accept these filters and execute real-time combined filtering

## Phase 5: Home Screen Widgets
- [x] Add `home_widget` package
- [x] Implement iOS SwiftUI widget (Streak + New Entry Button)
- [x] Update `Store` to sync data to widgets on save

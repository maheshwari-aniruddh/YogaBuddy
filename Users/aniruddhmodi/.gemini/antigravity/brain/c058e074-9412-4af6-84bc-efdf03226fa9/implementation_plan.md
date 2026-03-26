# Implementation Plan: 5 Major Features

Implementing these 5 features requires a fundamental change to the app's data model and architecture. To do this elegantly and safely—without breaking existing user data or the `TodayScreen` swiping gesture—we will break the work into 4 logical phases.

## Phase 1: Core Data Model & Migration (The Foundation)
Currently, `JournalEntry` relies on the `date` as its unique identifier (1 entry per day). To support multiple entries, we must introduce unique IDs to the data model.

### Goal
- Add `id` (UUID) to `JournalEntry`.
- Support multiple media files: change `photoPath` to `List<String> photos`.
- Support rich text: ensure text fields can store Markdown/HTML or just plain text with formatting markers.
- Update `Store` to handle `Map<String, List<JournalEntry>>` or a flat `List<JournalEntry>`.
- **Migration Logic:** Write a robust backward-compatibility layer in `Store._loadData` that converts old single-entry JSON to the new multi-entry format with generated UUIDs.

## Phase 2: Today Screen UI & Multiple Entries
The user specifically requested we **do not break the vertical vertical swiping gesture** on the journal entry page.

### Goal
- Keep the existing `PageView` / `GestureDetector` vertical swipe for navigating between "What went well?", "What was challenging?", and "Gratitude".
- On the main `TodayScreen` summary (before entering edit mode), show a **Timeline** of today's entries.
- Add a floating action button or "New Entry" button allowing the user to start a fresh sequence of the 3 fields for the same day.
- Update the Media Gallery to display multiple photos in a horizontal scrollable strip (`ListView.builder` or `Wrap`).

## Phase 3: Rich Text Formatting & Editor
To make entries beautiful and expressive.

### Goal
- Integrate a rich text or Markdown toolbar above the keyboard when a user is typing.
- Provide simple formatting options: **Bold**, *Italic*, Bulleted Lists.
- We will use `flutter_markdown` for rendering and a custom toolbar for the standard Flutter `TextField` (passing styled text or markdown tags). This avoids massive structural changes to the text fields and keeps the swiping intact.

## Phase 4: Advanced Search & Filtering
### Goal
- Revamp `SearchScreen`.
- Add filter chips below the search bar: 
  - Mood (filter by 1-5 rating)
  - Has Photo / Audio / Video
  - Starred only
- Real-time combined filtering (e.g., Search "Panera" + Mood: 5 + Has Photo).

## Phase 5: Home Screen Widgets
### Goal
- Add the `home_widget` package.
- **iOS:** Write a small SwiftUI widget extension that reads shared group defaults (latest streak, current mood).
- **Android:** Write a Kotlin AppWidgetProvider.
- Both widgets will update from the Flutter side when a new entry is saved.

---

> [!CAUTION]
> This is a massive update that touches almost every file in the app (Calendar, Stats, Search, PDF Export all need to handle `List<JournalEntry>` per day instead of just one).
>
> We *must* do Phase 1 (Data Model & Migration) first and ensure perfectly smooth backward compatibility before touching the UI.

## User Review Required
Please review the phased approach. 
1. Are you okay with adding a "Timeline" view on the main today screen that lets you view all of today's entries, and a "New Entry" button that opens the familiar swiping vertical editor?
2. Shall I proceed with **Phase 1 (Data Model Migration)**?

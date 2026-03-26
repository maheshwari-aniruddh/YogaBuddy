# Feature Gap Analysis: Roze Journal App

After a deep review of the codebase (models, screens, services, and dependencies), Roze is already a very robust journaling app with an impressive feature set (Mood tracking, Calendar Heatmap, Audio/Video/Photo support, Location Prompts, iCloud/Drive Backup, FaceID/TouchID, and PDF Exports).

However, compared to top-tier journaling apps (like Day One, Apple Journal, or Journey), here are the **essential features** currently missing, categorized by importance:

---

## 🔴 High Priority (Core Journaling Experience)

### 1. Multiple Entries Per Day
**Current State:** The app allows exactly *one* entry per day (overwriting the existing one if saved again).
**The Gap:** Real journaling doesn't happen just once. Users want to log a morning reflection, a quick thought at 2 PM, and an evening recap.
**Solution:** Change the data model from `Map<Date, Entry>` to a `List<Entry>` per day, and update the UI to show a timeline of entries for a given date rather than just one.

### 2. Rich Text Formatting (Markdown)
**Current State:** The text fields (`good`, `bad`, `gratitude`) are plain string text.
**The Gap:** Users love to use **bolding**, *italics*, bulleted lists, and headers to structure their thoughts.
**Solution:** Implement a Markdown or Rich Text editor (e.g., using `flutter_quill` or `flutter_markdown`) and update the `JournalEntry` model to store rich text data.

### 3. Media Gallery / Inline Photos
**Current State:** The `JournalEntry` model supports exactly one `photoPath`, one `videoPath`, and one `audioPath`.
**The Gap:** Users often want to attach *multiple* photos to an entry (e.g., a trip recap) or place photos inline between paragraphs.
**Solution:** Change `photoPath: String?` to `photos: List<String>` and add a horizontal scrolling media gallery to the entry viewer and editor.

---

## 🟡 Medium Priority (Growth & Retention)

### 4. Advanced Search & Filtering
**Current State:** There is a basic search (`search_screen.dart`), presumably searching text.
**The Gap:** As journals grow (years of data), users need to filter by **Mood**, **Location**, **Has Photo/Audio**, or **Tags**. (Note: the `tags` field is in the model, but I saw in the conversation history that tags were removed from the UI).
**Solution:** Add a filter drawer to the search screen allowing users to say "Show me all entries where Mood = 5 and contains 'Panera'".

### 5. Home Screen Widgets (iOS / Android)
**Current State:** No native widgets exist in the iOS/Android folders.
**The Gap:** Widgets are the #1 way to keep journaling apps top-of-mind. Users want to see their "Current Streak" or a "Daily Prompt" right on their home screen.
**Solution:** Use Flutter's `home_widget` package to build native iOS (SwiftUI) and Android (Kotlin/XML) widgets that read from shared preferences.

### 6. Customizable daily layout / Templates
**Current State:** Every entry forces the user through 3 specific fields: "What went well?", "What was challenging?", and "Gratitude".
**The Gap:** Not everyone journals this way. Some just want an open canvas ("Free write"), others want specific morning/evening templates.
**Solution:** Add a "Journal Style" settings page allowing users to customize the questions asked, or disable the 3-field layout in favor of a single large text box.

---

## 🟢 Low Priority (Nice-to-Haves / "Delight" Features)

### 7. "On This Day" Throwbacks
**The Gap:** The app doesn't currently remind users of past entries.
**Solution:** A notification or a special card on the `TodayScreen` that says "1 year ago today, you wrote..." to drive emotional engagement.

### 8. Voice-to-Text Transcription
**Current State:** You have audio recording (`record` package).
**The Gap:** Users love to rant via voice, but they also want to *read* what they ranted about later without listening to the whole file.
**Solution:** Use Apple's Speech framework (via platform channel) or a cloud API to transcribe audio entries into the text field.

---

### Recommendation for Next Steps
If you want to tackle the most impactful feature next, I highly recommend **Multiple Entries Per Day** or **Multiple Photos per Entry**. These are the most common friction points that cause users to abandon a journaling app.

*Which of these areas are you most interested in pursuing next?*

# Music to Notes Converter Feature

Add a new tab/page to the AirJam frontend that allows users to upload audio files (MP3, WAV) and convert them to piano notes using the `basic-pitch` library.

## Proposed Changes

### Backend Component

#### [NEW] [music_converter.py](file:///Users/aniruddhmodi/Documents/PycharmProjects/AirPlay%20copy/music_converter.py)
A Flask/FastAPI server that:
- Accepts audio file uploads
- Uses `basic-pitch` library to convert audio to MIDI/notes
- Returns JSON with detected notes and their timing

---

### Frontend Component

#### [NEW] [converter.html](file:///Users/aniruddhmodi/Documents/PycharmProjects/AirPlay%20copy/airplay%202/converter.html)
New page with:
- File upload area (drag & drop or click to select)
- Processing status indicator
- Results display showing detected notes with piano roll visualization
- Option to play the detected notes

#### [MODIFY] [instruments.html](file:///Users/aniruddhmodi/Documents/PycharmProjects/AirPlay%20copy/airplay%202/instruments.html)
Add a third instrument option card linking to the converter page with music note icon.

## Verification Plan

### Manual Verification
1. Start the backend: `cd /Users/aniruddhmodi/Documents/PycharmProjects/AirPlay\ copy && .venv/bin/python music_converter.py`
2. Start frontend: `cd /Users/aniruddhmodi/Documents/PycharmProjects/AirPlay\ copy/airplay\ 2 && python3 -m http.server 9000`
3. Navigate to http://localhost:9000/instruments.html
4. Verify "Music Converter" card appears alongside Piano and Drums
5. Click on converter, upload an audio file
6. Verify notes are detected and displayed

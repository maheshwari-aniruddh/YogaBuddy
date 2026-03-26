# Live Band / Jam Session Integration

- [x] Copy `session_server.py` to project root
- [x] Update `start.sh` to launch jam server on port 8502
- [x] Add Jam Session button + pages to `instruments.html`
- [x] Add Jam logic to `app.js`
- [x] Append jam CSS to `styles.css`
- [x] Verify servers start and UI loads correctly
- [x] Update ngrok server link for remote jam sessions
- [x] Fix room validation race condition in session server
- [x] Implement player join/leave notifications (toasts)
- [x] Synchronize bi-directional audio (Piano hears Drums & vice versa)

## Bass Guitar Implementation Plan

- [x] Check and ensure `Bass sounds` directory has correct WAV files.
- [x] Add `load_bass_samples` and `play_bass_note` to `AudioEngine` in `ar_studio.py`.
- [x] Add bass string/fret constants and `detect_bass_pluck`, `get_string_index`, `get_fret_zone`, `update_wobble` to `HandPhysics` in `ar_studio.py`.
- [x] Add bass mode camera loop rendering (strings, pluck detection, visual wobble, fret indicator) to `ar_studio.py`.
- [x] Add Bass Guitar card to `instruments.html`.
- [x] Update `app.js` `loadInstrument` handler for bass (skipped, used `bass.html` direct link).
- [x] Update `styles.css` with Bass card styles.
- [x] Match Bass Guitar page visual design to existing app themes (`styles.css` matching).
- [x] Ensure ALL instrument pages use dynamic AR camera iframe URLs for remote ngrok sessions.
- [x] Test Bass mode functionality (audio, visual, pluck detection, and detailed SOP UI).

## Bug Fixes & Refinements
- [x] Implement ngrok Reverse Proxy on Session Server (8502 -> 8768, 8766) to allow remote access to Streamlit and Music APIs.
- [x] Update `bass.html`, `piano-composer.html`, and `instruments.html` AR iframe URLs to use the `/streamlit/` proxy.
- [x] Update `piano-player.html` song fetch API URL to use the `/api/` proxy.
- [x] Shrink Piano Player fingertip glow radius to fix UI crowding.
- [x] Mute incorrect note pitch shifting when playing actual songs in Piano Player Mode.
- [x] Replace Piano web audio synthesizer with real pre-recorded `.wav` acoustic piano samples.

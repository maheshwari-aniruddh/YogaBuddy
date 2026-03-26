# Bass Guitar Implementation Plan

## Goal
Implement a new "Bass Guitar" mode that uses computer vision to detect string plucks and fret hand positions to synthesize and play 4-string bass audio, exactly per the provided SOP.

## Proposed Changes

### `ar_studio.py`
- **AudioEngine**: Add `load_bass_samples()` to load `Bass sounds/` files. Add `play_bass_note()` to calculate pitch shifts (resampling) based on semitone offsets.
- **HandPhysics**: Add constants and methods for tracking the 4 strings (`detect_bass_pluck`, `get_string_index`, `get_fret_zone`, `update_wobble`).
- **Main Loop**: Implement "bass" mode logic. Draw strings, detect plucks, play audio, send WebSocket events to frontend, and render visual wobble and hand indicators.

### `instruments.html`
- Add a new `.instrument-card` for the Bass Guitar.

### `app.js`
- Update `loadInstrument()` handler to route to the bass mode (`/?mode=bass`).

### `styles.css`
- Add styling for the `.bass-card`.

## Verification Plan
1. Launch `ar_studio.py`.
2. Open `instruments.html` and click Bass Guitar.
3. Verify AR strings appear, right hand plucks trigger sound and wobble, and left hand changes pitch.

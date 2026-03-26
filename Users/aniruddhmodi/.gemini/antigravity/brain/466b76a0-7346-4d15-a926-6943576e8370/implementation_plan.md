# Frontend + Backend Integration Plan

## Goal
Embed the Python ar_studio.py (hand tracking + audio) into the HTML/CSS frontend from "airplay 2".

## Architecture
```
HTML Frontend (index.html, instruments.html)
    ├── Landing Page (pure HTML/CSS)
    ├── Piano Practice → [IFRAME: Streamlit Piano]
    └── Drums Practice → [IFRAME: Streamlit Drums]
```

## Proposed Changes

### 1. Replace Camera Videos with Iframes
**File**: `instruments.html`
- **Piano Practice** (line ~305): Replace `<video id="piano-video">` with:
    ```html
    <iframe src="http://localhost:8501/?mode=piano" class="ar-embed" frameborder="0"></iframe>
    ```
- **Drums Practice** (line ~467): Replace `<video id="drums-video">` with:
    ```html
    <iframe src="http://localhost:8501/?mode=drums" class="ar-embed" frameborder="0"></iframe>
    ```

### 2. Modify ar_studio.py for Embedding
- Read `mode` from URL query param (via `st.query_params`)
- Hide sidebar when embedded
- Auto-start without checkbox

### 3. Create Launch Script
```bash
#!/bin/bash
# Start Streamlit backend
./.venv/bin/streamlit run ar_studio.py &
# Open frontend
open "airplay 2/index.html"
```

## Verification
1. Run launch script
2. Click "Piano Practice" → Should show Streamlit AR camera
3. Click "Drums Practice" → Should show Streamlit AR camera

# AirPlay Instruments - Final Walkthrough

## Navigation Flow
```
index.html (Landing)
    └── instruments.html (Choose Instrument)
            ├── piano.html → piano-player.html (AR Camera)
            │              → piano-composer.html (Click keyboard)
            └── drums.html → drums-player.html (AR Camera)
                           → drums-composer.html (Click pads)
```

## New Pages Created
| File | Purpose |
|------|---------|
| `piano.html` | Piano mode selection (Player/Composer) |
| `drums.html` | Drums mode selection (Player/Composer) |
| `piano-player.html` | AR camera with hand tracking |
| `drums-player.html` | AR camera with hand tracking |
| `piano-composer.html` | Clickable keyboard |
| `drums-composer.html` | Clickable drum pads |

## How to Run
```bash
# 1. Start backend
./.venv/bin/streamlit run ar_studio.py --server.headless true &

# 2. Open frontend
open "airplay 2/index.html"
```

## Features
- **Auto-thresholds**: Piano=0.5, Drums=0.15
- **Embedded AR**: Player Mode uses iframe to Streamlit
- **Composer Mode**: Web Audio API for instant feedback

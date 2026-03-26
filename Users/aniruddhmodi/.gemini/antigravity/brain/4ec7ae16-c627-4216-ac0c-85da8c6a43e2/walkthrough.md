# Geometry Dash Premium - Walkthrough

## Overview
A "AAA" quality web-based clone of Geometry Dash features premium visuals (Bloom, Particles) and procedurally generated levels with 10 unique themes.

![Game Instructions](https://placeholder.com/controls "Click/Space to Jump")

## How to Play
1.  **Start/Restart**: Click anywhere on the screen.
2.  **Jump**: Press `Spacebar`, `Arrow Up`, or `Click/Tap`.
3.  **Progression**: 
    - Avoid Spikes (Triangles) and Blocks (Squares).
    - Hitting an obstacle will **reset the level** and **advance you to the next visual theme** (for demonstration purposes).

## Features Verified
- [x] **Core Engine**: Three.js rendering with 60FPS physics.
- [x] **Premium Visuals**: 
    - **Bloom**: Glowing neon edges.
    - **Chromatic Aberration**: Glitch effects on screen.
    - **Particles**: Functional trail system.
- [x] **Audio**: Generative beat detection syncing visuals (the player "pulses" to the beat).
- [x] **Level Themes**: 10 distinct themes implemented.

## Level Themes
Try dying to cycle through these themes:
1.  **Welcoming Tutorial**: Soft Blue/Pink.
2.  **Energy Rising**: Neon Cyan/Yellow.
3.  **Sky Kingdom**: Gold/Airy Blue.
4.  **Velocity Rush**: Red/Orange Speed.
5.  **Zero Gravity**: Deep Space/Starfield.
6.  **Digital Matrix**: Matrix Green.
7.  **Prism Palace**: Rainbow/Crystal.
8.  **Shadow Realm**: High Contrast Black/White.
9.  **Inferno Core**: Lava Red/Orange.
10. **Transcendence**: Maximum Intensity.

## Technical Details
- **Stack**: Vite + Three.js
- **Post-Processing**: `postprocessing` library used for UnrealBloom and Custom Shaders.
- **Performance**: Optimized geometry reuse (though basic Mesh allocation is used for simplicity).

## Troubleshooting
- If the screen is black, ensure your browser supports WebGL 2.0.
- If audio doesn't play, interact with the document (click) as browsers block autoplay.

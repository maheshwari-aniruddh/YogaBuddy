# Implementation Plan - Geometry Dash Premium (Web Edition)

## Goal Description
Create a "AAA" quality clone of Geometry Dash usable as a localhost website. The focus remains on **premium visuals**: dynamic bloom, particles, and shaders, using **WebGL (Three.js)**.

## User Review Required
> [!IMPORTANT]
> **Tech Stack Constraint**: Since you asked for a "localhost website", we are switching from Python to **Node.js + Vite + Three.js**. This is the industry standard for high-performance 3D/2D graphics in the browser.

## Proposed Changes

### Project Structure (Web)
- `index.html`: Main entry point.
- `package.json`: Dependencies.
- `vite.config.js`: Build config.
- `src/`:
  - `main.js`: Game initialization.
  - `core/`:
    - `Game.js`: Main loop.
    - `Renderer.js`: Three.js setup + Post-Processing.
    - `Input.js`: Event listeners.
  - `entities/`:
    - `Player.js`: Cube logic, physics.
    - `Level.js`: Map management.
  - `effects/`:
    - `Particles.js`: Visual effects.
    - `ShaderPasses.js`: Custom shaders (Aberration, etc).
  - `utils/`: audio, math.

### Graphics Pipeline (Three.js)
1. **Scene Graph**:
   - Player (Mesh with glowing material).
   - Obstacles (InstancedMesh for performance).
   - Backgrounds (Planes at different depths for Parallax).
2. **Post-Processing (EffectComposer)**:
   - **RenderPass**: Draw the scene.
   - **UnrealBloomPass**: The "Neon" look. Reliable and fast.
   - **ShaderPass**: Chromatic Aberration & Vignette.
   - **OutputPass**: Tone mapping.

### Game Logic
- **Physics**: Custom AABB (Axis-Aligned Bounding Box) physics. Geometry Dash requires precise, non-floaty physics, so we will write a custom integrator rather than using a heavy engine like Cannon.js.
- **Audio**: Web Audio API to analyze frequency data and drive "Scale" animations for the "Pulsing" effect.

## Verification Plan
### Automated Tests
- None.

### Manual Verification
- Run `npm run dev`.
- Open `http://localhost:5173`.
- Verify the Cube jumps, trails appear, and Bloom makes everything glow.

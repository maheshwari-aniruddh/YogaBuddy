# PoseFlow Stable Implementation Plan

The project is now in a stable "Hybrid" state, optimized for ease of use and development.

## Deployment Architecture
- **Frontend**: Hosted on GitHub Pages at `https://maheshwari-aniruddh.github.io/PoseFlow/`.
- **Backend**: Runs locally on the user's machine to handle heavy MediaPipe and KNN processing.

## Key Features Implemented
- **Full Rebranding**: All references to YogaBuddy/OneBreath updated to **PoseFlow**.
- **Automated Deployment**: GitHub Actions workflow (`deploy.yml`) builds and pushes the React app to the `gh-pages` branch.
- **Routing**: React Router configured with `basename="/PoseFlow/"` for subdirectory hosting.
- **Disclaimer**: Clear UI messaging informs users that AI features require the local backend.

## Instructions for Use
1. Clone the `PoseFlow` repository.
2. Run `./start_yoga_web.sh` to start the local ML server.
3. Access the live website and start a session.

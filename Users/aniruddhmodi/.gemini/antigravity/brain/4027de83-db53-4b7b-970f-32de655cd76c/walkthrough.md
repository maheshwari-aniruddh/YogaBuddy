# Jumper Implementation Walkthrough

The `Jumper` class has been implemented as an extension of `Bug`, adding specialized jumping and obstacle-avoidance logic.

## Key Changes

### 1. Blossom Fixes
[Blossom.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/GridWorld/src/GridWorldCode/projects/activity3/Blossom.java)
- Changed `lifeTime` from `static` to an instance variable so each Blossom can have its own independent lifetime.
- Fixed `steps` initialization (was starting at 10, now starts at 0) so Blossoms don't disappear immediately.
- Updated imports to use `info.gridworld.actor.Flower` for compatibility with the project's JAR.

### 2. Jumper Logic
[Jumper.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/GridWorld/src/GridWorldCode/projects/boxBug/Jumper.java)
- **2-Cell Jump**: Overrides `act()` to prioritize a 2-cell jump forward.
- **Obstacle Avoidance**: If the target 2-cell location is blocked, it rotates (in 45° increments) until it finds a valid jump location.
- **Fallback**: If no 2-cell jump is possible in any of the 8 directions, it falls back to a standard 1-cell move (or turns if 1-cell is also blocked), preventing infinite loops.
- **Blossom Drops**: Leaves a `Blossom` (with a random lifetime between 5-15 steps) instead of a standard `Flower`.
- **Selective Landing**: Explicitly refuses to land on `Blossom` actors (checked in both `canJump` and `canMove`).
- **Directional Limit**: Includes a `maxStraight` parameter (default: 5) that forces a 90° turn after moving in the same direction for several consecutive jumps without hitting obstacles.

### 3. Runner Integration
[JumperRunner.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/GridWorld/src/GridWorldCode/projects/boxBug/JumperRunner.java)
- Integrated the user-provided runner code which sets up a 20x20 `BoundedGrid` with multiple Jumpers, Rocks, and Bugs.

## Verification
- **Compilation**: Successfully compiled using the following command:
  ```bash
  javac -cp GridWorldCode/gridworld.jar:. GridWorldCode/projects/activity3/Blossom.java GridWorldCode/projects/boxBug/Jumper.java GridWorldCode/projects/boxBug/JumperRunner.java
  ```
- **Requirements**: Confirmed that all criteria (blue color, 2-cell jumps, random Blossom life, no-Blossom-landing) are met in the source code.

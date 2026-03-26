# Jumper Class Implementation

Implement a `Jumper` that extends `Bug` in GridWorld. The Jumper is blue, jumps 2 cells forward (over obstacles), leaves `Blossom`s instead of `Flower`s, and has special fallback + direction-change behavior.

## Proposed Changes

### Jumper Component

#### [NEW] [Jumper.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/GridWorld/src/GridWorldCode/projects/boxBug/Jumper.java)

A new class extending `Bug` with:

- **Color**: Blue by default
- **`act()`**: Tries to jump 2 cells forward. If it can't, tries all other directions (turning 45° at a time). If ALL directions are blocked at 2-away, falls back to moving 1 cell forward (like a normal bug). Faces the direction it moved.
- **`canJump(int direction)`**: Checks if the cell 2 away in a given direction is valid, empty, and not a `Blossom`.
- **`jump()`**: Moves to the cell 2 ahead and leaves a `Blossom` (with random lifetime) at the old location.
- **`move()`**: Overridden to leave a `Blossom` instead of a `Flower`, used as 1-cell fallback.
- **Straight-line limit**: A `maxStraight` parameter — after moving this many times in the same direction without hitting an obstacle, the Jumper changes direction.
- **No landing on Blossoms**: `canJump()` treats `Blossom` as occupied.

#### [MODIFY] [Blossom.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/GridWorld/src/GridWorldCode/projects/activity3/Blossom.java)

- Fix `steps` to start at `0` (currently starts at `10`, which means a Blossom with default lifetime of 10 dies immediately).
- Make `lifeTime` an instance variable (currently `static`, which means all Blossoms share the same lifetime — changing one changes all).

---

### Runner

#### [NEW] [JumperRunner.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/GridWorld/src/GridWorldCode/projects/boxBug/JumperRunner.java)

A runner that creates a grid with a `Jumper`, some `Rock`s and `Flower`s as obstacles to showcase the jumping behavior.

## Verification Plan

### Manual Verification
1. Run `JumperRunner` from IntelliJ (right-click → Run)
2. Verify the Jumper:
   - Is **blue**
   - **Jumps over** rocks and flowers (moves 2 cells at a time)
   - Leaves **Blossoms** (not Flowers) that disappear after varying lifetimes
   - **Changes direction** when it can't jump 2 ahead, trying other directions
   - **Falls back to 1-cell move** only when no 2-cell jump is possible in any direction
   - **Does not land on Blossoms**
   - Changes direction after moving straight for `maxStraight` steps without obstacles

# GridWorld Class Notes

Here are detailed notes on the core GridWorld classes, plus the custom `Jumper` and `Blossom` classes. The classes follow an inheritance hierarchy where `Actor` is the base class for everything that appears in the grid.

## 1. `Actor` (The Base Class)
`Actor` is the fundamental class in GridWorld. Everything that can be placed in a grid (Bugs, Rocks, Flowers, Critters) extends `Actor`.

**Key State/Properties:**
- `color`: The visual color of the actor (default: `Color.BLUE`).
- `direction`: An integer representing the angle the actor is facing (0-359 degrees, default: `Location.NORTH` or 0).
- `location`: The current `Location` (row, col) in the grid.
- `grid`: The `Grid<Actor>` that currently contains the actor.

**Key Methods:**
- `getColor() / setColor(Color c)`: Gets/sets the actor's color.
- `getDirection() / setDirection(int dir)`: Gets/sets the facing direction (automatically wraps angles to 0-359).
- `getLocation()`: Returns the actor's current location in the grid.
- `getGrid()`: Returns the grid containing the actor (or `null` if it's not in a grid).
- `putSelfInGrid(Grid<Actor> gr, Location loc)`: Places the actor into the specified grid at the specified location. Also removes any existing actor at that location.
- `removeSelfFromGrid()`: Removes the actor from its grid (leaving the location empty).
- `moveTo(Location newLocation)`: Moves the actor from its current location to a new one within the same grid. If an actor is already there, it is removed.
- `act()`: The default behavior for an Actor. By default, it simply turns 180 degrees (`setDirection(getDirection() + Location.HALF_CIRCLE)`). Subclasses usually override this.

---

## 2. `Bug` (extends `Actor`)
A `Bug` is a specific type of actor that moves straight forward and drops a `Flower` in its previous location. When blocked, it turns right.

**Default Behavior (`act()`):**
- Checks if it can move forward (`canMove()`).
- If yes, it moves a step forward (`move()`).
- If no, it turns 45 degrees to the right (`turn()`).

**Key Methods:**
- `act()`: Moves if it can; otherwise, it turns.
- `turn()`: Changes direction 45 degrees to the right (`Location.HALF_RIGHT`).
- `move()`: Moves to the adjacent cell in its current direction. Drops a new `Flower` of the same color in the location it just left.
- `canMove()`: Checks if the cell directly in front is valid (inside the grid) and either empty or containing a `Flower` (Bugs can trample flowers, but not rocks or other bugs).

---

## 3. `Critter` (extends `Actor`)
A `Critter` is a more complex actor that follows a specific 5-step behavioral pattern every time it acts.

**The 5-Step `act()` Cycle (DO NOT OVERRIDE `act()` IN SUBCLASSES):**
1. `getActors()`: Finds the actors it interacts with (default: gets all immediately adjacent neighbors).
2. `processActors(ArrayList<Actor> actors)`: Does something to those actors. The default Critter "eats" (removes from grid) any actor that is not a `Rock` and not another `Critter`.
3. `getMoveLocations()`: Finds possible places it can move to (default: gets all empty adjacent locations).
4. `selectMoveLocation(ArrayList<Location> locs)`: Chooses one of those locations (default: picks one randomly).
5. `makeMove(Location loc)`: Moves to the chosen location. If the location is `null`, the critter removes itself from the grid.

*Note: When making custom Critters (like ChameleonCritter or CrabCritter), you override these 5 individual methods (usually `getActors`, `processActors`, or `getMoveLocations`), never the `act()` method itself.*

---

## 4. `Flower` (extends `Actor`)
A `Flower` is an actor dropped by a `Bug`. Its only behavior is that its color darkens over time.

**Key Features:**
- `DEFAULT_COLOR`: Pink.
- `act()`: Every step, it darkens its color by 5% (`DARKENING_FACTOR = 0.05`). This gives a visual history of where a bug has been (freshly dropped flowers are bright, old ones are dark).

---

## 5. `Blossom` (extends `Flower`)
`Blossom` is a custom subclass of `Flower` designed to have a limited lifespan before automatically removing itself from the grid.

**Key Additions:**
- `lifeTime`: How many steps the Blossom exists before dying.
- `steps`: A counter tracking how long the Blossom has been alive.
- `act()`: Calls `super.act()` to darken like a normal flower, then increments its `steps` counter. If `steps` >= `lifeTime`, it calls `removeSelfFromGrid()`.

---

## 6. `Jumper` (extends `Bug`)
`Jumper` is a custom subclass of Bug with advanced movement logic.

**Defined Behaviors (`act()`):**
- **Straight Line Limit**: If it moves straight without obstacles for a set number of steps (`maxStraight`), it forces a 90-degree turn to prevent getting stuck in infinite loops.
- **2-Cell Jump**: Tries to jump to the cell exactly 2 spaces ahead, ignoring whatever is in the middle adjacent cell.
- **Direction Rotation**: If it can't jump straight, it checks the other 7 directions (rotating 45 degrees at a time) to find a valid 2-cell jump.
- **1-Cell Fallback**: If *no* 2-cell jump is possible in *any* direction, it falls back to a normal `Bug` move (1 cell forward).
- **Blossom Dropping**: When it jumps or moves, it leaves a `Blossom` behind (with a random lifespan) instead of a standard `Flower`.

**Key Custom Methods:**
- `canJump(int direction)`: Checks if the cell 2 spaces away in the given direction is valid and empty (or contains a regular `Flower`). Explicitly returns `false` if the target contains a `Blossom`, preventing Jumpers from trampling Blossoms.
- `jump(int direction)`: Moves the Jumper to the target location 2 cells away and places a `Blossom` at the old location.
- Overridden `move()` and `canMove()`: Used for the 1-cell fallback. Overridden specifically to drop `Blossom`s instead of Flowers, and to respect the "do not step on Blossoms" rule.

---

## 7. `Grid<E>` (Interface)
The `Grid` interface defines how objects (usually `Actor`s) are stored and tracked in a 2D environment. It is typically implemented by `BoundedGrid` (fixed size walls) or `UnboundedGrid` (infinite size).

**Key Methods:**
- `getNumRows() / getNumCols()`: Dimensions of the grid (-1 if unbounded).
- `isValid(Location loc)`: Checks if a location actually exists within the grid boundaries.
- `put(Location loc, E obj)`: Adds an object to a specific location.
- `remove(Location loc)`: Removes and returns whatever is at that location.
- `get(Location loc)`: Returns the object at that location (or `null` if empty).
- `getOccupiedLocations()`: Returns a list of all locations currently holding an object.
- **Neighbor Methods**: Used heavily by actors (like Critters) to survey their surroundings:
  - `getValidAdjacentLocations(Location loc)`: Returns up to 8 surrounding valid locations.
  - `getEmptyAdjacentLocations(Location loc)`: Returns surrounding locations that have nothing in them.
  - `getOccupiedAdjacentLocations(Location loc)`: Returns surrounding locations that have something in them.
  - `getNeighbors(Location loc)`: Returns a list of the actual *objects* in the adjacent occupied locations.

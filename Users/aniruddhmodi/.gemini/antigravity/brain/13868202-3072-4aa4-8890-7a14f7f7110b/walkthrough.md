# Walkthrough - FullBoundedGrid Implementation

I have implemented a new type of grid, `FullBoundedGrid`, which uses a standard 2D array (`Object[][]`) for storage. This implementation is separated into its own directory and contains no comments as requested.

## Changes Made

### [FullGrid Project]

#### [NEW] [FullBoundedGrid.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/GridWorld/src/GridWorldCode/projects/fullGrid/FullBoundedGrid.java)
A bounded grid implementation using a 2D array.

#### [NEW] [FullGridRunner.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/GridWorld/src/GridWorldCode/projects/fullGrid/FullGridRunner.java)
A runner that populates a 10x10 `FullBoundedGrid` with blue rocks and a critter to demonstrate it.

## Verification Results

### Automated Tests
- Compiled both files successfully using `javac` with `gridworld.jar` in the classpath.
- The build was successful without errors.

```bash
javac -cp .:gridworld.jar projects/fullGrid/*.java
```

### Manual Verification
- The code is ready to be run. You can run it with:
```bash
java -cp .:gridworld.jar projects.fullGrid.FullGridRunner
```
(Note: Assuming the class is part of the default package or adjust according to your classpath structure). Since I didn't add a package, it should be:
```bash
java -cp .:gridworld.jar FullGridRunner
```
from the `projects/fullGrid` directory, or if you run from root:
```bash
java -cp .:gridworld.jar projects/fullGrid/FullGridRunner
```
Actually, `java` needs the class name.
If you are in `src/GridWorldCode/`:
`java -cp .:gridworld.jar:projects/fullGrid FullGridRunner`

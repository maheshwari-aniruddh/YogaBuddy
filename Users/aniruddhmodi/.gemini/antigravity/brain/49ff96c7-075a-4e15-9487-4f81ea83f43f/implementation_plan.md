# GridWorld Bug Commands

This plan outlines the commands to compile and run the various GridWorld bug projects: `CircleBug`, `ZBug`, `SpiralBug`, `DancingBug`, and `JumperRunner`.

## Proposed Commands

All commands should be run from the `src` directory of the project:
`/Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/GridWorld/src`

### 1. Compile All Bugs
To compile all the bug classes and runners in the `boxBug` project:
```bash
javac -cp .:GridWorldCode/gridworld.jar GridWorldCode/projects/boxBug/*.java
```
> [!NOTE]
> `SpiralBug.java` appears to be missing from the source directory, but its compiled `.class` file is present. If you need to recompile it, please ensure `SpiralBug.java` is restored.

### 2. Run Commands

#### CircleBug
```bash
java -cp .:GridWorldCode/gridworld.jar GridWorldCode.projects.boxBug.CircleBugRunner
```

#### ZBug
```bash
java -cp .:GridWorldCode/gridworld.jar GridWorldCode.projects.boxBug.ZBugRunner
```

#### DancingBug
```bash
java -cp .:GridWorldCode/gridworld.jar GridWorldCode.projects.boxBug.DancingBugRunner
```

#### JumperRunner
```bash
java -cp .:GridWorldCode/gridworld.jar GridWorldCode.projects.boxBug.JumperRunner
```

#### SpiralBug
```bash
java -cp .:GridWorldCode/gridworld.jar GridWorldCode.projects.boxBug.SpiralBugRunner
```

## Verification Plan
I will verify these commands by attempting to run one of them (e.g., `JumperRunner`) to ensure the classpath and package names are correct.

### Automated Tests
- Run `JumperRunner` to confirm environment setup.

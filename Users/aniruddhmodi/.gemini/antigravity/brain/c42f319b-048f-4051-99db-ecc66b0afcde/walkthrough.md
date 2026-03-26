# Sudoku Solver Skeleton Walkthrough

I've created the `SudokuSolver.java` file with the necessary boilerplate and helper methods as requested. The recursive `solve` method is left empty for you to implement.

## Changes
### [NEW] [SudokuSolver.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/Soduko/src/SudokuSolver.java)
- **`main(String[] args)`**: Sets up a sample board and calls the methods.
- **`printBoard(int[][] board)`**: Prints the formatted Sudoku grid.
- **`isValid(int[][] board, int row, int col, int num)`**: Checks if a move is valid.
- **`solve(int[][] board)`**: **TODO** - This is where you will add your recursive backtracking logic.

## Verification Results
I compiled and ran the code to ensure the structure is correct.

```bash
original Board:
5 3 0 | 0 7 0 | 0 0 0 
6 0 0 | 1 9 5 | 0 0 0 
0 9 8 | 0 0 0 | 0 6 0 
---------------------
8 0 0 | 0 6 0 | 0 0 3 
4 0 0 | 8 0 3 | 0 0 1 
7 0 0 | 0 2 0 | 0 0 6 
---------------------
0 6 0 | 0 0 0 | 2 8 0 
0 0 0 | 4 1 9 | 0 0 5 
0 0 0 | 0 8 0 | 0 7 9 
... Solve method not yet implemented ...

Unsolvable board
```

You are ready to start coding the `solve` method!

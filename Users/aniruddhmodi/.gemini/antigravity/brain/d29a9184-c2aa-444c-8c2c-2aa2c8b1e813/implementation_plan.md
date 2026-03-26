# SimpleCalc Part 2 — Variables & Identifiers

Add variable/identifier support to SimpleCalc per the `SimpleCalcP2.pdf` assignment.

## Proposed Changes

### Identifier Class

#### [NEW] [Identifier.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/SimpleCalc/src/Identifier.java)

Simple class with:
- `String name`, `double value`
- Constructor, `getName()`, `getValue()`, `setValue()`

---

### SimpleCalc Updates

#### [MODIFY] [SimpleCalc.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/SimpleCalc/src/SimpleCalc.java)

1. **Add `ArrayList<Identifier>` field** and initialize `e`/`pi` in constructor
2. **`getInput()` changes**:
   - Detect assignment statements (first token is letters, second token is `=`)
   - Evaluate the expression after `=`, store result in the database
   - Print `name = value`
   - Add `l` command to list all identifiers
3. **`evaluateExpression()` changes**:
   - When a token is not a number and not an operator/parenthesis, look it up in the database
   - If found, push its value; if not found, push `0.0`

## Verification Plan

### Automated Tests
- Compile and run with test expressions from the PDF sample run

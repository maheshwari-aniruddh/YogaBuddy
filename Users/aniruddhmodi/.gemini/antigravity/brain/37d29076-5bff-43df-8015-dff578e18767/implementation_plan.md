# HTMLRender Refactor and Commenting Plan

## Goal Description
Refactor `HTMLRender.java` to strictly adhere to the provided style guides:
- **Commenting**: Javadoc headers, method labels, single-line explanations.
- **Formatting**: 4-space indent, max 80 chars/line, blank lines between chunks.
- **Naming**: camelCase, full English words (no abbreviations), max ~15 chars, meaningful names.
- **Importing**: Explicit imports only (no wildcards).

Logic must remain identical.

## User Review Required
- **Variable Renaming**: Confirmed updates to meet "no abbreviations" and "max 15 chars" rules.

## Proposed Changes
### Source Code
#### [MODIFY] [HTMLRender.java](file:///Users/aniruddhmodi/Documents/Aniruddh/School/10th-grade/APCSA/untitled1/src/HTMLRender.java)
- **Variable Renaming**:
    - `tokens` -> `htmlTokens` (10 chars)
    - `TOKENS_SIZE` -> `MAX_TOKENS`
    - `render` -> `simpleRenderer` (14 chars)
    - `browser` -> `htmlPrinter` (11 chars)
    - `printMode` (enum) -> `RenderStyle`
    - `DEFAULT_CHAR_LIM` -> `LINE_LIMIT` (constant, short)
    - `elementCount` -> `tokenCount` (10 chars)
    - `newLine` -> `isStartOfLine` (13 chars)
    - `utility` -> `htmlUtils` (9 chars)
    - `reader` -> `fileScanner` (11 chars)
    - `hf` -> `renderer` (8 chars)
    - `fileName` (in main) -> `inputFileName` (13 chars)
    - `lineTokens` -> `lineTokens` (fine)
    - `finalTokens` -> `trimmedTokens` (13 chars) - *Wait, `finalTokens` is the array of size `elementCount`. `trimmedTokens` implies the content.* `sizedTokens`? `finalTokens` is okay but "final" is a keyword. `cleanTokens`? `tokenArray`? Let's go with `trimmedTokens`.
    - `charCount` -> `lineLength` (10 chars)
    - `toPrint` -> `outputBuffer` (12 chars)
    - `headerNum` -> `headerLevel` (11 chars)
    - `prevCharCount` -> `startLength` (11 chars)

- **Formatting & Style**:
    - Reformat all code to 4-space indentation.
    - wrap lines at 80 characters.
    - Add blank lines between logical blocks.
    - Ensure all imports are explicit.

- **Comment Rewording**:
    - Rewrite file header:
        ```java
        /**
         * HTMLRender.java
         * This program renders HTML code into a JFrame window...
         * ...
         * @author [User Name/Mr Greenstein]
         * @since [Date]
         */
        ```
    - Rewrite method comments with `@param` and `@return`.
    - Reword existing comments to be more descriptive.

## Verification Plan
### Manual Verification
- Visual inspection against all 3 style artifacts.
- Verify compilation.
- Run `HTMLRender` with `example8.html` to ensure no regressions in output.

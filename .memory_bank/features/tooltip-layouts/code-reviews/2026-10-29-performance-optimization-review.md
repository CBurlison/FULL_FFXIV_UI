# Code Review: Tooltip Layouts - Performance & Comparison Optimization

## Date
October 29, 2026

## Result: APPROVED

## Summary
Optimized equipment comparison and shopping tooltip reflow behavior to eliminate UI lag when hovering over large tooltips with multiple active comparison frames.

## Findings

### Major Resolved
- **Issue:** Synchronous layout reflows (`updateItemHeader()`) were called on every single `AddLine` and `AddDoubleLine` hook during shopping tooltip population (up to 20-40 times per tooltip across multiple active comparison tooltips), causing frame stutter and lag.
- **Fix:** Implemented debounced reflow scheduling using `C_Timer.After(0, ...)` (`QueueReflow`), ensuring that rapid line additions are batched into a single layout pass per frame.

## Verification
- All test suites successfully passed.
- Debouncing validated against mock timer environments in test files.

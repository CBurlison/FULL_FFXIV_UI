# Code Review: Tooltip Layouts - Comparison Flicker Elimination

## Date
October 29, 2026

## Result: APPROVED

## Summary
Resolved the tooltip comparison stat-change block flickering issue by deferring initial item header formatting on shopping/comparison tooltips (`ShoppingTooltip1`, `ShoppingTooltip2`, etc.) via `C_Timer.After(0, ...)` on `OnShow`. This allows all comparison lines to finish appending before layout computation runs for the first time, preventing state oscillation.

## Verification
- All test suites passed successfully with a 100% pass rate.

# Code Review: Tooltip Layouts - Comprehensive Flicker Elimination

## Date
October 29, 2026

## Result: APPROVED

## Summary
Completely eliminated tooltip comparison stat-change block flickering by removing `StyleItemHeader` from `OnShow` for shopping/comparison tooltips (`ShoppingTooltip1`, `ShoppingTooltip2`, `ItemRefShoppingTooltip1`, `ItemRefShoppingTooltip2`). This prevents premature rendering before comparison lines are appended by Blizzard's comparison subsystem. Shopping comparison tooltips now format exclusively via `TooltipDataProcessor` post-calls and debounced `QueueReflow` when comparison lines are fully present.

## Verification
- All test suites passed successfully with a 100% pass rate.

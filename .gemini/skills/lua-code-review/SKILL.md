---
name: lua-code-review
description: Comprehensive code review guidelines, checklists, and best practices for Lua 5.1 and World of Warcraft addon development. Use when reviewing Lua code for performance bottlenecks, global pollution, memory allocations, combat lockdown restrictions, taint safety, and code quality.
---

# Lua Code Review

## Overview

This skill provides a systematic framework for reviewing Lua source code, with specialized focus on Lua 5.1 runtime characteristics and World of Warcraft addon development (performance, memory conservation in hot paths, global scope hygiene, combat lockdown security, and taint prevention).

## Code Review Workflow

When performing a Lua code review, follow this structured process:

1. **Scope & Context Analysis**: Identify whether the code runs in an addon environment (WoW Retail/Forever) or standalone Lua 5.1. Determine if the code executes in hot paths (`OnUpdate`, event handlers) or initialization paths.
2. **Global Namespace Hygiene**: Verify that all variables and functions are explicitly declared `local` unless intended as global exports. Check for accidental global pollution.
3. **Performance & Garbage Collection (GC)**: Inspect loops and frequently called functions for table allocations, string concatenations (`..`), and closure creation inside hot paths.
4. **Local Caching**: Check if frequently accessed global APIs, math functions, or table methods are cached as local variables.
5. **Addon Security & WoW API Safety**: For WoW addons, verify adherence to combat lockdown (`InCombatLockdown()`), secure execution (`securecallfunction`), taint propagation rules, and proper event handling.
6. **Robustness & Error Handling**: Check for `nil` pointer safety, input validation, and appropriate error handling (`pcall` / `xpcall`).

## Reference Guide

For detailed review criteria, antipatterns, and optimization guidelines, see [references/lua-best-practices.md](references/lua-best-practices.md).

### Testing
- [ ] New code has corresponding tests
- [ ] Tests follow MSTest conventions
- [ ] Test names describe behavior
- [ ] No test coupling or order dependency

## Severity Levels

- **Critical:** Must fix — security vulnerability, data loss risk, crash
- **Major:** Should fix — bug, performance issue, design violation
- **Minor:** Consider fixing — style, naming, minor optimization
- **Nit:** Optional — preference, cosmetic

## Review Document

Stored at `.memory_bank/features/<feature-name>/code-reviews/phase-N-review-M.md`.

### Template

```markdown
# Code Review: Phase N - <Phase Name> (Review #M)

## Date
<date>

## Result: APPROVED / CHANGES NEEDED

## Summary
Brief overall assessment.

## Findings

### Critical
- **File:** `path/to/file.cs` (Line N)
  - **Issue:** Description
  - **Fix:** Recommended fix

### Major
- ...

### Minor
- ...

### Nits
- ...

## Positive Notes
- Good patterns observed
- Well-handled edge cases

## Changes Required (if CHANGES NEEDED)
1. Fix description with file references
2. ...
```
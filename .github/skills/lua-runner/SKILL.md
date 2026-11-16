---
name: lua-runner
description: Execute Lua scripts, run Lua tests, and evaluate Lua snippets using the lua5.1 command. Use when running Lua code, executing Lua-based unit tests, or evaluating Lua expressions.
---

# Lua Runner

## Overview

This skill provides instructions and patterns for executing Lua code and running Lua scripts or test suites using the `lua5.1` command-line interpreter.

## Execution Guidelines

### 1. Running a Lua Script File
To run a Lua script file, invoke `lua5.1` with the file path:
```bash
lua5.1 path/to/script.lua
```
You can pass arguments to the script after the file path, which will be accessible via `arg` table in Lua:
```bash
lua5.1 script.lua arg1 arg2
```

### 2. Evaluating Inline Lua Code
To execute one-liners or quick evaluation snippets directly from the command line, use the `-e` flag:
```bash
lua5.1 -e "print('Hello from Lua 5.1')"
```

### 3. Running Unit Tests & Test Suites
When testing Lua codebases or running test files:
- Locate the test files (e.g., `tests/` directory).
- Run specific test files using `lua5.1`:
  ```bash
  lua5.1 tests/ButtonSkins.lua
  ```
- Ensure any required test mocks or environment stubs are loaded or required at the top of the test script.

### 4. Interactive Mode (REPL)
To start an interactive Lua 5.1 REPL session for experimenting or debugging:
```bash
lua5.1
```
(Note: In automated agent workflows, prefer non-interactive script or `-e` evaluation commands).

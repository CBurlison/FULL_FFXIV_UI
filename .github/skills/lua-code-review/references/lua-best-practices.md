# Lua 5.1 & World of Warcraft Addon Code Review Best Practices

## Table of Contents
1. [Global Scope & Namespace Hygiene](#1-global-scope--namespace-hygiene)
2. [Performance & Garbage Collection (GC) Optimization](#2-performance--garbage-collection-gc-optimization)
3. [Local Caching for Hot Paths](#3-local-caching-for-hot-paths)
4. [World of Warcraft Addon Specifics (Combat Lockdown & Taint)](#4-world-of-warcraft-addon-specifics-combat-lockdown--taint)
5. [Table & Memory Management](#5-table--memory-management)
6. [Error Handling & Robustness](#6-error-handling--robustness)

---

### 1. Global Scope & Namespace Hygiene

- **Issue**: Omitting `local` creates global variables in the shared environment `_G`, causing pollution, name collisions, and difficult-to-trace bugs.
- **Review Check**:
  - Every file should ideally wrap its code in a local scope or ensure all top-level functions and variables are prefixed with `local`.
  - Check for undeclared assignments (`variable = value` without `local`).
  - Verify that addon tables are cleanly organized under a single global namespace or module table (e.g., `addonTable = ...`).

**Example (Incorrect):**
```lua
-- Pollutes global environment
function MyAddon_OnLoad(self)
    myVar = 10
end
```

**Example (Correct):**
```lua
local addonName, addonTable = ...

local function OnLoad(self)
    local myVar = 10
end
```

---

### 2. Performance & Garbage Collection (GC) Optimization

- **Issue**: Creating tables, closures (anonymous functions inside loops), or heavy string concatenations inside frequent callback functions (`OnUpdate`, high-frequency event listeners) triggers frequent garbage collection cycles, resulting in micro-stutters and frame rate drops.
- **Review Check**:
  - Ensure no `{}`, `table.insert` of temporary tables, or `..` string concatenations happen inside `OnUpdate` scripts or high-rate loops.
  - Check for closure allocation inside loops (e.g., `button:SetScript("OnClick", function() ... end)` inside a loop where a reusable function reference could be used instead).

**Anti-Pattern:**
```lua
frame:SetScript("OnUpdate", function(self, elapsed)
    local data = { x = self:GetCenter() } -- Table allocation every frame!
    print("Position: " .. data.x) -- String concatenation & GC pressure
end)
```

**Optimized Pattern:**
```lua
local function OnUpdate(self, elapsed)
    local x = self:GetCenter()
    -- Reuse existing tables or avoid allocation if possible
end
frame:SetScript("OnUpdate", OnUpdate)
```

---

### 3. Local Caching for Hot Paths

- **Issue**: Global table lookups (e.g., `math.floor`, `string.format`, `C_Timer.After`) in Lua are slower than local variable lookups because Lua must traverse global tables.
- **Review Check**:
  - Frequently used standard library functions and WoW API namespaces should be cached in local variables at the top of the file.

**Example:**
```lua
local math_floor = math.floor
local string_format = string.format
local C_Timer_After = C_Timer.After

local function ComputeValue(val)
    return math_floor(val)
end
```

---

### 4. World of Warcraft Addon Specifics (Combat Lockdown & Taint)

- **Issue**: Protected UI elements (action bars, unit frames, secure buttons) cannot be modified or re-anchored during combat (`InCombatLockdown()`). Attempting to do so throws errors and taints execution flow.
- **Review Check**:
  - Guard state-changing frame manipulations or attribute sets with `if InCombatLockdown() then ... end` or queue updates for `PLAYER_REGEN_ENABLED`.
  - Avoid insecure execution paths that mix addon scripts with protected Blizzard secure templates without proper secure APIs (`securecallfunction`, `IsSecureVariable`).

**Example:**
```lua
local function UpdateFrameState(frame)
    if InCombatLockdown() then
        -- Queue for post-combat or skip
        addonTable.pendingUpdates[frame] = true
        return
    end
    frame:SetWidth(200)
end
```

---

### 5. Table & Memory Management

- **Issue**: Leaving old data in tables or growing tables indefinitely without clearing or recycling causes memory bloat.
- **Review Check**:
  - Use object pools (`CreateFramePool`, `CreateFromTablePool`) or explicit table wiping (`wipe(tbl)` or `table.clear` equivalent) rather than creating new tables repeatedly.

---

### 6. Error Handling & Robustness

- **Issue**: Uncaught errors in event handlers or frame scripts can break addon functionality silently or disrupt the user interface.
- **Review Check**:
  - Wrap risky external calls, saved variable parsing, or dynamic execution in `pcall` or `xpcall` with a proper error handler.
  - Ensure defensive checks (`if not data or not data.subField then return end`) are used when consuming API payloads or SavedVariables.

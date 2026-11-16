# Taint safety: addon state on Blizzard frames

## Problem

In combat, Blizzard's `ActionBarButton.lua` `UpdateState` calls `SetChecked` with a secret value and fails:
`Secret values are only allowed during untainted execution for this argument`.
Stack: `Blizzard_GamepadActionBars/ActionBarButton.lua:842` (UpdateState) <- `:979` / `:1068` (OnEvent) <- `Camelot/ClassSpellFlyout.lua:25`.

Working hypothesis: insecure addon code taints Blizzard frames by
1. writing new keys onto Blizzard frame/region/button tables (`button.FFXIVUI*`), and
2. replacing Blizzard methods on those objects with `hooksecurefunc` wrappers, or adding `HookScript` handlers.

Taint persists once it is on the table, so deferring the install does not help.

## Scope

Rule: addon state lives in addon-owned weak-keyed side tables (`setmetatable({}, { __mode = "k" })`), keyed by the Blizzard object. Addon-created frames may keep their own keys.

Inventory (grep of `\.FFXIVUI\w+ =` writes in `FFXIV_UI/General`, `FFXIV_UI/PartyFrames`, `FFXIV_UI/PlayerFrames`, `FFXIV_UI/TargetFrames`, `FFXIV_UI/JobGauges`):

| Phase | Files | Approx. writes | Notes |
|---|---|---|---|
| 1 (origin) | `FFXIV_UI/General/ButtonSkins.lua` | 27 | Gamepad/controller action buttons, generic `applyButtonSkin`, hook installs. Tests: `tests/ButtonSkins.lua` (33 refs). |
| 2 | `FFXIV_UI/General/Tooltips/Core.lua`, `Items.lua`, `Spells.lua`, `Mounts.lua`, `Skills.lua`, `Toys.lua` | ~195 | Tooltip regions. |
| 3 | `FFXIV_UI/General/CharacterFrame.lua`, `Spellbook.lua`, `Talents.lua`, `Professions.lua`, `Social.lua`, `WindowControls.lua`, `Inventory.lua`, `Chat.lua`, `MicroMenu.lua`, `Reputation.lua`, `Skills.lua`, `RoundedPanels.lua`, `ProgressBars.lua` | ~200 | Blizzard tabs, rows, headers, panels. Tests cover each file. |
| 4 | `FFXIV_UI/PlayerFrames*`, `FFXIV_UI/PartyFrames*`, `FFXIV_UI/TargetFrames*`, `FFXIV_UI/JobGauges*`, `FFXIV_UI/General/QuestLog.lua`, `FFXIV_UI_Menu.lua` | ~100 | Cast bars, unit frames, gauges. |

## Acceptance

- `lua5.1 tests\<Name>.lua` passes for every touched file (exit 0).
- No `button.FFXIVUI*` / `frame.FFXIVUI*` writes remain on Blizzard-owned objects in phase scope (grep check).
- In-client: enter combat with the gamepad action bar and flyouts active; no `Secret values` error in `Errors.txt`. Not run yet.

## Status

- [x] Inventory
- [x] Phase 1: ButtonSkins.lua side tables (hooks removed; `Spellbook`, `PetAuras`, `Inventory`, `ButtonSkins`, `Professions` tests exit 0)
- [x] Phase 1 in-client follow-up: controller native art re-hidden in combat and on bar page reveal (throttled watcher in `FFXIV_UI/General/ButtonSkins.lua`); user confirmed visually.
- [ ] Phase 2: Tooltips (blocked on design choice: `Tooltips/Core.lua` restyles tooltips via about 20 `hooksecurefunc`/`HookScript` sites)
- [ ] Phase 3: General UI modules
- [ ] Phase 4: Unit frames, gauges, menu
- [ ] In-client combat verification

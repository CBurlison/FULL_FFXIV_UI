---
name: ffxiv-skin-dropdowns
description: "Skin WoW dropdowns and menus (WowStyle1DropdownTemplate filter dropdowns, DropdownButton openers, Menu/MenuUtil popup and context menus, radio/checkbox menu entries, legacy UIDropDownMenuTemplate) in the FFXIV_UI combo-box style. Use when converting, fixing or auditing combo boxes or popup menus in Retail or Forever."
---

# Skinning dropdowns, combo boxes and menus

- Visual spec: [wow-ui-layout §2](../wow-ui-layout/SKILL.md).
- Full requirements: [combo-boxes spec](../../../.memory_bank/features/combo-boxes/spec.md).
- Shared rules: [ffxiv-control-skinning](../ffxiv-control-skinning/SKILL.md).

## Standard

There are **two accepted combo-box styles** (decided 2026-11-07):
- **Value combo box:** shows the current selection. Uses the ComboBox bar described below.
- **Button combo box:** does not show a value; it only opens a menu. Uses the push-button pill (`StyleWindowControl(..., "Button")`) with a fixed label, or the hamburger icon.

**Opener (value field):**
- Art: `Panels/ComboBox-{Closed|Open}-Dark.tga`, 24 px high, 3-slice.
  - Left cap 20 px (u 0–26/512), right cap 12 px (u 323–339/512), centre u 26–323/512.
  - The arrow is part of the art; do not add a second one.
- Label: `filter.Text` (or `GetFontString()`), inset 24 px left and 12 px right, left-justified, no wrap, Axis 11.
  - Colour is `text`, or `muted` when disabled.
- Disabled: art alpha 0.5.

**Hamburger opener** (Spellbook settings):
- A 24×24 button with three 12×2 lines, 4 px apart, in the `text` token. It never shows a value.

**Popup:** `addonEnv.StyleComboBoxMenu(dropdown)`.
- Native menu textures and `NineSlice` are set to alpha 0.
- A 9-slice from `ComboBox-Menu-Dark.tga` is drawn with `menu:AttachTexture()`: 6 px edges, the middle stretches.
- All text uses `FFXIVUICharacterComboBoxMenuFont` (Axis 11) through `SetFontObject`.
- Radio and checkbox entries: `leftTexture1/2` are hidden, the label moves to an 8 px inset, and selected entries get a gold gradient band (0.82, 0.69, 0.40; alpha 0.26 → 0) with a rounded left edge.
- Entry styling is added with `MenuUtil.TraverseMenu` plus `description:AddInitializer`, so pooled rows restyle after refreshes.

## Implementation

The popup is shared. The opener is **not** shared yet: `SkinCharacterFilter` ([CharacterFrame.lua](../../../FFXIV_UI/General/CharacterFrame.lua#L461-L536)) and `SocialComboBox` ([Social.lua](../../../FFXIV_UI/General/Social.lua#L140-L206)) are near-identical copies (GAP-06). Until a shared `addonEnv.StyleComboBox` exists, follow this sequence, preferably by extracting that helper:

1. Require `type(dd.OnMenuOpened) == "function"`. Otherwise this is not a Retail-style `DropdownButton`, and the popup helper is skipped.
2. Probe the art: `probe:SetTexture(path)` for Closed, Open and Menu. **Return early if any of them fails** so the native control stays intact. (`SocialComboBox` currently ignores the result.)
3. Hide the native textures and `NineSlice`, add a non-mouse overlay panel, and build the 3 slices.
4. Call `addonEnv.StyleComboBoxMenu(dd)`.
5. Run `Update` from these hooks: `OnMenuOpened`, `OnMenuClosed`, `OnButtonStateChanged` and `UpdateText` (`hooksecurefunc`), plus `OnShow`, `OnEnable` and `OnDisable` (`HookScript`).
6. Open state is `dd:IsMenuOpen()`, or `dd:GetMenuOpen()` as a fallback.

**Context menus without a dropdown owner** (e.g. Chat mode via `MenuUtil.CreateContextMenu`): pass the owner button through `StyleComboBoxMenu`. Avoid writing stub methods onto Blizzard frames (GAP-15); prefer an addon-owned button.

**Menu text swaps:** use `Menu.ModifyMenu("MENU_TAG", fn)` (e.g. the Social status menus). Never globally replace Blizzard menu functions.

**Forbidden:**
- calling `SetFont` on compositor-owned menu labels
- keeping texture or FontString hooks on pooled entries after release
- changing an entry's selection data or responder

## Current coverage

| Target | Code | Client | Status |
|---|---|---|---|
| Reputation/Token/Currency `FilterDropdown` | `SkinCharacterFilter` | Retail menu system | Done (opener + popup) |
| `FriendsFrameStatusDropdown`, BNet `OnlineStatusDropdown` | `SocialComboBox` | Retail | Done (copy) |
| Social `SearchFilterDropdown`, Forever `FriendsFrameStatusDropdown` | `Dropdown` → Button pill, [Social.lua](../../../FFXIV_UI/General/Social.lua#L208-L213) | Both | Done (button combo box) |
| Professions `RecipeList.FilterDropdown` | `Control(..., "Dropdown")` → pill | Retail | Done (button combo box) |
| Spellbook `SettingsDropdown` | `Settings`, [Spellbook.lua](../../../FFXIV_UI/General/Spellbook.lua#L183-L193) | Retail | Done (hamburger) |
| Chat mode menu | [Chat.lua](../../../FFXIV_UI/General/Chat.lua#L189-L191) | Both | Done (popup only) |
| Talents dropdowns | `Scan` → `StyleComboBoxMenu` | Both | Popup only; opener unstyled |
| Options panel `UIDropDownMenuTemplate` | [FFXIV_UI_Menu.lua](../../../FFXIV_UI/General/FFXIV_UI_Menu.lua#L204) | Both | None (GAP-05) |

## Not done / incomplete
- **GAP-06:** extract `addonEnv.StyleComboBox(dropdown)` into WindowControls.lua and replace both copies. They produce identical output (see `mockups/duplicate-controls-comparison.html`). Keep the tests in `tests/CharacterFrame.lua` and `tests/Social.lua` passing.
- **GAP-05:** do the options panel during the options-menu rework. Legacy `UIDropDownMenu` has a different API (`UIDropDownMenu_*`, `DropDownList1..N`) and needs its own helper. Verify which API Forever ships first.
- Talents dropdown openers keep their native art (GAP-10; Retail `TalentsFrame.LoadSystem`).

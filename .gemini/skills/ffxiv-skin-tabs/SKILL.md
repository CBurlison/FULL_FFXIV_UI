---
name: ffxiv-skin-tabs
description: "Skin WoW tab controls (PanelTemplates tabs, TabSystem tabs, CharacterFrameTab, FriendsFrameTab, category/side tabs, icon tabs, chat tabs) in the FFXIV_UI style. Use when converting, fixing or auditing tabs in Retail or Forever, including selected/hover/disabled states and tab layout."
---

# Skinning tabs

The visual standard is the Retail Character Menu tab, specified in [wow-ui-layout §1](../wow-ui-layout/SKILL.md). For shared rules and the full helper API, see [ffxiv-control-skinning](../ffxiv-control-skinning/SKILL.md).

## Standard (top tabs)

- **Art:** `Panels/Tab-{Selected|Inactive}-<Theme>.tga`, a 3-slice built from the `FFXIV_ExtractedTab{Left,Center,Right}Template` textures in `FFXIV_UI/General/WindowControls.xml`.
  - The left cap is 23 px, the right cap 17 px, and the centre stretches.
  - The tex coords come from `UpdateExtractedTabArtwork`: x from 39/512 to 39 + 433 (selected) or 434 (inactive), y from 10/64 to 53/64.
- **Height and spacing:** 30 px high, `TAB_SPACING = -6`. Width = (parent width − 24 − (n − 1) × spacing) / n.
- **Label:** Axis 10–12, `tabText` token, centred horizontally and vertically.
- **States:**
  - Hover: brightness 1.12. Hook `OnEnter`/`OnLeave`/`OnHide`.
  - Selected: hook `SetChecked`, `SetTabSelected` or `PanelTemplates_SetTab`, whichever the native tab uses.
  - Disabled: FFXIV has no disabled tab art. Draw the normal art darker (decided 2026-11-07; not yet implemented, GAP-09).

## Implementation

Use the shared helper. Do not copy the coordinate maths (Character still has its own copy; GAP-08).

```lua
local function Tab(tab, isSelected)
    if tabs[tab] then return tabs[tab].update() end
    HideTextures(tab)                       -- alpha 0 + SetAlpha guard
    local panel = CreateFrame("Frame", nil, tab)
    panel:SetAllPoints(tab); panel:EnableMouse(false)
    panel:SetFrameLevel(math.max(0, tab:GetFrameLevel() - 1))
    local skin = {art = addonEnv.CreateExtractedTabArtwork(panel)}
    skin.update = function()
        addonEnv.UpdateExtractedTabArtwork(skin.art, isSelected(tab), skin.hovered)
        -- restyle tab.Text / tab:GetFontString(): Axis, tabText
    end
    tabs[tab] = skin
    if tab.SetTabSelected then hooksecurefunc(tab, "SetTabSelected", skin.update) end
    tab:HookScript("OnEnter", function() skin.hovered = true; skin.update() end)
    local function Reset() skin.hovered = false; skin.update() end
    tab:HookScript("OnLeave", Reset); tab:HookScript("OnHide", Reset)
    tab:HookScript("OnShow", skin.update)
    skin.update()
end
```

**How to tell which tab is selected:**

| Tab type | Selected when |
|---|---|
| TabSystem (Retail) | `tab:IsSelected()` |
| PanelTemplates | `PanelTemplates_GetSelectedTab(owner) == tab:GetID()` |
| FriendsFrame | `FriendsFrame.selectedTab == tab:GetID()` |
| CheckButton tabs | `tab:GetChecked()` |

**Layout changes on secure parents:** defer while `InCombatLockdown()` and resume on `PLAYER_REGEN_ENABLED`.

## Current coverage

| Variant | Code | Client | Status |
|---|---|---|---|
| Character top tabs | `SkinTab`/`UpdateTab`/`LayoutNativeTabs`, [CharacterFrame.lua](../../../FFXIV_UI/General/CharacterFrame.lua#L173-L243) | Retail; `ModeTabs` on the Forever path | Done visually; duplicates the helper |
| Social tabs | `Tab`/`ModernTab`, [Social.lua](../../../FFXIV_UI/General/Social.lua#L225-L253) | Both | Done (shared helper) |
| Spellbook category tabs | `Tab`, [Spellbook.lua](../../../FFXIV_UI/General/Spellbook.lua#L195-L261) | Retail | Variant: gradient side highlight, `accent` label at 18, `IsForceDisabled` → `muted` |
| Professions icon tabs | `Tab`, [Professions.lua](../../../FFXIV_UI/General/Professions.lua#L626-L663) | Retail | Variant: 40×40 Square control |
| Professions bottom TabSystem | `Control(tab)`, [Professions.lua](../../../FFXIV_UI/General/Professions.lua#L778-L780) | Retail | Drawn as Button pills; open Retail defect |
| Paper-doll sidebar tabs | `SkinNativeSidebar`, [CharacterFrame.lua](../../../FFXIV_UI/General/CharacterFrame.lua#L695-L756) | Both | Done (`Character/Sidebar-*` icons) |
| Chat tabs | `TabArtwork`/`UpdateTab`, [Chat.lua](../../../FFXIV_UI/General/Chat.lua#L87-L123) | Both | Always Dark colours **by design** (decided 2026-11-07); no theme registration |

## Not done / incomplete
- **GAP-08:** decide and document variant rules for side, icon and bottom tabs (needs a mock-up), then move Character onto `UpdateExtractedTabArtwork`.
- **GAP-09:** add the darker disabled state to the shared tab helper.
- **GAP-16:** only `-Dark` is reachable while the theme lock is active.

## Tests
`tests/CharacterFrame.lua` and `tests/Social.lua` cover the tab templates and states. Extend these suites and do not create new tab mocks.

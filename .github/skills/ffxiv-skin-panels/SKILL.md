---
name: ffxiv-skin-panels
description: "Skin WoW window and panel elements (PortraitFrameTemplate/ButtonFrameTemplate shells, NineSlice borders, title bars, insets, detail side panels, dividers, tooltips, money frames, resize grips) in the FFXIV_UI rounded-window style. Use when converting a whole Blizzard window, fixing panel chrome, or auditing frame backgrounds in Retail or Forever."
---

# Skinning panels, windows and chrome

Shared rules and the full helper API: [ffxiv-control-skinning](../ffxiv-control-skinning/SKILL.md). Specs:
- [shared-rendering](../../../.memory_bank/features/shared-rendering/)
- [rounded-panels](../../../.memory_bank/features/rounded-panels/)
- [tooltip-layouts](../../../.memory_bank/features/tooltip-layouts/)

## Window shell

**Standard:** rounded window chrome from `addonEnv.RoundWindow(panel, true)`.
- A 9-slice built from the `FFXIV_Window{Background,Rim,Header}<rc>Template` textures (`Window-*-Dark.tga`) in [RoundedPanels.xml](../../../FFXIV_UI/General/RoundedPanels.xml).
- The background UVs follow the panel size.
- Title: Axis 18, `text`, 22 px high.
- Close button: [ffxiv-skin-buttons](../ffxiv-skin-buttons/SKILL.md).

**Shell sequence**, copied today as `Shell` in Social, Spellbook and Talents and inline in Character, Professions and Inventory (GAP-12):

```lua
HideTextures(frame)
Hide(frame.NineSlice); Hide(frame.PortraitContainer); Hide(frame.PortraitFrame); Hide(frame.portrait)
if frame.Inset then HideTextures(frame.Inset); Hide(frame.Inset.NineSlice) end
addonEnv.RoundWindow(Panel(frame), true)      -- Panel = non-mouse child at frame level
local title = frame.TitleContainer and frame.TitleContainer.TitleText or frame.TitleText
-- title: Axis 18, "text"; close: HideTextures + 24x24 TOPRIGHT + SkinWindowClose
```

- **Retail** uses `TitleContainer.TitleText` and `PortraitContainer`. **Forever** may use `TitleText`, `portrait` or `PortraitFrame`; feature-detect each one.
- If a native window re-shows its art when hidden or shown again (as the Spellbook does), keep it hidden with the `SetAlpha` guard. Do not re-run the shell.
- Use **`RoundWindow(panel)` without chrome** for inner panels: a `surface-<Material>.tga` + `Panel-Border-Dark.tga` 9-slice plus `Grain.tga`.
- **`RoundFill(owner, ref, token)`** draws a rounded fill sized to another region.
- **`RoundOutline(frame)`** draws a border only.

## Detail panels: `addonEnv.StyleDetailPanel(frame)` (Forever)
- Hides the detail frame's textures and keeps them hidden.
- Stretches the frame to its native anchor box.
- Replaces `UI-Character-Info-Title` category banners with a divider. It hooks `AddCategory`, so pooled category rows stay styled.
- Used on the Reputation, Skills, PvP and Currency detail panes.

## Dividers: `addonEnv.Themes.StyleDivider(line, parent, layer, sublevel, vertical)`
- A dark line (alpha 0.85) with a 1 px white accent (alpha 0.4) that follows the line's Show/Hide.
- Use it for every header underline and section separator. The `FFXIV_*HeaderDividerTemplate` XML templates supply the geometry.

## Tooltips: `addonEnv.RoundTooltip(tooltip)` ([Tooltips/Core.lua](../../../FFXIV_UI/General/Tooltips/Core.lua))
- Art: `Tooltip-{Rim,Background,Fill}-Dark.tga`.
- Content is styled per data type through `TooltipDataProcessor`. Native money frames are hidden and sell rows are drawn by the addon.
- New tooltip frames: add them to the `RoundTooltips` list. Do not write a new skin.

## Money frames (partial)
Inventory recolours the Gold/Silver/Copper text and hides the border ([Inventory.lua](../../../FFXIV_UI/General/Inventory.lua#L466-L477)). No shared helper exists. Merchant, mail and auction money frames are untouched.

## Resize grips: **not implemented** (GAP-04)
**Standard (decided 2026-11-07; reference `Media/References/Resize-Grip/`):** a triangle made of three diagonal lines in the frame's bottom-right corner. Retail windows use `PanelResizeButtonTemplate`; check whether Forever has an equivalent before planning.

## Not done / incomplete
- **GAP-12:** promote `Shell` to a shared `addonEnv.StyleWindowShell(frame)`.
- **GAP-13:** the Spellbook card uses legacy `surface.tga`/`border.tga` instead of the material variants.
- **GAP-14:** Retail Reputation and Currency pages get no panel or header treatment beyond the filter.
- **GAP-16:** only `-Dark` window, tooltip and border art exists.

---
name: ffxiv-skin-buttons
description: "Skin WoW push buttons (UIPanelButtonTemplate, generic action buttons in panels), window close buttons, maximize/minimize buttons, circular arrow toggles, flat prev/next paging arrows and +/- steppers in the FFXIV_UI style. Use when converting, fixing or auditing clickable buttons and window controls in Retail or Forever."
---

# Skinning buttons and window controls

Shared rules and the full helper API: [ffxiv-control-skinning](../ffxiv-control-skinning/SKILL.md). Icon, item and action buttons have their own skill: [ffxiv-skin-bars-and-icons](../ffxiv-skin-bars-and-icons/SKILL.md).

## Push buttons: `addonEnv.StyleWindowControl(panel, owner, "Button")`

- **Art:** `Panels/Button-{fill,border}[-Disabled]-<Material>.tga`, a 3-slice with 12 px caps (`FFXIV_Control12*Template`), plus 3 drop-shadow copies from `AddTextureShadow`.
- **Colours:** fill uses `tab`, or `selected` while hovered. Border uses `border`.
- **Disabled:** swaps to the `-Disabled` textures.
- **Pressed (decided, not yet implemented — GAP-09):** draw the normal art moved down about 2 px. There is no separate pressed texture.
- **Label:** each caller sets it with its own `Control` wrapper: Axis 12, `tabText` when enabled, `muted` when disabled, refreshed on `OnEnable`/`OnDisable`.

Pattern used by Social, Professions and Spellbook:

```lua
local function Control(button, style)
    if not button or controls[button] then return end
    controls[button] = true
    HideTextures(button); Hide(button.NineSlice)
    local panel = CreateFrame("Frame", nil, button, "BackdropTemplate")
    panel:SetAllPoints(button); panel:SetFrameLevel(button:GetFrameLevel()); panel:EnableMouse(false)
    addonEnv.StyleWindowControl(panel, button, style or "Button")
    local label = button.GetFontString and button:GetFontString() or button.Text
    local function Update() Text(label, 12, button:IsEnabled() and "tabText" or "muted") end
    button:HookScript("OnEnable", Update); button:HookScript("OnDisable", Update); Update()
end
```

This wrapper is copied in three files. Talents expects a public `addonEnv.StyleButton(button)`, which does not exist (GAP-10). Promote the wrapper into WindowControls.lua as `addonEnv.StyleButton` and point the copies at it.

**Square icon buttons:** use `"Square"` (full-texture fill and border, no shadow), with the icon on the native button. Examples: Professions icon tabs, Spellbook display mode.

## Close: `addonEnv.SkinWindowClose(button)`

1. The caller hides the native textures and sets size 24×24 at `TOPRIGHT` −5/−6 (Character) or −6/−6 (Social, Spellbook).
2. The helper adds `FFXIV_WindowCloseIconTemplate` (`Panels/Close.tga`) at OVERLAY, tinted 0.85 grey, white on hover.
3. **By design** there is no pressed or disabled state (decided 2026-11-07). Hover-brighten is the only state.

Talents and Spellbook share one close button through `addonEnv.TalentsUI.UpdateCloseButton`.

## Maximize / minimize
Only the Spellbook handles it. It hides `MaximizeMinimizeButton` and replaces it with a pair of `DisplayMode` Square buttons ([Spellbook.lua](../../../FFXIV_UI/General/Spellbook.lua#L413-L475)):
- selected: `indicator` border, `selected` fill, `accent` icon
- disabled in combat

There is no shared helper. Generalise it only when a second window needs one.

## Circular arrows: `addonEnv.StyleCircularArrowButton(button, direction)`

- **Art:** `Arrow-Button-Circle.tga` (base) and `Arrow-Button-Glyph.tga` (glyph + shadow), from XML templates at ARTWORK sublevels 0, 1 and 2. Direction is applied by rotating the tex coords.
- **States:** hover 1.18; pressed 0.8 with a 1 px drop; disabled alpha 0.4. All states are handled inside the helper.
- **Used by:** Character right-pane toggle, Social BNet buttons, Statistics collapse (Forever).
- This is the preferred control for expand/collapse and panel toggles.

## Flat paging arrows and steppers

Two copies exist: Spellbook `Arrow` ([Spellbook.lua](../../../FFXIV_UI/General/Spellbook.lua#L157-L181)) and Professions `Arrow` ([Professions.lua](../../../FFXIV_UI/General/Professions.lua#L165-L188)).
- Art: `Panels/Arrow-{Left|Right}-{Enabled|Disabled}.tga` on OVERLAY, hover 1.12, native art hidden, button 22×22.
- Professions +/- steppers are a recorded open Retail defect.
- Before adding a third caller, promote them to a shared `addonEnv.StyleFlatArrowButton(button, "Left"|"Right")`.

## Not done / incomplete
- **GAP-09:** no pressed state on `StyleWindowControl` yet (decided: move down about 2 px).
- **GAP-10:** `addonEnv.StyleButton` is missing. Talents `Scan` would apply it to every Button, including talent nodes, so target named controls instead.
- **GAP-11:** unreferenced `Arrow-Down-*` and `Arrow-Side-*` assets, and an unused `"Tab"` style in `CreateControlArtwork`. Keep them until the final cleanup.
- **GAP-12:** the `Control`/`Arrow` wrappers are duplicated.

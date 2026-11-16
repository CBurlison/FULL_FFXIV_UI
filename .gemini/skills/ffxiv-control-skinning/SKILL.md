---
name: ffxiv-control-skinning
description: "Index and workflow for converting World of Warcraft UI controls (tabs, dropdowns, buttons, inputs, lists, scroll bars, panels, bars, icon buttons) to the FFXIV_UI style. Use when you need to find which control types are already skinned, decide what is missing or incomplete, pick the shared helper, or plan skinning work on any Blizzard frame in Retail or Forever."
---

# FFXIV_UI control skinning

This is the entry point for skinning Blizzard controls. Each control family has its own skill:

| Control family | Skill |
|---|---|
| Top, side, icon, bottom and chat tabs | [ffxiv-skin-tabs](../ffxiv-skin-tabs/SKILL.md) |
| Combo boxes, dropdown openers, popup and context menus, legacy `UIDropDownMenu` | [ffxiv-skin-dropdowns](../ffxiv-skin-dropdowns/SKILL.md) |
| Push buttons, close, maximize/minimize, circular and flat arrows, steppers | [ffxiv-skin-buttons](../ffxiv-skin-buttons/SKILL.md) |
| Edit/search boxes, checkboxes, radio buttons, sliders | [ffxiv-skin-inputs](../ffxiv-skin-inputs/SKILL.md) |
| Scroll bars, list rows, collapsible headers, highlights | [ffxiv-skin-lists](../ffxiv-skin-lists/SKILL.md) |
| Window shells, insets, detail panels, dividers, tooltips, money frames, resize grips | [ffxiv-skin-panels](../ffxiv-skin-panels/SKILL.md) |
| Status/progress bars, item/action/aura icon buttons, micro menu | [ffxiv-skin-bars-and-icons](../ffxiv-skin-bars-and-icons/SKILL.md) |

- Tab and combo-box visual specs: [wow-ui-layout](../wow-ui-layout/SKILL.md).
- Coverage status and the `GAP-` list: [.memory_bank/features/control-skinning/plan.md](../../../.memory_bank/features/control-skinning/plan.md). Update it whenever you close or discover a gap.

## Workflow: converting a control

1. **Locate.** Find the Blizzard frame and its key children with `/fstack` in-game, or in the `wow-ui-source` FrameXML for the target client. Record the client (Retail, Forever or both) and whether the frame is protected.
2. **Check coverage.** Look up the control type in the matrix. If a shared helper exists, use it. If the control is listed only under a per-file copy, promote that code into a shared helper before adding a third copy (GAP-12).
3. **Mock up when the look changes.** Any new or changed appearance requires an HTML mock-up built from the real `Media/` assets, approved by the user before Lua/XML work (`SPECIFICATIONS.md`). Re-applying an accepted standard to another frame does not need a new mock-up.
4. **Hide the native art, keep the native control.** Set native textures to alpha 0 and keep them hidden: hook `SetAlpha`, or hook `Show`/`SetShown`. Do not destroy, reparent or `SetScript`-replace Blizzard regions or scripts. The native button stays the click, keyboard and controller target.
5. **Overlay the addon art.** Create a non-mouse child `Frame` (`EnableMouse(false)`, same frame level, `SetAllPoints(owner)`) and draw the textures on it. Prefer the XML virtual templates in `FFXIV_UI/General/WindowControls.xml` and `FFXIV_UI/General/RoundedPanels.xml` for static geometry, and keep the dynamic UVs, colours and states in Lua.
6. **Wire the states.** Hook (`HookScript` / `hooksecurefunc`) `OnEnter`, `OnLeave`, `OnHide`, `OnEnable`, `OnDisable`, `OnMouseDown`/`OnMouseUp` and the native state methods (`SetChecked`, `SetTabSelected`, `OnMenuOpened`, `UpdateCollapsedState`, …). Reset hover and pressed on `OnHide`.
7. **Theme.** Take colours from palette tokens and register the re-tint with `addonEnv.Themes.Register`. Never hard-code RGB values (GAP-13).
8. **Be idempotent.** Guard with a weak-keyed table or a `FFXIVUI*` field on the owner, so repeated layout passes never duplicate textures or hooks.
9. **Test.** Add or extend the mocks in `tests/<Panel>.lua`. Cover creation, every state transition, reuse, theme refresh and combat deferral. Run with `lua5.1 -e "table.unpack = table.unpack or unpack; dofile('tests/<Panel>.lua')"`.
10. **Record.** Update the feature spec and checkpoint. Keep static, Retail-client and Forever-client results separate; Forever stays "deferred", never "passed", until it is actually verified.

## Shared conventions

- **Font:** `Interface\AddOns\FFXIV_UI\Media\Fonts\AxisRegular.ttf`, no flags, shadow alpha 0. Resolve it through `ns.GetFont(path)` (defined in [FFXIV_UI/Locales/Locales.lua](../../../FFXIV_UI/Locales/Locales.lua)) for locale fallbacks.
- **Sizes:** window title 18, button/tab label 10–12, combo value 11, menu 11.
- **Palette tokens** (from [Themes.lua](../../../FFXIV_UI/General/Themes.lua)):

  | Token | Use |
  |---|---|
  | `surface` | window fill |
  | `inset` | recessed fill |
  | `border` | outlines |
  | `text` | body text |
  | `muted` | disabled or prompt text |
  | `accent` | gold highlights |
  | `tab` | control fill |
  | `selected` | hovered or selected fill |
  | `tabText` | button/tab labels |
  | `indicator` | selected outline |
  | `beneficial` / `detrimental` | positive / negative values |

- **Panel material:** `addonEnv.GetPanelMaterial()` returns `Standard`, `Clear` or `Classic`. Button, Search and Square textures are suffixed with it.
- **Texture root:** `Interface\AddOns\FFXIV_UI\Media\Textures\Panels\`. Most control art exists only as `-Dark` (GAP-16).
- **State brightness:** hover is a vertex brightness of 1.12–1.18; pressed is 0.8 with a 1px downward nudge; disabled is alpha 0.4–0.5 or the `-Disabled` texture plus the `muted` label.

## Shared helper API (on `ns`/`addonEnv`)

| Helper | Signature | File |
|---|---|---|
| `StyleWindowControl` | `(panel, owner, "Button"\|"Search"\|"Square")` | FFXIV_UI/General/WindowControls.lua |
| `CreateControlArtwork` / `UpdateControlMaterial` | `(panel, style)` / `(art, style, disabled)` | FFXIV_UI/General/WindowControls.lua |
| `AddTextureShadow` | `(owner, sourceTexture)` | FFXIV_UI/General/WindowControls.lua |
| `CreateExtractedTabArtwork` / `UpdateExtractedTabArtwork` | `(panel)` / `(art, selected, hovered)` | FFXIV_UI/General/WindowControls.lua |
| `StyleComboBoxMenu` | `(dropdown)`; requires `dropdown.OnMenuOpened` | FFXIV_UI/General/WindowControls.lua |
| `StyleCircularArrowButton` | `(button, "up"\|"down"\|"left"\|"right")` | FFXIV_UI/General/WindowControls.lua |
| `SkinWindowClose` | `(button)` | FFXIV_UI/General/WindowControls.lua |
| `StyleForeverCollapsibleHeader` / `StyleComboCollapsibleHeader` | `(row)` | FFXIV_UI/General/WindowControls.lua |
| `RoundWindow` | `(panel, chrome)` | FFXIV_UI/General/RoundedPanels.lua |
| `RoundFill` | `(owner, ref, token)` | FFXIV_UI/General/RoundedPanels.lua |
| `RoundOutline` | `(frame)` | FFXIV_UI/General/RoundedPanels.lua |
| `StyleDetailPanel` | `(frame)` | FFXIV_UI/General/RoundedPanels.lua |
| `Themes.StyleDivider` | `(line, parent, layer, sublevel, vertical)` | FFXIV_UI/General/Themes.lua |
| `ApplyButtonSkin` | `(button, regions, styleName, auraSize)` | FFXIV_UI/General/ButtonSkins.lua |
| `DeferOutsideSecureUpdate` | `(owner, tag, callback)` | FFXIV_UI/General/ButtonSkins.lua |
| `ProgressBars.Skin` / `LayoutRow` / `StyleDetailBar` | see the bars skill | FFXIV_UI/General/ProgressBars.lua |
| `RoundTooltip` | `(tooltip)` | FFXIV_UI/General/Tooltips/Core.lua |

**Missing helpers** that callers already expect, or that would remove duplication:
- `addonEnv.StyleButton` and `addonEnv.StyleEditBox` (GAP-10)
- `addonEnv.StyleComboBox` (GAP-06)
- `StyleScrollBar` (GAP-01)
- `StyleCheckButton` (GAP-03)

## Rules every skin must follow

- **Dual client.** Feature-detect methods (`type(x.Method) == "function"`) and child keys instead of branching on the build number wherever possible. When a branch is needed, Forever is `select(4, GetBuildInfo()) == 16001`. Never assume a Retail template or child key exists on Forever.
- **Combat lockdown.** Geometry changes on protected frames (anything secure, or anchored to secure frames) are deferred while `InCombatLockdown()` is true and resumed on `PLAYER_REGEN_ENABLED`. Texture and colour changes on addon-owned overlay frames are safe in combat.
- **Taint.** Use `hooksecurefunc` / `HookScript`. Do not `SetScript` on Blizzard frames, and do not assign fields or functions onto Blizzard tables that Blizzard code later reads (GAP-15). Run skin work for secure button updates through `DeferOutsideSecureUpdate`.
- **Pooled frames** (ScrollBox rows, menu entries). Style them through `ScrollUtil.AddInitializedFrameCallback` / `OnInitializedFrame`, or menu-description initializers. Use `AttachTexture` on compositor menus; never call `SetFont` on compositor-owned labels.
- **Secret values (Retail 12.x).** Skins must not read or compare unit or combat values to decide appearance. Pass values straight to widgets.
- **Fallback.** If addon art fails to load (`texture:SetTexture(path)` returns false), leave the native control visible and usable.

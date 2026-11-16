---
name: ffxiv-skin-lists
description: "Skin WoW list controls (ScrollBox/WowScrollBoxList rows, MinimalScrollBar/UIPanelScrollFrame scroll bars, collapsible category headers, list highlights and selection) in the FFXIV_UI style. Use when converting, fixing or auditing scrolling lists, row styling, headers or scroll bars in Retail or Forever."
---

# Skinning lists, rows, headers and scroll bars

Shared rules and the full helper API: [ffxiv-control-skinning](../ffxiv-control-skinning/SKILL.md).

## Collapsible category headers

Both variants draw the dark combo-box bar (`ComboBox-Closed-Dark.tga` when collapsed, `ComboBox-Open-Dark.tga` when expanded) behind the row through `CreateComboHeader` in [WindowControls.lua](../../../FFXIV_UI/General/WindowControls.lua#L347-L394). The title is inset 26 px left and 12 px right, Axis 12, in `text`. The art already contains the arrow.

| Helper | Row shape | Client | Used by |
|---|---|---|---|
| `addonEnv.StyleForeverCollapsibleHeader(row)` | `row.Name` + `row.StateIcon`; atlas `common-button-list-plus` means collapsed; hides `common-button-list-collapseExpand` glyphs | Forever | Reputation, Currency, Skills, Statistics |
| `addonEnv.StyleComboCollapsibleHeader(row)` | `row.ButtonText` + `row.CollapseButton` (`collapsed`, `UpdateCollapsedState`) | Retail | Social lists, Professions recipe headers |
| `addonEnv.StyleCollapsibleHeader(row)` | Button pill + `accent` +/− bars | — | **No callers** (GAP-11) |

- Pick the helper by row shape (feature detection), not by build number.
- Both helpers are idempotent and leave the native click target in place.

## Rows and highlights

There is no shared row helper. Current pattern:
- Style pooled rows from `ScrollUtil.AddInitializedFrameCallback(scrollBox, fn, owner, true)`, or `scrollBox:RegisterCallback("OnInitializedFrame" / "OnDataRangeChanged", ...)`.
- Never style them once at creation, because pooled frames are reused.
- Highlight and selected: a `WHITE8X8` texture tinted with `accent` or `selected`. Alpha is about 0.12–0.18 for hover and 0.2–0.25 for selected.
- Text: Axis, `text`; secondary text in `muted`.
- Examples:
  - Social `Row` ([Social.lua](../../../FFXIV_UI/General/Social.lua#L305-L346))
  - Professions `RecipeRow` ([Professions.lua](../../../FFXIV_UI/General/Professions.lua#L242-L268))
  - Spellbook `Row`/`Header`/`SpellCard` ([Spellbook.lua](../../../FFXIV_UI/General/Spellbook.lua#L69-L141))

**Candidate helper:** `addonEnv.StyleListRow(row, {highlight=, selected=, isSelected=})`, to collapse these three copies (GAP-12).

## Scroll bars: implemented for Chat, Social, Character-menu pages, Professions (GAP-01, awaiting in-game approval)

- Chat `ScrollBar` uses `addonEnv.StyleScrollBar(bar, "Chat")`.
- Menu lists use `"Menu"`: Social (every tab and the Ignore list, via `List()` in `FFXIV_UI/General/Social.lua`), Reputation, Currency, Skills, Statistics (`page.ScrollBar`), and the Professions recipe list. Use `addonEnv.StyleListScrollBar(page)` for these; it is a no-op when the page has no `ScrollBar`.
- Character stats `ScrollBar`: still hidden. Not yet styled.
- `ScrollToBottomButton` in Chat is still only moved.

**Standard (decided 2026-11-07; references in `Media/References/Scroll-Bars/`).** There are two variants:
- **Chat:** a 1px light-grey line as the track. The thumb is a 4px gold bar with no outline (outline removed on user request).
- **Menu / window:** no track background. The thumb is a grey pill (`Bar-Pill.tga`).

**Shared helper** `addonEnv.StyleScrollBar(bar, "Chat"|"Menu")` (implemented in `FFXIV_UI/General/WindowControls.lua`):
- Hides `Back`/`Forward`/`ScrollUpButton`/`ScrollDownButton`. Hides the `Track` texture regions. Chat adds a 1 px grey line.
- Hides the native thumb art by alpha 0 and draws addon-owned thumb textures as children of the native thumb (so they follow its position and size). Blizzard keeps the hit regions and dragging. Menu thumb is `Bar-Pill.tga` in three slices (8px caps, sliced with 8-argument `SetTexCoord` so the horizontal pill runs vertically). Chat thumb is a flat 4px gold `SetColorTexture`.

- Keep native hit regions and dragging. Never reparent the bar.

# Tooltip Layouts Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Except for aura tooltips, tooltips use the extracted Dark rounded rim, tiled background/fill, and restrained header shine.
- Suppress the native border/NineSlice rather than drawing a second border over it.
- Use Axis text, generally a 14-pixel title, 11-pixel body/secondary labels, and 16-pixel metric values.
- Standard icon headers place a 32x32 icon at (16, -10) and the name beside it at x=56; content below uses 16-pixel side insets.
- Type-specific layouts below take precedence over the shared defaults.
- Use the real item, spell, currency, mount, or pet icon from its owning API/data.
- Never interpret another tooltip type's numeric ID as an item ID.

### Core Requirements 2
- Missing/cached data must not produce an unrelated icon or a fabricated category/stat.
- Request supported item/spell data loads and refresh the currently relevant tooltip when data becomes available.
- Prefer structured tooltip line types and existing native lines.
- Retain native text, semantic colors, localization, binding/requirement information, item comparisons, and unclassified details unless the layout explicitly omits them.
- Reflow both left and right columns and measure wrapped text after applying the intended width.
- Include late-appended native footer lines, such as currency "Click to view options," with bottom padding inside the background.
- Tooltips must fit their current contents and remain correctly anchored after native `Show`, resize, and data refresh work.
- Moving from a large spell to a smaller spell must shrink the tooltip rather than keep a previous minimum height.
- Repeated refreshes must not accumulate height or allocate duplicate artwork.
- On hide or a change of tooltip type, restore native regions, alpha, anchors, dimensions, wrapping, and line limits changed by the previous formatter; hide its custom icon, metrics, bands, and dividers.

### Core Requirements 3
- Guard restricted values before comparisons, branching, parsing, or arithmetic.
- Reuse restricted aura names/descriptions on their native font strings without reading them for classification.
- If a measurement is restricted, use a safe layout fallback.
- These presentation rules do not authorize combat decisions or inspection of secret values.
- Item tooltips start with the actual item icon and name.
- The default item minimum width is 320 pixels.
- Binding and unique/equipped restrictions, when present, are gathered into a muted ten-pixel line above the name rather than duplicated in the body.
- Preserve localized item names, quality information, requirements, and native comparisons.
- Non-equipment items may show their native item type/subtype and an owned-count/max-stack pair when readable and meaningful.
- Do not invent equipment cells for materials, quest items, miscellaneous items, or ordinary inventory objects.

### Core Requirements 4
- Keep their native descriptions and other applicable details in readable rows below the header.
- Equipment follows the armor/physical-weapon/magic-weapon references using only WoW data.
- After the icon/name/binding header, show the native equipment slot/type.
- Place available Defense or Damage/DPS/Speed values in right-aligned metric cells with muted labels and short underlines.
- Distinguish metric labels and values without adding FFXIV-only attributes or inferring unsupported weapon statistics.
- Show item level in a horizontal band, followed by native requirements, two-column stat bonuses where applicable, an Effects section for equip/use effects, and retained footer details.
- Keep meaningful beneficial/detrimental stat colors and comparison deltas.
- Unclassified item lines must not silently disappear.
- Durability and sell details remain in the footer; suppress duplicate native sell lines and money frames when a custom sell value is drawn.
- Equipment does not show the owned-count/max-stack cell.

### Core Requirements 5
- Current inner side padding is 16 pixels.
- Below the icon/name/binding header, show native item classification and readable owned-count/max-stack information.
- For supported usable items, add a Recast label/value cell with an underline.
- Recast describes the item's associated spell cooldown, not the current item cooldown countdown.
- Missing or restricted values use `--` rather than an invented duration.
- Group use effects beneath an Effects heading/divider, then description/flavor text and applicable sell details.
- Preserve native description colors and all meaningful footer rows.
- Omit empty sections rather than reserving blank blocks.
- Retain the native item interaction and modified-click behavior.
- Currency tooltips use the actual currency icon from `C_CurrencyInfo.GetCurrencyInfo` and place the native currency name beside it.

### Core Requirements 6
- Use at least 320 pixels of width.
- Place the native description, warband/account label, quantities, caps, and other currency details below the header without adding an item category such as Junk or Cloth.
- Keep native semantic colors and totals.
- Process all displayed lines, including lines appended after the initial tooltip-data callback; additions must trigger a reflow and height update so instruction/footer text stays inside the frame.
- Reusing the tooltip for another currency must update the icon and content without retaining the previous currency layout.
- Active spell tooltips use the icon/name header and a muted localized Spell/Ability category beneath the name.
- Use native category data when applicable and available spell/global-cooldown data for the implemented classification; arbitrary spell subtext such as a polymorph form is not a category.
- Keep available Range and Radius right-aligned on the category row, without crowding the category label.
- The implemented active-spell minimum width is 420 pixels.
- Arrange Cast, Recast, and an optional readable resource-cost cell below the header, with muted labels, larger right-aligned values, and short underlines.

### Core Requirements 7
- Cast is Instant or the known cast duration.
- Recast uses supported base/charge cooldown data and the global cooldown where applicable, not an arbitrary current countdown.
- Display the applicable resource abbreviation/cost and omit a resource cell that has no valid cost.
- Place native spell description/effect rows below the metric separator, preserving paragraph order and meaningful colors.
- Missing metadata uses `--` or omission as appropriate while supported spell-data requests are pending.
- A data-load result may refresh a still-relevant visible tooltip.
- Compute height from the current rows, never from the previously hovered spell's height.
- Passive spell tooltips retain the icon/name header and a muted Passive label.
- They omit the active Cast/Recast/resource grid and start the native description below a compact separator.
- Do not retain active-spell cells, range labels, or large empty blocks from a previous tooltip where those fields are not applicable.

### Core Requirements 8
- Multiple description paragraphs remain visible, and the background shrinks to their measured height.
- Auras have a separate, borderless layout rather than the item/spell chrome.
- Use a dark gray translucent background with rounded corners and a soft background-to-transparent fade around every edge.
- The current material uses four antialiased inset layers, with alphas 0.12, 0.22, 0.38, and 0.80 and RGB (0.16, 0.17, 0.17); progressively inset layers form the readable center without a hard outline.
- No icon, rim, header shine, caster label, spell classification, or metric grid is shown.
- The name is pale gold (RGB 0.88, 0.79, 0.57), 12 pixels, and unwrapped.
- Soft-white body text is 11 pixels, separated from the title by four pixels.
- Recognized remaining-time text appears in a separate muted-gray ten-pixel footer with an additional four-pixel gap.
- Duration recognition currently covers readable native lines beginning with a number and ending in English `remaining`; do not parse restricted strings or claim broader localized recognition without validation.
- Use eight-pixel horizontal padding and eight pixels of top padding.

### Core Requirements 9
- The minimum width is 240 pixels and must also accommodate the unbounded name width plus 16 pixels; do not impose a narrow maximum that wraps or ellipsizes the name.
- Use a readable native-width baseline when available.
- The body wraps across the entire inner width with automatic height and no native maximum-line truncation.
- Reassert these constraints after native show/layout changes; a wide background with a narrow text column is not valid.
- Restricted title-width measurements fall back to the readable minimum rather than arithmetic on a secret value.
- Identify aura tooltips through `UnitAura` data or supported native aura getters, including buff/debuff aura-instance getters, so ordinary spellbook entries retain the normal spell format.
- Native descriptions and recognized duration lines remain visible without exposing restricted names or text.
- The standard tooltip skin and native text constraints must return when the frame is reused for another type.
- Mounts use their real journal/spell icon and an icon/name header, with available native movement information beneath the name.
- A native category/type row precedes a Cast trait cell and the mount's description/source information; do not add the active-spell Recast/resource grid.

### Core Requirements 10
- Use native mount data and wording; omit an unavailable icon instead of borrowing an unrelated one.
- Toys use their real item icon and name, native category, Cast/Recast traits based on the associated spell when available, description/effects, and the native level requirement when applicable.
- Distinguish toy data from ordinary item metadata.
- Missing timing data uses `--`, and the requirement remains visually separate from the descriptive body.
- Simple skill-line/flyout and companion-pet tooltips use an icon/name header followed by native descriptive text, without an active-spell metric grid.
- Resolve an icon from the owning button or appropriate skill-line/pet-journal data when it is available.
- A companion pet may retain its category beneath the icon/header area; redundant cast text is omitted in that specialized layout.
- Do not invent a spell ID for a tooltip that does not supply one.
- Pet battle abilities use the native pet-type icon at 32x32, a name beside it, and trait cells for Cooldown in rounds and Hit percentage when provided.
- Missing values use `--`.

### Core Requirements 11
- Separate the description from traits with the existing thin divider treatment; retain meaningful native effect text and strong/weak type information with its icons.
- Do not present pet rounds as seconds or add player resource/cast cells.
- Reassert the measured size after Blizzard's own resizing without duplicate native text or dividers.
- Regression coverage should include item classification, binding/requirements, equipment comparisons and sell-value duplication, wrapped left/right rows, spell metadata loading, active/passive transitions, large-to-small spell height, currency icons and late footer lines, aura title width and long descriptions, restricted measurements/text, and restoration across tooltip types.
- Specialized mount/toy/skill/pet layouts must also be checked against their native data and references.
- Editor diagnostics and mocked assertions alone do not establish that a layout or API works on Forever or Retail; verify on the client build being used and record unavailable capabilities rather than assuming compatibility.

### Minimap mouseover labels
- `MinimapMouseover` titles use their measured, unbounded text width instead of a fixed width that adds an ellipsis.
- Long labels wrap only when they reach the available screen width, and the tooltip grows vertically to show all wrapped text.
- Restore the tooltip and title's native dimensions and line settings when hidden or reused for another tooltip type.
- Fit only completed single-line minimap mouseovers; preserve native sizing for multi-line content and restore the fit before tooltip lines are rebuilt.
- Mock-up: [minimap-tooltip-fit.html](../../../mockups/minimap-tooltip-fit.html) (approved 2026-11-14).
- Targets: Retail and Forever. API source branches checked: [Retail 12.1.5, commit `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`](https://github.com/Gethe/wow-ui-source/tree/297d7aaaa736f346b3e036f38ee088eaf7f8c07f) and [Forever 1.60.1, commit `bebcb6bf309cf41b41bd74f8ca651e6a105b2676`](https://github.com/Gethe/wow-ui-source/tree/bebcb6bf309cf41b41bd74f8ca651e6a105b2676).
- Runtime acceptance: the user will test in game. Automated Lua tests pass; no connected-client errors or screenshots were available in this session. Controller support is not applicable to this passive tooltip.

## XML Conversion
Status: mockup approved by the user. Implementation planned in `xml-conversion.md`. Not started.

- Goal: move as much static tooltip structure as possible into XML. Templates are declared as virtual frames and not built only from Lua frames.
- One shared virtual template (`FFXIV_TooltipTemplate`) holds the round-frame slices, bar underline, header icon, title and subtitle FontStrings, a fixed pool of label/value row pairs, description, footer and divider textures. Every section is created hidden.
- Row-level content is pre-declared in XML as a hidden template row (text rows) and a fixed pool of three trait cells per row. Lua clones the text-row template as many times as the native lines need, so no native line is dropped and there is no fixed cap. The trait cell count (three) comes from the code's existing cap.
- Specialised layouts (mount, toy, skill line, pet ability, companion pet) reuse the same template and sections. They do not get separate templates.
- Stays in Lua: the 40-strip shine gradient (per user decision), native tooltip line capture and restore, restricted-value handling, data acquisition, text and colour values, which sections show, per-row anchors when content changes, measured reflow, caching and lifecycle restoration.
- Converted to XML: static round-frame slices, bar underline pieces, header icon frame, title/subtitle/description/footer FontString templates with font inheritance, dividers and row label/value templates.
- Font rule: every virtual FontString declares `inherits` for a font object, because `SetText` on an unfonted FontString raises "Font not set". `Tooltips.StyleFont` may still override the font after creation, so tests must check the XML attribute itself.
- Visual rules: the Dark palette from `FFXIV_UI/General/Themes.lua` applies, and the layout keeps the measured width and padding from the aura template (text width 248, 16px side inset, 12px top inset).
- Testing: a Lua suite per template group in `tests/`, with the XML loader extended for Button and nested texture children. Tests cover template geometry, every pool row hidden by default, show/hide of sections per tooltip type, shine preserved in code, and reflow after native resizing. All 43 existing suites must pass in classic and Retail modes, and the XML must parse.
- Acceptance: Retail visual acceptance by the user is required. Forever checks are deferred and never recorded as passed.

### Reference layout rules (approved reference pass)
- Header: the icon and the item name share one row. The name is vertically centred beside the icon, left-aligned, and wraps so the full name shows. Names are never truncated with an ellipsis.
- Item type (for example Wrist / Plate, Crafting Reagent, Housing Decor, Spell) sits on its own line directly under the icon, left-aligned. It must not overlap the icon.
- The owned/max count (for example 1/200 or 1/1) sits on the item type line, right-aligned.
- Housing items: when a housing count exists, its house icon and count replace the owned/max text in that right-aligned slot. The icon must stay inside the tooltip and must not hang off the right edge.
- Trait cells (Cast, Recast, MP Cost, Damage, DPS, Speed) use a label above a right-aligned value with a thin bar underneath. Cells come from the pre-declared pool.
- Flavor text and other wrapped text are measured after wrapping. A tooltip whose final section is flavor text must hold its full height, with no clipping at the bottom.
- Reagents and other item types keep the existing muted colour for their type line. The Midnight/season line and the effect text use the effect colour. The muted type colour is a current decision and may need to be updated when themes are re-implemented.
- Sell Price and Durability use the body's left edge. Coin icons follow their amounts. No blank gap is left between the last text and the Sell Price line.
- Mockup: `.memory_bank/features/tooltip-layouts/xml-tooltip-preview.html`. Approved by the user. Plan: `xml-conversion.md`.
# Tooltip Layouts: XML Conversion and Layout Plan

Feature spec: `spec.md` (Core Requirements 1–11 are the functional acceptance list; "XML Conversion" and "Reference layout rules" are the conversion contract).
Approved mockup: `xml-tooltip-preview.html` (approved by the user; not yet opened in a browser).

## Status Summary
- Aura tooltip XML: implemented (`FFXIV_UI/General/Tooltips/AuraTooltip.xml`), awaiting Retail acceptance. Forever deferred.
- Shared tooltip template: not started.
- Layout fixes requested in the reference pass: not started.
- Functional requirements 1–11 have not been audited against the current code. Treat each as unverified until a test or Retail check covers it.

## Rules For Every Phase
- Lua keeps: data acquisition, native line capture and restore, restricted-value handling, text and colour values, section visibility, measured reflow, caching, lifecycle restoration, and the 40-strip shine gradient (user decision).
- XML owns: static structure, virtual frames, textures, FontStrings with `inherits` for a font object, and a hidden row pool.
- Each phase needs a test suite in `tests/`, and the phase must pass all 43 existing suites in classic and Retail modes plus XML parse checks.
- Each phase needs user acceptance on Retail before the next phase starts. Forever checks are deferred and never recorded as passed.

## Open Decisions (resolve before the phase that depends on them)
- [x] Palette: the mockup colours match the Dark theme and are approved by the user. No change needed.
- [x] Housing indicator: the house icon and count replace the owned/max text in the count slot, as the approved mockup shows.
- [x] LinkButton: this is the professions social menu button, not a tooltip item. It is tracked in `professions/xml-conversion.md` and removed from this plan.
- [x] Row pool design: option B, chosen by the user. Text rows grow from a hidden XML template row in Lua, with no cap. Trait cells use a fixed pool of three per row, which comes from the code's cap. Native lines are never dropped.

## Phase 1: Shared Template Foundation (XML)
- [x] Round-frame slices in `FFXIV_UI/General/Tooltips/Tooltip.xml`: eight rim templates, eight background templates, and the tiled centre fill (`FFXIV_TooltipBackground22Template`). Retail accepted corners, edges, and background. Shine and native-text layering were not explicitly confirmed and remain to verify. `FFXIV_TooltipTemplate` and the rest of its pieces are still open.
- [ ] Add the remaining `FFXIV_TooltipTemplate` pieces to `Tooltip.xml`. Done: the FontString templates for type, count, heading, value, description, and footer. Done and Retail-accepted: the header icon template (`FFXIV_TooltipIconTemplate`, 32×32 at 16,-10, used by Items, Spells, Mounts, Toys and Skills), the band template (`FFXIV_TooltipBandTemplate`, 0,0,0,0.35), and the divider template (`FFXIV_TooltipDividerTemplate`, 0,0,0,0.85). The divider keeps `Themes.StyleDivider` for its accent and runtime colour. A stale-divider bug (uncached dividers never hidden) was found on Retail and fixed in `Items.lua`; the user confirmed the layouts match. Done and Retail-accepted (the user confirmed the tooltips look unchanged): title (`FFXIV_TooltipTitleTemplate`), stat label and value (`FFXIV_TooltipStatLabelTemplate`, `FFXIV_TooltipStatValueTemplate`), money line (`FFXIV_TooltipMoneyTemplate`), and the hidden row pool (`FFXIV_TooltipRowTemplate`, a hidden Frame that Lua clones). Not yet wired into Lua; wiring happens in Phase 2 and later. Everything starts hidden.
- [x] Add `Tooltip.xml` to `FFXIV_UI/FFXIV_UI.toc` and `FFXIV_UI/FFXIV_UI_Camelot.toc` before `Core.lua` in both.
- [x] Extend `tests/support/PanelTemplates.lua` with the `FFXIV_Tooltip` prefix and the `Tooltip.xml` source. Button children and nested textures are still open and will be added when a template needs them.
- [x] Consumable text regions now come from XML FontString templates (`ConsumableRegion` in `Core.lua`). Palette colour and size stay in code. The bar underline stays in Lua because it uses mask textures, which the loader doesn't support, and it is sized per row.
- [ ] Remaining Lua-created static pieces in `RoundTooltip` move into template children where they're fixed. Keep the shine in Lua.
- [ ] Tests (`tests/Tooltip.lua`): the round-frame part exists and passes. Still open: every pool row hidden by default, every FontString declares `inherits`, and the template-level checks for the remaining pieces.
- [ ] Retail acceptance.

## Phase 2: Header Layout (requested reference fixes 1–4, 6, 7)
- [x] Name wraps in full beside the icon. It is left-aligned and vertically centred on the icon row. No ellipsis or truncation. Retail accepted: the name uses a 32px height with the header always reserving the binding row (name at -19, icon at 16,-19).
- [x] Item type sits on its own line directly under the icon, left-aligned. It must not overlap the icon (fixes the reagent overlap). Retail accepted with the type row at -48 + headerOffset (-8).
- [x] Owned/max count sits on the type line, right-aligned. Equipment does not show it. Retail accepted: the count row is correct.
- [x] Housing: the house icon and count take the right-aligned count slot. The icon stays inside the tooltip. Retail accepted: the native housing line is hidden, the masked house icon is drawn with the owned count (stored + placed), and the right side has no extra buffer.
- [x] Header icon is 32×32 at (16, -10) without a binding row, and (16, -19) with the reserved row. Name starts at x=56. Inner side padding is 16. Retail accepted.
- [x] Binding and unique/equipped restrictions stay in a muted 10-pixel line above the name. The header always reserves that row, so items without a binding line are laid out the same way. Retail accepted.
- [x] Tests for each rule above, using both reagent and housing fixtures (`tests/Tooltip.lua` header rules, `tests/CharacterFrame.lua` binding, name and housing cases).
- [x] Retail acceptance: the user confirmed the rest of Phase 2 is fixed.

## Phase 3: Body and Footer Fit (requested fixes 5, and reference rules)
- [x] Flavor text and other wrapped text are measured after applying the final width. A tooltip ending in flavor text holds its full height and nothing clips at the bottom (fix 5). Retail dump (`/ffxivframedump GameTooltip`) showed the flavor line bottom at about -220.5 against a 222px tooltip, so the height was about 14px short of the flavor text plus padding. Retail string heights stay stale for several frames after wrapping, so `ApplyContentLayout` now re-fits over four 0.05s steps. Test in `tests/CharacterFrame.lua` models stale measurement for three frames. Crafting reagents (the Rejected header path with no use effect) now register their native title and body rows as `consumableRows`, so the fit also grows their frames; a regression test covers this. Retail accepted the fix for Spark of Tides, Dornic Fir Lumber, and Gamey Flank.
- [x] Item-type colour kept as the existing muted colour per user decision. Note: this may need to be updated when themes are re-implemented.
- [x] Sell Price and Durability start at the body's left edge. Coin icons follow their amounts. No blank gap before Sell Price. (Sell Price for structured consumables is now a custom left-aligned label; Durability is not yet covered. Awaiting Retail check.)
- [x] Reagent and junk titles centre vertically on the header icon. The rejected path anchors title and icon at -19 with a 32px band, matching the structured path. Retail approved by the user. Test in `tests/CharacterFrame.lua` reagent block.
- [x] Sell Price per-unit value is correct. The larger stack-total figure seen in dumps is the stack value (for example, a stack of 2 shows 2 times the price). The user approved this.
- [x] Suppress duplicate native sell lines and money frames when the custom sell value is drawn. (Both paths hide every native sell region (left and right, by line index or "Sell Price:" prefix) through `HideNativeSellPrices` in `Core.lua`, then draw one custom label. The rejected path (reagents, junk, dyes, L00T) re-places its native body rows with `PlaceNativeLine` at x=16 and saves them at alpha 1, so flavor text stays visible. The sell label sits at the cursor on the tooltip's left margin, not the centred native region. The frame height is set from the content, so it can shrink. Awaiting Retail check on reagents, junk, housing dyes, L00T, and potions.)
- [x] Custom sell label anchors below the last visible row. The rejected path (reagents, dyes) copies each native row into an owned FontString (`MirrorRow` in `Items.lua`, stored in `tooltipSkin.rowMirrors`) and places only the copies; native regions are hidden. The structured path still places native regions. The user approved the Gamey Flank and Red Housing Dye fixes.
- [x] Late-appended native footer lines (for example "Click to view options") trigger reflow and keep bottom padding inside the background.
- [x] Reflow left and right columns after applying width, and remeasure after native `Show` and resize.
- [x] Socket gem icon (user report, reference image): the socket icon for a line such as "+12 Primary Stat and +1% Maximum Mana per unique Algari gem color" currently overlaps the "+21 Intellect" bonus line. Place it in front of the socket-bonus line, top-left aligned with that line's text, and start the text to its right with a small buffer. Keep the icon inside the body's left edge. (The native socket texture is hidden in the equipment layout and a 12px custom icon is drawn top-left, with the line text offset 16px. Approved by the user. Covered by the socket test in `tests/CharacterFrame.lua`; 44/44 suites pass in classic and Retail.)
- [x] Tests: flavor-text height, sell alignment, footer reflow, and duplicate sell suppression. (Reagent test covers a left and right sell row: one label at the tooltip's left margin, all native sell rows hidden, flavor visible, and the frame shrinks to content. Full suite: 44/44 pass.)
- [x] Crafting reagent Quality line. Closed by user decision: the native Quality row stays as it currently appears on the tooltip. No further changes planned.
- [x] Retail acceptance.

## Phase 4: Per-Type Layouts Using the Pool
Mockup for all groups: `phase4-type-layouts-preview.html` (approved by the user). Major-trait lines use three fixed slots: equipment fills from the right, spells, mounts and toys fill from the left. Equipment is the first group to implement.
- [x] Equipment: Defense and Damage/DPS/Speed metric cells, item level band, requirements, two-column stats with beneficial/detrimental colours, comparison rows and deltas under a divider (no heading, per user decision), Effects heading and divider, footer. Metric cells fill from the right; weapons always show all three cells. Tests cover 1 metric (armor), 3 metrics (weapon), a weapon-to-armor reuse that hides stale underlines, and comparison rows. Colours are copied from the native lines; the detrimental red is not separately asserted. Retail acceptance is still needed, including the native Defense x-position.
- [x] Usable items: Recast cell from the item's associated spell base cooldown, `--` when missing or secret (`Items.lua` recast block; tests `tests/CharacterFrame.lua` ~831–907 cover the zero, secret, unavailable-API, and Hearthstone 30-minute cases). Retail acceptance is still in the per-group line below.
- [x] Active spells: Cast, Recast and resource cells; muted Spell/Ability category with Range/Radius right-aligned on that row; 420 minimum width. Resource cell omitted when no valid cost. Tests cover the cast text, range/radius text, the MP cost cell, and the omitted-cost case (`tests/CharacterFrame.lua` ~1636–1760). The 420 minimum comes from `Spells.lua` (`targetWidth`) and is not asserted directly.
- [x] Passive spells: muted Passive label, no Cast/Recast/resource grid. Test added (`tests/CharacterFrame.lua`, after the instant-spell block) checks the label and hidden grid, then restores the Cast cell when the spell is no longer passive. The description-below-separator placement is code-only and not asserted.
- [x] Large-to-small spell transition shrinks height from the current rows only. Covered by the short-after-large spell assertion (`tests/CharacterFrame.lua` ~1679).
- [x] Currency: real icon from `C_CurrencyInfo.GetCurrencyInfo`, native name beside it, 320 minimum width, native description and totals, reuse without keeping the previous layout. Tests (`tests/CharacterFrame.lua` ~1300–1361) cover icon source, title beside icon, native details and totals, refresh, footer, and cleanup. The 320 minimum comes from `Items.lua` (~43) and is not asserted directly.
- [x] Mounts: real icon, native category row, Cast trait cell, description and source. No Recast/resource grid. (Covered by the mount layout block in `tests/CharacterFrame.lua` after the shrink test; passes classic and retail. Source is asserted only in code. Retail-accepted by the user.)
- [x] Toys: real item icon, category, Cast/Recast from the associated spell, description/effects, native level requirement separated from the body. (Covered by the toy layout block in `tests/CharacterFrame.lua`; a missing cooldown shows `--`. Passes classic and retail. Retail-accepted by the user.)
- [x] Skill-line/flyout and companion-pet: icon/name header and native descriptive text. No active-spell metric grid. Pet category may stay under the header. (Retail-accepted by the user for the skill-line/flyout and companion-pet tooltips.)
- [x] Pet battle ability: native pet-type icon at 32×32, Cooldown (rounds) and Hit (%) trait cells, `--` for missing values, and no seconds or player cast cells. (Retail-accepted by the user.)
- [ ] Aura tooltips: already converted. Confirm the borderless layout is unchanged by the shared template work. (Retail-confirmed by the user for native aura collection. Target frame, party frame and enemy list auras are still open: the user reports they still show the native dark background and solid border, so they are not converted yet.)
- [ ] Tests per type, including restoration when the frame is reused for another type.
- [ ] Retail acceptance per type group.

## Phase 5: Verification and Closeout
- [ ] All 43 existing suites plus the new suites pass in classic and Retail modes.
- [ ] XML parses for every tooltip template file.
- [ ] Audit Core Requirements 1–11 against the code. Record each as covered by a test, covered only by Retail acceptance, or not implemented.
- [ ] Update `spec.md` status and the window-controls backlog if this feature closes a row.

## Separate Backlog (not part of the tooltip XML conversion)
- [ ] Professions Retail defects, deferred by the user: overlapping items on the top row, buttons not in FFXIV_UI style, incorrectly displayed reagents, unstyled Crafting Details. Professions XML scope is not yet approved. Requires its own mockup before implementation.
- [ ] Social: confirm whether the Guild tab is in scope. Not answered yet.
- [ ] Reusable icon, metric, divider and background templates are not converted in other features. Only the tooltip aura template exists. Decide whether to share them after Phase 1.
- [ ] Forever verification for all tooltip phases and all window-controls rows. Deferred, never recorded as passed.

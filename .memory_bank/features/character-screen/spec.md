# Character Screen Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Stat-state theming handles both native text colors (including the lime-green variant) and embedded green/red color markup.
- Original value text is retained for live theme changes; unrelated embedded colors and native tooltips are unchanged.
- Health and active power appear in a full-width row above the two-column stat sections rather than under General.
- Each shows exact current and maximum values separated by a thin resource bar, with HP at the left and MP (or the localized active resource, such as Energy/Rage) at the right.
- Unit health, power, maximum-value, and resource-type events refresh them immediately, including in combat; reopening the pane also refreshes values.
- Pet details use their own live unit values.
- Other General stats remain in their original section.

### Core Requirements 2
- Character navigation tabs use beveled, pointed-end artwork inspired by the supplied FFXIV reference.
- Fixed-width endcaps preserve the shape in expanded and two-row collapsed layouts; fill, border, text, selection and hover colors follow the active theme.
- Native tab hit targets and actions are unchanged.
- Localized tab labels use 10-point text and can wrap onto two centered text lines in either layout, within a bounded area that reserves space for the marker and pointed ends; expanded labels no longer shrink to fit a single line.
- Unselected tabs show a subdued light diamond in the same position as the selected gold diamond.
- Shared control artwork provides the default shapes for future styled tabs, standalone capsule buttons, and plain rounded search fields.
- Currently the capsule button style applies to character equipment-set Equip/Save buttons and inventory bag options, while inventory item search uses the search-field style; FFXIV UI settings controls are unchanged.
- All three styles respect the selected theme and preserve native input handlers.
**Color Theme (account-wide)** in FFXIV UI settings selects Dark (default), Light, Classic FF, Clear Blue, Clear White, Clear Green, Clear Grey, or Clear Pink. The choice is saved separately from character settings and anchor profiles. Themes apply to the character screen and unified inventory, not the settings window or HUD. Colors update immediately, including in combat; newly created/recycled stat rows use the current palette. Normal text adapts for light backgrounds. Native beneficial/detrimental stat states use deep green/crimson on Light, Clear White, and Clear Pink, and bright green/red on darker themes; unrelated native colors and tooltips are preserved. These are screenshot-inspired palettes using existing artwork, not exact reproductions of the reference textures. The shared theme module is available for future styled windows.
- Forever's character window uses an FFXIV-inspired frame with Axis fonts and theme-colored panels and accents (dark with muted gold by default).

### Core Requirements 3
- The six native side tabs become a labeled horizontal row beneath the title: Character, Reputation, Skills, PvP, Currency, and Statistics (using the client's localized labels).
- When details are collapsed, the buttons use two rows of three with 10-point labels instead of shrinking text into a single narrow row; longer localized labels can wrap.
- The window gains 33 pixels of height in this mode to preserve the model's content area.
- Selection and hover highlights follow the native tabs, and controller shoulder-button indicators use the horizontal orientation.
- On the Character page, the stats/details pane is on the left and the character model and equipment slots are on the right.
- Stats use two columns of titled sections instead of the native scrolling list: General, Primary Attributes, Offensive Properties, Defensive Properties, Spell Properties, and Resistances.
- Sections use the native available-stat data and row initialization, retaining live calculations, tooltips, native class/equipment filtering, and meaningful value colors; empty sections are omitted.
- Spell stats are separated from the native Modifiers category, while weapon stats and other modifiers share Offensive Properties.
- Other native category titles use the client's localization, and unrecognized future categories are retained.
- Pet stats use their own section view.

### Core Requirements 4
- Section headers use gold icons extracted from the supplied closeups: Role for General, the figure for Primary Attributes, the sword for Offensive Properties, the shield for Defensive Properties, the staff for Spell Properties, and the star for Resistances.
- Icons display at 22 pixels and retain their original gold colors across themes.
- All seven supplied icons, including the unused Gear emblem, are preserved as transparent 64x64 PNGs and matching alpha-enabled TGAs under `Media\Textures\Character`; in-game headers load the TGAs.
- Unknown future categories retain text-only headings.
- The Character page's details area is 440 pixels wide; with the native 398-pixel model area, the expanded window is 838 pixels wide.
- Section headings use 12-point text and stat labels/values use 10-point text, with compact 24-pixel headers and 18-pixel rows.
- Its height grows if needed to fit all section rows without scrolling or clipping.
- Other pages retain their native widths and left/right content arrangement.
- Equipment slots reuse the square button skin at their native sizes.
- Equipment clicks/dragging, gear sets, pet details, model controls, and the close button retain their native actions.

### Core Requirements 5
- Controller pane-crossing directions follow the reversed layout.
- Collapsing details keeps the model visible and refits the tab row.
- The window gains at least 62 pixels of height to make room for navigation without shortening the original content area.
- The character window is an unprotected UI panel, and native code resizes it every time it opens, so addon layout runs in combat too. Opening it in combat shows the FFXIV layout, not the native one. Layout defers until `PLAYER_REGEN_ENABLED` only when `CharacterFrame:IsProtected()` is true; controller navigation setup always waits for combat to end. Stat values still refresh. If a native stat update fails in combat (secret values), its row shows the same localized label the native code uses (for example `SPELL_STAT1_NAME`, `INVTYPE_WEAPONMAINHAND`, `STAT_ATTACK_POWER`) with `--`, then retries after combat.
- The native level-info panel is restyled directly as a rounded two-line class banner, rather than covered by a second panel: a compact level label above a larger gold class name and native class icon, without weapon artwork.
- The native collapse button sits inside its right edge.
- Class and level labels remain localized, effective-level scaling remains visible, and the pet page retains its native level/family and loyalty labels.
- Native nine-slice and pane/model header artwork, including the separate `PaperDollFrame.TopBackgroundStripHost`, stays hidden across native refreshes.
- The collapse button retains its native action and renders above the level panel in the same frame strata.
- Rotate/zoom controls sit four pixels below the class banner.

### Core Requirements 6
- The model viewport also starts four pixels below the banner, reserving its space rather than rendering tall characters behind it; equipment-slot anchors and native camera controls are unchanged.
- The model background retains full pane coverage, inset eight pixels from the right and bottom window edges.
- A shared dark rounded resource panel sits above the stat sections, with HP on the left and the active primary resource on the right.
- Each group has a left-aligned label, right-aligned current value, thin colored progress bar, and right-aligned maximum beneath it.
- Health and power events update the values and bars without polling; native stat refreshes preserve the larger resource typography.
- The resource-only diagnostic isolation option also suppresses this panel.
- The model header uses a solid dark rounded background with banner-owned labels: localized Level on the first line, then the class icon and localized class name on the second.
- The native combined label is hidden, and native level refreshes update the replacement.
- Item level uses a 28-pixel icon next to the glove slot, with its light-blue value right-aligned immediately to the icon's left.
- The Retail/Mainline hostless character frame uses a separate FFXIV treatment and does not enter Forever's pane-host path.

### Core Requirements 7
- On the PaperDoll page, the window expands to 838x546, with a 440-pixel stats pane on the left and a 398-pixel equipment/model pane on the right.
- Item Level's category heading is hidden and its value is placed beside the glove slot with a placeholder icon.
- Attributes and Enhancements are separate side-by-side sections with gold icons and underlined headings; pooled native rows remain under their category after each refresh.
- The character name is right-aligned in the title bar, native tabs form a horizontal row beneath it, and a borderless level/class surface sits above the model.
- Equipment slots flank the model, with the first row below the header and weapon slots centered at the pane bottom.
- Only the outer shell, header divider, section underlines, and level surface remain visually framed; native panel fills and borders behind insets, stats, and sidebar buttons are hidden.
- Native item interactions, tab actions, and stat calculations remain intact.
- In-game visual alignment and navigation still need live confirmation.

### Core Requirements 8 (Forever Reputation, Skills, PvP and Statistics styling)
Status: Proposed. No implementation until the HTML mockup is approved (see Plan).

- Reputation expanded faction frame: the currently selected faction row shows a framed panel using the rounded surface panel (`RoundFill` "surface", `FFXIV_UI/General/RoundedPanels.lua`). Decided in Q1.
- Collapsible headers on the Reputation, Skills and Statistics tabs use the same style as the Social menu's headers (`addonEnv.StyleCollapsibleHeader`, `FFXIV_UI/General/WindowControls.lua`). This becomes the standard for every collapsible header in the character screen.
- Reputation faction bars and labels match the Retail reference `Media/References/Retail_FFXIV_Reputations.png`: faction name at top-left; a full-width, thin dark track below it; standing text (in its standing colour) at bottom-left; `current / max` in white at bottom-right; no text centred on the bar.
- The Forever screenshot (Pasted Image 1) shows the native standing text centred on the bar and progress in a separate box. That means native BarText or labels are still visible in-game, so verify and remove them as part of this requirement.
- Skills tab: collapsible headers match the Social style, and the expanded skill frame uses the same rounded surface panel as Requirement 1.
- Player Versus Player tab: the expanded frame uses the same rounded surface panel as Requirement 1.
- Statistics tab: section headers (category headings) match the Social style (Requirement 2). Individual stat-group toggles are handled by Requirement 7 (Q3: section headers only).
- Statistics tab: collapsible items (individual stat groups) replace the native `+` / `-` toggles (Pasted Images 3 and 4) with the circular arrow button (`addonEnv.StyleCircularArrowButton`): `right` when collapsed, `down` when expanded. Native toggle actions are preserved.
- Visual styling reads from the active theme palette; no hard-coded colours.
- Dual compatibility: Retail and Forever share the code path; any Forever-only native frame names are guarded.
- Combat lockdown: geometry changes made during combat are deferred until `PLAYER_REGEN_ENABLED`.
- Automated tests cover the header style application, circular toggle directions, and the selected-frame background in `tests/CharacterFrame.lua`.

#### Plan
1. Discovery (read-only): inspect the native Skills, PvP and Statistics frames for Forever (`SkillFrame`, `PVPFrame`, `StatisticsFrame` or equivalents) and Retail's reputation bar/label templates. Record the frame names and toggle textures in this spec.
2. HTML mockup: one `mockups` page (or a feature-folder preview like `shell-preview.html`) showing before/after for Reputation (selected frame, header, bar + labels), Skills, PvP and Statistics. Get the user's approval before any Lua/XML work.
3. Shared header: apply `StyleCollapsibleHeader` to Reputation, Skills and Statistics headers. Reuse the Social approach (hide native textures, add accent-coloured pill and arrow). Do not change `WindowControls.lua` behaviour for Social or Professions.
4. Reputation: restyle the selected entry frame and the bar/label layout in `FFXIV_UI/General/Reputation.lua` (`StyleEntry`), keeping the existing pill-bar drawing and extent calculators.
5. Skills and PvP: apply the same expanded-frame background to the expanded skill and PvP rows.
6. Statistics: replace the native `+`/`-` toggles with `StyleCircularArrowButton` (`right` / `down`) and style headers as in step 3.
7. Tests: add cases to `tests/CharacterFrame.lua` (and `tests/Social.lua` if the shared header changes), then run the suite with the `lua-runner` skill.
8. Live validation: in-game check on Retail and Forever, screenshots compared against the mockup, and combat-lockdown check.

#### Decisions (user answers)
- Q1: Selected frame background is the rounded surface panel (`RoundFill` "surface").
- Q2: Retail reference is `Media/References/Retail_FFXIV_Reputations.png`.
- Q3: Statistics: the Social-style header applies to section headers only; the circular arrow applies to individual stat-group toggles.

- Q4: Reputation bar target is the Retail reference (Q2). Forever currently draws the native BarText standing in the centre of the bar, and hover shows `current / max`. Hide it.

#### Confirmed Forever frame names (from `Dumps/*.txt` and `/fstack` captures, build 16001)
- Tabs: `ReputationFrame`, `SkillsFrame`, `PVPRankFrame`, `StatisticsFrame`, `TokenFrame` (tab label "Currency").
- Expanded panels: `ReputationFrame.ReputationDetailFrame`, `SkillsFrame.SkillDetailFrame`, `PVPRankFrame.DetailFrame`, `TokenDetailFrame`.
- Reputation section header row: `ReputationFrame.ScrollBox.ScrollTarget.<id>` (the row frame, runtime id). Children: `.Name` (label, Blizzard `ReputationFrame.xml:20`, anchored LEFT 10,0), two static glyph children (both `common-button-list-collapseExpand`) and `.StateIcon`, which is the state glyph: expanded atlas `common-button-list-minus` (`-`), collapsed atlas `common-button-list-plus` (`+`). Source `Blizzard_SharedXML/Scroll/ScrollBoxListView.lua:25`. Reputation, Skills and Statistics headers share this structure.
- Statistics toggle: native `ToggleCollapseButton` child of `StatisticsFrame.ScrollBox.ScrollTarget.<id>`. Find it by template or type, not by the runtime id.
- Atlas names are a Forever build 16001 observation; use the collapse state from the header hook as the source of truth.
- Skills header row: `SkillsFrame.ScrollBox.ScrollTarget.<id>`, with children `.Name`, two static glyph children (`.20033d3f340`, `.20033d3f480`, both `common-button-list-collapseExpand`) and `.StateIcon`. `ScrollBoxListView.lua:25`. `.StateIcon` is the state glyph: expanded atlas `common-button-list-minus` (`-`), collapsed atlas `common-button-list-plus` (`+`). Same pattern as Statistics.
- Statistics header row: `StatisticsFrame.ScrollBox.ScrollTarget.<id>`, with children `.Name`, two glyph children (`.<id>.20010e4c830`, `.20010e4c920`) and `.StateIcon`. Source is `Blizzard_Statistics/Camelot/StatisticsFrame.xml:7`, not SharedXML. `.StateIcon` is the state glyph: collapsed atlas `common-button-list-plus` (`+`), expanded atlas `common-button-list-minus` (`-`). The two other children report `common-button-list-collapseExpand` in both states, so they are static textures and not the state glyph.
- PvP has no collapsible header rows. Its page is a single detail layout (rank badge, `Rank Points`), so only its expanded frame (`PVPRankFrame.DetailFrame`) needs styling. Confirmed with `Pasted Image 5`.

#### Open Questions
- Confirm the Reputation header's state glyph. Confirmed: `.StateIcon` (`+` collapsed, `-` expanded). Resolved, so no further capture is needed.
- Skills header uses the `.StateIcon` `+`/`-` atlases, matching Statistics. Only the collapsed/expanded pair was captured for the hovered row, not the Reputation header.
- Whether the addon's own standing and progress labels (`StyleEntry`) are hidden or not rendering. The in-game screenshots show no labels below the bar.
- Currency tab (`TokenFrame`) has no entries yet, so its header style is unverified.

#### Decisions (user answers)
- Header state source is the `.StateIcon` atlas (`common-button-list-plus` = collapsed).
- Statistics section headers also get circle arrows. Item toggles use right (collapsed) and down (expanded).
- Header styling applies to the empty Currency (`TokenFrame`) tab too.
- Experiment (user request): Forever header rows use the dark ComboBox bar (`ComboBox-Closed-Dark` collapsed, `ComboBox-Open-Dark` expanded) instead of the Social pill. The bar includes its own arrow, so no circle arrow is added (user confirmed). Social and Professions keep the pill. Pending user review.

#### Implementation status
- [x] Shared Forever header path: `addonEnv.StyleForeverCollapsibleHeader` in `FFXIV_UI/General/WindowControls.lua`, drawn with the ComboBox bar. The bar's built-in arrow is used, so no circle arrow is added.
- [x] Reputation header rows routed to the Forever header path from `StyleEntry` in `FFXIV_UI/General/Reputation.lua`.
- [x] Reputation `BarText` kept hidden with `HideKeptHidden` (SetAlpha and Show hooks). Not covered by a test.
- [x] Test: `tests/CharacterFrame.lua` "Forever header rows hide the native StateIcon...".
- [ ] Skills, Statistics and Currency header wiring.
- [ ] Statistics circle-arrow item toggles and section headers.
- [ ] Expanded frame surfaces (Reputation, Skills, PvP, Token), nil-guarded.
- [ ] Combat-lockdown deferral for geometry changes.
- [ ] Live Retail and Forever verification and screenshots.
- Pre-existing: `tests/Professions.lua` fails at line 358 on a clean tree too.

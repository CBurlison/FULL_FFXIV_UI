# Character Screen: Forever Reputation, Skills, PvP and Statistics Styling Plan

Status: In progress. Requirements are in [spec.md](./spec.md) (Core Requirements 8). This document tracks the plan, progress, and open decisions.

## Goal

Bring the Forever character-screen tabs (Reputation, Skills, PvP, Statistics, Currency) in line with the rest of FFXIV_UI. The addon must keep working on Retail too.

Seven requested changes:
1. Expanded reputation frame gets a real frame (rounded surface panel).
2. Collapsible headers match the Social menu style, as the standard for all of them.
3. Reputation faction bars and labels match the Retail counterpart.
4. Skills tab: Social-style headers and an expanded-frame panel.
5. PvP tab: expanded-frame panel.
6. Statistics tab: Social-style section headers.
7. Statistics item toggles use the circle arrow (right = collapsed, down = expanded) instead of `+` / `-`.

## Decisions

| # | Decision | Source |
|---|----------|--------|
| Q1 | Selected frame background is the rounded surface panel (`RoundFill` "surface", `FFXIV_UI/General/RoundedPanels.lua`). | User |
| Q2 | Retail bar reference is `Media/References/Retail_FFXIV_Reputations.png`. | User |
| Q3 | Social-style header applies to section headers only. Circle arrow applies to item toggles. | User |
| Q4 | Bar text: the Retail reference layout is used. No text is centred on the bar, and `current / max` is always visible bottom-right. Supersedes the earlier "rank centred, hover" wording. | User (answered in ask_user: reference layout) |
| D1 | Header state comes from the `.StateIcon` atlas (`common-button-list-plus` = collapsed). | User |
| D2 | Statistics section headers also get circle arrows. | User |
| D3 | The empty Currency (`TokenFrame`) tab gets header styling too. | User |
| D4 | Forever header rows use the dark ComboBox bar (`ComboBox-Closed-Dark` collapsed, `ComboBox-Open-Dark` expanded). The bar texture already includes the arrow, so no separate circle arrow is added. Social and Professions keep the pill. | User (experiment, pending review) |
| D5 | Skill rows and the detail `RankBar` match the Reputation layout. Skills have no named rank, so only the progress number is shown, aligned left. | User |

## Confirmed Forever frame names

Build 16001, from `Dumps/*.txt` and `/fstack` captures:

- Tabs: `ReputationFrame`, `SkillsFrame`, `PVPRankFrame`, `StatisticsFrame`, `TokenFrame` (label "Currency").
- Expanded panels: `ReputationFrame.ReputationDetailFrame`, `SkillsFrame.SkillDetailFrame` (singular "Skill", from `Camelot/SkillsFrame.xml` at `forever@eac30af`), `PVPRankFrame.DetailFrame`, `TokenDetailFrame`.
- Header rows: `<Tab>.ScrollBox.ScrollTarget.<id>`. Each has `.Name`, two static `common-button-list-collapseExpand` glyphs, and `.StateIcon` (the state glyph).
  - Reputation and Skills use `ScrollBoxListView.lua:25`. Statistics uses `Blizzard_Statistics/Camelot/StatisticsFrame.xml:7`.
- Statistics item toggle: native `ToggleCollapseButton` child of the row. Find it by template or type, not by runtime id.
- PvP has no header rows. Only `PVPRankFrame.DetailFrame` needs styling.

Atlas names are a build 16001 observation. The collapse state from the header hook is the source of truth.

## Completed

- [x] Requirements, decisions and frame mapping recorded in [spec.md](./spec.md).
- [x] HTML mockup `mockups/forever-reputation-styling-mockup.html` created and approved. Updated for O2/O3: Forever headers use the dark ComboBox bar (`.combo-header`).
- [x] Step 2: Reputation expanded frame. `addonEnv.StyleDetailPanel` in `FFXIV_UI/General/RoundedPanels.lua` applies the surface panel. `StyleDetail()` in `FFXIV_UI/General/Reputation.lua` is gated to build 16001. Covered by `tests/Reputation.lua`.
- [x] Shared Forever header path: `addonEnv.StyleForeverCollapsibleHeader` in `FFXIV_UI/General/WindowControls.lua`. Drawn with the ComboBox bar only; the bar's built-in arrow is used, so no circle arrow is added (D4). It hides the native `StateIcon` and glyphs.
- [x] Shared helpers: `HideTextures` and `StyleHeader` in `FFXIV_UI/General/WindowControls.lua`. The Social path `addonEnv.StyleCollapsibleHeader` still uses `StyleHeader`.
- [x] Reputation header rows route to the Forever header path from `StyleEntry` in `FFXIV_UI/General/Reputation.lua`.
- [x] Reputation native bar `Text` kept hidden with `HideKeptHidden` (`SetAlpha` and `Show` hooks). The frame-stack dump confirms the key is `Text`, not `BarText`. This is not yet confirmed in game.
- [x] Test: "Forever header rows hide the native StateIcon..." in `tests/CharacterFrame.lua`. It checks the Open/Closed texture and that `StateIcon` stays hidden. It also asserts no separate arrow is created.
- [x] Fixed the unfinished D4 header path in `StyleForeverCollapsibleHeader` (`FFXIV_UI/General/WindowControls.lua`). It never registered `comboHeaders[row]`, never drew the circle arrow, and never recorded the bar pieces. `tests/CharacterFrame.lua` was failing at line 3412 because of this.
- [x] Reputation row bars and labels (Req 3) on Forever match `Media/References/Retail_FFXIV_Reputations.png` and the approved mockup: name top-left, full-width pill track, standing bottom-left (lightened rank colour), `current / max` bottom-right. Root cause of the unstyled Forever rows: Forever's `ReputationBar` is `ColoredProgressBarTemplate` (`Blizzard_SharedXML/Camelot/ProgressBars/ColoredProgressBar.xml`, wow-ui-source `forever@eac30af`), a plain Frame with no `LeftTexture`/`RightTexture`/`Background`/`BarText`/StatusBar methods, so `StyleEntry` errored after setting its styled flag. `StyleEntry` in `FFXIV_UI/General/Reputation.lua` now branches on `IsStatusBar`: Retail keeps the StatusBar path; Forever hides the unnamed `common-stat-bar-BG`, `Fill` and `Text` (`HideKeptHidden`), reads progress from `fillPercent`, and refreshes on a `SetFillPercent` hook. Labels refresh from an `UpdateBarColor` hook (called last by every Blizzard bar initializer). Covered by `tests/Reputation.lua`. Not confirmed in game.
- [x] Expanded detail bar (`ReputationDetailFrame.StandingBar`, Forever only) uses the same pill track via the shared `SkinBar` in `FFXIV_UI/General/Reputation.lua`. `StyleDetailBar` stretches it to the Description width (Divider bottom −6, left 0, right −14). The progress text sits below the track, left-aligned. No standing label is added because the pane title already shows it. The bar keeps its native 29px height, so Blizzard's `Description` anchor (bar bottom −8) still clears the text. Covered by `tests/Reputation.lua`. Not confirmed in game.
- [ ] New `tests/Reputation.lua`: header routing, extent calculators, hidden Blizzard textures and native `Text`, label anchors and visibility, computed current / max, the throttled refresh for late rows, and the Forever-only detail bar. Run with `lua5.1 tests\Reputation.lua`.
- [x] Reputation detail panel layout (approved in `mockups/character-expanded-detail-mockup.html`). Forever only. The detail panel has no surround and no content centering. `CenterDetailContent` was removed from `FFXIV_UI/General/RoundedPanels.lua`. While the detail panel is shown, `Layout()` in `FFXIV_UI/General/CharacterFrame.lua` expands the main panel to 786px and places the detail at x=545 below the header. The header name and close button track the top-right corner. Covered in `tests/CharacterFrame.lua`.
- [x] Detail panel refinements (user review):
  - The tab row is sized from the 540px page width, so it no longer changes size when the detail panel opens.
  - The vertical seam moved 5px left to x=535 (`DETAIL_SEAM_INSET`), away from the detail text and checkboxes.
  - The seam ends 10px above the bottom edge (`DETAIL_SEAM_BOTTOM_INSET`), matching the header divider's 10px inset (`FFXIV_CharacterHeaderDividerTemplate`).
  - Covered in `tests/CharacterFrame.lua`.

## Remaining work

Ordered by dependency:

1. **Reputation bar and labels (Req 3)** Row bars (Retail and Forever) and the Forever detail bar are done. Automated tests pass (`tests/Reputation.lua`). Awaiting in-game confirmation under step 9.
2. ~~**Reputation expanded frame (Req 1)**~~ Done (see Completed).
   - Surface panel and expanded layout done. Tabs keep their page width, and the seam sits at x=535 with a 10px bottom inset.
   - In-game check that the detail frame's Blizzard anchoring holds after updates (`Layout()` re-anchors it when shown) stays open under step 7 (Tests) and the final in-game review.
3. **Skills (Req 4)** Code done in `FFXIV_UI/General/Skills.lua` (Forever only). Automated tests pass (`tests/Skills.lua`, `tests/CharacterFrame.lua`). Awaiting your in-game check.
   - Headers (`SkillsHeaderTemplate`: `.Name` and `.StateIcon`) use `StyleForeverCollapsibleHeader`.
   - Rows (D5): name top-left, full-width pill track, and only the progress number below it, left-aligned. Blizzard's `(+modifier)` colour code is kept. Extents: header 26, entry and sub-header 56.
   - `SkillsFrame.SkillDetailFrame` gets the surface panel. Its `RankBar` matches the Reputation detail bar.
   - Detail section headers (weapon skills: "Equal-Level Enemy", "Against Raid Bosses") are pooled `CharacterFrameSidePaneCategoryTemplate` rows from `AddCategory`. `StyleDetailPanel` in `FFXIV_UI/General/RoundedPanels.lua` hooks `AddCategory`, hides each row's framed banner (`Background`, atlas `UI-Character-Info-Title`) and adds the standard divider (`Themes.StyleDivider`) under the label. The divider spans the banner's full width (195px). This applies to every Forever detail pane that uses `AddCategory`. Covered in `tests/CharacterFrame.lua`. Awaiting your in-game check.
   - `Layout()` in `FFXIV_UI/General/CharacterFrame.lua` now handles detail panes through `DETAIL_PANES` (Reputation and Skills): same 786px expansion, x=545 placement and seam.
   - The shared bar code moved to `FFXIV_UI/General/ProgressBars.lua`, loaded before `Reputation.lua` and `Skills.lua` in both TOCs. Forever bars are detected by `SetFillPercent`, not the widget type, because `SkillsBarTemplate` is a StatusBar built on `ColoredProgressBarTemplate`. Labels refresh on `UpdateBarColor` (Reputation calls it last) and `UpdateBarProgressText` (Skills calls it last).
4. **PvP (Req 5)** Code done in `FFXIV_UI/General/PvP.lua` (Forever only). Automated tests pass (`tests/PvP.lua`, `tests/CharacterFrame.lua`). Awaiting your in-game check.
   - `PVPRankFrame.DetailFrame` (a `CharacterFrameSidePaneTemplate` pane) gets the surface panel. Its "Next reward" `AddCategory` header gets the standard divider through `StyleDetailPanel`.
   - `DETAIL_PANES` in `FFXIV_UI/General/CharacterFrame.lua` now includes `PVPRankFrame = "DetailFrame"`, so the page uses the same 786px expansion, x=545 placement and seam.
   - The central honour ring (`MainInfoFrame`) is unchanged; Req 5 covers the detail panel only.
5. **Statistics (Req 6 and 7)** Code done in `FFXIV_UI/General/Statistics.lua` (Forever only). Automated tests pass (`tests/Statistics.lua`). Awaiting your in-game check.
   - Top-level `StatisticsHeaderTemplate` rows (`.Name` and `.StateIcon`, set by `RefreshStateIcon`) use `StyleForeverCollapsibleHeader`. Under D4 the ComboBox bar's own arrow replaces D2's separate circle arrow on section headers.
   - Each `StatisticsSubHeaderTemplate` toggle (`ToggleCollapseButton`) hides its native campaign +/- art (normal, pushed and highlight textures) and uses `StyleCircularArrowButton`: right when collapsed, down when expanded. A hook on the toggle's `RefreshIcon` (Blizzard calls it on initialise and on every click) keeps the arrow in step with `treeNode:IsCollapsed()`. Blizzard's own click handler still does the toggling.
   - Rows are styled on `OnInitializedFrame` / `OnDataRangeChanged`, so recycled rows pick up their new node's state. Each toggle is hooked once.
6. **Currency (D3)** Done (approved).
   - `Blizzard_TokenUI` is load-on-demand (`Camelot/Blizzard_TokenUI.xml`, `forever@eac30af`), so styling runs on `ADDON_LOADED`.
   - Top-level `TokenHeaderTemplate` rows (`.Name` and `.StateIcon`) use `StyleForeverCollapsibleHeader`. The native height is already 26, so there's no extent change. Currency rows and sub-headers (campaign toggle) stay native, the same as Reputation and Skills sub-headers.
   - `TokenFrame.DetailFrame` (`TokenDetailFrame`) gets the surface panel and joins `DETAIL_PANES`. It has no `AddCategory` headers. Its footer checkboxes and transfer button keep their native look.
7. **Tests** Per-tab suites exist: `tests/Reputation.lua`, `tests/Skills.lua`, `tests/PvP.lua`, `tests/Currency.lua`, `tests/Statistics.lua`. The detail-pane layout and section-header dividers are in `tests/CharacterFrame.lua`. Run `tests/Social.lua` after any shared-header change.
8. **Combat lockdown**
   - Defer geometry changes made during combat until `PLAYER_REGEN_ENABLED`. Not implemented yet.
9. **Live validation**
   - In-game checks on Retail and Forever. Compare screenshots against the mockup, and run the combat-lockdown check.

## Open items

- **O1.** Should the Forever headers keep the combo bar (D4), or revert to the pill after the in-game check?
- **O2.** Should the approved mockup be updated to show the combo-bar header for Forever?
- **O3.** Confirm that Skills, Statistics and Currency should use the same header style as Reputation.
- **O4.** Is the Reputation bar's native `Text` hidden in game? The Forever screenshot showed it unstyled before this change. Confirm after the fix with a live check.
- **O5.** `tests/Professions.lua` fails at line 358. This was already true before this work, so it is out of scope unless it turns out to be related.

## Validation status

- Testing route: the agent runs the automated tests after each change. The user checks the result in game. The agent doesn't run in-game or simulator testing.
- UIForever (Forever 16001, 1920×1080): the Reputation rows rendered in the new layout. The only error was in `FFXIV_UI/General/SoundEffects.lua:134` (`UpdateQuestSoundMutes` is nil), which is unrelated to this work.
- `tests/CharacterFrame.lua`: passes (exit 0) after the D4 header fix.
- `tests/Social.lua`: passes (exit 0).
- `tests/Reputation.lua`: passes (exit 0). New.
- `tests/Professions.lua`: fails at line 358 on a clean tree too (pre-existing, O5).
- In-game behaviour: not checked yet.

# Collections Menu Plan

Status: Planning. Requirements are in [spec.md](./spec.md). This document tracks phases, decisions, acceptance evidence, and the resumption checkpoint.

## Goal

Restyle the Collections journal (Mounts, Pets, Toy Box, Appearances) in the FFXIV_UI style per [spec.md](./spec.md). Keep Retail working. Forever is pending Q1.

## Decisions

| # | Decision | Source |
|---|----------|--------|
| D1 | Scope is the four Collections tabs and the shared header and tab row. | User |
| D2 | Header: remove round icon, left-align title, standard close button. | User |
| D3 | Tabs move under the header, and the menu grows taller for the new row. | User |
| D4 | Mounts and Pets: 5-wide icon grid, no names, highlight around the icon, one divider, no side backgrounds. | User |
| D5 | Toy Box: total-toys card matches the Character HP/class card; spell-style action-button cards. | User |
| D6 | Appearances: FFXIV-styled Items tab, search, and combo; RoundOutline on item boxes; Left/Right arrow buttons. | User |
| D7 | No true 1:1 FFXIV equivalent for Appearances. FFXIV Glamour Dresser references are used as the nearest visual reference. | User |
| D8 | HTML mockups are required before implementation for each visible tab. | Project standard (`.github/...` agent instructions; `wow-addon-development` skill) |
| D10 | Client scope: Retail and Forever (Q1). Forever support requires verified frame names before code. | User |
| D11 | Appearances slot-type icon row restyled as FFXIV icon buttons (Q2). | User |
| D12 | Mounts/Pets bottom-left type button and checkbox restyled FFXIV (Q3). | User |
| D13 | Close button uses the Character-menu style (Q4). | User |
| D9 | Tests go in `tests/Collections.lua` and run with `lua5.1 tests\Collections.lua`. | Project memory (testing) |

## Open Decisions

| # | Question | Status |
|---|----------|--------|
| Q1 | Client scope | Resolved: Retail and Forever (user). Forever frames verified in Phase 1. |
| Q2 | Appearances slot-type icon row | Revised: default buttons for now; FFXIV icon-button restyle deferred (user). |
| Q3 | Mounts/Pets bottom-left type button and "Show Character" checkbox | Resolved: restyle FFXIV (user). |
| Q4 | Close button | Resolved: Character-menu close (user). |
| Q5 | Grid icon size for the 5-wide mount/pet grid | Resolved: 56px (user). |
| Q6 | Retail tab placement | Resolved: move tabs to a horizontal row under the header (user). Forever is also a header row. |
| Q7 | Retail Warband Scenes tab | Resolved: in scope (user). |
| Q8 | Appearances Sets tab | Resolved: kept next to Items; reskinned per `WoW_Sets.png` (COL-SET-01..05). |
| Q9 | Appearances sub-tabs (Items, Sets) | Partly resolved (user): the screenshot is Forever. Sets is hidden when the character has no sets. UIForever shows both tabs. Forever sub-tabs are `WardrobeCollectionFrame.ItemsTab`/`SetsTab` and are not handled by the Phase 3 shell yet. Retail still to confirm. |
| Q10 | Forever Pet frame name (`PetJournal` expected, unconfirmed) | On hold (user). Blocks Forever Pets code. |

## Phases

Each phase lists its gate. Later phases do not start until the gate is met.

### Phase 1: Research and frame mapping
- [x] Retail frame names (Gethe/wow-ui-source `live`, `Interface/AddOns/Blizzard_Collections`):
  - `CollectionsJournal` (`Mainline/Blizzard_Collections.xml`), a `PortraitFrameTemplate`, 703x606.
  - Tabs: `CollectionsJournal.MountsTab`, `PetsTab`, `ToysTab`, `HeirloomsTab`, `WardrobeTab`, `WarbandScenesTab` (6 tabs, `PanelTabButtonTemplate`, anchored along the bottom).
  - `ToyBox` (`Mainline/Blizzard_ToyBox.xml`), child of `CollectionsJournal`. Contains `progressBar` (`CollectionsProgressBarTemplate`), `searchBox` (`SearchBoxTemplate`), `FilterDropdown` (`WowStyle1FilterDropdownTemplate`), `iconsFrame` (`CollectionsBackgroundTemplate`), and `spellButtonN` (`ToySpellButtonTemplate`, inherits `CollectionsSpellButtonTemplate`).
  - Pets list rows: `CompanionListButtonTemplate` (`Shared/Blizzard_PetCollection.xml`).
  - Mounts: `Mainline/Blizzard_MountCollection.xml` defines `MountEquipmentButtonTemplate`. The `MountJournal` frame name was not confirmed in the fetched excerpt.
  - Wardrobe: `Mainline/Blizzard_Wardrobe.xml` defines `WardrobeItemsModelTemplate`. The `WardrobeCollectionFrame` name was not confirmed in the excerpt.
- [x] Forever frame names (`forever` branch):
  - `CollectionsJournal` is defined in `Shared/Blizzard_Collections.xml` with `mixin="CollectionsJournalMixin"` and a `TabContainer` child using `CollectionsJournalTabContainer`.
  - The TOC loads `Camelot\Blizzard_CollectionsTabs.xml` for Forever (Camelot game type). It is on `AllowLoadGameType camelot`.
  - Forever tabs are `LargeSideTabButtonTemplate` side tabs, anchored TOPLEFT to the container's TOPRIGHT. They are on the right side of the frame, and there are 5 tabs (no Warband Scenes).
  - Forever loads the Shared Pet, Toy, Wardrobe, and Mount files. The TOC conditions allow them on `mists, mainline` (Pet) and `mainline` (Warband). The Forever Mount/Toy/Wardrobe frame names are not yet verified.
- [x] Character card helper: `Panel(parent, token)` at `FFXIV_UI/General/CharacterFrame.lua:124` calls `Skin.Panel(parent, token or "surface")` (`FFXIV_UI/General/SkinUtils.lua:91`). This is the source of the HP/class card, and the Toy total card uses it too.
- [x] Close-button helper: the Character menu uses `addonEnv.SkinWindowClose(close)` after `SetSize(24, 24)` and `SetPoint("TOPRIGHT", character, "TOPRIGHT", -5, -4)` (`FFXIV_UI/General/CharacterFrame.lua:1480-1485`). `addonEnv.SkinWindowClose` is defined at `FFXIV_UI/General/WindowControls.lua:586`. This matches the Q4 answer.
- [x] Paging arrow helper: `addonEnv.StyleFlatArrowButton(button, direction, glyphSize, offsetY)` (`FFXIV_UI/General/WindowControls.lua:698`). Spellbook uses it for `PagedSpellsFrame.PagingControls.PrevPageButton` / `NextPageButton` (`FFXIV_UI/General/Spellbook.lua:298-301`).
- [x] Forever Mount/Toy/Wardrobe frame names (`forever` branch, `Interface/AddOns/Blizzard_Collections`):
  - Mounts: `MountJournal` (`Mainline/Blizzard_MountCollection.xml`, child of `CollectionsJournal`).
  - Toy Box: `ToyBox` (`Mainline/Blizzard_ToyBox.xml`), same layout as Retail: `searchBox`, `FilterDropdown`, `iconsFrame`, `spellButtonN`.
  - Appearances: `WardrobeCollectionFrame` (`Mainline/Blizzard_Wardrobe.xml`). Forever has `ItemsTab` and `SetsTab` (`PanelTopTabButtonTemplate`) at TOPLEFT 58,-28. The spec asks for a single Items tab. Retail's tab set must be confirmed before the mockup.
  - Pets: `Shared/Blizzard_PetCollection.xml` (mists/mainline) and `Classic/Blizzard_PetCollection.xml` (Forever) plus `[Game]/Blizzard_PetCollectionScrollBar.xml` (camelot). The exact Pet frame name is not confirmed in the excerpts. It is expected to be `PetJournal`.
- [x] Gate: frame mapping recorded above. Q1 answered.

**Resolved (Q6):** Tabs move to a horizontal row under the header on both clients. Retail's six tabs (including Warband Scenes, Q7) and Forever's five side tabs are re-laid out as that row.

### Phase 2: HTML mockups (approval gate)
- [x] Mockup: shared shell (header, tab row, increased height). Approved by user.
- [x] Mockup: Mounts grid and detail divider (also used for Pets). Approved as drawn; Q5 grid icon size still open for the in-game pass. Resolves Q3 partly.
- [x] Mockup: Toy Box total card, divider, and action-button grid. Approved after rework (total card merged onto the search row).
- [x] Mockup: Appearances row, divider, combo flyouts, RoundOutline grid, arrows. Resolves Q2. Approved after rework (class dropdown and item-type row added under the divider).
- [x] Mockups stored under `.memory_bank/features/collections/mockups/` (shell-mounts.html, toy-box.html, appearances.html).
- [x] Gate: user approves each mockup. No Lua/XML work before approval.

### Phase 3: Shared shell
- [x] Header: remove round icon, left-aligned title, standard close button (COL-HDR-01..04). Resolves Q4. Code in `FFXIV_UI/General/Collections.lua`. User approved in-game (2026-11-11) after the Lua error and tab fixes.
- [x] Tab row under header and height increase (COL-TAB-01..04). Code in `FFXIV_UI/General/Collections.lua`. User approved in-game (2026-11-11) after hidden-tab gap and native close fixes.
- [x] Combat-lockdown deferral for geometry changes (COL-X-01). Covered by `tests/Collections.lua`.
- [x] Reapply after show and tab change (COL-X-05). Hooks on OnShow, `SetTab`, `PanelTemplates_SetTab`, Forever's `CollectionsJournal_SetTab`, tab OnClick; also ADDON_LOADED and PLAYER_LOGIN.
- [x] Tests: `tests/Collections.lua` covers header/tab placement, content shift, Retail and Forever selected-tab state, and combat deferral.
- [x] Gate: `lua5.1 tests\Collections.lua` passes.
- [x] Frame-name check: Forever tabs are unnamed Frames in `TabContainer`; the code scans `TabContainer` children, lays out visible tabs only, and reads labels from `tooltipText`. Confirmed in-game by user (2026-11-11).

### Phase 4: Mounts and Pets (shared list-grid component)
- [x] 5-wide icon grid with no names (COL-MNT-01). Confirmed in-game (2026-11-11): grid looks good; drag-to-action-bar and native-style tooltips work.
- [ ] Icon-ring highlight for selection and hover (COL-MNT-02).
- [ ] FFXIV search box and scroll bar (COL-MNT-03).
- [ ] Remove side frames; single divider (COL-MNT-04, COL-MNT-05).
- [ ] Apply to Pets (COL-PET-01).
- [ ] Tests cover grid layout, highlight placement, divider presence, and background removal.
- [ ] Gate: tests pass; user approves in-game screenshot against the mockup.

### Phase 5: Toy Box
- [ ] Total-toys card (COL-TOY-01), search and scroll (COL-TOY-02), divider (COL-TOY-03).
- [ ] Spell-style grid with action-button style and spell card behind each toy (COL-TOY-04, COL-TOY-05).
- [ ] Axis paging text (COL-TOY-06).
- [ ] Tests cover card helper use and the card on each toy.
- [ ] Gate: tests pass; user approves in-game screenshot.

### Phase 6: Appearances
- [ ] Items tab, search, combo row styled (COL-APP-01). Background removed, divider added (COL-APP-02).
- [ ] Combo box and flyouts styled via `StyleComboBoxMenu` (COL-APP-03).
- [ ] RoundOutline on item boxes; grid layout unchanged (COL-APP-04).
- [ ] Left/Right arrow buttons (COL-APP-05). Slot icon row per Q2 (COL-APP-06).
- [ ] Tests cover combo styling, outlines, and arrow buttons.
- [ ] Gate: tests pass; user approves in-game screenshot.

### Phase 7: Cross-cutting review
- [ ] Controller navigation, focus, and back/close for every interactive element (COL-X-02). Record unperformed checks.
- [ ] Localization of addon-owned text through the Locales catalog (COL-X-03).
- [ ] Mouse/keyboard, tooltips, and bindings unchanged (COL-X-04).
- [ ] Forever path verified per Q1, or documented as Retail-only.
- [ ] Code review saved as `.memory_bank/features/collections/code-reviews/<YYYY-MM-DD>-<name>.md`.

## Acceptance Evidence

| Requirement | Evidence | Status |
|-------------|----------|--------|
| COL-HDR-* | Test + in-game screenshot vs. mockup | Not started |
| COL-TAB-* | Test + in-game screenshot | Not started |
| COL-MNT-* / COL-PET-01 | Test + in-game screenshot | Not started |
| COL-TOY-* | Test + in-game screenshot | Not started |
| COL-APP-* | Test + in-game screenshot | Not started |
| COL-X-01 | Test: deferral in combat | Not started |
| COL-X-02 | Controller check, or listed as not performed | Not started |
| COL-X-03 | Locale catalog check | Not started |

Static checks and tests are reported separately from in-game visual confirmation.

## Checkpoint

- Current phase: Phase 3 (shared shell) approved by user in-game (2026-11-11). Phase 4 (Mounts and Pets list grid) in progress: `FFXIV_UI/General/Mounts.lua` and `tests/Mounts.lua`. User confirmed the grid, native drag pickup (`C_MountJournal.Pickup`), and spell tooltips in-client.
- Open Phase 4 items: highlight ring (COL-MNT-02), scroll bar restyle (COL-MNT-03), divider and side-frame removal (COL-MNT-04/05), bottom-left/checkbox restyle (COL-MNT-07), and Pets (COL-PET-01).
- Next action: Ask user whether the highlight ring and scroll bar are needed now, then resolve Q10 (Pet frame name) and start Pets.
- Files created so far: `spec.md`, `plan.md`, `FFXIV_UI/General/Collections.lua`, `tests/Collections.lua`, `FFXIV_UI/General/Mounts.lua`, `tests/Mounts.lua`. TOC entries added to `FFXIV_UI/FFXIV_UI.toc` and `FFXIV_UI/FFXIV_UI_Camelot.toc`.


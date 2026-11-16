# Collections Menu Specification

Status: Draft. Requirements are from the user's request. Open questions are listed at the end and tracked in [plan.md](./plan.md).

## Scope
- Restyle the Retail Collections journal (`CollectionsJournal`) in the FFXIV_UI style: Mounts, Pets, Toy Box, and Appearances.
- Ensure seamless compatibility across WoW Retail and WoW Forever (Q1, resolved: both clients).
- Maintain combat lockdown safety, automated tests in `tests/Collections.lua`, and the shared UI standards.
- Reference images: `Media/References/Collections/`. Files marked `WoW_` are the source layouts. Files marked `FFXIV_` are the target style.
  - Mounts: `WoW_Mount_Menu.png`, `FFXIV_Mount_Menu_Dark.png`.
  - Pets: `WoW_Minion_Menu.png`, `FFXIV_Minion_Menu_Dark.png`.
  - Toy Box: `WoW_Toy_Box.png`.
  - Appearances: `WoW_Appearences.png`. `FFXIV_Glamour_Dresser_*.png` and `FFXIV_Full_Glamour_Menu.png` are the nearest FFXIV equivalent. There is no true 1:1 match.

## Functional Requirements

### Shared Header (COL-HDR)
- COL-HDR-01: Remove the large round portrait/icon in the top left.
- COL-HDR-02: Move the header title to the left, using the same left-aligned Axis label treatment as the Spellbook header (`.memory_bank/features/spellbook/spec.md`, Core Requirements 5).
- COL-HDR-03: Replace the native close button with the standard close button (`addonEnv.StyleWindowControl`, `FFXIV_UI/General/WindowControls.lua:404`). Use the Character-menu close button geometry (Q4, resolved).
- COL-HDR-04: Native title text and close behaviour remain functional.

### Shared Tabs (COL-TAB)
- COL-TAB-01: Move the category tabs to a horizontal row directly below the header. Retail has six tabs (Mounts, Pets, Toy Box, Heirlooms, Wardrobe/Appearances, Warband Scenes). Forever has five side tabs with no Warband Scenes tab, and they are re-laid out as the same horizontal row. Retail's tabs are currently along the bottom edge (`PanelTabButtonTemplate`). Forever's are on the right side (`LargeSideTabButtonTemplate`). Both move to the header row (Q6, resolved).
- COL-TAB-02: The tabs use the universal tab standard in `.gemini/skills/wow-ui-layout/SKILL.md` section 1 (30 px height, `Tab-Selected-Dark` / `Tab-Inactive-Dark`, Axis Regular 10, native art hidden).
- COL-TAB-03: Increase the menu height to fit the new tab row. Existing content areas shift down by the same amount. Width is unchanged.
- COL-TAB-04: Native tab click handlers, tab IDs, availability, and controller tab order are unchanged.

### Mounts (COL-MNT)
- COL-MNT-01: Replace the name-list with a 5-icon-wide grid. Mount names are not shown in the grid.
- COL-MNT-02: Selection and hover highlights go around the icon, not the name. Use the shared action-bar highlight from the Spellbook icon skin, not a text-row highlight.
- COL-MNT-03: The search box and scroll bar are restyled to FFXIV style (`addonEnv.StyleEditBox` / `ffxiv-skin-inputs`; `ffxiv-skin-lists` for the scroll bar).
- COL-MNT-04: Neither the list side nor the detail/paperdoll side has its own frame or background.
- COL-MNT-05: A single divider sits to the right of the scroll bar. It separates the grid from the detail/model display.
- COL-MNT-06: Native model, name, and detail text remain. Those elements are restyled only where they sit on a removed background.
- COL-MNT-07: The bottom-left type button and the "Show Character" checkbox are restyled with the FFXIV button and checkbox styles (Q3, resolved).

### Pets (COL-PET)
- COL-PET-01: Apply COL-MNT-01 to COL-MNT-06 to the Pets tab.

### Toy Box (COL-TOY)
- COL-TOY-01: The "Total Toys" frame uses the same card as the HP/resource display and the class/level display in the Character menu. This is the `Skin.Panel(parent, token or "surface")` path in `FFXIV_UI/General/CharacterFrame.lua:131`. Confirm the exact helper in Phase 1.
- COL-TOY-02: The search box and scroll bar are restyled to FFXIV style (as COL-MNT-03).
- COL-TOY-03: A divider sits below the total-toys and search row.
- COL-TOY-04: Toys are laid out in a grid similar to the Spellbook. Each toy uses the standard FFXIV action-button style.
- COL-TOY-05: Each toy sits on the same card as the spells in the Spellbook (`SpellCard`, `FFXIV_UI/General/Spellbook.lua:68`): flat rounded surface, nine-slice, six-pixel corners.
- COL-TOY-06: Native paging text ("Page x / y") uses Axis Regular. The native paging arrows use the flat Left/Right Arrow buttons, the same as COL-APP-05.

### Appearances (COL-APP)
- COL-APP-01: The row under the header contains the "Items" tab and the "Sets" tab (kept, Q8), the search box, and the filter combo box. All of them use FFXIV styling.
- COL-APP-02: Remove the background behind the content area. Add a divider between the Items/search/filter row and the content grid.
- COL-APP-03: The slot-type combo box and all of its flyouts and submenus are FFXIV combo-box styled (`ComboBox-Closed-Dark`, `ComboBox-Menu-Dark`, `StyleComboBoxMenu`, `FFXIV_UI/General/WindowControls.lua:94`).
- COL-APP-04: The item grid keeps its current layout. Each item's outline is replaced with the `RoundOutline` used on empty action-bar slots and the Character menu (`FFXIV_UI/General/RoundedPanels.lua:173`).
- COL-APP-05: The bottom left and right arrows use the Left and Right Arrow buttons (flat paging arrows, `ffxiv-skin-buttons`).
- COL-APP-06: The slot-type icon row uses the default buttons for now (user, revising Q2). It will be restyled to FFXIV icon buttons in a later pass.

### Sets (COL-SET)
Reference: `Media/References/Collections/WoW_Sets.png` (user-provided, WoW Sets view).
- COL-SET-01: Remove the background frames from both sides of the Sets view, following COL-MNT-04.
- COL-SET-02: A divider sits to the right of the set list's scroll bar, following COL-MNT-05.
- COL-SET-03: Each set list row is a card that holds the set icon and name, following the COL-TOY-05 card style.
- COL-SET-04: All Sets dropdowns (class/filter) and icons are restyled to FFXIV style, following COL-APP-03 and COL-MNT-03.
- COL-SET-05: The set search box and scroll bar use FFXIV style (COL-MNT-03). The detail title and item icon row keep their native layout and are restyled only where they sit on a removed background.

### Cross-cutting (COL-X)
- COL-X-01: Combat lockdown: any protected frame or geometry change defers during `InCombatLockdown()` and resumes on `PLAYER_REGEN_ENABLED`.
- COL-X-02: Controller: each interactive element (tabs, search, grid, scroll, combo, arrows, close) keeps native navigation, activation, and back/close behaviour, with visible focus. Per-client limits and unperformed checks are recorded in the plan.
- COL-X-03: Localization: all addon-owned text (new labels, dividers, fallback strings) uses the Locales catalog. Native localized text is not replaced.
- COL-X-04: Mouse/keyboard behaviour, native tooltips, and existing bindings are retained.
- COL-X-05: Installed styling is reapplied after the journal shows and after native tab changes, following the existing shell pattern used by the Spellbook.

## Resolved Decisions
- Q1 (client scope): Retail and Forever. Forever frame availability must be verified in Phase 1 before Forever code is written.
- Q2 (Appearances slot-type icon row): default buttons for now (user, revised). FFXIV icon-button restyle is deferred.
- Q3 (Mounts/Pets bottom-left type button and "Show Character" checkbox): restyle with FFXIV button and checkbox.
- Q4 (close button): use the Character-menu close button.
- Q5 (grid icon size): resolved, 56px (user). Adjust after in-game review if needed.
- Q6 (tab placement, Retail): move the tabs to a horizontal row under the header, not along the bottom and not on the side. Forever is also laid out as a header row. Confirmed by the user.
- Q7 (Retail Warband Scenes tab): in scope.
- Q8 (Appearances Sets tab): kept next to Items, restyled as an FFXIV tab (user).

## Out of Scope
- Changes to mount, pet, toy, or appearance data, summoning, or collection logic.
- Changes to the micro-menu Collection button (already mapped in `FFXIV_UI/General/MicroMenu.lua`).

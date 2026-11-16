# Inventory (Forever) Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- The inventory and character windows share antialiased, 8-pixel rounded outer corners and theme-colored borders/backgrounds.
- Fixed-size corner slices retain their radius as either window resizes; internal controls and item slots keep their existing geometry.
- Dark and Light add faint grain at 1.8% opacity and top-edge lighting.
- The grain repeats at a fixed 128-pixel scale across the full interior and updates when windows resize, avoiding stretched edge streaks.
- Clear themes use lighting around all window edges, right-to-left tab shading, and square-cornered standalone buttons with a broad, smoothly fading rounded bottom glow rather than a defined circular highlight.
- Classic FF uses its own beveled control shading without grain.
- Materials switch live with the selected theme in both windows; these are reference-inspired treatments rather than exact texture replicas.

### Core Requirements 2
- The character and inventory close buttons use the transparent gold emblem extracted from the supplied screenshot, with a brighter hover state.
- The emblem retains its original colors across themes, and native close actions and click targets are unchanged.
- WoW's built-in **Combine Bags** setting determines whether regular bags share the combined container or use individual native frames.
- The reagent bag and keyring stay in separate native frames, which receive the same themed skin.
- The addon does not override the manager's combined-mode decision, bag matching, open-state checks, bag-size calculation, or slot enumeration; it does not rewrite the `combinedBags` CVar or close/reopen existing bags at installation.
- Native controller-specific combined mode remains available.
- Restoring native routing keeps the open-all toggle's close-then-count logic consistent with the separate reagent bag.
- Bank storage is unchanged.
**Inventory Layout** in FFXIV UI settings switches the combined container between **Per-bag grids** (default) and **Unified grid**, saved per character independently of anchor profiles and the native Combine Bags setting. Both use one uniform, theme-colored surface without individual bag borders/backgrounds. Per-bag grids give each included bag a labeled five-column grid of 40-pixel slots, arranged two across starting with the backpack. Each uses only the rows its capacity requires; each new pair starts below the taller preceding bag, and unequipped bags are omitted. Unified grid uses ten continuous columns with a wider gutter between groups of five and no bag headings. Only bags matched by the native combined container are included. Switching applies immediately outside combat or waits until combat ends.
- The combined window remains 472 pixels wide.

### Core Requirements 3
- Separate backpack, regular-bag, reagent-bag, and keyring windows use 244-pixel shells with five columns and no extra bag-name section label in either layout setting; their window title still identifies the bag.
- Separate windows place bag options below the title, retain native filter indicators, and omit the search-row space except in the backpack.
- Grids use 40-pixel square-skinned slots and 3-pixel spacing.
- The combined/backpack grid starts 108 pixels below the top; other separate grids start at 76 pixels.
- Windows grow with capacity and retain native anchoring/scaling.
- Inventory, standard hotbars and controller hotbars share centered slot artwork with empty wells/outlines approximately 92% of the populated gloss's visible width, compensating for transparent padding; artwork does not change size when items are added or removed.
- Slots display in ascending bag/slot order without moving items or altering bag restrictions.
- Native click/drag actions, stack splitting, tooltips, quality/quest/junk/upgrade indicators, locks, cooldowns, search, sorting, bag options, money, watched currencies, keyring actions, and controller interactions are retained.
- Each capacity label counts only that container's bags, excluding locked backpack-extension slots.
- The shared search field follows its native owner between the backpack and combined container.

### Core Requirements 4
- The account-wide theme colors every inventory shell, separator, heading, control, empty slot, outline, money label, and capacity count; item/status and coin artwork retain native colors.
- Colors update live in combat. Native bag frames and item buttons are unprotected, so bags opened in combat still receive the addon grid, controls and skin (matching Blizzard's own in-combat layout); geometry only defers if the client reports a bag frame or item button as protected. Layout-setting changes, bag-capacity rebuilds and initial installation still wait until combat ends.
- Native pooled frame reuse updates titles and counts without duplicating skins, and newly generated container frames also receive the shared skin.
- Empty slots are plain themed wells (no gloss, no native empty-slot atlas or Forever's desaturated `EmptyBagIcon`). Each item button's `SyncAppearanceWithHasItem` is hooked so Forever's `BAG_UPDATE_COOLDOWN` refresh (spell casts, on-hit procs) cannot restore the native empty-slot art.
- This integration requires Forever's pooled container implementation.
- Mocked regressions cover both native bag modes, open-all toggling, reagent/keyring separation, hidden redundant headings, item identities and controls, pooled/late-created frames, all eight themes, capacity, watched currencies, and combat deferral.
- Live visual alignment, controller navigation, and compatibility with other bag addons still need in-game confirmation.
- The inventory slots should be in 5x7 grids.
- Each grid should have slightly larger spaces between them than inventory spaces usually do.
- As inventory spaces are added, they will populate these grids from left to right, then top to bottom.
- The same will apply to the placement of new 5x7 grids.

### Core Requirements 5
- The maximum number of grids on the x axis shall be definable by the user with a default of 2.
- Additionally, the inventory window title label ("Inventory" / Backpack / bag name) is explicitly left-aligned (`justifyH = "LEFT"`), and any background frames or borders around currency icons in the watched currency token tracker are hidden.
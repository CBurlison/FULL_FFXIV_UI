# Crafting Log Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- `FFXIV_UI/General/Professions.lua` skins Forever's combined `ProfessionsFrame`, including `BookPage` and `CraftingPage`.
- It loads after shared themes, panels, and button skins in both TOCs.
- The main window uses the shared rounded shell, Axis title, and inset 24x24 close emblem.
- Native profession overview cards use themed inset surfaces and square spell-button artwork; unlearn confirmations, flyouts, cooldowns, and gamepad prompts remain native.
- The overview tab and visible profession tabs move into a single horizontal icon row at y=-34, using square 40x40 controls with three-pixel gaps and 32x32 icons.
- Unlike the pointed tabs elsewhere, these controls have subtly rounded corners (3.75-pixel radius at display size) with hover and selection states.
- Shared `CreateControlArtwork` accepts the `Square` style, using full 64x64 fill/border textures with antialiased corners.

### Core Requirements 2
- Their Standard, Classic, and Clear variants reuse the corresponding Button material's vertical shading and border opacity, with the same theme colors rather than flat backdrops.
- Native side-tab icon masks are removed, and notification glow uses a low-opacity rounded-square fill matching the active material while retaining native animation timing.
- The first tab starts 38 pixels inside the window to leave room for controller shoulder prompts.
- Forty-eight pixels are reserved above both pages, and window height grows once from its original height to retain native content space.
- Page-specific native widths, recipe/schematic positioning, tab order, tooltip text, click scripts, and visibility remain native.
- Selection uses `SetChecked`, not unsupported `GetChecked` calls.
- Controller tab indicators become horizontal, refresh their visible tabs, and restore the selected profession's visible index after native visibility updates.
- Profession navigation and overview card icons map by locale-independent skill-line IDs to the supplied Alchemist, Blacksmith, Cooking, Enchanting, Engineer, Fishing, Herbalism, Leatherworker, Mining, and Tailoring artwork.
- The overview uses the supplied 32x32 `Professions/Professions.png` through a pixel-identical TGA copy, not the red Menu/CraftingLog image.
- First Aid (skill line 129) uses original `FirstAid.png` artwork: a gray outer rim, transparent interior with translucent gradient shading, slender gray beveled drop, outlines, and drop shadows, rendered with supersampling at 56x56.

### Core Requirements 3
- Ability buttons keep their native spell icons rather than receiving the parent profession's category icon.
- The 56x56 profession PNGs have pixel-identical 64x64 top-origin BGRA TGA copies with four-pixel transparent padding, without modifying supplied originals.
- Texture post-hooks retain replacements through native refreshes and restore the latest native icon if a reused frame changes to an unmapped profession.
- Professions without matching artwork, including Skinning, retain their native icons.
- Profession ability icons (e.g. Smelting, Find Minerals, Fishing) are not replaced anywhere: spellbook, profession books, action bars, flyouts, cast bar, and the tracking menu all keep native WoW artwork. Only the profession navigation tabs and overview card icons use custom Professions artwork.

### Core Requirements 4
- Rank bars are 22 pixels tall.
- Their Rank frame fills the bar, and its single-line 12-pixel Axis label is vertically centered inside four-pixel horizontal and two-pixel vertical insets instead of the native downward offset and nine-pixel text box.

### Core Requirements 5
- Overview unlearn controls are 22x22, centered four pixels to the right of their bar; controller unlearn prompts share the same vertical center.
- Accent fill opacity is 0.22.
- Label colors start with theme text and adjust toward black/white only as needed to achieve at least 4.5:1 contrast against both the filled and empty portions.
- Theme changes and native rank updates replay this contrast correction without changing rank text or skill data.
- Search/filter controls, recipe list and schematic surfaces, output/reagent slots, Create/Create All buttons, and quantity controls follow the account-wide theme.
- Recipe rows retain craftable counts, native selection, locks, skill-up difficulty colors, and tooltips.
- Collapsible categories use the same Dark ComboBox header as Social and Reputation (`addonEnv.StyleComboCollapsibleHeader`): Open texture when expanded, Closed when collapsed, Axis title, native `CollapseButton` toggle preserved.
- Skill progress is drawn from the native rank bar's ratio, including empty/max-zero states; the original bar's data handling remains untouched.
- Native quality, tracking, favorite, lock, and add-action state is not replaced with FFXIV-specific crafting mechanics.
- Reagent names use the native unwrapped `nameText` and `GetNameColor()` state so native outer color markup cannot bypass light/pink theme text colors.

### Core Requirements 6
- Available/unavailable labels follow text/muted tokens, red requirements and cooldowns use detrimental colors, and generic slot skinning preserves reagent-count availability colors.
- Native labels, quantities, allocation data, and asynchronous item loading remain authoritative.
- Required-modification slots retain an explicit native green-plus indicator, hidden while locked.
- Initialization retries after native addon loading; profession, page, overview, recipe-row, and schematic refreshes reuse installed artwork.
- Newly pooled frames and geometry changes defer during combat and retry on `PLAYER_REGEN_ENABLED`; theme replay does not rebuild geometry.
- No permanent update loop is added.
- `tests/Professions.lua` uses the real shared theme, panel, and slot helpers to cover both pages, native-shaped tabs, all eight themes, native color refreshes, progress, controller selection, preserved actions/quantities, pooled rows and reagents, late loading, combat deferral, and idempotency.
- In-game visual and controller checks are still required.

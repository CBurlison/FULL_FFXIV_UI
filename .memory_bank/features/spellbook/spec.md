# Spellbook (Forever) Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- `FFXIV_UI/General/Spellbook.lua` skins `PlayerSpellsFrame.SpellBookFrame` and loads after Professions in both TOCs.
- The native parchment, bookmark, top bar, category icon/tab artwork, and decorative spell borders are suppressed through refreshes.
- One shared rounded window contains the header and sidebar, separated only by thin themed divider lines, without separate header/sidebar fills or borders.
- Spell cards use the existing flat rounded surface texture in nine slices with fixed six-pixel corners, rather than pill-shaped button materials.
- Their fill stays at the theme's tab color even while hovered, without a bevel or outline; hover feedback comes only from the shared Equipment icon skin's additive action-bar highlight.
- The small corner radius complements the Equipment spell icons.
- Axis text, section headings, and native paging controls replace the artwork.

### Core Requirements 2
- Native unlearned/off-spec alpha, desaturation, tint, required-level text, locks, autocast indicators, and flyout arrows remain functional.
- The shared profession ability resolver remains attached to spell icons.
- The sidebar reserves 204 pixels.
- Its search box is first at (14, -22), sized 152x28, with the native settings dropdown alongside it.
- Existing category buttons are arranged below it at x=10, y=-62, with 184x32 hit targets and 36-pixel row spacing.
- Separate left-aligned 18-pixel labels have explicit 28-pixel height.
- Single-skill-line categories resolve localized names from `C_SpellBook.GetSpellBookSkillLineInfo(category.skillLineIndex)` because their inherited `GetName()` returns nil on Forever; other categories use `GetName()` or their native tooltip text.
- Native icons and text regions are hidden without changing tab IDs, callbacks, availability, tooltips, or controller category ordering.
- Rows have no button fill or border: gold/accent text sits directly on the sidebar.
- Selection adds a subtle accent-colored horizontal fade; hover adds a darker fade; unselected, unhovered text has no background.

### Core Requirements 3
- Hidden categories consume no space, and newly available pet/outfit categories reflow automatically.
- Search suggestions and overflow text also use shared theme colors.
- Native category-label suppression includes each button's `GetFontString()` result even if absent from `GetRegions()`, plus direct and nested label regions.
- Keep native label alpha at zero and the labels hidden after show/selection refreshes or font-string replacement, while leaving the custom category name visible.
- The title-bar `HelpPlateButton` is fully hidden and mouse-disabled, including after native show attempts.
- Right-pane category headers keep their shaded fill and fixed corners but use untinted `Panel-Border-Dark.tga` border slices for Dark rather than the old generic border texture.
- The settings filter uses the hamburger opener and shared multi-select popup described under Combo boxes.
- The native `AssistedCombatRotationSpellFrame` is 176x40, anchored to the book's bottom-left at (14, 10), with its icon, native label, availability, drag behavior, and tooltip intact.
- It must not overlap a right-pane category header.
- Controller category/search/settings prompts sit at y=64 above this control when it is shown, or return to y=16 when it is unavailable.

### Core Requirements 4
- Native host spellbook compact/expanded widths and book widths gain 204 pixels once, leaving both fixed-width spell grids and their view/page counts intact.
- The paged frame starts after the sidebar at (204, -8), with native view and paging anchors unchanged.
- Category container size/layout and native search/attic resizing receive visual layout corrections.
- Category buttons opt out of native horizontal layout with `ignoreInLayout`, and the container receives fixed dimensions.
- Its old horizontal-bar OnSizeChanged search callback is replaced with the sidebar layout callback; a one-pixel container width keeps the native search-width calculation positive while its child category buttons retain full width.
- A coalesced next-frame installation after host/page show, category creation, and native layout cleanup corrects late opening/layout work without requiring a category click.
- Controller category/search/settings prompts remain in the sidebar with clearance above the rotation control.
- No search strings, spell data providers, drag/click scripts, or global APIs are replaced.
- The host portrait/border/close/maximize artwork is themed only while the spellbook page is shown.
- Both parent chrome frames and their direct texture regions are suppressed, including the book portrait and NineSlice edges.

### Core Requirements 5
- The original centered title is hidden; a separate left-aligned Axis label at x=20 follows its localized text, in a transparent 30-pixel-high header with a thin bottom divider.
- The sidebar's vertical divider meets that line at x=204.
- The native close button is resized to 24x24 and centered vertically within the header, two pixels inward from its right edge; its original size and anchors return for talent pages.
- Close-button geometry changes defer during combat.
- Native title text/font/color and host artwork remain intact for talent pages and return when leaving the spellbook.
- Shell state is reapplied after host show, portrait/title refreshes, and the deferred opening pass.
- A footer Display Mode control replaces the visible title-bar expand arrow.
- Two 50x28 rounded-square buttons show a one-column list glyph and a two-column glyph, respectively.
- Compact mode highlights the first button; expanded mode highlights the second.
- Selection reads `book.isMinimized`, including native/controller setting changes, rather than maintaining separate state.

### Core Requirements 6
- Buttons invoke the existing maximize/minimize controller methods, preserving native callbacks and CVar persistence, and are disabled during combat.
- The collapsed spellbook retains its existing window width and sidebar while showing the native two-column spell grid; each spell card fits half of the available spell-pane width and category headers remain full width. Combat category changes preserve the two-column layout. Protected geometry is deferred until combat ends; the approved appearance is `mockups/combat-open.html` (2026-11-06).
- The native controller is visually suppressed, not removed or rebound.
- Addon-created FontStrings receive their Axis font before any SetText call, including Display Mode and paging/settings arrow labels.
- The spellbook test mock rejects text assignment without a font, matching the client and guarding against partial initialization that leaves native header artwork visible.
- Layout explicitly restores the category container and each category's visibility from its native `IsAvailable()` state, including label visibility/alpha, rather than trusting visibility left over from the hide/resize/reopen cycle.
- Host `SetMinimized` receives immediate and coalesced deferred installation hooks, in addition to page minimization and opening callbacks.
- Unavailable pet/outfit categories remain hidden.
- Main window sizing continues to use native minimize/maximize behavior.
- Installation and pooled spell-card styling defer during combat. Layout updates existing unprotected frames independently; protected geometry resumes on PLAYER_REGEN_ENABLED.
- Page callbacks, category creation/availability changes, and native layout refreshes reinstall idempotently.

### Core Requirements 7
- All account-wide themes update existing surfaces.
- `tests/Spellbook.lua` checks delayed loading, first-show late layout correction without interaction, search-first placement, localized skill-line categories whose inherited names are nil, explicit label height, borderless selected/hover/unselected fades, availability/selection, native layout and search resizing, pooled cards/search suggestions, paging actions, untouched native search/drag behavior, unlearned visual states, native ability icons, all themes, compact/expanded widths, two-column combat/category layout without collapsed-window widening, portrait/NineSlice texture suppression and restoration, left-aligned title, display-mode highlights, repeated expand/collapse cycles that hide categories during native resizing, talent-shell restoration, combat deferral, and repeated-refresh stability.
- Live in-game layout and controller validation remain necessary.
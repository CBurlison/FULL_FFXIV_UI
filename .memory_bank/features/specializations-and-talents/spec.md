# Specializations and Talents Feature

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- This feature folder contains the specification and design documentation for the Specializations and Talents screens in `FFXIV_UI`, bridging WoW Retail (`PlayerSpellsFrame` / `C_ClassTalents`) and WoW Forever (`PlayerTalentFrame`) into an FFXIV-inspired interface.
- [Specializations and Talents Specification](specializations-and-talents.md)
- Final Fantasy XIV does not feature traditional World of Warcraft talent trees or spec switching mechanics; instead, FFXIV utilizes Job systems, Role Actions, and trait progression.
- To maintain seamless integration across **both WoW Retail (Patch 12.0.0+) and WoW Forever (Classic/WotLK/Cata)** while delivering an authentic FFXIV UI experience, the Specializations and Talents screens (`PlayerSpellsFrame` Talents/Specialization tabs in Retail, and `PlayerTalentFrame` / `TalentFrame` in Forever) are redesigned as a brand-new, FFXIV-styled feature.
- The user approved [the focused close-button preview](close-button-preview.html).
- Talents and Specializations now retain the shared 24x24 FFXIV_UI close icon and anchor the native button RIGHT-to-active-header-RIGHT at -2/0.
- Native close artwork is suppressed without replacing its click script.

### Core Requirements 2
- The legacy talent frame uses its own header and close button when present.
- TalentsUI.UpdateCloseButton coordinates ownership with the shared PlayerSpells Spellbook shell: Spellbook no longer restores native close geometry/art when a styled talent panel claims the button.
- Panel show/hide hooks update placement; combat defers geometry until PLAYER_REGEN_ENABLED.
- Unstyled panels retain the previous native restoration path.
- Validation: the talents and spellbook regression suites pass, covering talents/spec switching, legacy containment, native clicks, Spellbook ownership transitions and deferred combat updates.
- In-game verification is pending on Retail; Forever is currently inaccessible.
- No screenshot comparison was run.
- The user approved the close-button fix on Retail.
- Forever verification remains deferred.
- Reuses the shared dark rounded window container (`Dark` default theme or account-wide theme palette).

### Core Requirements 3
- Header title displayed in Axis font with gold accents and standard window control buttons (Close, Minimize/Collapse if applicable).
- Horizontal navigation tabs beneath the title banner (e.g., Specializations, Talents, PvP Talents / Role Actions), matching the Character Screen and Spellbook tab design (beveled pointed ends, 10-point text, gold diamond selection indicator).
- **Retail (`PlayerSpellsFrame` / Specialization Panel)** / **Forever**:
- Displays available specializations for the player's class as distinct FFXIV-inspired job/role cards.
- Each card features its role icon loaded directly from `Media\Textures\Character\Tank.tga`, `Media\Textures\Character\Healer.tga`, or `Media\Textures\Character\DPS.tga` at 24-32 pixels (or larger feature display).
- Each card shows the localized name, role category, core role description, and an activate button styled with the standard capsule button artwork.
- Active specialization features a glowing gold border and "Active" status badge.
- **Retail (`C_ClassTalents` / `C_Traits`)**:
- Restyles the trait tree nodes, hero talent selection, and loadout management.
- **Loadout Dropdown / Combo Box**: Uses the shared dark combo box component (`ComboBox-Closed-Dark.tga`, gold hover/selection highlight) for selecting, creating, renaming, and deleting talent loadouts.

### Core Requirements 4
- **Talent Nodes**: Replaces native node backgrounds with FFXIV-themed circular/square button skins. Allocated nodes feature a bright gold glow; unallocated nodes use muted grey/bronze borders. Rank text and point counters use clean Axis typography.
- **Action Buttons**: Import, Export, Share, and Apply/Commit buttons use the FFXIV capsule button style.
- **Forever (`PlayerTalentFrame` / Classic Talent Trees)**:
- Restyles the three talent tree tabs (e.g., Arms, Fury, Protection for Warrior) into horizontal or vertical FFXIV-styled tab selectors.
- Talent points remaining counter displayed in a clean gold-accented text box.
- Talent icons framed in square button skins with gold borders upon point investment. Learn/Reset buttons styled as capsule buttons.
- **Combo Boxes**: Loadout selectors and filtering dropdowns use [Combo Boxes specification](combo-boxes.md).
- **Button Skins**: Talent icons and spell previews use [Shared Window and Tooltip Rendering](shared-rendering.md) button skins.
- **Tooltips**: Hovering over talents or specializations uses standard FFXIV tooltip layouts with secret value / tooltip info integration.
- Per FFXIV_UI engineering standards, before any implementation of the Specializations and Talents screens in WoW Lua/XML, an interactive HTML/CSS mockup (`mockups/specializations-and-talents.html`) must be created utilizing actual media assets (`FFXIV_UI/Media/Textures`, `FFXIV_UI/Media/Fonts`) and explicitly approved by the user.
- Forever Talents layout (approved mockup: `talents-forever-preview.html`, tabs left-aligned under the header):
  - The Talents view is `PlayerSpellsFrame.TalentsFrame` (named in the in-game Frame Stack). `PlayerSpellsFrame.SpecFrame` is hidden and empty.
  - The host top art (`TopTileStreaks`, `Bg`, etc.) and the view's `Background` are hidden only while the Talents view is shown, and restored on hide, so Spellbook is unaffected.
  - Primary and Secondary are the wide two-button row (about 300 px) under the header. They become left-aligned 130x30 extracted tabs.
  - The search box (`TalentsFrame.SearchBox`) sits on the Apply Changes row, immediately left of the options button (-6 px). The options button (`TalentsFrame.SearchOptionsDropdown`) sits immediately left of Apply Changes (`TalentsFrame.ApplyButton`, -12 px). Without the Apply button, the search falls back to the options button's position, and then to the header's right edge.
  - The counter (`TalentsFrame.ClassCurrencyDisplay`) keeps its text; its `Border` is hidden.
  - The opener has its native `Arrow` hidden and becomes a 24x24 down circle button (`StyleCircularArrowButton`). Its popup is styled by `StyleComboBoxMenu`, which only applies when the frame exposes `OnMenuOpened`.
  - Apply Changes is textured with `StyleButton`.
  - Apply Changes (`TalentsFrame.ApplyButton`) uses the FFXIV_UI button skin.
  - Still unconfirmed in game: that tabs clear the header, that the top band is `TalentsFrame.Background`, and that the opener's popup is skinned.

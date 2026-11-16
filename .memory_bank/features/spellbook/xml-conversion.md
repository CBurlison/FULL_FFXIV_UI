# Spellbook XML Conversion
- Status: header batch accepted on Retail (approved 2026-11-03). Batch closed as header-only: display-mode glyph/button geometry and category labels stay in Lua by user decision (their anchors are relative to sibling textures and loop indices). Forever verification deferred.
- Prerequisites: shared controls and rounded panels.
- Scope: addon-owned shell/header, dividers, category labels and display-mode controls.
- Header batch: FFXIV_UI/General/Spellbook.xml defines the header Frame (TOPLEFT 8,-4 / TOPRIGHT -8,-4, height 30), title FontString (LEFT 12 / RIGHT -36, height 26, justifyH LEFT) and header divider (BOTTOMLEFT/BOTTOMRIGHT, height 1). Both TOCs load it before Spellbook.lua.
- Kept in Lua: header frame level, title text/font, StyleDivider, the sidebar and footer dividers (they depend on runtime SIDEBAR and header position), and close placement.
- Keep native spell rows, search/filter actions, category availability, pooling, runtime grid/layout measurements and shared close-button transitions in Lua.
- tests/Spellbook.lua applies the FFXIV_SpellbookHeader templates in its mocks and asserts template names, geometry, justification and divider anchors. The suite passes; all tests/*.lua exit 0; XML parses.
- Run the spellbook suite including late loading, compact/expanded modes and combat deferral.
- Require Retail visual acceptance; Forever verification deferred.
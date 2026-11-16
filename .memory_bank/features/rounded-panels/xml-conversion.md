# Rounded Panels XML Conversion
- Status: window-chrome and generic-surface batches accepted on Retail (user confirmed); Forever verification deferred.
- Shared window controls were accepted by the user on Retail on 2026-11-03.
- Targets remain Retail and Forever; Forever client verification is deferred while inaccessible.
- Scope: reusable window rim, tiled background and header-lighting materials/geometry in FFXIV_UI/General/RoundedPanels.lua.
- Preserve direct texture ownership/layers and transparent corners.
- Keep size-dependent tiling coordinates, theme selection and resizing hooks in Lua.
- Test exact slice geometry/materials, small/large panel resizing, reuse and consumer regressions.
- Require Retail visual acceptance; Forever verification deferred.

## Window-chrome batch (2026-11-03)
- RoundedPanels.xml now supplies nine tiled background, eight rim and six header-lighting virtual texture templates.
- Both TOCs load XML before RoundedPanels.lua.
- Chrome creates these textures directly on the original panel at the original call sites and in the original order; BACKGROUND -2/-1 and BORDER layers are unchanged.
- XML preserves the original assets, repeat wrapping/tiling, transparent background/header corners, 8-pixel caps/insets, 40-pixel lower header lighting, anchor order and fixed rim/header UVs.
- Repeating thirds/sixths use decimal XML values matching the Lua fractions to floating-point precision.
- Lua retains per-size background sampling, the minimum-one-pixel sampling clamp, show/resize hooks, lazy creation and reuse.
- This is a structure-only conversion of the accepted appearance, not a redesign.
- The existing test-only template applicator was renamed to PanelTemplates.lua and extended to apply both shared-control and rounded-panel definitions, including material/wrapping/tiling/alpha attributes.
- All five consumer mocks use it.
- Independent character-frame assertions cover all 23 templates, exact ownership/layers/dimensions/anchors/materials/alpha/UVs, initial tiling, 400x300/900x600/16x16/10x7 resize sampling, show refresh, reuse and both TOC orders.
- Validation: character-frame, inventory, professions, spellbook and social suites pass, including Social's default Forever and explicit Retail configurations.
- XML parsing (23 templates) and scoped whitespace checks pass.
- These are mocked/static results, not client operation certification.
- No simulator or screenshot comparison was run.
- Retail acceptance: reload, open the Character window and other framed windows, and inspect rim corners, header lighting and the tiled interior.
- Resize supported windows; confirm unchanged appearance, transparent corners, native controls and no errors.
- Cross-reference anchors for RoundFill, theme material selection, dynamic UVs and callbacks stay Lua.

## Generic-surface batch (2026-11-03)
- RoundedPanels.xml adds 35 virtual templates: 9 surface and 9 border slices (anchored, border with Panel-Border-Dark.tga), 9 fill slices (size and UVs only, because RoundFill anchors to a caller-supplied ref), and one grain template (REPEAT wrap, tiling, 8px insets).
- RoundWindow (non-chrome), grain, RoundFill and RoundOutline now create textures from these templates. Lua keeps the theme-dependent surface material, palette/vertex colour, grain sizing and alpha, RoundFill's ref anchors and theme callback, and reuse guards.
- Layers and order are unchanged: surface BACKGROUND -2, border BACKGROUND -1, grain -1, fill -8, outline OVERLAY.
- PanelTemplates.lua recognises the four new prefixes. CharacterFrame.lua has a generic-surface block covering 19 regions, template names, layers, anchors, sizes, UVs, files, grain resize/alpha, fill and outline geometry, and reuse.
- Validation: CharacterFrame, Inventory, Professions, Spellbook, Social and Talents suites exit 0; all tests/*.lua pass; XML parses. Mocked/static results only.
- Retail acceptance: user approved the batch on 2026-11-03 ("This change is approved. Continue.").
- Forever verification is deferred; it has not been run.
- Remaining outside this batch: the Talents, Spellbook, Character, Inventory, Professions, Social, Tooltip and Settings features.
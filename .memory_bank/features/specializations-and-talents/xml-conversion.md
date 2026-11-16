# Talents/Specializations XML Conversion
- Status: header/title/divider converted to XML templates; accepted on Retail by the user (approved 2026-11-03); Forever verification deferred.
- Prerequisites: shared controls and rounded panels.
- Scope: custom header, Axis title and divider tree.
- FFXIV_UI/General/Talents.xml holds the header Frame (TOPLEFT 8,-4 / TOPRIGHT -8,-4, height 30), title FontString (LEFT 12 / RIGHT -36, height 26, justifyH LEFT) and divider Texture (BOTTOM anchors, height 1). Both TOCs load it before Talents.lua.
- Lua keeps header frame level, mouse setting, the AxisRegular font/size/colour, localized title selection, palette updates, StyleDivider, native scanning, role icons and shared close ownership/combat deferral.
- tests/Talents.lua applies these templates in its mocks and asserts template names, geometry, justification and divider anchors. Suites: Talents passes; all tests/*.lua exit 0; XML parses.
- Preserve the approved inside-header close placement and native panel ownership.
- Test Talent/Spec/Spellbook transitions and legacy-frame support.
- Require Retail visual acceptance; Forever verification deferred.
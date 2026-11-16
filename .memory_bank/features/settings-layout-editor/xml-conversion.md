# Settings and Layout Editor XML Conversion
- Status: accepted on Retail. Forever verification deferred.
- Prerequisite: shared window controls (complete).
- Converted: the anchor visual tree is now `FFXIV_AnchorVisualTemplate` in `FFXIV_UI/General/FFXIV_UI_Menu.xml`. It holds the backdrop frame's `nameText` and `percentText` FontStrings (inherit GameFontNormalSmall, TOPLEFT/TOPRIGHT anchors at 4/-4) and the `btnInc`/`btnDec` buttons (25x25, CENTER -14/+14, Plus/Minus normal, pushed and ADD highlight textures).
- Kept in Lua: backdrop colours, AXIS_FONT and outline, text values, the scale/drag/wheel/clamp and save logic, the options panel (native InterfaceOptions, dropdowns, profile dialogs), and the minimap/reset flows.
- Approved mockup not required: the anchor visual is unchanged in appearance.
- Tests: `tests/Menu.lua` builds the visual through `tests/support/MenuTemplates.lua` and asserts template geometry, fonts, textures and handlers. The existing profile, reset and inventory dropdown checks still pass in classic and retail modes.
- Not yet verified: combat deferral and profile switching for the anchor visuals in-game.
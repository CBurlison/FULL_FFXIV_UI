# Shared Window and Tooltip Rendering Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- `FFXIV_UI/General/RoundedPanels.lua` owns rounded window surfaces, window chrome, grain, and their theme refreshes.
- `FFXIV_UI/General/WindowControls.lua` owns shared button/search/tab materials, texture shadows, close icons, collapsible headers, combo-box popup styling, and control theme refreshes.
- Existing namespace helpers such as `RoundWindow`, `StyleWindowControl`, and `StyleCollapsibleHeader` keep their names and calling conventions; material selection is shared through `GetPanelMaterial`.
- `StyleComboBoxMenu` supplies the common popup and selection treatment without replacing the opener or native menu behavior.
- Tooltip rendering is split across the modules in [Tooltips](../../../FFXIV_UI/General/Tooltips).
- Core owns tooltip artwork, aura presentation, native-region restoration, layout enforcement, hooks, and the single tooltip event dispatcher.
- Items owns item headers, equipment/consumable layouts, and currencies; Spells owns spell headers, metrics, passive presentation, and description layouts.

### Core Requirements 2
- Mounts, Toys, Skills, and PetAbility own their corresponding specialized layouts.
- The internal `ns.Tooltips` table provides layout initializers and shared font, native-region snapshot, and left/right row helpers.
- Native snapshots retain the first captured state unless replacement is explicitly requested.
- Item rows measure both columns for height; spell rows retain their supplied right-column width.
- Spell height is calculated from current content, not the height of the previously displayed spell.
- Both TOCs load Themes, RoundedPanels, WindowControls, tooltip Core, Items, Spells, Mounts, Toys, Skills, and PetAbility in that order, before feature skins.
- Tooltip initializers run when a tooltip is first styled, after all addon files have loaded.
- The character, inventory, professions, social, and spellbook test entry points load the shared rendering dependencies in the same base order.
- Character-frame tests also cover shared tooltip snapshots, fonts, row measurement, and right-only rows.
- Mocked tests and in-game validation are still required after changes to this shared rendering layer.

### Core Requirements 3
- Button enabled/disabled fill and border nine-slice atlases are extracted from `Button-Enabled.png` and `Button-Disabled.png` with `FFXIV_UI/Media/Textures/Panels/ExtractButtonControls.py`; the enabled reference also supplies Search fill atlases.
- Generated TGA dimensions and filenames remain compatible with the shared renderer, and native button enable/disable events select the matching state atlas.
- The user approved standard end caps plus supplied arrow artwork with directional optical centering.
- `ns.StyleCircularArrowButton(button, direction)` in `FFXIV_UI/General/WindowControls.lua` is the shared renderer for circular arrow buttons on Retail (interface 120000 baseline) and Forever (16001).
- Directions are `left`, `right`, `up`, and `down` (default).
- Repeated calls update direction without adding regions or hooks.
- The character class-banner pane toggle now uses this renderer; its native click, controller routing, tooltip, hit region, and existing combat-deferred layout remain unchanged.
- Plain paging arrows and dropdown chevrons are not circular controls and are unchanged.
- The visual diameter is the smaller button dimension, preserving circular artwork for non-square hit regions.
- The neutral base includes the approved continuous border and is not recolored by themes.

### Core Requirements 4
- A single supplied down-arrow glyph is rotated using texture coordinates; the base lighting never rotates.
- The source canvas occupies 75% of the diameter.
- Arrow and identical black-tinted shadow both move 2 design pixels toward the pointing direction.
- Shadow opacity is 85% and its offset stays 2.5 design pixels upward, independent of direction.
- Design pixels scale with diameter / 32.
- Hover brightness is 1.18, pressed brightness is 0.8 with a 1-pixel downward glyph/shadow displacement, and disabled alpha is 0.4.
- Leaving, hiding, or disabling clears transient states.
- Only addon texture regions are sized or repositioned by the renderer; it does not move protected buttons or replace their handlers.
- `FFXIV_UI/Media/Textures/Panels/ExtractButtonControls.py --circular-only --overwrite` (run with `py`, Pillow required) exports `Arrow-Button-Circle.tga` (32x32) and `Arrow-Button-Glyph.tga` (currently 512x512), both uncompressed RGBA.
- The circle matches the approved mockup PNG pixel-for-pixel.

### Core Requirements 5
- The glyph is resampled from the current high-resolution square `Arrow-Button-Base.png` onto a power-of-two canvas with centered 75% content; the PNG source is never overwritten.
- Full button-control exports include these assets as well.
- The production renderer uses the same glyph TGA for foreground and shadow, not separate direction/theme composites.
- Verification: Lua 5.1 character tests cover all four coordinate rotations, optical offsets, matching shadow movement, states, disable-while-pressed reset, resizing, non-square hit regions, native clicks, idempotence, collapse/expand, theme refreshes, and existing combat-deferred layout.
- Inventory, Spellbook, Professions, and Social tests passed.
- Both TOCs already load the shared renderer before the character skin.
- Export byte checks confirm the circle matches the approved PNG and the glyph matches expected alpha-preserving resampling/padding.
- Actual in-game visual/taint checks on both clients and simulator testing remain not run.
- Source ledger (2026-11-02): Retail `Gethe/wow-ui-source` live commit `d07eb00237d8891f153215db98a5df880a26cfe5` (12.1.5.70688); Forever commit `aff0d8cd53bf4d9ef1c1dd2786b94461a276fb16` (1.60.1.70707).
- Shared `Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua` evidence was inspected for path-based texture loading and texture-coordinate/rotation contracts.

### Core Requirements 6
- This establishes source evidence, not installed-client runtime certification; TOC targets remain unchanged.
- Preferred combination: user selected standard end caps with supplied artwork, requesting further optical centering.
- The supplied arrow and its matching shadow now move 2 design pixels toward the pointing direction at a 32-pixel button size (left -X, right +X, up -Y, down +Y), proportionally scaled with button diameter.
- Manual X/Y controls add fine adjustments on top of this correction.
- Other arrow candidates are unchanged.
- Browser checks passed all four directions at 32 and 96 pixels, matching shadow movement with its separate upward displacement, additive manual adjustments, and desktop/mobile/narrow layouts; updated screenshots were reviewed.
- Final centering approval and production implementation remain pending.
- `mockups/round-arrow-buttons.html` is an isolated approval mockup for both clients, not an accepted production design.
- Regenerate its PNG layers with `py mockups/GenerateRoundArrowPreview.py` (Pillow required).
- It separates one left-arrow glyph from `Media/References/Round-Arrow-Button-Left-Dark.png` and rotates only that glyph for right/up/down; the circular base keeps its lighting orientation.

### Core Requirements 7
- Each direction has independent X/Y offsets.
- The reference background underneath the glyph is inferred with harmonic interpolation, not recovered original artwork.
- The alternative base joins the enabled standard button's end caps.
- Size, glyph scale, backdrops, and illustrative normal/hover/pressed/disabled states are available for comparison.
- No live arrow assets, Lua, or TOCs are changed.
- Revision after visual feedback: standard caps use native-width 16-pixel slices instead of squeezing 22 pixels into each half, and include an added circular light-gray border.
- A third, procedurally drawn circle is available.
- The redrawn arrow candidate is a separately drawn rounded triangular outline: nominal 3-pixel light-gray stroke at a 32-pixel button size, opaque stroke center, transparent triangle interior, softened edges, and a narrow dark contour.
- Its independent blurred oval shadow stays horizontal for every direction, defaulting to 2.5 design pixels above the arrow and scaling with button size.
- The Shadow Y control adjusts that offset.

### Core Requirements 8
- Extracted-arrow comparison retains its baked shading and does not receive a duplicate shadow.
- All candidates remain unapproved.
- Current default: user-supplied `FFXIV_UI/Media/Textures/Panels/Arrow-Button-Base.png`, a transparent 24x24 down arrow, is loaded directly without modifying or regenerating it.
- Its image canvas occupies 75% of the button diameter (native 24 pixels in a 32-pixel button).
- The shadow uses the identical source with black tint and 85% opacity, preserving the original alpha silhouette.
- Arrow and shadow rotate together, accounting for the source's downward orientation, while the shadow translation remains vertically upward in screen space (default 2.5 design pixels).
- No oval shadow is added to this option.
- Supplied, extracted, and redrawn arrows remain available for comparison.
- Prototype validation: PNG round-trips are lossless; recombining layers at original coordinates differs from the reference by at most 3 RGB levels out of 255.
- Local Edge/Playwright checks passed asset loading, rotations, direction-specific offset persistence, base switching, activation, disabled behavior, backdrop selection, and no horizontal overflow at 1280, 390, and 320 pixel widths.

### Core Requirements 9
- Desktop/mobile screenshots were visually reviewed.
- These checks do not certify a clean original-layer recovery or in-game rendering; user approval and client implementation/testing remain pending.
- Revised checks additionally cover the curved cap silhouette and visible top border, redrawn arrow opacity/open center, unchanged horizontal shadow transform across directions, adjustable shadow offset, arrow selection, all three bases, and disabled shadow controls for the extracted arrow.
- Updated desktop/mobile screenshots were reviewed; browser checks passed at the same three widths.
- Supplied-artwork checks passed identical source URLs for arrow/shadow, black tint, matching rotations in all four directions, fixed upward shadow translation, adjustable offset, source loading, arrow selection, and no browser errors or horizontal overflow at 1280, 390, and 320 pixels.
- Updated desktop/mobile screenshots were visually reviewed.
- Approval remains pending; no production Lua or live texture modifications were made.
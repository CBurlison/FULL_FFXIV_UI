# Shared Window Controls

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- WindowControls.xml supplies virtual texture templates for the existing Arrow-Button-Circle.tga and Arrow-Button-Glyph.tga materials.
- Both TOCs load it before WindowControls.lua.
- The shared helper instantiates them directly on their original buttons at ARTWORK sublevels 0 (base), 1 (shadow) and 2 (glyph).
- Lua retains direction-dependent UVs, optical offsets, runtime sizing, shadow/color updates, hooks and native interactions.
- This structure-only conversion preserves the accepted appearance.
- No new UI or redesign is introduced.
- Character-frame tests verify XML-backed materials, template binding, ownership, layers/sublevels, both TOC orders, all directions, resizing, hover/pressed/disabled states and reuse.
- Inventory, professions, spellbook and social mocks also instantiate the shared templates.
- The user approved this conversion on Retail; Forever verification remains unavailable.
- Validation: character-frame, inventory, professions, spellbook and social regression suites pass.

### Core Requirements 2
- XML parsing and scoped whitespace checks pass.
- The shared close-icon template supplies the original Close.tga asset.
- SkinWindowClose creates it directly on the native button at OVERLAY; Lua retains all-points coverage, idle/hover tint, idempotency and existing scripts.
- No appearance or native interaction changes are intended on either target.
- The character-frame suite checks the exact XML-backed asset, template, parentage, draw layer, coverage, idle/hover/reset colors, reuse and native click preservation.
- All five consumer mocks support the template.
- The user accepted the shared close-icon conversion on Retail; no simulator comparison was run.
- Forever remains deferred.
- Validation: character-frame, inventory, professions, spellbook and social suites, XML parsing and scoped whitespace checks pass.
- The user approved the ordered backlog.

### Core Requirements 3
- See the [feature-by-feature plan](xml-conversion-plan.md) for all ten features, dependencies, exclusions and acceptance gates.
- The close-button containment fix was separately accepted on Retail.
- Status: accepted by the user on Retail on 2026-11-03.
- Forever verification remains deferred.
- This was the first batch of the remaining shared-controls feature.
- WindowControls.xml now owns extracted-tab left/center/right geometry (23/17-pixel caps), square all-points coverage, and shared three-piece control geometry (4-, 10- and 12-pixel caps).
- Lua retains material/theme/disabled selection, selected-tab UV changes, colors and hover updates.
- Original owners, BACKGROUND layers/sublevels, anchor order and runtime creation points are unchanged.
- The transient pre-theme texture assignment was removed because UpdateControlMaterial immediately supplies the selected material before returning.
- All five consuming test suites read the same geometry definitions through a test-only template applicator.

### Core Requirements 4
- Independent assertions cover exact cap sizes/insets/UVs, extracted-tab asymmetry, all-points squares, draw layers, search fill-only behavior, material state changes and reuse.
- Character-frame, inventory, professions, spellbook and social suites pass; XML parsing and scoped whitespace checks pass.
- No simulator/client screenshot comparison was run.
- Retail acceptance covered character/social tabs, search fields, standard buttons and square controls in inventory, spellbook and professions, including resize, selected/hover/disabled states, themes and native clicks.
- Both targets retain the same API behavior; Forever client verification remains deferred.
- WindowControls.xml now owns the all-points, mouse-disabled shadow frame and the equivalent collapsible-header panel (including BackdropTemplate inheritance).
- Header plus/minus textures retain their original collapse-button ownership and OVERLAY layer, with XML supplying the centered 10x2 and 2x10 white geometry.
- Creation remains lazy at the original call sites.
- Lua retains frame levels, source mirroring, themes, native artwork suppression, title styling and collapsed-state updates.
- No new UI or visual redesign is introduced.

### Core Requirements 5
- Intentional Lua boundaries completing this feature's scope:
- Shadow source-relative anchors, three offset/opacity pairs, material and UV synchronization remain together in Lua. Their dimensions follow arbitrary source regions rather than the container. A separate template for each tint would split this compact source-copy specification without eliminating dynamic setup.
- Popup nine-slice artwork and selected-row gradient strips remain on native AttachTexture pooling. Preserve native release/reuse and per-menu initialization instead of substituting persistent XML regions. This is a deliberate lifecycle boundary, not a claim that pooled textures support template inheritance.
- Frame levels, theme materials/colors, state-dependent UVs, native interactions and combat deferral remain runtime work.
- Automated coverage: exact container parentage/coverage/mouse behavior; both header templates' geometry, solid-white material, center anchors and draw layers; all shadow offsets/tints; initial and updated source material/UV synchronization; frame-level changes and zero clamp; shared-container/per-source reuse; native header clicks, collapse toggling, hover/theme updates and combat-deferred installation.
- Character-frame, inventory, professions, spellbook and social suites pass, including Social's default Forever and explicit Retail configurations.
- XML parsing, backdrop inheritance, both TOC load-order assertions and scoped whitespace checks pass.
- No simulator or client screenshot comparison was run.
- The user approved this batch on Retail and authorized moving on to rounded panels.
- No independent screenshot comparison was run.
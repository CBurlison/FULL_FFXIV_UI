# Micro Menu

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- The accepted appearance is unchanged.
- FFXIV_UI/General/MicroMenu.xml defines the centered icon anchor and the existing GoldRing.tga material.
- Both client TOCs load it before MicroMenu.lua.
- Lua creates textures directly on native buttons at ARTWORK and OVERLAY sublevel 1, retaining runtime icon selection/size, circular masks, cross-region ring anchoring, hover/pressed/disabled updates, alert pulses and combat-deferred installation.
- The micro-menu suite checks XML definitions/load order and instantiated template binding, ownership, layers, center anchor and clearing of competing ring anchors.
- Existing tests cover native clicks/tooltips, layout, notifications, state changes, combat deferral and reuse.
- This conversion is approved in-game.
- Validation: the targeted micro-menu suite, XML parsing and scoped whitespace checks pass.
- The attempted standalone virtual mask template was reverted after the client reported that CreateMaskTexture could not find the inherited node.
- XML parsing and mocks did not validate client template registration.

### Core Requirements 2
- The circular mask remains Lua-created with CircleMask.tga and CLAMPTOBLACKADDITIVE wrapping on both axes, matching the original implementation.
- Lua binds coverage to the runtime-sized icon and retains AddMaskTexture.
- Tests reject mask-template inheritance and standalone mask definitions, and check material, wrapping, parentage and icon-mask linkage alongside existing state/combat/native-behavior regressions.
- The prior approval is superseded by the reported client failure; verification of the restored mask path is pending.
- Per the request to finish the feature before further visual acceptance, all fourteen distinct icon materials now live in XML templates inheriting the centered base.
- Lua selects the appropriate template for each native button, including shared Talent/PlayerSpells and MainMenu/Help mappings.
- Native flash borders reuse the XML-backed ring material without replacing their existing animation-controlled region.
- This completes the appropriate static XML surface.
- Native secure buttons are deliberately not recreated or reparented.
- Runtime dimension calculation, mask/ring attachment, native alert blend/geometry, artwork suppression, hover/pressed/disabled updates, notifications, spacing/layout and event-driven combat deferral remain Lua.

### Core Requirements 3
- They depend on native button availability/state and must not be replaced with fixed XML frames.
- No appearance or interaction redesign is intended.
- Tests cover all fourteen materials and sixteen button mappings (including late PlayerSpells creation), inherited centering, exact artwork, clipping/wrapping, ring ownership/layers, non-square button dimensions, buttons without flash borders, menu-only layout fallback, native alerts/tooltips/clicks, state changes, reuse and combat deferral.
- Both TOCs retain XML-before-Lua order.
- Full-feature in-game visual acceptance remains pending; no simulator comparison was run.
- Validation: the complete micro-menu regression suite, XML parsing, all referenced artwork existence checks and scoped whitespace checks pass.
- Client acceptance: reload, exercise every available native micro button and tooltip, check hover/pressed/disabled states and circular clipping, verify notification/alert pulses when available, test horizontal/vertical layouts, and confirm combat-delayed installation resumes after leaving combat.
- The user confirmed no errors and correct menu display after restoring Lua mask creation.
- The completed static artwork conversion is visually accepted with the circular mask intentionally remaining Lua.
- This confirmation does not separately establish every interaction/state or both-client acceptance.
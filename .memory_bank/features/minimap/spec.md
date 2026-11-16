# Minimap XML Conversion

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Preserve the accepted minimap appearance on Retail and Forever.
- This structure-only conversion does not redesign the UI or change game API signatures.
- `FFXIV_UI/General/Minimap.xml` defines a virtual `FFXIV_MinimapTemplate`.
- Lua instantiates it as the existing `FFXIV_MinimapFrame` on PLAYER_LOGIN, retaining the initialization guard and timing.
- Both TOCs load XML before Lua.
- The template holds the 245x245 frame centered at -5/0, FFMap artwork with 0.08-0.92 texture coordinates, the 245x245 coordinate background at BOTTOM 0/-20, the existing unused size-14 coordinate label, and the 120x20 coordinate frame at BOTTOM 0/-8.
- The four coordinate text regions retain AxisMedium sizes 12/10 and color 221/255, 216/255, 202/255.
- Sibling text anchors stay in Lua, with explicit anchor clearing.
- Lua retains suppression of native decorations, zoom-button parenting/position/scale/levels, the 0.2-second ticker, coordinate formatting, and hiding coordinate text/background when dead or without map position.
- `tests/Minimap.lua` checks template artwork/layout, both TOC orders, login-only creation, duplicate initialization prevention, zoom controls, sibling anchors, coordinate output, and missing-map/death behavior.

### Core Requirements 2
- In-game visual acceptance remains pending; no simulator comparison was run.
- The targeted Lua regression test passes, XML parsing passes, and the changed tracked files pass the whitespace check.
- The user approved the conversion in-game.
- The existing optional quest-overlay container now instantiates a mouse-disabled all-points virtual frame from Minimap.xml at its original file-load point.
- Lua retains Minimap frame level +5.
- Pooled OVERLAY markers use a virtual 24x24 texture template; icon selection, runtime positions, scanning, tracking, visibility and combat handling are unchanged.
- Both TOCs already load Minimap.xml before MinimapQuests.lua.
- The accepted appearance is unchanged; no redesign or new UI is introduced.
- The optional overlay remains off by default.
- Tests cover XML declarations and both load orders, instantiated geometry/layers, marker pooling, scanning budget, projection, restricted values and all existing behavior.

### Core Requirements 3
- In-game visual acceptance is pending; no simulator comparison was run.
- Validation: the minimap and optional quest-overlay regression suites, XML parsing and scoped whitespace checks pass.
- The user is currently testing on Retail, where the minimap tooltip scanning API is unavailable in their installed client.
- Forever is currently inaccessible.
- Quest-overlay in-game verification is therefore deferred, not passed.
- Retest on a client with the required scanning APIs when available: enable the optional overlay, check 24x24 completed-quest markers and tracked colors, movement/rotation/zoom positioning, hover pause, combat clearing and disable cleanup.
- Keep the feature off by default and retain its explicit unsupported-client notification.
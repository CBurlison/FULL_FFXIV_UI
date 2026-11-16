# Player, Party, Raid, and Pet Frames Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Raid health styling uses a separate visual status bar; it does not hook Blizzard's health color setter or recolor Blizzard's health texture, preserving the native color state used by secret-value comparisons.
- The visual health bar is anchored independently and does not write Blizzard's temporary-max-health-loss control fields.
- Druids use one power bar in human form.
- Cat, Bear, and Dire Bear Form also show a secondary mana bar alongside the primary energy or rage bar, regardless of specialization.
- Player primary and secondary power bars initialize on login and world entry, including a fresh game launch, without waiting for a resource-change event or UI reload.
- Standard party frames use a compact FFXIV-inspired layout: gold-bordered WoW class icons, party-slot numbers, level and name text, and slim blue health bars with resource-colored power bars and current values underneath.
- While in a party, your character appears as row 1 above the other members, numbered 2 through 5.

### Core Requirements 2
- This extra player row is hidden while solo, in raids, or when standard party frames are hidden; the existing standalone player HUD is unchanged.
- On Forever, names include both first and last names.
- Blizzard's existing unit buttons, tooltips, menus, auras, pets, ready checks, and party indicators remain in use.
- Move and scale the group with WoW's Edit Mode; disable raid-style party frames to see this skin.
- Protected layout changes wait until combat ends.
- Raid frames use dark, gold-edged subgroup panels with gold-tinted WoW class icons, pale-blue health bars, and a 3-pixel primary-resource strip below each health bar.
- The resource strip is shown for every raid member regardless of WoW's healer-only power-bar setting.
- Names are hidden in the tiles, as in the reference layout, but remain available in Blizzard's unit tooltips.
- WoW's five-member subgroups, Edit Mode sizing/positioning, secure targeting and menus, auras, heal/absorb predictions, selection/threat indicators, and ready checks remain in use.
- Enable separate groups in Edit Mode for bordered subgroup panels.

### Core Requirements 3
- Raid-style party frames and nameplates are not changed by the raid skin.
- Your pet uses a matching compact row with blue health and resource-colored power bars instead of occupying the Secondary Power anchor.
- It follows the last visible standard party member, or occupies the first row when solo.
- In raids or raid-style party layouts, it stays at the standard party list's saved position.
- The pet row follows the party list's Edit Mode position and scale, remains independent of the party list's visibility, and is automatically hidden when no pet exists.
- Roster-driven moves during combat wait until combat ends; targeting and the right-click pet menu use a secure unit button.
- `FFXIV_UI/PartyFrames/PartyFrames.xml` defines the virtual `FFXIV_PartyRowVisualTemplate`, loaded before PartyFrames.lua in both Retail and Forever TOCs.
- It preserves the existing icon border/background, gold order badge, icon geometry, and five text regions (order, level, name, healthValue, powerValue), including font sizes, OUTLINE flags, colors, shadows, and anchors.
- `PartyRowStyle.CreateVisual` instantiates this template and returns the visual frame with the same child keys previously returned in a table.
- Lua retains relative frame level +1, icon desaturation/tint, and the cross-region order-to-badge anchor (clearing XML anchors first).

### Core Requirements 4
- Party members, the custom player party row, and Enemy List rows use this helper; the already-converted pet layout remains unchanged.
- Native secure buttons, bar layout, combat deferral, identity/value updates, and events remain Lua-driven.
- This is a structure-only conversion of the accepted appearance, not a redesign.
- `tests/PartyFrames.lua` checks template geometry, text styling, load order, and existing party/player/pet behavior with a template-backed mock.
- Enemy List behavior is also tested.
- In-game visual confirmation remains pending; no simulator comparison was run.
- Validation: party/player/pet and Enemy List regression tests pass, shared template XML parsing passes, and changed tracked files pass the whitespace check.
- The shared party-row visual conversion is approved in-game.
- The same XML now defines a virtual `FFXIV_PartyPlayerTemplate` inheriting SecureUnitButtonTemplate, initially hidden at 284x32, with health and ManaBar children.
- A shared virtual player-bar template holds their 108x5 size, WHITE8X8 fill, and disabled mouse handling.

### Core Requirements 5
- Health remains blue, with the original health/power anchors at 34/-16 and 152/-16.
- Lua creates the button only outside combat as before, configures secure attributes, binds the existing HealthBarContainer wrapper, applies shared background art, sets bar levels to row +1, and retains tooltips, updates, state-driver visibility and deferred layout.
- The shared visual is still created through PartyRowStyle; Blizzard's native unit buttons are unchanged.
- Both targets use the existing XML load order.
- The party regression suite verifies template structure and binding alongside the existing combat, visibility, secure interaction, health/power and pet behavior.
- This preserves the accepted design without visual changes.
- In-game confirmation remains pending; no simulator comparison was run.
- Validation: the party/player/pet regression suite passes, XML parsing passes, and changed tracked code passes the whitespace check.
- The player party button and bars are approved in-game.
- `FFXIV_UI/PartyFrames/RaidFrames.xml` adds virtual non-clickable health and power StatusBar templates, loaded before RaidFrames.lua in both TOCs.

### Core Requirements 6
- Health retains WHITE8X8 fill and color 0.63/0.88/1; power retains WHITE8X8 fill and its all-points dark background (0.015/0.025/0.035).
- Lua instantiates these templates outside combat and retains relative levels, layout, 3-pixel power height, native frame suppression, secret-safe value forwarding, resource colors, and all hooks/events.
- Native Blizzard health color state is still untouched.
- The raid tests validate both XML definitions and TOC orders, then exercise the existing behavior with template-backed bar mocks and combat-time creation assertions.
- This is a structure-only conversion of the accepted design on Retail and Forever.
- In-game bar rendering remains pending; no simulator comparison was run.
- Validation: all seven raid behavior tests and the XML/TOC checks pass, XML parsing passes, and changed tracked files pass the whitespace check.
- The raid health and power bar conversion is approved in-game.
- The existing raid XML adds virtual texture templates for the 22x24 dark icon base (LEFT 3/0, color 0.13/0.11/0.065) and the 18x20 class icon.
- Lua creates these textures directly on the native raid button using the existing BACKGROUND and ARTWORK layers, avoiding a new overlay frame or a change to layering.

### Core Requirements 7
- Lua clears the icon's anchors before centering it on its base and retains desaturation, gold tint, class texture/coordinates, role icons, border creation and combat deferral.
- This structure-only conversion preserves the accepted design on Retail and Forever.
- Tests verify texture template structure, geometry, layers, anchor clearing, tint and class artwork alongside the existing raid behavior suite.
- Client rendering remains pending; no simulator comparison was run.
- Validation: all seven raid behavior tests and template checks pass, XML parsing passes, and changed tracked code passes the whitespace check.
- The raid class-icon artwork is approved in-game.
- RaidFrames.xml now defines virtual texture templates for the subgroup background (all-points, color 0.055/0.055/0.045 at alpha 0.85) and one-pixel health shine (0.92/1/1 at alpha 0.8).
- Lua creates them on their original owners and layers: subgroup BACKGROUND sublevel -2 and native raid-button ARTWORK.
- Shine anchors are explicitly cleared before anchoring to the custom health bar's top corners.
- Border creation, native subgroup titles, dynamic health layout, and combat deferral are unchanged on both clients.

### Core Requirements 8
- The raid regression suite checks template properties, owners, draw layers, shine thickness and cross-parent anchors, along with existing rendering updates and combat behavior.
- This preserves the accepted appearance; in-game confirmation remains pending and no simulator comparison was run.
- Validation: all eight raid behavior tests and template checks pass, XML parsing passes, and changed tracked code passes the whitespace check.
- The raid subgroup background and health shine are approved in-game.
- RaidFrames.xml defines four virtual border texture templates with the original one-pixel thickness and corner anchor pairs.
- Lua creates them directly on the original subgroup or raid button at BORDER layer, retaining the subgroup, tile, and icon border colors.
- Icon borders clear the template anchors and reanchor to the icon base; tile and subgroup borders use the template's parent-relative anchors.
- Combat deferral, native interactions, and all value updates remain unchanged for Retail and Forever.
- The raid tests verify each template's thickness and anchors, all twelve initial tile/icon/group edges, colors, owners, layering, and cross-region icon anchoring alongside the existing combat and reuse tests.
- This is a structure-only conversion of the accepted appearance.

### Core Requirements 9
- In-game visual acceptance remains pending; no simulator comparison was run.
- Validation: all nine raid behavior tests and template checks pass, XML parsing passes, and changed tracked code passes the whitespace check.
- The raid border conversion is approved in-game.
- PartyFrames.xml adds virtual texture templates for the shared bar edge, background, and shine.
- The edge retains -1/1 and 1/-1 corner offsets and color 0.05/0.22/0.3/0.9; the background fills the bar at 0.02/0.07/0.1/0.9; the shine spans the top at one-pixel height with color 0.75/0.94/1/0.65.
- PartyRowStyle.AddBarBackground creates these directly on the original bars at BACKGROUND -2, BACKGROUND -1, and OVERLAY, respectively.
- Party members, the custom player party row, and Enemy List health/cast bars continue using the same helper.
- Pet bars retain their existing identical XML artwork.
- No runtime layout, secure behavior, value updates, or client-specific API behavior changes.
- The party tests verify exact template colors/geometry, creation order, ownership, layers/sublevels, and reuse alongside existing party/player/pet behavior.

### Core Requirements 10
- Validation: party/player/pet and Enemy List regression suites pass, XML parsing passes, and changed tracked code passes the whitespace check.
- The shared party-bar background and highlight conversion is approved in-game.
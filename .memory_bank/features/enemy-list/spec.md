# Enemy List Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Enable **Enemy List (non-clickable)** in FFXIV UI settings.
- It is off by default and saved per character.
- Use Show Anchors or `/ffxivtoggle` to move and scale the **Enemy List** anchor; its position participates in anchor profiles.
- The list grows downward from that point while you are in combat.
- The **Enemy List** settings section also offers **Show Enemy List label**, **Show icon legend**, and **Dynamically size casting entries** (all on by default, saved per character).
- Hiding the label or legend removes its reserved space.
- Combat-data warnings and the empty-list message remain visible even with the legend hidden.

### Core Requirements 2
- Turn dynamic sizing off to reserve cast-bar space on every row, including idle enemies.
- All three controls are disabled while the Enemy List is off; their saved choices are retained and restored when it is enabled again.
- Changes apply immediately.
- This is a separate informational display: Blizzard does not allow addons to freely relocate clickable nameplates during combat.
- Normal world nameplate placement and auras remain unchanged.
- Turn on enemy nameplates to expose units to the list; enemies outside nameplate availability cannot be retained or discovered.
- While an enemy is listed, its world nameplate displays the matching list-row number on its left.
- The Enemy List row receives a gold outline when targeted and a softer gold outline when the enemy is moused over; the target outline takes priority when both apply.
- The soft outline clears when the cursor leaves the enemy, without waiting for another mouseover event.
- World nameplates only receive numbers, not these outlines.

### Core Requirements 3
- These cosmetic overlays do not change targeting or mouse interaction, and disappear when the enemy leaves the list, combat ends, or the feature is disabled.
- Numbers follow the current row order.
- Target/mouseover outlines are omitted when the client restricts the corresponding unit comparison.
- Rows use the party style with red health bars and current health.
- An enemy appears when a readable player threat-table entry or its player target confirms involvement, not merely because it is fighting someone.
- `!` means targeting you, `-` means targeting another unit, and `?` means its target is unavailable.
- These indicate current target, not guaranteed aggro ownership.
- Up to four buffs followed by eight debuffs flow together in one row to each enemy's right, with counts, timers, and tooltips.
- Missing buffs leave no reserved gap before debuffs.
- The rows cannot be clicked to target or cast.

### Core Requirements 4
- Forever/Retail can restrict combat membership and target information.
- The list never compares secret values: unconfirmed enemies are omitted and a combat-data warning is displayed when membership cannot be determined.
- A `?` marker is used when an included enemy's target cannot be determined.
- Leaving combat clears the display; disabling the option hides it immediately.
- With dynamic sizing enabled, each enemy row expands beneath its health for a cast/channel bar with the ability icon and name only while casting or channeling.
- When the cast ends, the row returns to its compact height; entries below move automatically without changing list order.
- Gold fill indicates an interruptible ability; gray fill with a red X indicates an uninterruptible ability.
- Progress uses WoW's native duration objects, including channel countdowns, without calculating restricted timestamps.
- The fixed marker styling is defined by `FFXIV_EnemyListMarkerTemplate` in EnemyList.xml: AxisMedium 18, OUTLINE, and the original gold initial color.
- Lua creates the FontString on the same shared visual as before at OVERLAY, clears initial anchors, and centers it on the row icon.

### Core Requirements 5
- The `!`, `-`, and `?` states and their dynamic colors, pooled-row updates, and secret-value handling remain unchanged on Retail and Forever.
- The now-unused Lua text factory is removed.
- The Enemy List tests verify template styling, owner, layer, anchor clearing, status text/colors, and the existing behavioral suite.
- This is a structure-only conversion of the accepted appearance; in-game acceptance remains pending.
- Validation: the Enemy List regression suite, XML parsing, and changed tracked code whitespace checks pass.
- No simulator comparison was run.
- The aggro-marker conversion is approved in-game.
- `FFXIV_UI/PartyFrames/EnemyList.xml` defines the existing `FFXIV_EnemyList` global as a hidden, non-clickable frame with its fixed title and status FontStrings.
- The title retains AxisMedium 14 with OUTLINE, gold color, and TOPLEFT anchoring; status retains AxisMedium 10 with OUTLINE, gray color, and TOPLEFT 0/-18 anchoring.
- Both Retail and Forever TOCs load XML before Lua.

### Core Requirements 6
- Lua reparents the container to the existing EnemyList anchor and fills it, then binds the header children.
- Dynamic row creation, party-row styling, aura slots, nameplate overlays, casts, configuration, restricted-value handling, and visibility behavior are unchanged.
- This bounded conversion preserves the accepted appearance; it does not redesign the UI.
- `tests/EnemyList.lua` now verifies the XML header/container and both TOC orders before running the existing behavioral suite.
- In-game rendering remains pending; no simulator comparison was run.
- Validation: the targeted Enemy List test and all 42 Lua test files pass; the new XML parses successfully and changed tracked files pass the whitespace check.
- The container/header conversion is approved in-game.
- The next slice adds the virtual `FFXIV_EnemyListRowTemplate` to the same XML file.
- It defines each non-clickable row's health bar and hidden cast bar, including cast icon, spell name, and interrupt indicator, preserving the original anchors, sizes, colors, and artwork.
- Lua retains row dimensions from PartyRowStyle, health bar sizing, explicit bar frame levels (row +1), shared styling/background helpers, marker and outline creation, aura slots, and all runtime behavior.

### Core Requirements 7
- The existing Enemy List test now builds a template-backed mock row and verifies its binding, bar dimensions/levels, XML definitions, and the complete existing behavior suite.
- This structure-only change preserves the accepted design on Retail and Forever.
- In-game rendering of the row bars remains pending; no simulator comparison was run.
- Validation: the template-backed Enemy List regression suite passes, XML parsing passes, and changed code passes the whitespace check.
- The repeated row bars are approved in-game.
- The row template now also defines the non-clickable, all-points outline frame and its four OVERLAY edges.
- Horizontal edges remain 2 pixels high at y=2/-2; vertical edges remain 2 pixels wide at x=-2/2 with the same corner offsets.
- Lua binds the four edge keys in top/bottom/left/right order, retains the row +10 frame level, and continues setting colors and target/mouseover visibility exactly as before.
- Aura slots and native nameplate numbering remain unchanged.
- The Enemy List regression test checks every edge's XML thickness and anchor pair, child binding, frame level, and the existing target/mouseover priority, restricted-value handling, resize and pooled-row behavior.

### Core Requirements 8
- Retail and Forever use the same template; no new API calls or visual redesign are introduced.
- In-game outline confirmation remains pending; no simulator comparison was run.
- Validation: the targeted Enemy List regression suite passes, XML parsing passes, and changed tracked code passes the whitespace check.
- The nameplate number badge conversion is approved in-game.
- The row outlines are approved in-game.
- `FFXIV_EnemyListPlateTemplate` now defines the non-clickable nameplate overlay's number (AxisMedium 16, OUTLINE, gold, RIGHT-to-LEFT offset -6/0) and dark badge texture.
- Lua retains native health-bar/plate anchoring, relative frame level +10, numbering, pooling, and visibility.
- Badge anchors cross to the number region and remain in Lua; existing anchors are cleared before applying the original -4/2 and 4/-2 padding.
- No native nameplate behavior or API signatures change on Retail or Forever.
- The Enemy List test checks the template artwork/colors/font, both child bindings, frame level, number position, cleared badge anchors and padding, plus existing numbering, plate recycling, combat exit, and restricted-data behaviors.

### Core Requirements 9
- This is a structure-only conversion of the accepted appearance.
- In-game visual confirmation remains pending; no simulator comparison was run.
# Experience Bar

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- The player XP strip anchored to the ExpBar anchor.
- Shows level, class abbreviation, XP numbers and percent, the XP fill, and the rested overlay.
- Spec: [experience-bar.md](experience-bar.md)
- Files: `FFXIV_UI/General/ExperienceBar.xml` (structure), `FFXIV_UI/General/ExperienceBar.lua` (behavior)
- Tests: `tests/ExperienceBar.lua`
- The **Experience Bar** is the player XP strip anchored to the **ExpBar** anchor (see [Anchor Profiles](../anchor-profiles.md)).
- It is built from XML and driven by Lua.

### Core Requirements 2
- Global frame `FFPlayerXPFrame`, parented to `UIParent` at `MEDIUM` strata, 750×750.
- `restedIndicator`: overlay texture, hidden by default, shown while resting.
- `restedBar` and `xpBar`: `StatusBar` children with `XPRested` and `XPBar` fill textures.
- `outlineFrame`: child frame holding the text: `classLabel`, `LLabel`, `vLabel`, `levelText`, `xpNumbers`, and `xpPercent`. The static `L` and `v` labels are set in XML.
- Parents and centers the frame on `FFXIV_UI_Anchors.ExpBar`. This stays in Lua because anchors are created at runtime from profiles.
- Sets the outline frame level to bar level + 5 and the fill draw sub-layers (XP fill 0, rested fill -1).
- Hides the default Blizzard XP bar and tracking-bar manager.
- Updates level, class abbreviation, XP numbers, percent, XP fill, and rested fill on `PLAYER_ENTERING_WORLD`, `PLAYER_XP_UPDATE`, `PLAYER_LEVEL_UP`, `PLAYER_UPDATE_RESTING`, `ZONE_CHANGED`, and `ZONE_CHANGED_NEW_AREA`.
- Rested fill shows `min(currentXP + rested, maxXP)` only while rested XP is greater than zero.
- Both `FFXIV_UI/FFXIV_UI.toc` (Retail) and `FFXIV_UI/FFXIV_UI_Camelot.toc` (Forever) load `FFXIV_UI/General/ExperienceBar.xml` before `FFXIV_UI/General/ExperienceBar.lua`.

### Core Requirements 3
- `tests/ExperienceBar.lua` checks the XML names, parent keys, asset paths, and TOC load order as text, then runs the Lua against a stub frame tree and checks anchoring, draw layers, Blizzard bar hiding, event registration, text, bar values, and rested visibility.
- The conversion is intended to be pixel-identical to the prior Lua-built frame.
- No visual changes were made, so no HTML mockup was required.
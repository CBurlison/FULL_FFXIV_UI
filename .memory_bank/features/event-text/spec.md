# Event Text XML Conversion

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Preserve the accepted appearance and behavior on Retail and Forever.
- This is a structure-only conversion, not a visual redesign.
- `FFXIV_UI/General/EventText.xml` defines the existing `EventTexturesFrame` global, its hidden OVERLAY texture (1200x1200, alpha 0, centered on UIParent at 0/250), and a hidden sibling `FFEventTextAnimationFrame`.
- Both TOCs load XML immediately before `FFXIV_UI/General/EventText.lua`.
- Lua binds these objects and retains the event artwork paths, two-second world-entry delay, quest acceptance filtering, and the original animation: 0.15-second fade-in with scale 1 to 0.9, two-second hold, and 0.25-second fade-out.
- Notifications restart the animation as before.
- No game API signatures, events, or compatibility behavior change.

### Core Requirements 2
- `tests/EventText.lua` verifies XML structure and both TOC orders, binding without frame creation, artwork selection, quest filters, world-entry delay and reset, animation timing and scale, hiding after completion, and notification restart.
- The targeted Lua regression test passes, XML parsing passes, and the changed tracked files pass the whitespace check.
- The user approved the conversion in-game.
- No simulator or screenshot comparison was run.
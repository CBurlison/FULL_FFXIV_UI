# Quest Tracker Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Watched quests and campaign quests use an FFXIV-inspired objective-tracker skin: right-aligned gold titles, pale-blue objective text and chevrons, Axis Medium fonts with dark outlines/shadows, and quest-state icons on the right.
- Completed quests use the Complete icon, repeatable quests use Repeatable, and other accepted quests use Incomplete.
- Blue variants identify hovered or super-tracked quests.
- New Quest artwork is included but is not used for already-accepted quests.
- Unfinished objective lines use the extracted cyan/white `ObjectiveIndicator.tga` artwork on their right.
- Blizzard's existing green completion check replaces that indicator when an objective completes, retaining the native check animation.
- Waypoint icons remain unchanged.

### Core Requirements 2
- Native tracker quest-POI artwork stays hidden through acceptance/completion animations and icon refreshes so it cannot overlap the custom quest icons.
- Its original visibility is restored when the button returns to Blizzard's shared pool; quest buttons and interactions remain native.
- The original quest buttons, map navigation, context menus, quest-item buttons, timers, progress bars, completion animations, and collapse controls remain native.
- Tracker position/width/scale remain controlled by WoW; the full quest-log/map window layout and other objective categories are unchanged.
- Layout changes triggered during combat wait until combat ends.
- Supplied PNG artwork is preserved under `Media\Textures\Quests`; matching power-of-two, alpha-enabled TGA copies are used in game because WoW does not load PNG textures.
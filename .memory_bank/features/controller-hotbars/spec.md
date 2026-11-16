# Controller Hotbars and Cast Labels Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Forever's built-in controller main hotbars use the same square button artwork, scaled to each slot's native collapsed/expanded size.
- All four main bars keep their cross layouts, trigger/shoulder indicators, paging, bindings, and interactions.
- When enabled, each slot has a device-aware activation glyph in its upper-right corner, visible on both active and inactive bars, using the native button's input mapping (including alternate controller icon sets), rather than relying on the old circular/arrow-shaped slots.
- Native slot shapes and shadows stay hidden through controller style refreshes; protected geometry changes wait until combat ends.
**Show Controller Button Glyphs** in FFXIV UI settings toggles these individual slot glyphs. It defaults to on, is saved per character, and applies immediately, including in combat. Trigger/shoulder indicators are unaffected.
- The top-right controller utility actions use the same square mask and gloss as spell slots, including when their icons change with the current target.
- Native atlas/raid-marker sprite coordinates are preserved.

### Core Requirements 2
- Hotbar background hiding only changes artwork visibility; it does not modify Blizzard's action-bar state or invoke action-bar refresh methods.
- Main-bar divider artwork stays transparent through combat refreshes without hiding or changing protected divider frames.
- Player cast and channel labels omit a trailing ` - No Name` placeholder (for example, `Opening - No Name` displays as `Opening`).
- Named objects and other spell names are unchanged.
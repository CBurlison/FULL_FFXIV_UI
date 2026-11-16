# Technical Context: FFXIV UI

## Technology Stack
- **UI Prototyping:** HTML/CSS/JS mockups required prior to WoW implementation for all UI elements and visual changes.
- **Language:** Lua 5.1 (World of Warcraft execution environment).
- **Markup:** XML (Frame definitions, templates, templates inheritance via Blizzard FrameXML).
- **Client Environments:** World of Warcraft: Forever (Classic/Beta variants) and Retail / Retail.
- **Assets:** Custom PNG textures converted to power-of-two alpha-enabled TGA textures (`FFXIV_UI/Media/Textures`).
- **Testing:** Standalone Lua unit tests located in `tests/` covering core logic, icon resolution, professions, spellbooks, and UI components.

## Constraints & Rules
- **Mandatory HTML Mockup & Retrofitting Approval:** No UI element or visual component may be implemented or modified in WoW Lua/XML without first being mocked up in HTML/CSS and explicitly approved by the user. If an existing feature has implementation code but lacks an HTML mockup, a mockup must be created for it first.
- Never break combat lockdown (`InCombatLockdown()`).
- Avoid global API replacements where localized hooking or composition is sufficient.
- Respect client security boundaries (no inspection of secret combat log values in restricted environments).

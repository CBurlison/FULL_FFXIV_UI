# Progress: FFXIV UI

## Completed Features
- **Window & Tooltip Rendering:** Shared rounded panels, chrome, and modular tooltip refactoring.
- **Menu Bar:** Red-and-gold custom micro-menu button replacement with circular masks and rings.
- **Controller Hotbars:** Square button artwork, activation glyphs, and trigger indicators.
- **Crafting Log:** Combined professions frame skinning with themed overview cards; profession ability icons use native artwork.
- **Spellbook (Forever):** Sidebar search, category filtering, borderless fades, and display mode toggles.
- **Friends, Social & Chat:** Translucent dark chat logs, scrollbar repositioning, and Social UI skins.
- **Character & Inventory:** FFXIV-inspired character sheet, live resource bars, account-wide themes, and unified bag grids.
- **Quests & Minimap:** FFXIV objective tracker skins and world-map quest icons.
- **Unit & Target Frames:** Compact party/raid rows, pet rows, target resource bars, and combo-point gauges.
- **Enemy List:** Optional non-clickable combat threat and cast-bar list.
- **Anchor Profiles:** Account-wide shared layout profiles with per-character selection.
- **Retail & Forever Dual Compatibility:** Updated all agents, instructions, specs (`SPECIFICATIONS.md`, `README.md`, Memory Bank), and API skills (including creating dedicated Forever counterpart skills for Retail-only features like housing, Great Vault, crafting orders, armor dyes, and renown) to ensure seamless support for both WoW Retail and WoW Forever.

## In Progress / Maintenance
- **HTML UI Mockup Workflow:** Mandatory requirement established that all new UI elements and visual adjustments must be mocked up in HTML/CSS and explicitly approved by the user before implementation in WoW Lua/XML.
- Spec-Driven Development (SDD) adherence via the centralized `.memory_bank/features/`.

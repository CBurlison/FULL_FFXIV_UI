# System Patterns: FFXIV UI

## Architecture & Design Patterns
- **HTML Prototyping Workflow:** Mandatory prerequisite step for all new UI elements or visual changes. Elements must be mocked up in HTML/CSS first and explicitly approved by the user before any implementation in WoW Lua/XML. Furthermore, if a feature has existing implementation code but no HTML mockup yet, a mockup must be retroactively created and approved before proceeding with further changes.
- **AddOn Structure:** Modular Lua files organized by UI domain (`FFXIV_UI/General`, `FFXIV_UI/PlayerFrames`, `FFXIV_UI/TargetFrames`, `FFXIV_UI/PartyFrames`, `FFXIV_UI/JobGauges`, `FFXIV_UI/Locales`, `Media/`).
- **Shared Rendering Layer:** `FFXIV_UI/General/RoundedPanels.lua` and `FFXIV_UI/General/WindowControls.lua` provide unified window chrome, rounded panel surfaces, grain effects, button/tab materials, and theme refreshes.
- **Theme Engine:** Account-wide color themes (Dark, Light, Classic FF, Clear variants) dynamically restyle UI windows and controls without rebuilding protected geometry during combat.
- **Tooltip Hooking & Formatting:** Split across `FFXIV_UI/General/Tooltips/` (Core, Items, Spells, Mounts, Toys, Skills, PetAbility) to intercept and reformat native Blizzard tooltips while preserving native data and safety guards.
- **Combat Safety:** Protected frame manipulations and geometry changes defer during combat (`InCombatLockdown()`) and resume on `PLAYER_REGEN_ENABLED`.

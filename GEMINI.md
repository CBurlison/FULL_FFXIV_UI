# FFXIV_UI Addon Guidelines & Conventions

## Planning & Workflow
- **Feature-by-Feature Planning:** All plans, phases, progress tracking, and design documents must be structured and maintained on a feature-by-feature basis within `.memory_bank/features/<feature-name>/`.
- **Feature-by-Feature Code Reviews:** Code reviews going forward must be performed on a feature-by-feature basis, with their results and reports recorded in their respective feature folders (`.memory_bank/features/<feature-name>/code-reviews/`) and filenames prefixed with the ISO date (`YYYY-MM-DD-<review-name>.md`).
- **HTML Prototyping Workflow:** Mandatory prerequisite step for all new UI elements or visual changes. Elements must be mocked up in HTML/CSS first and explicitly approved by the user before any implementation in WoW Lua/XML.

## Addon Standards
- **Dual Compatibility:** Codebase must maintain seamless compatibility with both WoW Retail and WoW Forever (handling API differences gracefully).
- **Combat Lockdown:** Protected frame manipulations and geometry changes must defer during combat (`InCombatLockdown()`) and resume on `PLAYER_REGEN_ENABLED`.
- **Testing:** All features and bug fixes require corresponding automated tests in `tests/`.

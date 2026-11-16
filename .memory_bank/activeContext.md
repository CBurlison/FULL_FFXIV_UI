# Active Context: FFXIV UI

## Current Focus
- Maintaining dual compatibility and support for **both WoW Retail (Patch 12.0.0+) and WoW Forever (Build 16001)** across all agents, instructions, specifications, skills, and code modules.
- Enforcing the mandatory workflow: all UI elements and visual changes must first be mocked up in HTML and approved by the user before implementation in the WoW UI (`FFXIV_UI`).
- Transitioning the project to Spec-Driven Development (SDD) using a centralized `.memory_bank/features/` structure.

## Recent Changes
- Updated all agents, instructions, specs (`SPECIFICATIONS.md`, `README.md`, Memory Bank), and skills to explicitly support both WoW Retail and WoW Forever.
- Created dedicated Forever counterpart skills (`wow-api-housing-forever`, `wow-api-weekly-rewards-forever`, `wow-api-professions-forever`, `wow-api-reputation-forever`, `wow-api-transmog-forever`) and labeled Retail-only features accordingly.
- Established core Memory Bank tracking files (`productBrief.md`, `activeContext.md`, `systemPatterns.md`, `techContext.md`, `progress.md`).

## Next Steps
- Continue feature development and refactoring strictly following SDD methodology.
- Maintain memory bank synchronization for any future UI changes or new add-on features.

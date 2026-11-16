# FFXIV UI Specifications (Memory Bank)

Detailed layout, rendering, native-integration, persistence, and compatibility behavior for FFXIV UI, designed to operate seamlessly across **both WoW Retail (Patch 12.0.0+) and WoW Forever (Build 16001)**. All specifications are organized into the centralized **Memory Bank** (`.memory_bank/features/`) following Spec-Driven Development (SDD) methodology. For a feature overview and user-facing settings, see [README](README.md).

## Workflow Mandate: HTML UI Prototyping & Media Accuracy

**Mandatory Rule:** Before any UI element or visual component is implemented in World of Warcraft Lua/XML (`FFXIV_UI`), it must first be mocked up in HTML/CSS/JS and explicitly approved by the user. 
**Media Accuracy Mandate:** All mockups must be 100% accurate to in-game visuals, utilizing the actual media assets (`FFXIV_UI/Media/Textures...`, `FFXIV_UI/Media/Fonts...`) for constructing frames, backgrounds, borders, tabs, combo boxes, and UI elements. Only after approval will we proceed to implementation in the WoW UI add-on.

## Memory Bank & Specification Modules

1. **Memory Bank Core Files**
   - [Product Brief](.memory_bank/features/productBrief.md)
   - [Active Context](.memory_bank/features/activeContext.md)
   - [System Patterns](.memory_bank/features/systemPatterns.md)
   - [Tech Context](.memory_bank/features/techContext.md)
   - [Progress](.memory_bank/features/progress.md)

2. **Window & Tooltip Rendering**
   - [Shared Window and Tooltip Rendering](.memory_bank/features/shared-rendering.md)
   - [Tooltip Layouts](.memory_bank/features/tooltip-layouts.md)

3. **UI Controls & Elements**
   - [Control Skinning Inventory & Gaps](.memory_bank/features/control-skinning/plan.md) (skills: `.github/skills/ffxiv-control-skinning`, `ffxiv-skin-*`)
   - [Combo Boxes](.memory_bank/features/combo-boxes.md)
   - [Menu Bar](.memory_bank/features/menu-bar.md)
   - [Controller Hotbars and Cast Labels](.memory_bank/features/controller-hotbars.md)

4. **Panels & Windows**
   - [Crafting Log & Profession Ability Artwork](.memory_bank/features/crafting-log.md)
   - [Specializations and Talents](.memory_bank/features/specializations-and-talents/specializations-and-talents.md)
   - [Spellbook (Forever)](.memory_bank/features/spellbook.md)
   - [Friends and Social](.memory_bank/features/friends-and-social.md)
   - [Chat Log](.memory_bank/features/chat-log.md)
   - [Character Screen (Forever & Retail)](.memory_bank/features/character-screen.md)
   - [Inventory (Forever)](.memory_bank/features/inventory.md)

5. **Quests & Minimap**
   - [Quest Tracker](.memory_bank/features/quest-tracker.md)
   - [World-Map Quest Icons](.memory_bank/features/world-map-quest-icons.md)
   - [Experimental Minimap Turn-In Icons](.memory_bank/features/experimental-minimap-turn-in-icons.md)

6. **Unit Frames & Combat**
   - [Focus, Target-of-Target, and Pet Auras](.memory_bank/features/focus-target-of-target-pet-auras.md)
   - [Enemy List](.memory_bank/features/enemy-list.md)
   - [Player, Party, Raid, and Pet Frames](.memory_bank/features/unit-frames.md)
   - [Target Frames and Combo-Point Gauges](.memory_bank/features/target-frames.md)
   - [Experience Bar](.memory_bank/features/experience-bar/experience-bar.md)
   - [Player Frames](.memory_bank/features/player-frames/player-frames.md)

7. **Layout & Management**
   - [Anchor Profiles](.memory_bank/features/anchor-profiles.md)

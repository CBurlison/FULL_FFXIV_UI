# Target Classification Icons

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- This feature displays classification icons (Normal, Elite, Rare, Boss, Rare Boss) to the left of the FFXIV_UI target frame based on `UnitClassification("target")`.
- **Icons Added:** Normal-Icon, Elite-Icon, Rare-Icon, Boss-Icon, Rare-Boss-Icon in `FFXIV_UI/Media/Textures/TargetFrame/`.
- **Placement:** Positioned to the left of the target frame / LLabel area.
- **Mapping:**
- `worldboss` / `boss` -> Boss-Icon
- `rareelite` -> Rare-Boss-Icon
- `elite` -> Elite-Icon

### Core Requirements 2
- `rare` -> Rare-Icon
- `normal` / `trivial` / `minus` / default -> Normal-Icon (or displayed appropriately per classification).
- Display enemy classification icons (Normal, Elite, Rare, Boss, Rare Boss) to the left of the FFXIV_UI target frame.
- 1.
- HTML Mockup in `.memory_bank/features/target-classification-icons/mockup.html`.
- 2.
- Update `FFXIV_UI/TargetFrames/TargetFrame_HP.lua` to manage classification icon texture and visibility based on `UnitClassification("target")`.
- 3.
- Add unit tests in `tests/TargetFrame.lua` (or equivalent test file).
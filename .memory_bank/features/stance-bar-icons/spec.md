# Stance Bar Icons Feature

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Updates stance action bar button icon sizing to match pet action bar icons (32px icon size, 44px highlight size, 30px backdrop size, 32px normal size).
- Stance action bar buttons (`StanceButton1` through `StanceButton12`) previously fell back to the `General` button style (46px icon size).
- This feature introduces dedicated `skinStyles.Stance` mirroring `skinStyles.Pet`, scaling stance action bar icon size down to 32px to match pet action bar buttons.
- Defined `skinStyles.Stance` in `FFXIV_UI/General/ButtonSkins.lua` with:
- `iconSize = 32`
- `highlightSize = 44`
- `backdropSize = 30`

### Core Requirements 2
- `normalSize = 32`
- Maintained vertical centering offset (`1px`) for stance/pet button icons.
- Added automated unit test coverage in `tests/ButtonSkins.lua`.
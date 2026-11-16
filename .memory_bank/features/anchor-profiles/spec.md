# Anchor Profiles Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Anchor profiles are shared across characters, with each character remembering its selected profile.
- The Anchor Profile dropdown in FFXIV UI settings can select, add, rename, or delete a profile.
- Add Profile offers From Default and Copy Current; copied layouts are independent.
- When no Default profile exists, the first character to load the addon supplies its saved anchor positions, scale, and dimensions if they differ from the standard layout.
- Otherwise, Default uses the standard layout.
- Subsequent characters do not overwrite Default.
- Existing per-character sound settings are unchanged.

### Core Requirements 2
- Default cannot be renamed or deleted.
- Deleting another profile returns its users to Default.
- Reset All Anchors resets the selected profile to the standard layout.
- Layout changes are saved automatically; switching and resetting profiles are blocked during combat.
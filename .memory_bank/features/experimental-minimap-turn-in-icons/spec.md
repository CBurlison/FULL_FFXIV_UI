# Experimental Minimap Turn-In Icons Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
**Minimap turn-in icons (experimental)** in FFXIV UI settings enables a per-character, off-by-default overlay prototype. It samples minimap tooltips in small batches while stationary and out of combat, then draws Complete artwork where a tooltip exactly matches a unique, completed quest title in your current log. Super-tracked quests use blue artwork. Unknown names, duplicate quest titles, ambiguous separated matches, available quests, unfinished quests, and the minimap's outer edge are left unchanged. It does not replace or hide native markers, so native artwork may remain visible underneath the transparent icon.
- Confirmed icons follow player movement, minimap rotation, and zoom using estimated map coordinates and the minimap's view radius.
- Stationary rescans preserve confirmed positions within one scan-grid step (8 minimap pixels) to prevent sampling jitter after stopping; larger corrections still update the position.
- Scanning pauses during movement or minimap mouseover without hiding known in-range icons, preserving native tooltips; new markers are discovered when stationary.
- Icons hide outside the inner minimap area, on another map, during combat, or when position data is unavailable/restricted.
- Clients without usable map-position data retain the stationary-only behavior.
- It is non-clickable and does not alter tracking, native marker scale, or quest selection.

### Core Requirements 2
- Alignment, scan cost, controller soft-cursor behavior, and coexistence with NodeSight require in-game testing; disable the setting if tooltips or controller cursor behavior are affected.
- This is a limited visual experiment, not full minimap quest-icon replacement.
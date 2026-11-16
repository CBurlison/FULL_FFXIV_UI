# Menu Bar Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- LegacyMicroButton uses the supplied Legacy artwork.
- Native grid child padding is four pixels horizontally and vertically instead of the original negative overlap; the native container relayout updates its bounds.
- This applies to horizontal, vertical, and stacked arrangements without changing button dimensions or manually overriding individual anchors.
- The native micro-menu buttons use the supplied red-and-gold PNG artwork, with 128x128 alpha-enabled TGA copies for in-game loading.
- Original PNGs remain unchanged.
- Character maps to Character, Professions to CraftingLog, Spellbook to Actions, combined Player Spells/Talents to Talents, Achievements to Achievements, Quest Log to Journal, Guild to FreeCompany, Group Finder to DutyFinder, Collections to Collection, Store to Shop, and Game Menu to GameMenu.
- The optional native Help button also uses GameMenu.

### Core Requirements 2
- Unmapped native buttons remain unchanged.
- Each replacement icon has a runtime circular mask and a separate antialiased, beveled gold ring.
- The mask and ring are 128x128; the icon diameter uses the smaller native button dimension without changing its rectangular click target, anchors, order, scale, visibility, or bar orientation.
- The bar's native rectangular BorderArt/BackgroundArt and each mapped button's original icon, portrait, tabard, state art, and rectangular flash-content artwork are suppressed through native refreshes.
- Native notification overlays remain visible.
- Native alert timing is retained, with FlashBorder using an additive circular gold ring.
- Hover brightens the icon/ring, pressed state darkens them, and disabled icons desaturate while retaining native button alpha and disabled tooltips.
- Native click handlers, key bindings, tooltip scripts, notifications, controller behavior, and Edit Mode positioning remain in place.
- Installation defers in combat and retries after native addon loading; state visuals update without changing protected button geometry or adding a permanent update loop.
- Red-and-gold menu artwork does not follow the character/inventory window theme.

### Core Requirements 3
- Mocked regressions cover mappings, state changes, native-art suppression, actions/tooltips, alert/notification preservation, late loading, and idempotency; live visual alignment and controller navigation still require in-game confirmation.
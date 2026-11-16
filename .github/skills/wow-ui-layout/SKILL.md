---
name: wow-ui-layout
description: Complete reference and standard for FFXIV_UI layout and design of UI elements, specifically establishing the Retail Character Menu tab design as the universal standard for tabs across the UI, and detailing combo boxes / dropdowns (such as those in Reputation and Currency headers and the Retail Spellbook search/filter). Use when creating or updating tabs, combo boxes, dropdowns, or panel layouts in FFXIV_UI.
---

# FFXIV_UI Layout and Component Standards

This skill defines the canonical UI layout and design standards for FFXIV_UI, ensuring consistent FFXIV-styled aesthetics across all addon panels, menus, and widgets.

For implementation helpers, coverage status and gaps per control type, see [ffxiv-control-skinning](../ffxiv-control-skinning/SKILL.md).

## 1. Tab Design & Layout Standard

The tab design established at the top of the Retail Character Menu (`CharacterFrame`) serves as the universal standard for all tabs across the addon UI.

### Visual Architecture
- **Texture Assets**: Located under `Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Tab-{State}-{Theme}.tga` (e.g., `Tab-Selected-Dark.tga`, `Tab-Inactive-Dark.tga`).
- **States**: `Selected` (active tab) and `Inactive` (unselected tab). Theme-aware (`Dark`, etc.).
- **Native Art Removal**: Hide all native tab art (`Icon`, `Background`, `SelectedTexture`, `HighlightTexture`, `TabGlow`) and hook `Show`/`SetShown` to keep them hidden.
- **Sizing & Spacing**:
  - Height: `30` pixels.
  - Width: Dynamically calculated based on parent frame width minus padding, divided by the number of visible tabs, factoring in negative tab spacing (`TAB_SPACING = -6`).
- **Typography**:
  - Font: Axis Regular (`Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf`), size `10`.
  - Color: `tabText` palette token (`Color(label, "SetTextColor", "tabText")`).
  - Alignment: Centered horizontally (`SetJustifyH("CENTER")`) and vertically (`SetJustifyV("MIDDLE")`).
- **Behavioral Hooking**:
  - Hook `SetChecked` to update tab visual state (`UpdateTab`).
  - Hook `OnEnter`, `OnLeave`, and `OnHide` to handle hover brightness (`1.12` multiplier when hovered) and reset states cleanly.

---

## 2. Combo Boxes & Dropdowns Standard

Combo boxes and dropdowns must follow the Dark character-menu visual language. This applies across headers (such as Retail Reputation and Currency screens) and filter controls (such as next to the search box in the Retail Spellbook and Professions).

### Value Field (Opener) Appearance
- **Textures**: `ComboBox-Closed-Dark.tga` and `ComboBox-Open-Dark.tga` from `Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\`.
- **Dimensions**:
  - Height: `24` pixels.
  - Endcap widths: `20` pixels (left) and `12` pixels (right).
  - Center: Stretched horizontally between endcaps.
- **Label & Padding**:
  - Left padding: `24` pixels.
  - Right padding: `12` pixels.
  - Text alignment: Left-aligned (`SetJustifyH("LEFT")`), no word wrap.
- **Typography**:
  - Font: Axis Regular, size `11`.
  - Color: `text` palette token when enabled, `muted` when disabled.
  - Disabled state: Artwork and text dimmed to `0.5` alpha.

### Popup Menu Appearance
- **Background Texture**: `ComboBox-Menu-Dark.tga`.
- **Border**: Shaded rounded border preserving extracted shading (do not substitute generic border colors).
- **Nine-Slice Sizing**: Stretch the middle of the nine-slice material (6-pixel edge pieces), not the corners.
- **Menu Font**: Axis Regular at size `11` (`FFXIVUICharacterComboBoxMenuFont`).
- **Integration**: Shared via `StyleComboBoxMenu` (`FFXIV_UI/General/WindowControls.lua`) while preserving native menu sizing, screen-edge placement, scrolling, submenu arrows, enabled/disabled states, localization, and keyboard/controller navigation.

### Specific Component Applications
1. **Retail Reputation Screen**: Header filter dropdown (`ReputationFrame.FilterDropdown`).
2. **Retail Currency / Token Screen**: Header filter dropdown (`TokenFrame.FilterDropdown` / `CurrencyFrame.FilterDropdown`).
3. **Retail Spellbook**: Filter/settings dropdown positioned next to the search box (`SpellbookFrame` search filter).

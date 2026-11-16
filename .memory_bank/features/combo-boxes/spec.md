# Combo Boxes Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Combo boxes use the Dark character-menu visual language, including when their opener is an icon rather than a value field.
- Use the extracted gray `ComboBox-Menu-Dark.tga` background, its shaded rounded border, and Axis menu text at 11 pixels.
- Stretch the middle of the nine-slice material, not the corners; the popup currently uses six-pixel edge pieces.
- Retain native menu sizing, screen-edge placement, scrolling, submenu arrows, enabled/disabled states, localization, and keyboard/controller navigation.
- The source references are [Dark-Combo-Box-1-Closed.png](Media/References/Dark-Combo-Box-1-Closed.png) and [Dark-Combo-Box-1-Open.png](Media/References/Dark-Combo-Box-1-Open.png).
- [ExtractDarkComboBox.py](../../../Media/Textures/Panels/ExtractDarkComboBox.py) exports text-free header states and the menu background as PNG previews and client-ready TGA textures.
- The left menu border uses a mirrored clean right border to avoid copying icons or discoloration from behind the reference menu.

### Core Requirements 2
- Preserve extracted shading rather than drawing a substitute border or recoloring it with the theme's generic border color.
- Both radio and checkbox-type entries use the same selection artwork instead of native circle, square, dot, or checkmark indicators.
- Hide the indicator regions and move the native entry label to an eight-pixel left inset.
- Do not change the entry's selection data or responder.
- Radio entries represent a single choice. Only the selected entry in its native radio group has a selection highlight; picking another entry transfers the highlight according to the native menu rules.
- Checkbox entries represent independent choices. Every checked choice has its own highlight; turning one off removes only that highlight. Multiple entries may be highlighted at once. A selected multi-select entry is not converted into a radio choice, and its native refresh/keep-open behavior is retained.
- The selected-row highlight is semi-transparent gold, rounded on the left, and fades horizontally to fully transparent at the right. Current color is RGB (0.82, 0.69, 0.40), fading from alpha 0.26 to 0. The left cap follows half the row height; the normal row height is at least 20 pixels. The background must not obscure the label.
- An unselected entry has no persistent selection band. Native pointer/controller hover feedback is separate from the selected state. Selection must remain correct after a menu refresh, reopening, or external setting change.
- Disabled entries remain disabled and retain native disabled presentation. Preserve dividers, titles, submenu arrows, and any non-selection content; do not generate fake choices or counts to resemble the reference.
- This is the required presentation for new multi-select combo boxes.

### Core Requirements 3
- The spellbook settings filter and the character-panel filters share [StyleComboBoxMenu](../../../FFXIV_UI/General/WindowControls.lua), rather than maintaining separate popup implementations.
- The spellbook filter keeps its small hamburger button next to the search field.
- The button is 24x24, using three 12x2 horizontal lines spaced four pixels apart.
- It does not display the selected option, add a second disclosure arrow, or expand into a labeled value field.
- Opening it displays the shared popup; "Hide Passives" is highlighted when enabled and unhighlighted when disabled.
- Its existing setting callback, spell-list refresh, availability conditions, and tooltip remain native.
- The reputation and currency filters use a rounded value field displaying the native localized current selection.
- The disclosure arrow is on the left, not in a separate gold-arrow button on the right.
- Use `ComboBox-Closed-Dark.tga` and `ComboBox-Open-Dark.tga` for the closed/open states; preserve the fixed endcaps while stretching the text-free center.
- Current field height is 24 pixels, endcap widths are 20 and 12 pixels, and the label has 24 pixels of left padding and 12 pixels of right padding.

### Core Requirements 4
- Text is left-aligned Axis at 11 pixels.
- Disabled artwork is dimmed to half alpha.
- The field remains aligned at the right of the character page's header/banner.
- The currency transfer-log button sits eight pixels to its left and is vertically centered against it.
- Opening the field changes its header state and opens the same popup used by the hamburger variant; closing it restores the closed artwork.
- The native selection string remains the source of the displayed value.
- Apply the shared skin per dropdown, not by globally replacing Blizzard menu functions.
- Use native menu-description initializers for entry styling so pooled rows are restyled after refreshes.
- Use `AttachTexture` for compositor-managed artwork and `SetFontObject` with an addon-owned font object for menu text; accessing or calling `SetFont` on compositor-owned labels is forbidden.
- Do not retain texture/font-string hooks on pooled menu entries after release.

### Core Requirements 5
- Check addon-local texture loading directly with `SetTexture`; a positive `GetFileIDFromPath` result is not required for addon files.
- If the required artwork or menu capability is unavailable, leave the native control usable.
- Repeated layout/menu setup must not duplicate callbacks, entry initializers, or persistent artwork.
- Validate independent checkbox toggling, radio selection, opener state, native callbacks, disabled states, menu refreshes, and opening/closing on the client build being tested.
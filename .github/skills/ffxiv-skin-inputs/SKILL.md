---
name: ffxiv-skin-inputs
description: "Skin WoW input controls (EditBox, SearchBoxTemplate, InputBoxTemplate, chat edit box, CheckButton/UICheckButtonTemplate checkboxes, radio buttons, Slider/MinimalSliderTemplate) in the FFXIV_UI style. Use when converting, fixing or auditing text fields, search boxes, checkboxes, radios or sliders in Retail or Forever."
---

# Skinning input controls

Shared rules and the full helper API: [ffxiv-control-skinning](../ffxiv-control-skinning/SKILL.md).

## Edit and search boxes: `StyleWindowControl(panel, box, "Search")`

- **Art:** `Panels/Search-fill-<Material>.tga`, a 3-slice with 4 px caps (`FFXIV_Control4*Template`). Fill only, no border, `tab` token. The path is built at runtime by `UpdateControlMaterial`.
- **Text:** the box text is Axis 12 in `text`. `Instructions` or `PromptText` are Axis 11–12 in `muted`.
- **Search icon:** keep the native `searchIcon` when hiding textures (Spellbook passes it as an exception to `HideTextures`).
- **Focus (decided, not implemented):** a shining outline while focused, none when unfocused. References: `Media/References/Search-Box/Search-Box-{Focused,Unfocused}-Dark.png`. Drive it from `OnEditFocusGained`/`OnEditFocusLost`.
- **Disabled (decided, not implemented):** FFXIV has none. Draw the box darker.

```lua
local function Input(box)
    if not box or controls[box] then return end
    controls[box] = true
    HideTextures(box)                               -- keep box.searchIcon if present
    addonEnv.StyleWindowControl(Panel(box), box, "Search")
    Text(box, 12, "text")
    Text(box.PromptText or box.Instructions, 12, "muted")
end
```

Talents expects a public `addonEnv.StyleEditBox(box)`, which does not exist (GAP-10). Promote this pattern into WindowControls.lua.

**Applied to:**
- Social: `FilterBar.SearchBar`, `WhoFrameEditBox`, the broadcast `EditBox`
- Spellbook: `SearchBox`
- Professions: `RecipeList.SearchBox`, `CreateMultipleInputBox`, `MinimizedSearchBox`
- Inventory: `BagItemSearchBox`, with an extra `inset` backdrop

**Chat edit box:** a separate implementation, `FFXIV_ChatInputBackgroundTemplate` (`surface.tga` + `border.tga`, insets 12/12/4/4) in [Chat.lua](../../../FFXIV_UI/General/Chat.lua#L166-L180). Keep it separate; chat has its own approved look.

## Checkboxes and radio buttons: checkbox implemented (GAP-03), radio helper implemented, not yet applied

- Popup-menu radio and checkbox entries are styled through `StyleComboBoxMenu` (gold gradient band).
- **Checkbox (implemented):** `addonEnv.StyleCheckButton(button)` in `FFXIV_UI/General/WindowControls.lua`. Native art is hidden with the alpha guard (`Skin.HideTextures`). The box is a 16x16 texture swapped on `GetChecked()`: `FFXIV_UI/Media/Textures/Checkboxes/Unchecked.tga` and `Checked.tga`, extracted from the `Media/References/Checkboxes/*-Enlarged-Dark.png` captures (cropped to the box, transparent background, generated with Pillow). Disabled dims the texture and label via vertex color and label alpha. Hooks `SetChecked`, `OnClick`, and `OnEnable`/`OnDisable`. Applied to Professions `TrackRecipeCheckbox` and `AllocateBestQualityCheckbox`. In-game look is not yet verified.
- **Not yet applied:** the options panel checkboxes in `FFXIV_UI/General/FFXIV_UI_Menu.lua` (`InterfaceOptionsCheckButtonTemplate`); they belong to the options rework.
- **Radio (helper implemented):** `addonEnv.StyleRadioButton(button)` in `FFXIV_UI/General/WindowControls.lua` mirrors the checkbox. It swaps `FFXIV_UI/Media/Textures/Radio-Buttons/Unselected.tga` and `Selected.tga` (extracted from `Media/References/Radio-Buttons/*-Enlarged-Dark.png`, transparent background) on `GetChecked()`. Disabled dims via vertex color and label alpha. No UI target is wired yet; apply it to a radio control after a mock-up is approved. In-game look is not yet verified.
- Never use `SetNormalTexture(nil)`: that is visible to secure code on protected buttons.

## Sliders: **not implemented** (GAP-02)

No addon surface skins a slider today.

**Standard (decided 2026-11-07; theme-dependent; Dark reference `Media/References/Value-Slider/Value-Slider-Dark.png`):**
- **Track:** a dark-grey pill. Its outline is darker on the upper half and lighter on the lower half.
- **Fill:** a semi-dark green pill, slightly smaller than the track, running from the left edge to the thumb.
- **Thumb:** a metallic circle that looks like a freshly lathed round metal bar face.
- **Value:** shown as text to the right of the bar.

When implementing:
- Retail uses `MinimalSliderWithSteppersTemplate`: child `Slider`, `Back`/`Forward` steppers, `MinText`/`MaxText`.
- Forever and legacy use `OptionsSliderTemplate`: `Low`/`High`/`Text` regions and `GetThumbTexture()`.
- Verify the template for each client before writing code.
- Reuse `ProgressBars`' `Bar-Pill.tga` for the track and `StyleCircularArrowButton` for the steppers. Draw the thumb with `slider:SetThumbTexture(...)` only on non-protected sliders.

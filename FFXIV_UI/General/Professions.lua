local addonName, ns = ...
local addonEnv = ns
local Themes = addonEnv.Themes
local Skin = addonEnv.Skin
local styled, tabs, lists = {}, {}, {}
local pending, layingOut, paintingTheme = false, false, false
local watcher = CreateFrame("Frame")
local Install, Layout, CraftingLayout
local PROFESSION_TEXTURES = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Professions\\"
local professionIcons = {
    [164] = "Blacksmith", [165] = "Leatherworker", [171] = "Alchemist",
    [182] = "Herbalism", [185] = "Cooking", [186] = "Mining", [197] = "Tailoring",
    [202] = "Engineer", [333] = "Enchanting", [356] = "Fishing", [129] = "FirstAid",
}
local iconBindings = {}
local rankBars = {}
local RANK_FILL_ALPHA = 0.22

local function Luminance(color)
    local total = 0
    for index, weight in ipairs({0.2126, 0.7152, 0.0722}) do
        local value = color[index]
        total = total + weight * (value <= 0.04045 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4)
    end
    return total
end

local function RankText(bar)
    if not bar.Rank then return end
    local palette = Themes.GetPalette()
    local filled = {}
    for index = 1, 3 do
        filled[index] = palette.accent[index] * RANK_FILL_ALPHA + palette.inset[index] * (1 - RANK_FILL_ALPHA)
    end
    local backgrounds = {Luminance(palette.inset), Luminance(filled)}
    local color = {unpack(palette.text)}
    local target = Luminance(color) < 0.5 and 0 or 1
    -- A label spans both fill and well; keep at least 4.5:1 contrast against both.
    for step = 1, 16 do
        local foreground, readable = Luminance(color), true
        for _, background in ipairs(backgrounds) do
            if (math.max(foreground, background) + 0.05) / (math.min(foreground, background) + 0.05) < 4.5 then
                readable = false
            end
        end
        if readable then break end
        for index = 1, 3 do color[index] = color[index] * 0.85 + target * 0.15 end
    end
    bar.Rank.Text:SetTextColor(unpack(color))
end

local function ProfessionIcon(icon, skillLine, overview)
    if not icon then return end
    local binding = iconBindings[icon]
    if not binding then
        binding = {native = icon:GetTexture()}
        iconBindings[icon] = binding
        hooksecurefunc(icon, "SetTexture", function(_, texture)
            if binding.painting then return end
            binding.native = texture
            if binding.path then
                binding.painting = true
                icon:SetTexture(binding.path)
                binding.painting = false
            end
        end)
    end
    local name = professionIcons[skillLine]
    binding.path = overview and PROFESSION_TEXTURES .. "Professions.tga"
        or name and PROFESSION_TEXTURES .. name .. ".tga" or nil
    binding.painting = true
    icon:SetTexture(binding.path or binding.native)
    binding.painting = false
    if binding.path then icon:SetTexCoord(0, 1, 0, 1) end
end

local Hide, HideTextures, Color, Text, Fonts, Panel = Skin.Hide, Skin.HideTextures, Skin.Color, Skin.Text,
    Skin.Fonts, Skin.Panel

local function Rounded(owner)
    local panel = Panel(owner)
    addonEnv.RoundWindow(panel)
    return panel
end

local function Divider(owner, vertical)
    local line = owner:CreateTexture(nil, "BACKGROUND")
    addonEnv.Themes.StyleDivider(line, owner, "BACKGROUND", 0, vertical)
    return line
end

local function Control(button, style)
    if not button then return end
    addonEnv.StyleButton(button, style, button.FFXIVUICounterLabel)
end

local function Arrow(button, direction)
    addonEnv.StyleFlatArrowButton(button, direction, 22, 0)
end

local function Slot(button, icon)
    if not button or not icon then return end
    if button.OutlineMask then icon:RemoveMaskTexture(button.OutlineMask) end
    -- Reagent counts carry native availability colors, not the generic slot's white.
    local countColor = button.Count and {button.Count:GetTextColor()}
    paintingTheme = true
    addonEnv.ApplyButtonSkin(button, {Icon = icon}, "Equipment")
    if countColor then button.Count:SetTextColor(unpack(countColor)) end
    paintingTheme = false
    for _, key in ipairs({"SlotBackground", "IconTextureOverlay", "CropFrame"}) do Hide(button[key]) end
    local state = addonEnv.GetButtonSkinState(button)
    if state.backdrop then Color(state.backdrop, "SetVertexColor", "inset") end
    if state.normal then Color(state.normal, "SetVertexColor", "border") end
end

local function RankBar(bar)
    if not bar or styled[bar] then return end
    styled[bar] = true
    rankBars[bar] = true
    bar:SetHeight(22)
    for _, key in ipairs({"Background", "Border", "Fill", "Flare"}) do Hide(bar[key]) end
    local panel = Panel(bar, "inset")
    local fill = panel:CreateTexture(nil, "ARTWORK")
    fill:SetColorTexture(1, 1, 1, 1)
    fill:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -2)
    fill:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 2, 2)
    Color(fill, "SetVertexColor", "accent")
    fill:SetAlpha(RANK_FILL_ALPHA)
    if bar.Rank then
        bar.Rank:ClearAllPoints()
        bar.Rank:SetAllPoints(bar)
        local label = bar.Rank.Text
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", bar.Rank, "TOPLEFT", 4, -2)
        label:SetPoint("BOTTOMRIGHT", bar.Rank, "BOTTOMRIGHT", -4, 2)
        label:SetJustifyH("CENTER")
        label:SetJustifyV("MIDDLE")
        label:SetWordWrap(false)
    end
    local function Update()
        fill:SetWidth(math.max(1, (bar:GetWidth() - 4) * (bar.ratio or 0)))
        fill:SetShown((bar.ratio or 0) > 0)
        if bar.Rank then
            Text(bar.Rank.Text, "text", 12)
            RankText(bar)
        end
    end
    bar.FFXIVUIRankFill = fill
    hooksecurefunc(bar, "Update", Update)
    bar:HookScript("OnSizeChanged", Update)
    bar:HookScript("OnShow", Update)
    Update()
end

local function RecipeRow(row)
    if InCombatLockdown() then pending = true; return end
    if row.ButtonText and row.CollapseButton then
        addonEnv.StyleComboCollapsibleHeader(row)
        if row.RankBar then
            Color(row.RankBar, "SetStatusBarColor", "accent")
            Fonts(row.RankBar)
        end
        return
    end
    if not styled[row] then
        styled[row] = true
        for _, key in ipairs({"SelectedOverlay", "HighlightOverlay"}) do
            local texture = row[key]
            if texture then
                texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                texture:SetTexCoord(0, 1, 0, 1)
                texture:ClearAllPoints()
                texture:SetAllPoints(row)
                Color(texture, "SetVertexColor", "accent")
                texture:SetAlpha(key == "SelectedOverlay" and 0.25 or 0.12)
            end
        end
        if row.SetLabelFontColors then
            hooksecurefunc(row, "SetLabelFontColors", function()
                Text(row.Label, row.learned and "text" or "muted", 12)
                Text(row.Count, "muted", 12)
            end)
        end
    end
    Text(row.Label, row.learned == false and "muted" or "text", 12)
    Text(row.Count, "muted", 12)
end

local function RecipeList(list)
    if not list then return end
    if not styled[list] then
        styled[list] = true
        Hide(list.Background)
        Hide(list.BackgroundNineSlice)
        local search = CreateFrame("Frame", nil, list)
        search:SetPoint("TOPLEFT", list, "TOPLEFT")
        search:SetPoint("TOPRIGHT", list, "TOPRIGHT")
        search:SetHeight(64)
        search.FFXIVUIBackground = Rounded(search)
        local title = search:CreateFontString(nil, "OVERLAY")
        Text(title, "muted", 16)
        title:SetText("Recipe Search")
        title:SetPoint("TOPLEFT", search, "TOPLEFT", 10, -6)
        title:SetPoint("TOPRIGHT", search, "TOPRIGHT", -10, -6)
        title:SetJustifyH("LEFT")
        list.FFXIVUISearchPanel = search
        Control(list.SearchBox, "Search")
        Control(list.FilterDropdown, "Dropdown")
        Fonts(list, "muted")
    end
    if list.ScrollBox then
        if not lists[list.ScrollBox] then
            lists[list.ScrollBox] = true
            ScrollUtil.AddInitializedFrameCallback(list.ScrollBox, function(_, row) RecipeRow(row) end, watcher)
        end
        list.ScrollBox:ForEachFrame(RecipeRow)
    end
end

local reagentText = {}
local function ReagentText(label)
    if not label or reagentText[label] then return end
    local r, g, b = label:GetTextColor()
    local function Update(_, red, green, blue)
        if reagentText[label].painting or paintingTheme or Skin.painting then return end
        local token = red > 0.7 and green < 0.4 and blue < 0.4 and "detrimental" or "text"
        reagentText[label].painting = true
        Text(label, token, 12)
        reagentText[label].painting = false
    end
    reagentText[label] = {}
    hooksecurefunc(label, "SetTextColor", Update)
    Update(label, r, g, b)
end

local function SaveGeometry(frame)
    local saved = {width = frame:GetWidth(), height = frame:GetHeight(), points = {}}
    for index = 1, frame:GetNumPoints() do saved.points[index] = {frame:GetPoint(index)} end
    return saved
end

local function RestoreGeometry(frame, saved)
    frame:ClearAllPoints()
    for _, point in ipairs(saved.points) do frame:SetPoint(unpack(point)) end
    frame:SetSize(saved.width, saved.height)
end

local function ReagentColumns(slot)
    if not slot.GetReagentSlotSchematic or not Professions or not Professions.GetReagentName
        or not ProfessionsUtil or not ProfessionsUtil.GetReagentQuantityInPossession then return end
    local schematic = slot:GetReagentSlotSchematic()
    if not schematic or not schematic.required or not schematic.reagents or #schematic.reagents ~= 1 then return end
    local reagent = schematic.reagents[1]
    local name = Professions.GetReagentName(reagent)
    if issecretvalue and issecretvalue(name) then return end
    if not name then return end
    local transaction = slot.GetTransaction and slot:GetTransaction()
    local inventoryOnly = transaction and transaction:ShouldUseCharacterInventoryOnly() or false
    local required = schematic.GetQuantityRequired and schematic:GetQuantityRequired(reagent) or schematic.quantityRequired
    local owned = ProfessionsUtil.GetReagentQuantityInPossession(reagent, inventoryOnly)
    if issecretvalue and (issecretvalue(required) or issecretvalue(owned) or issecretvalue(name)) then return end
    if required == nil or owned == nil then return end
    if not slot.FFXIVUIRequired then
        slot.FFXIVUIRequired = slot:CreateFontString(nil, "OVERLAY")
        slot.FFXIVUIOwned = slot:CreateFontString(nil, "OVERLAY")
        slot.FFXIVUIReagentDivider = Divider(slot, true)
    end
    Text(slot.FFXIVUIRequired, "accent", 18)
    Text(slot.FFXIVUIOwned, owned < required and "detrimental" or "text", 14)
    slot.FFXIVUIRequired:SetText(required)
    slot.FFXIVUIOwned:SetText(owned)
    slot.Name:SetText(name)
    slot.Button.Count:SetAlpha(0)
    slot.FFXIVUIRequired:SetShown(true)
    slot.FFXIVUIOwned:SetShown(true)
    slot.FFXIVUIReagentDivider:SetShown(true)
    slot.FFXIVUIColumns = true
end

local function Reagent(slot)
    local function RestoreNative()
        local saved = slot.FFXIVUINativeReagentGeometry
        if saved then
            RestoreGeometry(slot.Button, saved.button)
            RestoreGeometry(slot.Name, saved.name)
        end
    end
    local function UpdateName()
        slot.FFXIVUIColumns = false
        if slot.FFXIVUIRequired then
            slot.FFXIVUIRequired:Hide()
            slot.FFXIVUIOwned:Hide()
            slot.FFXIVUIReagentDivider:Hide()
            slot.Button.Count:SetAlpha(1)
        end
        if not slot.nameText or not slot.Name:IsShown() then RestoreNative(); return end
        if slot.continuableContainer and slot.continuableContainer:AreAnyLoadsOutstanding() then return end
        local r, g, b = slot:GetNameColor():GetRGB()
        local token = r > 0.7 and g < 0.4 and b < 0.4 and "detrimental"
            or math.max(r, g, b) < 0.7 and "muted" or "text"
        slot.Name:SetText(slot.nameText)
        Text(slot.Name, token, 12)
        ReagentColumns(slot)
        if not slot.FFXIVUIColumns then RestoreNative() end
    end
    if not styled[slot] then
        styled[slot] = true
        slot.FFXIVUINativeReagentGeometry = {button = SaveGeometry(slot.Button), name = SaveGeometry(slot.Name)}
        hooksecurefunc(slot, "Update", UpdateName)
    end
    UpdateName()
    Slot(slot.Button, slot.Button.Icon)
    ReagentText(slot.Button.Count)
    local button = slot.Button
    if button.InputOverlay and not button.FFXIVUIRequiredAddIcon then
        local add = button:CreateTexture(nil, "OVERLAY")
        add:SetAtlas("itemupgrade_greenplusicon")
        add:SetSize(26, 26)
        add:SetPoint("CENTER", button, "CENTER")
        button.FFXIVUIRequiredAddIcon = add
        local function UpdateAdd() add:SetShown(button.showLargeAddIcon and not button.locked) end
        hooksecurefunc(button, "UpdateOverlay", UpdateAdd)
        hooksecurefunc(button, "SetModifyingRequired", UpdateAdd)
        UpdateAdd()
    end
end

local function Schematic(form)
    if not form then return end
    if not styled[form] then
        styled[form] = true
        HideTextures(form)
        Hide(form.NineSlice)
        if form.GetChildren then
            for _, child in ipairs({form:GetChildren()}) do
                if child.NineSlice and child:GetObjectType() == "Frame" then Hide(child.NineSlice) end
            end
        end
        local header = CreateFrame("Frame", nil, form)
        header:SetPoint("TOPLEFT", form, "TOPLEFT")
        header:SetPoint("TOPRIGHT", form, "TOPRIGHT")
        header:SetHeight(76)
        header.FFXIVUIBackground = Rounded(header)
        form.FFXIVUIRecipeHeader = header
        for _, method in ipairs({"Init", "Refresh", "UpdateOutputItem", "UpdateRecipeDescription"}) do
            if form[method] then hooksecurefunc(form, method, function() Install() end) end
        end
    end
    Fonts(form)
    Text(form.OutputText, "text", 17)
    Text(form.Cooldown, "detrimental")
    Text(form.MinimizedCooldown, "detrimental")
    if form.OutputIcon then
        local border = form.OutputIcon.IconBorder
        if border then
            if not styled[border] then
                styled[border] = true
                hooksecurefunc(border, "SetAtlas", function(self, atlas)
                    if atlas ~= "Professions-Slot-Frame" then self:SetAtlas("Professions-Slot-Frame") end
                end)
            end
            border:SetAtlas("Professions-Slot-Frame")
            border:ClearAllPoints()
            border:SetAllPoints(form.OutputIcon.Icon)
        end
        Hide(form.OutputIcon.CountShadow)
    end
    Slot(form.OutputIcon, form.OutputIcon and form.OutputIcon.Icon)
    local header = form.FFXIVUIRecipeHeader
    header:SetFrameLevel(math.max(0, form:GetFrameLevel() - 1))
    header.FFXIVUIBackground:SetFrameLevel(header:GetFrameLevel())
    if form.OutputIcon then
        form.OutputIcon:ClearAllPoints()
        form.OutputIcon:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -12)
        form.OutputIcon:SetSize(48, 48)
    end
    if form.OutputText then
        form.OutputText:ClearAllPoints()
        form.OutputText:SetPoint("TOPLEFT", header, "TOPLEFT", 72, -14)
        form.OutputText:SetPoint("TOPRIGHT", header, "TOPRIGHT", -40, -14)
        form.OutputText:SetWordWrap(true)
        form.OutputText:SetHeight(52)
    end
    if form.FavoriteButton then
        form.FavoriteButton:ClearAllPoints()
        form.FavoriteButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -10, -10)
        form.FavoriteButton:SetSize(24, 24)
    end
    local requirements = form.RequiredTools
    local hasRequirements = requirements and requirements:IsShown()
    if hasRequirements then
        requirements:ClearAllPoints()
        requirements:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 12, -12)
        requirements:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", -12, -12)
        requirements:SetWordWrap(true)
        requirements:SetHeight(math.max(1, requirements:GetStringHeight()))
    end
    if form.Description then
        local anchor = hasRequirements and requirements or header
        form.Description:ClearAllPoints()
        form.Description:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", hasRequirements and 0 or 12, hasRequirements and -8 or -12)
        form.Description:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", hasRequirements and 0 or -12, hasRequirements and -8 or -12)
        form.Description:SetWordWrap(true)
        Text(form.Description, "text", 12)
        form.Description:SetHeight(math.max(1, form.Description:GetStringHeight()))
    end
    for _, key in ipairs({"TrackRecipeCheckbox", "AllocateBestQualityCheckbox"}) do
        local checkbox = form[key]
        if checkbox then
            Text(checkbox.Text or checkbox.text, "text", 12)
            addonEnv.StyleCheckButton(checkbox)
        end
    end
    for _, key in ipairs({"Reagents", "OptionalReagents", "FinishingReagents"}) do
        local container = form[key]
        if container then Fonts(container, "accent") end
    end
    if form.reagentSlotPool then
        local nextRow = 0
        if form.Reagents and form.Description then
            form.Reagents:ClearAllPoints()
            form.Reagents:SetPoint("TOPLEFT", form.Description, "BOTTOMLEFT", 0, -16)
        end
        for slot in form.reagentSlotPool:EnumerateActive() do
            Reagent(slot)
            if slot.FFXIVUIColumns then
                slot:ClearAllPoints()
                slot:SetPoint("TOPLEFT", form.Reagents or form.Description or header, "TOPLEFT", -4, -28 - nextRow * 46)
                slot:SetSize(math.max(240, form:GetWidth() - 16), 44)
                slot.Button:ClearAllPoints()
                slot.Button:SetPoint("LEFT", slot, "LEFT", 32, 0)
                slot.Button:SetSize(36, 36)
                slot.FFXIVUIRequired:ClearAllPoints()
                slot.FFXIVUIRequired:SetPoint("LEFT", slot, "LEFT")
                slot.FFXIVUIRequired:SetSize(26, 32)
                slot.FFXIVUIRequired:SetJustifyH("RIGHT")
                slot.FFXIVUIOwned:ClearAllPoints()
                slot.FFXIVUIOwned:SetPoint("LEFT", slot, "LEFT", 76, 0)
                slot.FFXIVUIOwned:SetSize(48, 32)
                slot.FFXIVUIOwned:SetJustifyH("CENTER")
                local divider = slot.FFXIVUIReagentDivider
                divider:ClearAllPoints()
                divider:SetPoint("TOPLEFT", slot, "TOPLEFT", 132, -6)
                divider:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 132, 6)
                divider:SetWidth(1)
                slot.Name:ClearAllPoints()
                slot.Name:SetPoint("LEFT", slot, "LEFT", 144, 0)
                slot.Name:SetPoint("RIGHT", slot, "RIGHT", -4, 0)
                slot.Name:SetHeight(40)
                slot.Name:SetWordWrap(true)
                nextRow = nextRow + 1
            end
        end
        if nextRow > 0 and form.Reagents then
            form.Reagents:SetSize(math.max(240, form:GetWidth() - 24), nextRow * 46 + 28)
        end
    end
end

local function Book(book)
    if not book or not book.ProfessionsContentFrame then return end
    if not styled[book] then
        styled[book] = true
        HideTextures(book)
        if book.Update then hooksecurefunc(book, "Update", function() Install() end) end
    end
    for _, key in ipairs({"PrimaryProfession1", "PrimaryProfession2", "SecondaryProfession1",
        "SecondaryProfession2", "SecondaryProfession3"}) do
        local card = book.ProfessionsContentFrame[key]
        if card then
            if not styled[card] then
                styled[card] = true
                HideTextures(card)
                card.FFXIVUIOverviewPanel = Rounded(card)
            end
            Fonts(card)
            Text(card.ProfessionName, "accent", 14)
            Text(card.missingText, "muted", 12)
            RankBar(card.StatusBar)
            if card.StatusBar and card.UnlearnButton then
                card.UnlearnButton:ClearAllPoints()
                card.UnlearnButton:SetPoint("LEFT", card.StatusBar, "RIGHT", 4, 0)
                card.UnlearnButton:SetSize(22, 22)
                if card.GamepadUnlearnButton then
                    card.GamepadUnlearnButton:ClearAllPoints()
                    card.GamepadUnlearnButton:SetPoint("LEFT", card.UnlearnButton, "RIGHT", 3, 0)
                end
            end
            ProfessionIcon(card.icon, card.skillLine)
            for _, button in ipairs(card.spellButtons or {}) do
                Slot(button, button.IconTexture)
                Text(button.spellString, "text", 12)
                Text(button.subSpellString, "muted", 10)
            end
        end
    end
    local content = book.ProfessionsContentFrame
    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", book, "TOPLEFT", 12, -48)
    content:SetPoint("BOTTOMRIGHT", book, "BOTTOMRIGHT", -12, 12)
    local width = ProfessionsFrame:GetWidth() - 24
    local top = 0
    for index, key in ipairs({"PrimaryProfession1", "PrimaryProfession2", "SecondaryProfession1",
        "SecondaryProfession2", "SecondaryProfession3"}) do
        local card = content[key]
        if card then
            local primary = index <= 2
            local cardWidth = primary and width or (width - 16) / 3
            local height = primary and math.max(118, 72 + #(card.spellButtons or {}) * 44) or 152
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", content, "TOPLEFT", primary and 0 or (index - 3) * (cardWidth + 8), -top)
            card:SetSize(cardWidth, height)
            if card.ProfessionName then
                card.ProfessionName:ClearAllPoints()
                card.ProfessionName:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
            end
            if card.StatusBar then
                card.StatusBar:ClearAllPoints()
                card.StatusBar:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -34)
                card.StatusBar:SetWidth(cardWidth - (card.UnlearnButton and card.UnlearnButton:IsShown() and 54 or 24))
            end
            for spellIndex, spell in ipairs(card.spellButtons or {}) do
                spell:ClearAllPoints()
                spell:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -64 - (spellIndex - 1) * 44)
                spell:SetSize(36, 36)
                if spell.spellString then
                    spell.spellString:ClearAllPoints()
                    spell.spellString:SetPoint("TOPLEFT", spell, "TOPRIGHT", 8, -2)
                    spell.spellString:SetPoint("RIGHT", card, "RIGHT", -12, 0)
                    spell.spellString:SetWordWrap(true)
                end
                if spell.subSpellString and spell.spellString then
                    spell.subSpellString:ClearAllPoints()
                    spell.subSpellString:SetPoint("TOPLEFT", spell.spellString, "BOTTOMLEFT", 0, -2)
                    spell.subSpellString:SetPoint("RIGHT", card, "RIGHT", -12, 0)
                    spell.subSpellString:SetWordWrap(true)
                end
            end
            if primary then top = top + height + 8 end
        end
    end
end

local function Tab(tab)
    if tabs[tab] then return end
    for _, region in ipairs({tab:GetRegions()}) do
        if region:GetObjectType() == "Texture" and region ~= tab.Icon and region ~= tab.TabGlow then Hide(region) end
    end
    local art = addonEnv.CreateControlArtwork(Panel(tab), "Square")
    local checked = ProfessionsFrame.selectedGamepadTabID == tab:GetID()
    local hovered = false
    if tab.TabGlow then
        tab.TabGlow:SetTexCoord(0, 1, 0, 1)
    end
    local function Update(_, value)
        if value ~= nil then checked = value end
        local palette = Themes.GetPalette()
        addonEnv.UpdateControlMaterial(art, "Square")
        for _, texture in ipairs(art.fill) do
            texture:SetDesaturated(true)
            texture:SetVertexColor(unpack((checked or hovered) and palette.selected or palette.tab))
        end
        for _, texture in ipairs(art.border) do
            texture:SetDesaturated(true)
            texture:SetVertexColor(unpack(checked and palette.accent or palette.border))
        end
        if tab.TabGlow then
            local color = palette.tab
            tab.TabGlow:SetTexture(art.fill[1]:GetTexture())
            tab.TabGlow:SetDesaturated(true)
            tab.TabGlow:SetVertexColor(color[1], color[2], color[3], 0.15)
        end
    end
    tabs[tab] = Update
    hooksecurefunc(tab, "SetChecked", Update)
    tab:HookScript("OnEnter", function() hovered = true; Update() end)
    local function Reset() hovered = false; Update() end
    tab:HookScript("OnLeave", Reset)
    tab:HookScript("OnHide", Reset)
    Update()
end

CraftingLayout = function(page)
    if not page or not page.RecipeList or not page.RecipeList.FFXIVUISearchPanel then return end
    local list, form = page.RecipeList, page.SchematicForm
    if not page.FFXIVUIRankDivider then
        page.FFXIVUIRankDivider = Divider(page)
        page.FFXIVUIRankDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -76)
        page.FFXIVUIRankDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -76)
        page.FFXIVUIRankDivider:SetHeight(1)
        page.FFXIVUICenterDivider = Divider(page, true)
        page.FFXIVUICenterDivider:SetPoint("TOP", page.FFXIVUIRankDivider, "BOTTOM")
        page.FFXIVUICenterDivider:SetPoint("LEFT", list, "RIGHT", 8, 0)
        page.FFXIVUICenterDivider:SetPoint("BOTTOM", page, "BOTTOM", 0, 40)
        page.FFXIVUICenterDivider:SetWidth(1)
    end
    local width = ProfessionsFrame:GetWidth()
    local listWidth = (width - 40) * 0.43
    if page.RankBar then
        page.RankBar:ClearAllPoints()
        page.RankBar:SetPoint("TOPLEFT", page, "TOPLEFT", 110, -42)
        -- Leave room on the right for the top-right window buttons.
        page.RankBar:SetWidth(math.max(1, width - 110 - 140))
    end
    if page.TutorialButton then
        page.TutorialButton:ClearAllPoints()
        page.TutorialButton:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -42)
        page.TutorialButton:SetSize(22, 22)
    end
    if page.LinkButton then
        page.LinkButton:ClearAllPoints()
        page.LinkButton:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -42)
        page.LinkButton:SetSize(24, 24)
    end
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -86)
    list:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 12, 40)
    list:SetWidth(listWidth)
    local search = list.FFXIVUISearchPanel
    search:SetFrameLevel(math.max(0, list.SearchBox:GetFrameLevel() - 1))
    search.FFXIVUIBackground:SetFrameLevel(search:GetFrameLevel())
    list.SearchBox:ClearAllPoints()
    list.SearchBox:SetPoint("TOPLEFT", search, "TOPLEFT", 10, -34)
    list.SearchBox:SetPoint("TOPRIGHT", search, "TOPRIGHT", -10, -34)
    list.SearchBox:SetHeight(22)
    if list.FilterDropdown then
        list.FilterDropdown:ClearAllPoints()
        list.FilterDropdown:SetPoint("TOPRIGHT", search, "BOTTOMRIGHT", -2, -6)
        list.FilterDropdown:SetSize(88, 24)
    end
    if list.ScrollBox then
        list.ScrollBox:ClearAllPoints()
        list.ScrollBox:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -36)
        list.ScrollBox:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -16, 4)
    end
    ns.StyleListScrollBar(list)
    if form then
        form:ClearAllPoints()
        form:SetPoint("TOPLEFT", list, "TOPRIGHT", 16, 0)
        form:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -12, 40)
        form:SetWidth(width - 40 - listWidth)
    end
end

Layout = function()
    local frame = ProfessionsFrame
    if not frame or layingOut then return end
    if InCombatLockdown() then pending = true; return end
    layingOut = true
    local ordered = {}
    if frame.ProfessionsOverviewTab then ordered[#ordered + 1] = frame.ProfessionsOverviewTab end
    for _, tab in ipairs(frame.rightProfessionTabs or {}) do
        if tab:IsShown() then ordered[#ordered + 1] = tab end
    end
    local offset = #ordered > 0 and 48 or 0
    frame.FFXIVUIProfessionBaseHeight = frame.FFXIVUIProfessionBaseHeight or frame:GetHeight()
    frame:SetHeight(frame.FFXIVUIProfessionBaseHeight + offset)
    for index, tab in ipairs(ordered) do
        Tab(tab)
        tab:ClearAllPoints()
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 38 + (index - 1) * 43, -34)
        tab:SetSize(40, 40)
        tab.Icon:ClearAllPoints()
        tab.Icon:SetPoint("CENTER", tab, "CENTER")
        tab.Icon:SetSize(32, 32)
        if tab.Mask then
            tab.Icon:RemoveMaskTexture(tab.Mask)
        end
        ProfessionIcon(tab.Icon, tab.skillLine, tab == frame.ProfessionsOverviewTab)
        if tab.TabGlow then tab.TabGlow:ClearAllPoints(); tab.TabGlow:SetAllPoints(tab) end
    end
    for _, page in ipairs(frame.Pages or {}) do
        page:ClearAllPoints()
        page:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -offset)
        page:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    end
    if frame.TabIndicators then
        local indicators = frame.TabIndicators
        indicators.isVertical = false
        indicators:UpdateTabVisibility()
        for index, tab in ipairs(indicators.visibleTabs) do
            if tab:GetID() == frame.selectedGamepadTabID then
                indicators:SetCurrentIndex(index)
                break
            end
        end
        indicators:UpdateTabIndicators()
    end
    CraftingLayout(frame.CraftingPage)
    layingOut = false
end

Install = function()
    if not ProfessionsFrame then return end
    if InCombatLockdown() then pending = true; return end
    pending = false
    local frame = ProfessionsFrame
    if not styled[frame] then
        styled[frame] = true
        HideTextures(frame)
        Hide(frame.NineSlice)
        Hide(frame.PortraitContainer)
        Hide(frame.PortraitFrame)
        addonEnv.RoundWindow(Panel(frame), true)
        local title = frame.TitleContainer and frame.TitleContainer.TitleText
        Text(title, "text", 18)
        if title then
            title:ClearAllPoints()
            title:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -6)
            title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -6)
            title:SetHeight(22)
            title:SetJustifyH("LEFT")
        end
        local close = frame.CloseButton
        if close then
            HideTextures(close)
            close:ClearAllPoints()
            close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
            close:SetSize(24, 24)
            addonEnv.SkinWindowClose(close)
        end
        frame:HookScript("OnShow", Install)
        for _, method in ipairs({"RefreshRightTabs", "RightTabSelected", "SelectBookPage", "Update"}) do
            if frame[method] then hooksecurefunc(frame, method, Install) end
        end
        frame:HookScript("OnSizeChanged", Layout)
    end
    Layout()
    Book(frame.BookPage)
    if frame.TabSystem and frame.TabSystem.tabs then
        for _, tab in ipairs(frame.TabSystem.tabs) do Control(tab) end
    end
    local page = frame.CraftingPage
    if page then
        if not styled[page] then
            styled[page] = true
            HideTextures(page)
            for _, method in ipairs({"Refresh", "SchematicPostInit"}) do
                if page[method] then hooksecurefunc(page, method, Install) end
            end
        end
        RankBar(page.RankBar)
        RecipeList(page.RecipeList)
        CraftingLayout(page)
        Schematic(page.SchematicForm)
        Control(page.CreateButton)
        Control(page.CreateAllButton)
        Control(page.ViewGuildCraftersButton)
        Control(page.CreateMultipleInputBox, "Search")
        local spinner = page.CreateMultipleInputBox
        if spinner then
            Arrow(spinner.DecrementButton, "Left")
            Arrow(spinner.IncrementButton, "Right")
        end
        Control(page.MinimizedSearchBox, "Search")
    end
end

Themes.Register(function()
    paintingTheme = true
    for _, update in pairs(tabs) do update() end
    for bar in pairs(rankBars) do RankText(bar) end
    paintingTheme = false
end)
local handlers = {
    ADDON_LOADED = Install,
    PLAYER_LOGIN = Install,
    PLAYER_REGEN_ENABLED = function() if pending then Install() end end,
}
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(_, event)
    local handler = handlers[event]
    if handler then handler() end
end)
Install()

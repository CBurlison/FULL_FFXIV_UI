local addonName, ns = ...
local addonEnv = ns or {}
local Themes = addonEnv.Themes or { GetPalette = function() return { inset = {0,0,0}, text = {1,1,1},
          accent = {1,1,1} } end }
local Skin = addonEnv.Skin
local styled = {}
local art = setmetatable({}, {__mode = "k"})
local function ArtOf(frame)
    art[frame] = art[frame] or {}
    return art[frame]
end
local pending = false
local DeferOutside = addonEnv.DeferOutsideSecureUpdate
local watcher = CreateFrame("Frame")
local Install
local Hide, HideTextures = Skin.Hide, Skin.HideTextures

local function UpdateCloseButton(host)
    if not host or not host.CloseButton then return false end
    local active
    if host.SpellBookFrame and host.SpellBookFrame:IsShown() then return false end
    for _, key in ipairs({"TalentsFrame", "SpecFrame"}) do
        local frame = host[key]
        if frame and ArtOf(frame).header and frame:IsShown() then active = frame; break end
    end
    if not active then
        for _, child in ipairs({host:GetChildren()}) do
            if ArtOf(child).header and child:IsShown() then active = child; break end
        end
    end
    if not active and ArtOf(host).header and host:IsShown() then active = host end
    if not active then return false end
    if InCombatLockdown() then pending = true; return true end
    local close = host.CloseButton
    addonEnv.SkinWindowClose(close)
    for _, region in ipairs({close:GetRegions()}) do
        if region:GetObjectType() == "Texture" and region ~= close.FFXIVUICloseIcon then Hide(region) end
    end
    close.FFXIVUICloseIcon:Show()
    close:ClearAllPoints()
    close:SetSize(24, 24)
    close:SetPoint("RIGHT", ArtOf(active).header, "RIGHT", -2, 0)
    return true
end

local TANK_ICON = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\Tank.tga"
local HEALER_ICON = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\Healer.tga"
local DPS_ICON = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\DPS.tga"

local function StyleRoleIcon(texture)
    if not texture or ArtOf(texture).roleSkinned then return end
    ArtOf(texture).roleSkinned = true
    local function Update(self, atlasOrTexture)
        local state = ArtOf(self)
        if state.updatingRole then return end
        state.updatingRole = true
        local name = tostring(atlasOrTexture or ""):lower()
        if name:find("tank") then
            self:SetTexture(TANK_ICON)
        elseif name:find("heal") then
            self:SetTexture(HEALER_ICON)
        elseif name:find("dps") or name:find("damage") or name:find("damager") then
            self:SetTexture(DPS_ICON)
        end
        state.updatingRole = false
    end
    -- Blizzard sets role art inside its own update chain, so the swap runs after that chain returns.
    local function Queue(self, value)
        if ArtOf(self).updatingRole then return end
        C_Timer.After(0, function() Update(self, value) end)
    end
    hooksecurefunc(texture, "SetAtlas", Queue)
    hooksecurefunc(texture, "SetTexture", Queue)
    if texture.GetAtlas then Update(texture, texture:GetAtlas())
    elseif texture.GetTexture then Update(texture, texture:GetTexture()) end
end

local TAB_WIDTH, TAB_HEIGHT, TAB_SPACING = 130, 30, -6
local TOP_ART_KEYS = {"Bg", "Background", "TopBackground", "TopBG", "TopTileStreaks", "TopTexture"}

local function FindChildren(owner, match, depth, found, skip)
    found = found or {}
    if depth <= 0 or type(owner.GetChildren) ~= "function" then return found end
    for _, child in ipairs({owner:GetChildren()}) do
        if not (skip and skip(child)) then
            if match(child) then found[#found + 1] = child end
            FindChildren(child, match, depth - 1, found, skip)
        end
    end
    return found
end

local function TextOf(region)
    if not region then return "" end
    local label = region
    if region.GetObjectType and region:GetObjectType() ~= "FontString" then
        label = region.GetFontString and region:GetFontString() or region.Text
    end
    if not label then return "" end
    local text = label.GetText and label:GetText() or label.text
    return tostring(text or "")
end

-- Blizzard's oversized header art sits on the frame or a direct child, anchored to the top edge.
local function IsTopBanner(texture, frame)
    if not texture.GetPoint or texture:GetObjectType() ~= "Texture" then return false end
    local point = texture:GetPoint(1)
    return (point == "TOP" or point == "TOPLEFT" or point == "TOPRIGHT")
        and texture:GetHeight() >= 64 and texture:GetWidth() >= frame:GetWidth() * 0.8
end

-- Only children are scanned: the frame's own regions include the FFXIV_UI panel, which must stay visible.
local function HideForeverTopArt(frame)
    for _, key in ipairs(TOP_ART_KEYS) do
        local region = frame[key]
        if region and region.GetObjectType then
            if region:GetObjectType() == "Texture" then Hide(region) else Skin.HideArt(region, true) end
        end
    end
    for _, owner in ipairs(FindChildren(frame, function() return true end, 2)) do
        for _, region in ipairs({owner:GetRegions()}) do
            if IsTopBanner(region, frame) then Hide(region) end
        end
    end
end

local function HideTabArt(owner, depth)
    for _, region in ipairs({owner:GetRegions()}) do
        if region:GetObjectType() == "Texture" then Skin.KeepHidden(region) end
    end
    if depth <= 0 or type(owner.GetChildren) ~= "function" then return end
    for _, child in ipairs({owner:GetChildren()}) do HideTabArt(child, depth - 1) end
end

local function UpdateForeverTab(tab)
    local state = ArtOf(tab)
    addonEnv.UpdateExtractedTabArtwork(state.tabArt, state.selected == true)
    Skin.Text(state.label, state.selected and "text" or "tabText", 12)
end

local function SetForeverTabSelected(tabs, selectedTab)
    for _, tab in ipairs(tabs) do
        local selected = tab == selectedTab
        if tab.SetChecked then tab:SetChecked(selected) end
        ArtOf(tab).selected = selected
        UpdateForeverTab(tab)
    end
end

local function SkinForeverTab(tab, tabs)
    local state = ArtOf(tab)
    if state.skinnedTab then return end
    state.skinnedTab = true
    for _, key in ipairs({"Left", "Middle", "Right", "Background", "SelectedTexture", "HighlightTexture",
        "NormalTexture", "PushedTexture", "LeftActive", "MiddleActive", "RightActive", "LeftHighlight",
        "MiddleHighlight", "RightHighlight", "SquareBackground", "SquareBackgroundActive",
        "SquareBackgroundActiveGlow"}) do
        if tab[key] and tab[key].GetObjectType then Skin.KeepHidden(tab[key]) end
    end
    HideTabArt(tab, 2)
    local native = tab.GetFontString and tab:GetFontString() or tab.Text
    Skin.Hide(native)
    state.tabArt = addonEnv.CreateExtractedTabArtwork(tab)
    local label = tab:CreateFontString(nil, "OVERLAY")
    Skin.Font(label, 12)
    label:SetPoint("CENTER", tab, "CENTER", 0, 0)
    label:SetText(TextOf(native))
    state.label = label
    tab:HookScript("OnClick", function(self)
        DeferOutside(self, "select", function() SetForeverTabSelected(tabs, self) end)
    end)
    UpdateForeverTab(tab)
end

local function IsButton(child)
    local objType = child.GetObjectType and child:GetObjectType()
    return objType == "Button" or objType == "CheckButton"
end

-- The Primary/Secondary buttons have no text in the Forever dump, so they are found as the wide two-button row.
local function FindForeverTabs(frame)
    local tabs = {}
    for _, label in ipairs({"Primary", "Secondary"}) do
        local button = frame[label] or frame[label .. "Button"]
        if not button then
            button = FindChildren(frame, function(child)
                return IsButton(child) and TextOf(child) == label
            end, 3)[1]
        end
        if button then tabs[#tabs + 1] = button end
    end
    if #tabs == 2 then return tabs end
    for _, child in ipairs({frame:GetChildren()}) do
        local buttons = {child:GetChildren()}
        if #buttons == 2 and IsButton(buttons[1]) and IsButton(buttons[2]) and child:GetWidth() > 250 then
            return buttons
        end
    end
    return {}
end

local function LayoutForeverTabs(frame, tabs)
    ArtOf(frame).layingOut = true
    for index, tab in ipairs(tabs) do
        tab:ClearAllPoints()
        tab:SetSize(TAB_WIDTH, TAB_HEIGHT)
        if index == 1 then
            tab:SetPoint("TOPLEFT", ArtOf(frame).header, "BOTTOMLEFT", 8, -10)
        else
            tab:SetPoint("LEFT", tabs[index - 1], "RIGHT", TAB_SPACING, 0)
        end
    end
    ArtOf(frame).layingOut = false
end

-- Blizzard re-anchors the spec tabs after actions such as Apply Changes, so any move is undone by re-running the layout.
local function GuardForeverTabAnchors(frame, tab)
    local state = ArtOf(tab)
    if state.anchorHooked then return end
    state.anchorHooked = true
    local function Restore()
        if ArtOf(frame).layingOut then return end
        DeferOutside(tab, "anchor", function()
            if ArtOf(frame).layingOut then return end
            if InCombatLockdown() then pending = true; return end
            LayoutForeverTabs(frame, ArtOf(frame).tabs)
        end)
    end
    hooksecurefunc(tab, "SetPoint", Restore)
    hooksecurefunc(tab, "ClearAllPoints", Restore)
end

local function StyleForeverLayout(frame, host)
    HideForeverTopArt(frame)

    local tabs = FindForeverTabs(frame)
    for _, tab in ipairs(tabs) do SkinForeverTab(tab, tabs) end
    ArtOf(frame).tabs = tabs
    for _, tab in ipairs(tabs) do GuardForeverTabAnchors(frame, tab) end
    LayoutForeverTabs(frame, tabs)
    for _, tab in ipairs(tabs) do
        local state = ArtOf(tab)
        if state.selected == nil then state.selected = tab.GetChecked and tab:GetChecked() == true or false end
        UpdateForeverTab(tab)
    end

    local search = frame.SearchBox or FindChildren(frame, function(child)
        return child.GetObjectType and child:GetObjectType() == "EditBox"
    end, 3)[1]
    local currency = frame.ClassCurrencyDisplay
    local opener = frame.SearchOptionsDropdown
    local apply = (host and host.ApplyButton) or FindChildren(frame, function(child)
        return child.GetObjectType and child:GetObjectType() == "Button" and TextOf(child) == "Apply Changes"
    end, 3)[1]

    if currency and currency.Border then Hide(currency.Border) end

    -- The opener is placed first: Blizzard anchors it to the search box, so the search box must not anchor back to it until that link is cleared.
    if opener then
        opener:ClearAllPoints()
        if apply then
            opener:SetPoint("RIGHT", apply, "LEFT", -12, 0)
        else
            opener:SetPoint("TOPRIGHT", ArtOf(frame).header, "BOTTOMRIGHT", -8, -10)
        end
        opener:SetSize(24, 24)
        if opener.Arrow then Hide(opener.Arrow) end
        addonEnv.StyleCircularArrowButton(opener, "down")
        addonEnv.StyleComboBoxMenu(opener)
    end

    -- Search sits on the Apply Changes row, left of the options button.
    if search then
        search:ClearAllPoints()
        if opener then
            search:SetPoint("RIGHT", opener, "LEFT", -6, 0)
        elseif apply then
            search:SetPoint("RIGHT", apply, "LEFT", -12, 0)
        elseif currency then
            search:SetPoint("BOTTOMRIGHT", currency, "TOPRIGHT", -30, 8)
        else
            search:SetPoint("TOPRIGHT", ArtOf(frame).header, "BOTTOMRIGHT", -8, -10)
        end
        search:SetSize(180, 24)
        addonEnv.StyleEditBox(search)
    end

    if apply then addonEnv.StyleButton(apply) end
end

-- The host's art is shared with Spellbook, so it is hidden only while the Talents view is shown.
local overflowRegions = {}
local heldAlpha = {}

-- Blizzard re-applies alpha when a panel animates in, so the hold is enforced through a SetAlpha hook.
local function Hold(region, active)
    local state = ArtOf(region)
    if active then
        if state.savedAlpha == nil then state.savedAlpha = region:GetAlpha() end
        heldAlpha[region] = true
        region:SetAlpha(0)
    else
        heldAlpha[region] = nil
        if state.savedAlpha ~= nil then
            region:SetAlpha(state.savedAlpha)
            state.savedAlpha = nil
        end
    end
    if not state.alphaHooked then
        state.alphaHooked = true
        hooksecurefunc(region, "SetAlpha", function(self, alpha)
            if heldAlpha[self] and alpha ~= 0 then
                DeferOutside(self, "alpha", function()
                    if heldAlpha[self] then self:SetAlpha(0) end
                end)
            end
        end)
    end
end

-- Textures in the host tree that rise above the Talents window's top edge are the stretched band.
local function IsOverflowing(region, frameTop)
    if not region.GetTop or region:GetObjectType() ~= "Texture" then return false end
    local top = region:GetTop()
    return top ~= nil and frameTop ~= nil and top > frameTop + 2
end

local function ApplyHostTopArt(host, frame, talentsActive)
    if not host then return end
    local function Apply(region)
        if talentsActive then Hold(region, true) elseif heldAlpha[region] then Hold(region, false) end
    end
    for _, key in ipairs(TOP_ART_KEYS) do
        local region = host[key]
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then Apply(region) end
    end
    local global = _G["PlayerSpellsFrameBg"]
    if global and global.GetObjectType and global:GetObjectType() == "Texture" then Apply(global) end
    for _, region in ipairs({host:GetRegions()}) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then Apply(region) end
    end
    if talentsActive then
        local frameTop = frame and frame.GetTop and frame:GetTop()
        -- Spellbook's own window panel and book are full-height overlays that Talents must never hold.
        local spellbookArt = addonEnv.SpellbookFrameArt and addonEnv.SpellbookFrameArt(host)
        local spellbookPanel = spellbookArt and spellbookArt.panel
        local spellbookBook = host.SpellBookFrame
        local function IsSpellbookArt(child)
            return child == spellbookPanel or child == spellbookBook
        end
        for _, owner in ipairs(FindChildren(host, function() return true end, 3, nil, IsSpellbookArt)) do
            if owner ~= frame then
                for _, region in ipairs({owner:GetRegions()}) do
                    if IsOverflowing(region, frameTop) then
                        overflowRegions[region] = true
                        Apply(region)
                    end
                end
            end
        end
    else
        for region in pairs(overflowRegions) do Apply(region) end
        overflowRegions = {}
    end
end

local function StyleSubFrame(frame, forever)
    if not frame then return end
    if styled[frame] then
        if type(styled[frame]) == "function" then styled[frame]() end
        return
    end
    styled[frame] = true
    HideTextures(frame)

    local host = (frame == PlayerTalentFrame or frame == TalentFrame) and frame or frame:GetParent() or frame
    if host and host.NineSlice then Hide(host.NineSlice) end
    if host and host.PortraitContainer then Hide(host.PortraitContainer) end
    if host and host.PortraitFrame then Hide(host.PortraitFrame) end
    if host and host.TitleContainer then Hide(host.TitleContainer) end

    if type(addonEnv.RoundWindow) == "function" then
        addonEnv.RoundWindow(frame, true)
    end

    if not ArtOf(frame).header then
        local header = CreateFrame("Frame", nil, frame, "FFXIV_TalentsHeaderTemplate")
        header:SetFrameLevel(frame:GetFrameLevel() + 2)
        header:EnableMouse(false)

        local label = header:CreateFontString(nil, "OVERLAY", "FFXIV_TalentsHeaderTitleTemplate")
        Skin.Text(label, "text", 16)
        
        local spellsFrame = _G["PlayerSpellsFrame"]
        local titleText = "Talents"
        if spellsFrame and frame == spellsFrame.SpecFrame then
            titleText = "Specializations"
        elseif spellsFrame and frame == spellsFrame.TalentsFrame then
            titleText = "Talents"
        else
            local name = frame.GetName and frame:GetName() or tostring(frame)
            if name:lower():find("spec") then
                titleText = "Specializations"
            else
                titleText = "Talents"
            end
        end
        label:SetText(titleText)
        ArtOf(frame).headerTitle = label

        local divider = header:CreateTexture(nil, "BACKGROUND", "FFXIV_TalentsHeaderDividerTemplate")
        if Themes.StyleDivider then
            Themes.StyleDivider(divider, header)
        else
            divider:SetColorTexture(0.71, 0.61, 0.32, 1)
        end
        ArtOf(frame).header = header
    end

    -- Talent nodes are Buttons too, so only recognised control templates are styled.
    local function Scan(owner)
        if not owner then return end
        if type(owner.GetChildren) == "function" then
            local children = {owner:GetChildren()}
            for _, child in ipairs(children) do
                local objType = child.GetObjectType and child:GetObjectType() or ""
                if objType == "EditBox" then
                    addonEnv.StyleEditBox(child)
                elseif type(child.OnMenuOpened) == "function" and child.Text then
                    addonEnv.StyleComboBox(child)
                elseif type(child.GetMenuDescription) == "function" then
                    addonEnv.StyleComboBoxMenu(child)
                elseif IsButton(child) and child.Left and child.Middle and child.Right and not ArtOf(child).skinnedTab then
                    addonEnv.StyleButton(child)
                end
                Scan(child)
            end
        end
        if type(owner.GetRegions) == "function" then
            for _, region in ipairs({owner:GetRegions()}) do
                if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                    local atlas = region.GetAtlas and region:GetAtlas() or ""
                    local tex = region.GetTexture and tostring(region:GetTexture() or "") or ""
                    if (atlas and atlas:lower():find("role")) or (tex and tex:lower():find("role")) then
                        StyleRoleIcon(region)
                    end
                end
            end
        end
    end
    local isForever = forever == true
    local function Refresh()
        if isForever then
            ApplyHostTopArt(host, frame, frame:IsShown())
            StyleForeverLayout(frame, host)
        end
        Scan(frame)
    end
    Refresh()
    styled[frame] = Refresh
    frame:HookScript("OnShow", function()
        DeferOutside(frame, "show", function()
            if InCombatLockdown() then pending = true else Refresh() end
            UpdateCloseButton(host)
        end)
    end)
    frame:HookScript("OnHide", function()
        DeferOutside(frame, "hide", function()
            if isForever then ApplyHostTopArt(host, frame, frame:IsShown()) end
            UpdateCloseButton(host)
        end)
    end)
end

-- The Forever Talents view is unnamed; it is the child of PlayerSpellsFrame that holds the search EditBox.
local function FindTalentsView(host)
    local function IsEditBox(child) return child.GetObjectType and child:GetObjectType() == "EditBox" end
    for _, child in ipairs({host:GetChildren()}) do
        if #FindChildren(child, IsEditBox, 2) > 0 then return child end
    end
end

local function Install()
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false

    local host = _G["PlayerSpellsFrame"]
    if host then
        local view = host.TalentsFrame or FindTalentsView(host)
        if view then StyleSubFrame(view, true) end
        if host.SpecFrame then StyleSubFrame(host.SpecFrame) end
        UpdateCloseButton(host)
    end

    local foreverFrame = _G["PlayerTalentFrame"] or _G["TalentFrame"]
    if foreverFrame then
        StyleSubFrame(foreverFrame, true)
        UpdateCloseButton(foreverFrame)
    end
end

watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function(_, event)
    if event ~= "PLAYER_REGEN_ENABLED" or pending then
        Install()
    end
end)

addonEnv.TalentsFrameArt = ArtOf
addonEnv.TalentsUI = {
    Install = Install,
    TankIcon = TANK_ICON,
    HealerIcon = HEALER_ICON,
    DpsIcon = DPS_ICON,
    StyleRoleIcon = StyleRoleIcon,
    UpdateCloseButton = UpdateCloseButton,
}

Install()
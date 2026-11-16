local addonName, ns = ...
local addonEnv = ns
local FONT = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf"
local TAB_TEXTURE_ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Tab-"
local HEADER_ICON_ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\"
local EXTRA_HEIGHT, CONTENT_TOP = 46, 66
local STATS_WIDTH, COLUMN_WIDTH = 440, 202
local PAGE_WIDTH = 540
-- Forever detail panels (page key -> detail frame key): each sits right of its page while it is shown
local DETAIL_WIDTH, DETAIL_GAP, DETAIL_RIGHT_PAD = 233, 5, 8
local DETAIL_PANES = {
    ReputationFrame = "ReputationDetailFrame", SkillsFrame = "SkillDetailFrame", PVPRankFrame = "DetailFrame",
    TokenFrame = "DetailFrame",
}
-- Seam sits left of the page edge, away from the detail text; its bottom matches the header divider's 10px inset
local DETAIL_SEAM_INSET, DETAIL_SEAM_BOTTOM_INSET = 5, 10
-- 8px padding to match the right edge, plus the level banner's -1px left offset
local COLLAPSED_PANE_INSET = 9
local desiredWidth
local detailSeam
local layoutCalls, layoutFinished = 0, 0
local TAB_SPACING = -6
local NATIVE_FRAME_WIDTH, NATIVE_STATS_WIDTH, NATIVE_MODEL_WIDTH = 838, 440, 398
local NATIVE_EQUIPMENT_SLOTS = {
    "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot", "CharacterBackSlot",
    "CharacterChestSlot", "CharacterShirtSlot", "CharacterTabardSlot", "CharacterWristSlot",
    "CharacterHandsSlot", "CharacterWaistSlot", "CharacterLegsSlot", "CharacterFeetSlot",
    "CharacterFinger0Slot", "CharacterFinger1Slot", "CharacterTrinket0Slot", "CharacterTrinket1Slot",
    "CharacterMainHandSlot", "CharacterSecondaryHandSlot",
}
local Layout
local installed, pending, layingOut = false, false, false
local nativeShellInstalled = false
local ready, diagnosticDisabled = false, false
local diagnosticResourcesDisabled = false
local layoutReady = false
local skins = {}
local sidebarUpdates = {}
local updatePaneArrow
local ApplyNativeLayout
local UpdateNativeTabSelection
local nativeTabSelectionHooked = false
local pageWidths = setmetatable({}, {__mode = "k"})
local Themes = addonEnv.Themes

-- The character window is an unprotected UI panel, and native code resizes it on every open.
-- Skipping our layout in combat leaves the native geometry visible, so only defer when it is protected.
local function GeometryLocked(frame)
    if not InCombatLockdown() then return false end
    if not frame or not frame.IsProtected then return true end
    return frame:IsProtected() and true or false
end
local colors = {}
local statColors = setmetatable({}, {__mode = "k"})
local statText = setmetatable({}, {__mode = "k"})
local coloringText = false
local coloringValue = false
local navigationHooks = setmetatable({}, {__mode = "k"})
local watcher = CreateFrame("Frame")

function addonEnv.GetCharacterTaintReport()
    if not issecurevariable then return {"issecurevariable is unavailable on this client."} end
    local report = {}
    local function Inspect(owner, label, keys)
        if not owner then return end
        for _, key in ipairs(keys) do
            local secure, source = issecurevariable(owner, key)
            report[#report + 1] = label .. "." .. key .. ": "
                .. (secure and "secure" or "tainted by " .. (source or "unknown"))
        end
    end
    Inspect(_G, "Global", {"CharacterFrame", "PlayerFrame", "ToggleCharacter", "TextStatusBarMixin"})
    Inspect(CharacterFrame, "CharacterFrame", {"activeSubframe", "OnShow", "OnHide", "Show", "Hide"})
    local health = PlayerFrame and PlayerFrame.healthbar or PlayerFrameHealthBar
    if health then
        Inspect(health, "PlayerHealth", {"TextString", "lockShow", "showNumeric", "forceHideText",
            "UpdateTextString", "UpdateTextStringWithValues", "ShowStatusBarText", "HideStatusBarText"})
    else
        report[#report + 1] = "Player health-bar alias unavailable; capture the taint log."
    end
    return report
end

if SlashCmdList then
    SLASH_FFXIVUICHARTAINT1 = "/ffxivchartaint"
    SlashCmdList.FFXIVUICHARTAINT = function(action)
        action = (action or ""):match("^%s*(.-)%s*$"):lower()
        if action == "isolate" or action == "resume" or action == "noresources" then
            FFXIV_UI_DB = FFXIV_UI_DB or {}
            FFXIV_UI_DB.characterSkinDiagnosticDisabled = action == "isolate" or nil
            FFXIV_UI_DB.characterResourcesDiagnosticDisabled = action == "noresources" or nil
            local mode = action == "isolate" and "disabled"
                or action == "noresources" and "enabled without HP/resource displays" or "enabled"
            print("Character skin " .. mode
                .. " for the next session. Log out and restart the client.")
            return
        end
        for _, line in ipairs(addonEnv.GetCharacterTaintReport()) do print(line) end
    end
end

local Skin = addonEnv.Skin
local colors = {}
local function Color(region, method, token)
    colors[region] = colors[region] or {}
    colors[region][method] = token
    Skin.Color(region, method, token)
    if method == "SetTextColor" then region:SetShadowColor(0, 0, 0, 0) end
end

local function Font(region, size, r, g, b)
    if not region then return end
    Skin.Font(region, size)
    if colors[region] then region:SetShadowColor(0, 0, 0, 0) end
    if r then region:SetTextColor(r, g, b) end
end

local function HideArt(owner, keepHidden)
    if keepHidden then
        Skin.HideArt(owner, true)
    else
        Skin.HideArt(owner, false)
    end
end

local function HideNativeFrame(frame)
    if frame then Skin.KeepHidden(frame) end
end

local function Panel(parent, token)
    return Skin.Panel(parent, token or "surface")
end

local function HideSlotFrame(button)
    if button.FFXIVUISlotFrameHidden then return end
    button.FFXIVUISlotFrameHidden = true
    local name = button:GetName()
    local regions = {name and _G[name .. "Frame"]}
    for _, region in ipairs({button:GetRegions()}) do
        if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
            local atlas = region.GetAtlas and region:GetAtlas()
            local _, relativeTo = region:GetPoint(1)
            if (type(atlas) == "string" and atlas:lower():find("slot", 1, true))
                or (relativeTo and relativeTo == regions[1]) then regions[#regions + 1] = region end
        end
    end
    for _, region in pairs(regions) do
        Skin.Hide(region)
    end
end

local function UpdateTab(tab, checked)
    local skin = skins[tab]
    local palette = Themes.GetPalette()
    if checked ~= nil then skin.checked = checked end
    local state = skin.checked and "Selected" or "Inactive"
    local theme = Themes.GetName():gsub(" ", "-")
    local path = TAB_TEXTURE_ROOT .. state .. "-" .. theme .. ".tga"
    local width = skin.checked and 433 or 434
    local coordinates = {39 / 512, 71 / 512, (39 + width - 24) / 512, (39 + width) / 512}
    local brightness = skin.hovered and 1.12 or 1
    for index, texture in ipairs(skin.fill) do
        texture:SetTexture(path)
        texture:SetTexCoord(coordinates[index], coordinates[index + 1], 10 / 64, 53 / 64)
        texture:SetVertexColor(brightness, brightness, brightness, 1)
    end
    skin.label:SetTextColor(unpack(palette.tabText))
end

local function SkinTab(tab, text)
    if skins[tab] then return end
    local nativeLabel = tab.GetFontString and tab:GetFontString() or tab.Text
    text = text or tab.tooltipText or (nativeLabel and nativeLabel.GetText and nativeLabel:GetText())
    if nativeLabel then nativeLabel:Hide() end
    for _, key in ipairs({"Icon", "Background", "SelectedTexture", "HighlightTexture", "TabGlow"}) do
        local region = tab[key]
        if region then
            region:Hide()
            local function KeepHidden(self) if self:IsShown() then self:Hide() end end
            hooksecurefunc(region, "Show", KeepHidden)
            hooksecurefunc(region, "SetShown", KeepHidden)
        end
    end
    local panel = CreateFrame("Frame", nil, tab)
    panel:SetAllPoints(tab)
    panel:SetFrameLevel(tab:GetFrameLevel())
    panel:EnableMouse(false)
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", panel, "LEFT", 18, 0)
    label:SetPoint("RIGHT", panel, "RIGHT", -18, 0)
    label:SetText(text or "")
    label:SetWordWrap(true)
    label:SetMaxLines(2)
    label:SetHeight(28)
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    Font(label, 10)
    Color(label, "SetTextColor", "tabText")
    local art = {fill = {}, border = {}}
    for index, anchor in ipairs({"LEFT", "CENTER", "RIGHT"}) do
        local texture = panel:CreateTexture(nil, "BACKGROUND")
        texture:SetPoint("TOP", panel, "TOP")
        texture:SetPoint("BOTTOM", panel, "BOTTOM")
        if index == 2 then
            texture:SetPoint("LEFT", panel, "LEFT", 23, 0)
            texture:SetPoint("RIGHT", panel, "RIGHT", -17, 0)
        else
            texture:SetPoint(anchor, panel, anchor)
            texture:SetWidth(index == 1 and 23 or 17)
        end
        art.fill[index] = texture
    end
    skins[tab] = {panel = panel, label = label, checked = false, hovered = false, fill = art.fill}
    tab.FFXIVUISkinned = true
    panel.FFXIVUITabArt = art
    if type(tab.SetChecked) == "function" then
        hooksecurefunc(tab, "SetChecked", UpdateTab)
    end
    tab:HookScript("OnEnter", function(self) skins[self].hovered = true; UpdateTab(self) end)
    tab:HookScript("OnLeave", function(self) skins[self].hovered = false; UpdateTab(self) end)
    tab:HookScript("OnHide", function(self) skins[self].hovered = false; UpdateTab(self) end)
end

local function SkinNativeTextTree(root, statWidth)
    local visited = {}
    local function Visit(frame)
        if not frame or visited[frame] then return end
        if frame == root.Resources then return end
        visited[frame] = true
        for _, region in ipairs({frame:GetRegions()}) do
            if region:GetObjectType() == "FontString" then
                Font(region, 10)
                local red, green, blue = region:GetTextColor()
                if red > 0.82 and green > 0.5 and blue < 0.5 then
                    Color(region, "SetTextColor", "accent")
                elseif red > 0.78 and green > 0.72 and blue > 0.62 then
                    Color(region, "SetTextColor", "text")
                end
            end
        end
        if frame.Title then
            if statWidth and frame.SetWidth then frame:SetWidth(statWidth) end
            Font(frame.Title, 12)
            Color(frame.Title, "SetTextColor", "accent")
        end
        if frame.Label and frame.Value then
            if statWidth and frame.SetWidth then frame:SetWidth(statWidth) end
            Font(frame.Label, 10)
            Color(frame.Label, "SetTextColor", "accent")
            Font(frame.Value, 11)
            if frame.Background and not frame.FFXIVUIBackgroundHidden then
                frame.Background:Hide()
                hooksecurefunc(frame.Background, "Show", function(texture) texture:Hide() end)
                hooksecurefunc(frame.Background, "SetShown", function(texture) texture:Hide() end)
                frame.FFXIVUIBackgroundHidden = true
            end
        end
        for _, child in ipairs({frame:GetChildren()}) do Visit(child) end
    end
    Visit(root)
end

local SkinNativeStatHeader

local function LayoutNativeStats(stats)
    if not stats then return end
    local width = NATIVE_STATS_WIDTH - 22
    SkinNativeTextTree(stats, width)
    local itemLevelCategory = stats.ItemLevelCategory
    local itemLevelFrame = stats.ItemLevelFrame
    local attributes = stats.AttributesCategory
    local enhancements = stats.EnhancementsCategory
    if not itemLevelCategory or not itemLevelFrame or not attributes or not enhancements then return end
    if not stats.FFXIVUIItemLevelHeaderHidden then
        HideNativeFrame(itemLevelCategory)
        stats.FFXIVUIItemLevelHeaderHidden = true
    end
    SkinNativeStatHeader(attributes, "Attributes")
    SkinNativeStatHeader(enhancements, "Offensive")
    if itemLevelFrame.Background then itemLevelFrame.Background:Hide() end

    local columnWidth = math.floor((width - 12) / 2)
    local sectionTop = stats.Resources and -82 or -8
    attributes:ClearAllPoints()
    attributes:SetPoint("TOPLEFT", stats, "TOPLEFT", 4, sectionTop)
    attributes:SetSize(columnWidth, 30)
    enhancements:ClearAllPoints()
    enhancements:SetPoint("TOPLEFT", stats, "TOPLEFT", columnWidth + 16, sectionTop)
    enhancements:SetSize(columnWidth, 30)

    if itemLevelFrame.Value and CharacterHandsSlot then
        local model = _G.CharacterModelScene
        if model then
            itemLevelFrame:SetFrameStrata(model:GetFrameStrata())
            itemLevelFrame:SetFrameLevel(model:GetFrameLevel() + 5)
        end
        itemLevelFrame.Value:ClearAllPoints()
        itemLevelFrame.Value:SetWidth(48)
        itemLevelFrame.Value:SetJustifyH("RIGHT")
        Font(itemLevelFrame.Value, 16)
        if colors[itemLevelFrame.Value] then colors[itemLevelFrame.Value].SetTextColor = nil end
        itemLevelFrame.Value:SetTextColor(0.45, 0.85, 0.93, 1)
        if not itemLevelFrame.FFXIVUIPlaceholderIcon then
            local icon = itemLevelFrame:CreateTexture(nil, "ARTWORK")
            local path = HEADER_ICON_ROOT .. "ItemLevel.tga"
            if GetFileIDFromPath and GetFileIDFromPath(path) then
                icon:SetTexture(path)
            else
                icon:SetTexture(HEADER_ICON_ROOT .. "Physical.tga")
            end
            icon:SetSize(28, 28)
            itemLevelFrame.FFXIVUIPlaceholderIcon = icon
        end
        itemLevelFrame.FFXIVUIPlaceholderIcon:ClearAllPoints()
        itemLevelFrame.FFXIVUIPlaceholderIcon:SetPoint("RIGHT", CharacterHandsSlot, "LEFT", -15, 5)
        itemLevelFrame.Value:SetPoint("RIGHT", itemLevelFrame.FFXIVUIPlaceholderIcon, "LEFT", -2, 0)
    end

    local rows = {}
    for _, child in ipairs({stats:GetChildren()}) do
        if child.Label and child.Value and child:IsShown() then
            local _, relativeTo = child:GetPoint(1)
            local visited = {}
            local category
            while relativeTo and not visited[relativeTo] do
                if relativeTo == attributes then
                    category = attributes
                    break
                elseif relativeTo == enhancements then
                    category = enhancements
                    break
                end
                visited[relativeTo] = true
                if not relativeTo.GetPoint then break end
                local _, parent = relativeTo:GetPoint(1)
                relativeTo = parent
            end
            if category then rows[#rows + 1] = {frame = child, category = category} end
        end
    end
    table.sort(rows, function(left, right)
        if not left.frame.GetTop or not right.frame.GetTop then return false end
        return left.frame:GetTop() > right.frame:GetTop()
    end)
    local offsets = {[attributes] = 0, [enhancements] = 0}
    for _, entry in ipairs(rows) do
        local row, category = entry.frame, entry.category
        local offset = offsets[category]
        row:ClearAllPoints()
        row:SetWidth(columnWidth)
        row:SetPoint("TOPLEFT", category, "BOTTOMLEFT", 0, -2 - offset * 20)
        row:SetHeight(18)
        offsets[category] = offset + 1
    end
end

local function HideNativePanelArt(frame)
    if not frame then return end
    HideArt(frame, true)
    if frame.NineSlice then HideNativeFrame(frame.NineSlice) end
end

SkinNativeStatHeader = function(frame, iconName)
    if not frame or frame.FFXIVUIHeaderIcon then return end
    HideArt(frame, true)
    if frame.Title then
        frame.Title:ClearAllPoints()
        frame.Title:SetPoint("LEFT", frame, "LEFT", 28, 0)
        frame.Title:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
        frame.Title:SetJustifyH("LEFT")
        Font(frame.Title, 12)
        Color(frame.Title, "SetTextColor", "muted")
    end
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(HEADER_ICON_ROOT .. iconName .. ".tga")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", frame, "LEFT", 2, 0)
    frame.FFXIVUIHeaderIcon = icon
    local underline = frame:CreateTexture(nil, "BORDER")
    Themes.StyleDivider(underline, frame, "BORDER")
    underline:SetHeight(1)
    underline:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, 4)
    underline:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    frame.FFXIVUIUnderline = underline
end

local function SkinNativeTabs(character)
    local selected = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(character)
    for index = 1, 8 do
        local tab = _G["CharacterFrameTab" .. index]
        if tab and not skins[tab] then
            local nativeLabel = tab.GetFontString and tab:GetFontString() or tab.Text
            local text = tab.tooltipText or (nativeLabel and nativeLabel.GetText and nativeLabel:GetText())
            HideArt(tab, true)
            SkinTab(tab, text)
            local checked
            if selected and tab.GetID then
                checked = tab:GetID() == selected
            elseif tab.GetChecked then
                checked = tab:GetChecked()
            end
            if checked == nil then checked = index == 1 end
            UpdateTab(tab, checked)
        end
    end
end

UpdateNativeTabSelection = function(character)
    if not character or character ~= CharacterFrame then return end
    local selected = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(character)
    if not selected then return end
    for index = 1, 8 do
        local tab = _G["CharacterFrameTab" .. index]
        if tab and skins[tab] and tab.GetID then
            UpdateTab(tab, tab:GetID() == selected)
        end
    end
end

local function LayoutNativeTabs(character)
    local visibleTabs = {}
    for index = 1, 8 do
        local tab = _G["CharacterFrameTab" .. index]
        if tab and tab:IsShown() then visibleTabs[#visibleTabs + 1] = tab end
    end
    if #visibleTabs == 0 then return end
    local tabWidth = (character:GetWidth() - 24 - (#visibleTabs - 1) * TAB_SPACING) / #visibleTabs
    for index, tab in ipairs(visibleTabs) do
        tab:ClearAllPoints()
        tab:SetPoint("TOPLEFT", character, "TOPLEFT", 12 + (index - 1) * (tabWidth + TAB_SPACING), -36)
        tab:SetSize(tabWidth, 30)
        local skin = skins[tab]
        if skin then
            skin.label:SetWidth(tabWidth - 34)
            Font(skin.label, 10)
        end
    end
end

local function SkinCharacterFilter(filter, pageName)
    if pageName ~= "ReputationFrame" and pageName ~= "TokenFrame" and pageName ~= "CurrencyFrame" then return end
    if filter.FFXIVUIComboBox then return end
    local root = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\ComboBox-"
    if type(filter.OnMenuOpened) ~= "function" or type(filter.OnMenuClosed) ~= "function" then return end
    local probe = filter.FFXIVUIComboBoxProbe
    if not probe then
        probe = filter:CreateTexture(nil, "BACKGROUND")
        probe:Hide()
        filter.FFXIVUIComboBoxProbe = probe
    end
    for _, state in ipairs({"Closed", "Open", "Menu"}) do
        if not probe:SetTexture(root .. state .. "-Dark.tga") then return end
    end
    HideArt(filter, true)
    if filter.NineSlice then HideNativeFrame(filter.NineSlice) end
    local panel = CreateFrame("Frame", nil, filter)
    panel:SetAllPoints(filter)
    panel:SetFrameLevel(filter:GetFrameLevel())
    panel:EnableMouse(false)
    local pieces = {}
    for index = 1, 3 do
        local texture = panel:CreateTexture(nil, "BACKGROUND")
        texture:SetPoint("TOP", panel, "TOP")
        texture:SetPoint("BOTTOM", panel, "BOTTOM")
        if index == 1 then
            texture:SetPoint("LEFT", panel, "LEFT")
            texture:SetWidth(20)
            texture:SetTexCoord(0, 26 / 512, 0, 1)
        elseif index == 2 then
            texture:SetPoint("LEFT", panel, "LEFT", 20, 0)
            texture:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
            texture:SetTexCoord(26 / 512, 323 / 512, 0, 1)
        else
            texture:SetPoint("RIGHT", panel, "RIGHT")
            texture:SetWidth(12)
            texture:SetTexCoord(323 / 512, 339 / 512, 0, 1)
        end
        pieces[index] = texture
    end
    filter.FFXIVUIComboBox = pieces
    filter:SetHeight(24)
    local function Update()
        local opened = filter.IsMenuOpen and filter:IsMenuOpen()
        local path = root .. (opened and "Open" or "Closed") .. "-Dark.tga"
        local enabled = filter:IsEnabled()
        for _, texture in ipairs(pieces) do
            texture:SetTexture(path)
            texture:SetAlpha(enabled and 1 or 0.5)
        end
        local label = filter.Text
        if label then
            label:ClearAllPoints()
            label:SetPoint("LEFT", filter, "LEFT", 24, 0)
            label:SetPoint("RIGHT", filter, "RIGHT", -12, 0)
            label:SetJustifyH("LEFT")
            label:SetWordWrap(false)
            Font(label, 11)
            Color(label, "SetTextColor", enabled and "text" or "muted")
        end
    end
    addonEnv.StyleComboBoxMenu(filter)
    if type(filter.OnMenuOpened) == "function" then hooksecurefunc(filter, "OnMenuOpened", Update) end
    if type(filter.OnMenuClosed) == "function" then hooksecurefunc(filter, "OnMenuClosed", Update) end
    for _, method in ipairs({"OnButtonStateChanged", "UpdateText"}) do
        if type(filter[method]) == "function" then hooksecurefunc(filter, method, Update) end
    end
    filter:HookScript("OnShow", Update)
    filter:HookScript("OnEnable", Update)
    filter:HookScript("OnDisable", Update)
    Update()
end

-- Reputation, Currency and other non-paperdoll pages inside the native shell.
local function ApplyNativePageLayout(character)
    local inset = character.Inset or _G.CharacterFrameInset
    if inset then
        inset:ClearAllPoints()
        inset:SetPoint("TOPLEFT", character, "TOPLEFT", 5, -70)
        inset:SetPoint("BOTTOMRIGHT", character, "BOTTOMRIGHT", -5, 5)
    end
    local page = character[character.activeSubframe] or _G[character.activeSubframe]
    if page and inset then
        local banner = inset.FFXIVUILevelBanner
        local filter = page.filterDropdown or page.FilterDropdown
        if filter then
            SkinCharacterFilter(filter, character.activeSubframe)
            filter:ClearAllPoints()
            if banner then
                filter:SetPoint("RIGHT", banner, "RIGHT", -8, 0)
            else
                filter:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -8, -6)
            end
            local transferLog = page.CurrencyTransferLogToggleButton
            if transferLog then
                transferLog:ClearAllPoints()
                transferLog:SetPoint("RIGHT", filter, "LEFT", -8, 0)
            end
        end
        local box = page.ScrollBox
        if box and box.ClearAllPoints then
            box:ClearAllPoints()
            box:SetPoint("TOPLEFT", inset, "TOPLEFT", 8, banner and -62 or filter and -38 or -8)
            box:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -26, 6)
        end
    end
    LayoutNativeTabs(character)
    pending = false
end

ApplyNativeLayout = function()
    local character = CharacterFrame
    if not nativeShellInstalled or not character then return end
    if GeometryLocked(character) then pending = true; return end
    if character.activeSubframe ~= "PaperDollFrame" then return ApplyNativePageLayout(character) end
    local inset = character.Inset or _G.CharacterFrameInset
    local rightInset = character.InsetRight or _G.CharacterFrameInsetRight
    local paperDoll = _G.PaperDollFrame
    if not inset or not rightInset or not paperDoll then return end

    character:SetSize(NATIVE_FRAME_WIDTH, 546)
    rightInset:ClearAllPoints()
    rightInset:SetPoint("TOPLEFT", character, "TOPLEFT", 5, -82)
    rightInset:SetPoint("BOTTOMRIGHT", character, "BOTTOMLEFT", NATIVE_STATS_WIDTH + 5, 0)
    inset:ClearAllPoints()
    inset:SetPoint("TOPLEFT", rightInset, "TOPRIGHT", 2, 0)
    inset:SetPoint("BOTTOMRIGHT", character, "BOTTOMRIGHT", -5, 0)
    rightInset:Show()

    local model = _G.CharacterModelScene
    if model then
        model:ClearAllPoints()
        model:SetPoint("TOPLEFT", inset, "TOPLEFT", 58, -60)
        model:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -58, 48)
        if not model.FFXIVUIBackground then
            HideArt(model, true)
            model.FFXIVUIBackground = addonEnv.RoundFill(model, model, "inset")
            local outline = CreateFrame("Frame", nil, model)
            outline:SetAllPoints(model)
            outline:SetFrameLevel(model:GetFrameLevel() + 5)
            outline:EnableMouse(false)
            addonEnv.RoundOutline(outline)
        end
    end
    if not inset.FFXIVUILevelBanner then
        local banner = CreateFrame("Frame", nil, inset, "BackdropTemplate")
        banner:SetFrameLevel(inset:GetFrameLevel() + 1)
        banner:SetPoint("TOPLEFT", inset, "TOPLEFT", 5, -5)
        banner:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -5, -5)
        banner:SetHeight(48)
        addonEnv.RoundWindow(banner)
        for _, region in ipairs({banner:GetRegions()}) do
            if region:GetObjectType() == "Texture" then
                local texture = region:GetTexture()
                if type(texture) == "string" and texture:match("surface%.tga$") then
                    region:SetVertexColor(0.11, 0.11, 0.11, 1)
                end
            end
        end
        inset.FFXIVUILevelBanner = banner
        local level = banner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        level:SetPoint("TOPLEFT", banner, "TOPLEFT", 12, -4)
        level:SetPoint("RIGHT", banner, "RIGHT", -124, 0)
        level:SetJustifyH("LEFT")
        level:SetWordWrap(false)
        Font(level, 11)
        Color(level, "SetTextColor", "text")
        local icon = banner:CreateTexture(nil, "OVERLAY")
        icon:SetSize(24, 24)
        icon:SetPoint("BOTTOMLEFT", banner, "BOTTOMLEFT", 12, 3)
        local className = banner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        className:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        className:SetPoint("RIGHT", banner, "RIGHT", -124, 0)
        className:SetJustifyH("LEFT")
        className:SetWordWrap(false)
        Font(className, 18)
        Color(className, "SetTextColor", "accent")
        banner.Level, banner.ClassIcon, banner.ClassName = level, icon, className
        local function UpdateBanner()
            local value, effective = UnitLevel("player"), UnitEffectiveLevel("player")
            if effective ~= value then value = EFFECTIVE_LEVEL_FORMAT:format(effective, value) end
            level:SetText(LEVEL .. " " .. value)
            local localized, class = UnitClass("player")
            local specializationName
            if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization
                and C_SpecializationInfo.GetSpecializationInfo then
                local specialization = C_SpecializationInfo.GetSpecialization()
                if specialization then
                    specializationName = select(2, C_SpecializationInfo.GetSpecializationInfo(specialization))
                end
            end
            className:SetText(specializationName and specializationName ~= ""
                and specializationName .. " " .. localized or localized)
            icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            if CLASS_ICON_TCOORDS[class] then icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class])) end
            if CharacterLevelText then CharacterLevelText:SetAlpha(0) end
        end
        if CharacterLevelText then
            CharacterLevelText:SetAlpha(0)
        end
        if type(PaperDollFrame_SetLevel) == "function" then
            hooksecurefunc("PaperDollFrame_SetLevel", UpdateBanner)
        end
        banner:HookScript("OnShow", UpdateBanner)
        UpdateBanner()
    end
    if PaperDollSidebarTabs then
        PaperDollSidebarTabs:ClearAllPoints()
        PaperDollSidebarTabs:SetPoint("TOPRIGHT", inset.FFXIVUILevelBanner, "TOPRIGHT", 20, -8)
        PaperDollSidebarTabs:SetSize(116, 35)
    end
    if CharacterHeadSlot and CharacterHandsSlot then
        CharacterHeadSlot:ClearAllPoints()
        CharacterHeadSlot:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, -60)
        CharacterHandsSlot:ClearAllPoints()
        CharacterHandsSlot:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -4, -60)
    end

    local stats = _G.CharacterStatsPane
    if stats then
        LayoutNativeStats(stats)
    end
    LayoutNativeTabs(character)
    pending = false
end

local function EquipmentReturn(row)
    if row.FFXIVUIStatColumn == 1 then return end
    if SmartNavigation_RegisterOutgoingDirNavCallback and not navigationHooks[row] then
        SmartNavigation_RegisterOutgoingDirNavCallback(row, SMART_NAV_INPUT_DIRECTION.RIGHT, function()
            CharacterFrame:SwapToLeftSide()
        end)
        navigationHooks[row] = true
    end
end

local function SidebarIcon(button, image)
    if not button or button.FFXIVUISidebarIcon then return end
    local icon = button.Icon or button.icon
    if not icon then return end
    local function HideDecoration(region)
        if not region or region == icon then return end
        region:SetAlpha(0)
        hooksecurefunc(region, "SetAlpha", function(self, alpha)
            if alpha ~= 0 then self:SetAlpha(0) end
        end)
    end
    HideDecoration(button.TabBg)
    if button.GetNormalTexture then HideDecoration(button:GetNormalTexture()) end
    local painting = false
    local function Update()
        if painting then return end
        painting = true
        local theme = Themes.GetName():gsub(" ", "-")
        local path = HEADER_ICON_ROOT .. "Sidebar-" .. image .. "-" .. theme .. ".tga"
        icon:SetTexture(path)
        icon:SetTexCoord(0, 1, 0, 1)
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", button, "CENTER")
        local size = math.min(button:GetWidth(), button:GetHeight())
        icon:SetSize(size, size)
        icon:SetDesaturated(not button:IsEnabled())
        painting = false
    end
    for _, key in ipairs({"Mask", "IconMask", "CircleMask"}) do
        if button[key] then icon:RemoveMaskTexture(button[key]) end
    end
    button.FFXIVUISidebarIcon = icon
    sidebarUpdates[button] = Update
    for _, method in ipairs({"SetTexture", "SetAtlas", "SetTexCoord"}) do
        if icon[method] then hooksecurefunc(icon, method, Update) end
    end
    if SetPortraitTexture then
        hooksecurefunc("SetPortraitTexture", function(texture)
            if texture == icon then Update() end
        end)
    end
    button:HookScript("OnEnable", Update)
    button:HookScript("OnDisable", Update)
    button:HookScript("OnSizeChanged", Update)
    Update()
end

local function SkinNativeSidebar(button, image)
    if not button then return end
    SidebarIcon(button, image)
    for _, key in ipairs({"Hider", "Highlight"}) do
        local texture = button[key]
        if texture then
            texture:Hide()
            local function KeepHidden(self) if self:IsShown() then self:Hide() end end
            hooksecurefunc(texture, "Show", KeepHidden)
            hooksecurefunc(texture, "SetShown", KeepHidden)
        end
    end
end

local function StyleLevelBanner(character)
    local banner = PaperDollLevelInfo
    HideArt(banner, true)
    banner:ClearAllPoints()
    banner:SetPoint("TOPLEFT", character.LeftPaneHost, "TOPLEFT", -1, 2)
    banner:SetPoint("TOPRIGHT", character.LeftPaneHost, "TOPRIGHT", -8, 2)
    banner:SetHeight(48)
    addonEnv.RoundWindow(banner)
    local toggle = character.RightPaneToggleButton
    HideArt(toggle, true)
    if toggle.NineSlice then HideNativeFrame(toggle.NineSlice) end
    toggle:ClearAllPoints()
    toggle:SetPoint("RIGHT", banner, "RIGHT", -5, 0)
    toggle:SetSize(26, 26)
    local art = addonEnv.StyleCircularArrowButton(toggle, character:IsRightPaneCollapsed() and "right" or "left")
    toggle.FFXIVUISideArrow = art.glyph
    updatePaneArrow = function()
        addonEnv.StyleCircularArrowButton(toggle, character:IsRightPaneCollapsed() and "right" or "left")
    end
    updatePaneArrow()
    local function LayerToggle()
        toggle:SetFrameStrata(banner:GetFrameStrata())
        toggle:SetFrameLevel(banner:GetFrameLevel() + 1)
    end
    hooksecurefunc(banner, "SetFrameLevel", LayerToggle)
    hooksecurefunc(banner, "SetFrameStrata", LayerToggle)
    LayerToggle()
    local level = banner:CreateFontString(nil, "OVERLAY", "FFXIV_CharacterLevelTemplate")
    level:SetJustifyH("LEFT")
    level:SetWordWrap(false)
    level:SetFont("Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\MiedingerMedium.ttf", 11, "")
    Color(level, "SetTextColor", "text")
    local icon = banner:CreateTexture(nil, "ARTWORK", "FFXIV_CharacterClassIconTemplate")
    local className = banner:CreateFontString(nil, "OVERLAY", "FFXIV_CharacterClassNameTemplate")
    className:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    className:SetJustifyH("LEFT")
    className:SetWordWrap(false)
    className:SetFont("Fonts\\FRIZQT__.TTF", 20, "")
    Color(className, "SetTextColor", "accent")
    banner.Level, banner.ClassName, banner.ClassIcon = level, className, icon
    local function Update()
        local value = UnitLevel("player")
        local effective = UnitEffectiveLevel("player")
        if effective ~= value then value = EFFECTIVE_LEVEL_FORMAT:format(effective, value) end
        level:SetText(LEVEL .. " " .. value)
        local localized, class = UnitClass("player")
        className:SetText(localized)
        icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
        CharacterLevelText:SetAlpha(0)
        level:Show()
        className:Show()
        icon:Show()
        banner:SetHeight(48)
    end
    hooksecurefunc("PaperDollFrame_SetLevel", Update)
    hooksecurefunc("PaperDollFrame_SetPetLevel", function()
        level:Hide()
        className:Hide()
        icon:Hide()
        CharacterLevelText:SetAlpha(1)
    end)
    Update()
end

local function RememberStatColor(value, r, g, b, a)
    local token
    if r == 1 and g == 1 and b == 1 then token = "text"
    elseif g == 1 and r <= 0.2 and b <= 0.2 then token = "beneficial"
    elseif r == 1 and g <= 0.2 and b <= 0.2 then token = "detrimental" end
    statColors[value] = {r, g, b, a or 1, token = token}
end

local function ApplyStatText(value, palette)
    local text = statText[value]
    if issecretvalue and issecretvalue(text) then return end
    if type(text) ~= "string" then return end
    local function Code(token)
        local color = palette[token]
        return string.format("|cff%02x%02x%02x", math.floor(color[1] * 255 + 0.5),
            math.floor(color[2] * 255 + 0.5), math.floor(color[3] * 255 + 0.5))
    end
    text = text:gsub("|cnGREEN_FONT_COLOR:", Code("beneficial"))
        :gsub("|cnRED_FONT_COLOR:", Code("detrimental"))
        :gsub("|c(%x%x)(%x%x)(%x%x)(%x%x)", function(alpha, red, green, blue)
            local r, g, b = tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16)
            if g == 255 and r <= 51 and b <= 51 then return Code("beneficial") end
            if r == 255 and g <= 51 and b <= 51 then return Code("detrimental") end
            return "|c" .. alpha .. red .. green .. blue
        end)
    coloringText = true
    value:SetText(text)
    coloringText = false
end

local function ApplyStatColor(value, palette)
    local native = statColors[value]
    coloringValue = true
    value:SetTextColor(unpack(native.token and palette[native.token] or native))
    coloringValue = false
end

local function StyleStats(pane)
    local owner = pane.FFXIVUISections or pane.ScrollBox
    for _, row in owner:EnumerateFrames() do
        if row.Background then row.Background:SetAlpha(0) end
        if row.Title then
            Font(row.Title, 12, 0.76, 0.73, 0.65)
            Color(row.Title, "SetTextColor", "muted")
            row.Title:ClearAllPoints()
            row.Title:SetPoint("LEFT", row, "LEFT", row.FFXIVUIHeaderIcon and 28 or 10, 0)
            row.Title:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            row.Title:SetJustifyH("LEFT")
            if not row.FFXIVUILine then
                row.FFXIVUILine = row:CreateTexture(nil, "BACKGROUND")
                Themes.StyleDivider(row.FFXIVUILine, row, "BACKGROUND")
                row.FFXIVUILine:SetHeight(1)
            end
            local line, icon = row.FFXIVUILine, row.FFXIVUIHeaderIcon
            line:ClearAllPoints()
            if icon then
                line:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, 4)
                line:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            else
                line:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 4)
                line:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 4)
            end
        else
            Font(row.Label, 10, 0.86, 0.83, 0.74)
            if row.Label then Color(row.Label, "SetTextColor", "text") end
            Font(row.Value, 10)
            local value = row.Value
            if value and statColors[value] == nil then
                local originalText = value:GetText()
                if issecretvalue and issecretvalue(originalText) then
                    statText[value] = nil
                else
                    statText[value] = originalText
                end
                local function TextChanged(self)
                    if coloringText then return end
                    local text = self:GetText()
                    if issecretvalue and issecretvalue(text) then
                        statText[self] = nil
                        return
                    end
                    statText[self] = text
                    ApplyStatText(self, Themes.GetPalette())
                end
                hooksecurefunc(value, "SetText", TextChanged)
                hooksecurefunc(value, "SetFormattedText", TextChanged)
                RememberStatColor(value, value:GetTextColor())
                hooksecurefunc(value, "SetTextColor", function(self, red, green, blue, alpha)
                    if coloringValue then return end
                    RememberStatColor(self, red, green, blue, alpha)
                    ApplyStatColor(self, Themes.GetPalette())
                end)
            end
            if value then
                ApplyStatText(value, Themes.GetPalette())
                ApplyStatColor(value, Themes.GetPalette())
                value:SetShadowColor(0, 0, 0, 0)
            end
            EquipmentReturn(row)
        end
    end
end

local function InstallResources(sections, unit)
    if diagnosticResourcesDisabled then return end
    local panel = Panel(sections)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", sections, "TOPLEFT", 12, -6)
    panel:SetSize(416, 62)
    addonEnv.RoundWindow(panel)
    sections.Resources = panel
    local function Resource(index, labelText, r, g, b)
        local group = CreateFrame("Frame", nil, panel)
        group:SetSize(184, 50)
        group:SetPoint("TOPLEFT", panel, "TOPLEFT", 16 + (index - 1) * 200, -6)
        local label = group:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", group, "TOPLEFT", 0, -3)
        Font(label, 12)
        Color(label, "SetTextColor", "muted")
        label:SetText(labelText)
        local current = group:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        current:SetPoint("TOPRIGHT", group, "TOPRIGHT", 0, 0)
        Font(current, 18)
        Color(current, "SetTextColor", "text")
        local maximum = group:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        maximum:SetPoint("BOTTOMRIGHT", group, "BOTTOMRIGHT", 0, 0)
        Font(maximum, 18)
        Color(maximum, "SetTextColor", "text")
        local bar = CreateFrame("StatusBar", nil, group)
        bar:SetPoint("TOPLEFT", group, "TOPLEFT", 0, -24)
        bar:SetSize(184, 3)
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        bar:SetStatusBarColor(r, g, b)
        local track = bar:CreateTexture(nil, "BACKGROUND")
        track:SetAllPoints(bar)
        track:SetColorTexture(0, 0, 0, 0.7)
        return {Label = label, Current = current, Maximum = maximum, Bar = bar}
    end
    panel.Health = Resource(1, "HP", 0.65, 0.82, 0.25)
    panel.Power = Resource(2, "MP", 0.9, 0.52, 0.7)
    local function Update()
        local health, maximum = UnitHealth(unit), UnitHealthMax(unit)
        panel.Health.Current:SetFormattedText("%d", health)
        panel.Health.Maximum:SetFormattedText("%d", maximum)
        panel.Health.Bar:SetMinMaxValues(0, maximum)
        panel.Health.Bar:SetValue(health)
        local powerType, token = UnitPowerType(unit)
        local power, maxPower = UnitPower(unit, powerType), UnitPowerMax(unit, powerType)
        panel.Power.Label:SetText(token == "MANA" and "MP" or _G[token] or token)
        panel.Power.Current:SetFormattedText("%d", power)
        panel.Power.Maximum:SetFormattedText("%d", maxPower)
        panel.Power.Bar:SetMinMaxValues(0, maxPower)
        panel.Power.Bar:SetValue(power)
        local color = PowerBarColor[token]
        if color then panel.Power.Bar:SetStatusBarColor(color.r, color.g, color.b) end
    end
    for _, event in ipairs({"UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT",
        "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER"}) do panel:RegisterUnitEvent(event, unit) end
    panel:RegisterEvent("PLAYER_ENTERING_WORLD")
    panel:RegisterEvent("UNIT_PET")
    panel:SetScript("OnEvent", Update)
    panel:HookScript("OnShow", Update)
    Update()
end

local function InstallSections(pane)
    local sections = CreateFrame("Frame", nil, pane)
    sections:SetAllPoints(pane)
    sections.rows, sections.headers, sections.statRows = {}, {}, {}
    pane.FFXIVUISections = sections
    InstallResources(sections, pane == CharacterStatsPaneScrollBox and "player" or "pet")
    function sections:EnumerateFrames()
        return ipairs(self.rows)
    end
    local definitions = {
        {title = STAT_CATEGORY_GENERAL, column = 1, icon = "Role"},
        {title = STAT_CATEGORY_PRIMARY_ATTRIBUTES, column = 1, icon = "Attributes"},
        {title = "Offensive Properties", column = 1, icon = "Offensive"},
        {title = "Defensive Properties", column = 2, icon = "Defensive"},
        {title = "Spell Properties", column = 2, icon = "Mental"},
        {title = STAT_CATEGORY_RESISTANCE, column = 2, icon = "Physical"},
    }
    local categories = {
        [STAT_CATEGORY_GENERAL] = 1, [STAT_CATEGORY_PRIMARY_ATTRIBUTES] = 2,
        [STAT_CATEGORY_WEAPONS] = 3, [STAT_CATEGORY_MODIFIERS] = 3,
        [STAT_CATEGORY_DEFENSE] = 4, [STAT_CATEGORY_RESISTANCE] = 6,
    }
    -- Native update functions set labels; when they fail in combat, use the same global strings.
    local fallbackLabels = {
        MOVESPEED = "STAT_MOVEMENT_SPEED",
        STRENGTH = "SPELL_STAT1_NAME", AGILITY = "SPELL_STAT2_NAME", STAMINA = "SPELL_STAT3_NAME",
        INTELLECT = "SPELL_STAT4_NAME", SPIRIT = "SPELL_STAT5_NAME",
        MAINHAND_DAMAGE = "INVTYPE_WEAPONMAINHAND", OFFHAND_DAMAGE = "INVTYPE_WEAPONOFFHAND",
        RANGED_DAMAGE = "INVTYPE_RANGED", ATTACK_DAMAGE = "DAMAGE", ATTACK_ATTACKSPEED = "WEAPON_SPEED",
        ATTACK_AP = "STAT_ATTACK_POWER", RANGED_ATTACK_AP = "RANGED_ATTACK_POWER",
        CRITCHANCE = "STAT_CRITICAL_STRIKE", HITCHANCE = "STAT_HIT_CHANCE", ARMORPEN = "STAT_ARMOR_PENETRATION",
        MANAREGEN = "MANA_REGEN",
    }
    local function FallbackLabel(data)
        if data.labelText then return data.labelText end
        local name = tostring(data.name)
        return _G[fallbackLabels[name] or ""] or _G["STAT_" .. name] or _G[name] or name
    end
    local preservedFields = {"onEnterFunc", "UpdateTooltip", "tooltip", "tooltip2", "tooltip3", "numericValue"}
    -- Native Init reruns stat update functions; under addon taint those can hit secret values
    -- (e.g. GetUnitSpeed in combat), so keep the last good display and retry after combat.
    local function InitStatRow(row, data)
        local saved = {}
        for _, field in ipairs(preservedFields) do saved[field] = row[field] end
        if pcall(row.Init, row, data) then return true end
        for _, field in ipairs(preservedFields) do row[field] = saved[field] end
        if (row.Label:GetText() or "") == "" then
            local label = FallbackLabel(data)
            row.Label:SetText(STAT_FORMAT and format(STAT_FORMAT, label) or label)
            row.Value:SetText("--")
        end
        sections:RegisterEvent("PLAYER_REGEN_ENABLED")
        return false
    end
    local function Rebuild()
        local previousRows, used = sections.rows, {}
        sections.rows = {}
        local groups, current = {}, 1
        for _, data in ipairs(pane.elementData or {}) do
            if data.isHeader then
                current = categories[data.name]
                if not current then
                    -- Retain future native categories rather than silently dropping their stats.
                    for index, definition in ipairs(definitions) do
                        if definition.title == data.name then current = index; break end
                    end
                    if not current then
                        current = #definitions + 1
                        definitions[current] = {title = data.name, column = 2}
                    end
                end
            elseif not data.shouldRemove and data.name ~= "HEALTH" and data.name ~= "POWER" then
                local group = data.name and data.name:match("^SPELL") and 5 or current
                groups[group] = groups[group] or {}
                groups[group][#groups[group] + 1] = data
            end
        end
        local heights = {78, 78}
        for index, definition in ipairs(definitions) do
            local entries = groups[index]
            if entries and #entries > 0 then
                local column = definition.column
                local x, y = 12 + (column - 1) * (COLUMN_WIDTH + 12), heights[column]
                local header = sections.headers[index]
                if not header then
                    header = CreateFrame("Frame", nil, sections, "CharacterStatFrameCategoryScrollBoxElementTemplate")
                    sections.headers[index] = header
                end
                header:Init({name = definition.title})
                if definition.icon and not header.FFXIVUIHeaderIcon then
                    local icon = header:CreateTexture(nil, "ARTWORK")
                    icon:SetTexture(HEADER_ICON_ROOT .. definition.icon .. ".tga")
                    icon:SetSize(22, 22)
                    icon:SetPoint("LEFT", header, "LEFT", 3, 1)
                    header.FFXIVUIHeaderIcon = icon
                end
                header:ClearAllPoints()
                header:SetPoint("TOPLEFT", sections, "TOPLEFT", x, -y)
                header:SetSize(COLUMN_WIDTH, 24)
                header:Show()
                used[header] = true
                sections.rows[#sections.rows + 1] = header
                y = y + 24
                for _, data in ipairs(entries) do
                    local key = (data.unit or "") .. ":" .. (data.name or data.labelText) .. ":" .. tostring(data.id or "")
                    local row = sections.statRows[key]
                    if not row then
                        row = CreateFrame("Frame", nil, sections, "CharacterStatFrameScrollBoxLabelElementTemplate")
                        sections.statRows[key] = row
                        row:EnableMouse(true)
                        if SmartNavigation_MarkFrameFocusable then SmartNavigation_MarkFrameFocusable(row) end
                    end
                    InitStatRow(row, data)
                    row.FFXIVUIStatColumn = column
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", sections, "TOPLEFT", x, -y)
                    row:SetSize(COLUMN_WIDTH, 18)
                    row.Label:ClearAllPoints()
                    row.Label:SetPoint("LEFT", row, "LEFT", 10, 0)
                    row.Label:SetPoint("RIGHT", row.Value, "LEFT", -8, 0)
                    row.Label:SetWordWrap(false)
                    row.Label:SetJustifyH("LEFT")
                    Font(row.Value, 10)
                    local valueWidth = row.Value:GetStringWidth()
                    if (issecretvalue and issecretvalue(valueWidth)) or type(valueWidth) ~= "number" then valueWidth = 56 end
                    row.Value:SetWidth(math.max(40, valueWidth + 4))
                    row:Show()
                    used[row] = true
                    sections.rows[#sections.rows + 1] = row
                    y = y + 18
                end
                heights[column] = y + 12
            end
        end
        for _, row in ipairs(previousRows) do if not used[row] then row:Hide() end end
        sections.requiredHeight = math.max(heights[1], heights[2]) + 8
        StyleStats(pane)
        if layoutReady then Layout() end
    end
    for _, child in ipairs({pane.ScrollBox, pane.ScrollBar}) do
        child:Hide()
        hooksecurefunc(child, "Show", function(self) self:Hide() end)
        hooksecurefunc(child, "SetShown", function(self) if self:IsShown() then self:Hide() end end)
    end
    sections:SetScript("OnEvent", function(self, event)
        if event ~= "PLAYER_REGEN_ENABLED" then return end
        self:UnregisterEvent(event)
        if pane:IsShown() then Rebuild() end
    end)
    hooksecurefunc(pane, "UpdateStats", Rebuild)
    pane:HookScript("OnShow", Rebuild)
    local tab = pane == CharacterStatsPaneScrollBox and PaperDollSidebarTab1 or PaperDollSidebarTab3
    tab:HookScript("OnClick", function()
        if not InputUtil.IsGamepadUIEnabled() or SmartNavigation:GetActiveFrame() ~= CharacterFrame then return end
        SmartNavigation:SetScrollFrameForFrame(CharacterFrame, nil)
        GamepadScrollBarHint:Hide()
        for _, row in ipairs(sections.rows) do
            if not row.Title and row:IsShown() then SmartNavigation:SelectButton(row); break end
        end
    end)
    Rebuild()
end

local function SetupEquipmentReturns()
    for _, row in PaperDollFrame.EquipmentManagerPane.ScrollBox:EnumerateFrames() do EquipmentReturn(row) end
end

local function SetupNavigation()
    if not CharacterFrame.leftFooter or not SmartNavigation_ClearJumpNavigationOverridesInDirection then return end
    if InCombatLockdown() then pending = true; return end
    local slots = PaperDollItemsFrame.EquipmentSlots
    local half = #slots / 2
    -- Native left/right pane names stay unchanged; only the visual crossing direction reverses.
    for index, button in ipairs(slots) do
        if index > half then
            SmartNavigation_ClearJumpNavigationOverridesInDirection(button, SMART_NAV_INPUT_DIRECTION.RIGHT)
        else
            SmartNavigation_AddJumpNavigationOverride(button, SMART_NAV_INPUT_DIRECTION.LEFT, function()
                return CharacterFrame:RightSideSwapSmartNavigationJumpOverride()
            end)
            if not navigationHooks[button] then
                SmartNavigation_RegisterOutgoingDirNavCallback(button, SMART_NAV_INPUT_DIRECTION.LEFT, function()
                    CharacterFrame:SwapToRightSide()
                end)
                navigationHooks[button] = true
            end
        end
    end
    StyleStats(CharacterStatsPaneScrollBox)
    StyleStats(CharacterStatsPanePetScrollBox)
    SetupEquipmentReturns()
end

local function LayoutContentPage(character, owner, width)
    local page = character[character.activeSubframe] or _G[character.activeSubframe]
    if not page or page == PaperDollFrame or page == character or page == owner or not page.SetWidth then return end
    if not pageWidths[page] then
        local nativeWidth = page:GetWidth()
        if nativeWidth <= 0 then return end
        pageWidths[page] = {width = nativeWidth, children = {}}
        for _, key in ipairs({"Inset", "ScrollBox", "ScrollFrame", "FilterBar"}) do
            local child = page[key]
            if child and child.GetWidth and child.SetWidth then
                local childWidth = child:GetWidth()
                if childWidth > 0 then pageWidths[page].children[child] = childWidth end
            end
        end
    end
    local geometry = pageWidths[page]
    local extraWidth = width - geometry.width
    page:ClearAllPoints()
    page:SetAllPoints(owner)
    page:SetWidth(width)
    for child, nativeWidth in pairs(geometry.children) do
        child:SetWidth(math.max(1, nativeWidth + extraWidth))
    end
end

Layout = function()
    layoutCalls = layoutCalls + 1
    if GeometryLocked(CharacterFrame) then pending = true; return end
    if layingOut then return end
    layingOut = true
    -- Keep combat-deferred navigation/equipment work queued for PLAYER_REGEN_ENABLED.
    if not InCombatLockdown() then pending = false end
    local character = CharacterFrame
    local collapsed = character:IsRightPaneCollapsed()
    local paperDoll = character.activeSubframe == "PaperDollFrame"
    local left, right = character.LeftPaneHost, character.RightPaneHost
    local tabs = character.ModeTabs
    local count = 0
    for _, tab in ipairs(tabs.Tabs) do if tab:IsShown() then count = count + 1 end end
    local compact = collapsed and paperDoll
    local columns = compact and math.ceil(count / 2) or count
    local extraRowHeight = compact and count > 1 and 33 or 0
    local contentTop = CONTENT_TOP + extraRowHeight
    character.FFXIVUINativeLeftWidth = character.FFXIVUINativeLeftWidth or left:GetWidth()
    local leftWidth = paperDoll and character.FFXIVUINativeLeftWidth or PAGE_WIDTH
    if not paperDoll then LayoutContentPage(character, left, leftWidth) end
    left:SetWidth(leftWidth)
    right:SetWidth(paperDoll and STATS_WIDTH or DETAIL_WIDTH)
    right:SetAlpha(paperDoll and 1 or 0)
    local modelX = 0
    if paperDoll then modelX = collapsed and COLLAPSED_PANE_INSET or right:GetWidth() end
    local forever = select(4, GetBuildInfo()) == 16001
    local detailPage = forever and not paperDoll and DETAIL_PANES[character.activeSubframe]
    local detailPane = detailPage and _G[character.activeSubframe]
        and _G[character.activeSubframe][detailPage] or nil
    local showDetail = detailPane ~= nil and detailPane:IsShown()
    local frameWidth = modelX + left:GetWidth()
    if showDetail then frameWidth = left:GetWidth() + DETAIL_GAP + DETAIL_WIDTH + DETAIL_RIGHT_PAD end
    character:SetWidth(frameWidth)
    desiredWidth = frameWidth
    local height = CHARACTER_FRAME_HEIGHT + EXTRA_HEIGHT + extraRowHeight
    if paperDoll and not collapsed then
        for _, pane in ipairs({CharacterStatsPaneScrollBox, CharacterStatsPanePetScrollBox}) do
            if pane:IsShown() and pane.FFXIVUISections then
                height = math.max(height, CONTENT_TOP + 48 + pane.FFXIVUISections.requiredHeight)
            end
        end
    end
    character:SetHeight(height)
    local detailX = paperDoll and 0 or left:GetWidth()
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", character, "TOPLEFT", modelX, -contentTop)
    left:SetPoint("BOTTOMLEFT", character, "BOTTOMLEFT", modelX, 0)
    right:ClearAllPoints()
    right:SetPoint("TOPLEFT", character, "TOPLEFT", detailX, -contentTop)
    right:SetPoint("BOTTOMLEFT", character, "BOTTOMLEFT", detailX, 0)
    if detailPane then
        local detailLeft = left:GetWidth() + DETAIL_GAP
        detailPane:ClearAllPoints()
        detailPane:SetPoint("TOPLEFT", character, "TOPLEFT", detailLeft, -contentTop)
        detailPane:SetPoint("BOTTOMLEFT", character, "BOTTOMLEFT", detailLeft, 0)
        detailPane:SetWidth(DETAIL_WIDTH)
        if not detailPane.FFXIVUIVisibilityHook then
            detailPane.FFXIVUIVisibilityHook = true
            detailPane:HookScript("OnShow", Layout)
            detailPane:HookScript("OnHide", Layout)
        end
    end
    if detailSeam then detailSeam:SetShown(showDetail) end

    -- Tabs size to the page, not the expanded width, so opening the detail panel leaves them unchanged
    local pageWidth = modelX + left:GetWidth()
    tabs:ClearAllPoints()
    tabs:SetPoint("TOPLEFT", character, "TOPLEFT", 22, -35)
    tabs:SetWidth(pageWidth - 44)
    tabs:SetHeight(24 + extraRowHeight)
    tabs:SetFrameLevel(character:GetFrameLevel() + 520)
    if count > 0 then
        local width = (pageWidth - 44 - (columns - 1) * TAB_SPACING) / columns
        local index = 0
        for _, tab in ipairs(tabs.Tabs) do
            if tab:IsShown() then
                tab:ClearAllPoints()
                tab:SetPoint("TOPLEFT", tabs, "TOPLEFT", (index % columns) * (width + TAB_SPACING),
                    -math.floor(index / columns) * 33)
                tab:SetSize(width, 24)
                local label = skins[tab].label
                Font(label, 10)
                label:SetWidth(width - 30)
                label:SetWordWrap(compact)
                label:SetMaxLines(compact and 2 or 1)
                label:SetHeight(compact and 28 or 20)
                index = index + 1
            end
        end
    end
    if character.TabIndicators then
        character.TabIndicators.isVertical = false
        character.TabIndicators:UpdateTabVisibility()
    end
    if not character.FFXIVUIWidthHook then
        character.FFXIVUIWidthHook = true
        character:HookScript("OnSizeChanged", function()
            if not layingOut and desiredWidth and math.abs(character:GetWidth() - desiredWidth) > 1 then Layout() end
        end)
    end
    if not paperDoll then
        local page = character[character.activeSubframe] or _G[character.activeSubframe]
        if page then
            if not page.FFXIVUIShowHook then
                page.FFXIVUIShowHook = true
                page:HookScript("OnShow", Layout)
            end
            local filter = page.filterDropdown or page.FilterDropdown
            if filter then
                SkinCharacterFilter(filter, character.activeSubframe)
                filter:ClearAllPoints()
                filter:SetPoint("TOPRIGHT", left, "TOPRIGHT", -12, -8)
                local transferLog = page.CurrencyTransferLogToggleButton
                if transferLog then
                    transferLog:ClearAllPoints()
                    transferLog:SetPoint("RIGHT", filter, "LEFT", -8, 0)
                end
            end
            local box = page.ScrollBox
            if box and box.ClearAllPoints then
                box:ClearAllPoints()
                box:SetPoint("TOPLEFT", left, "TOPLEFT", 12, filter and -44 or -12)
                box:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -28, 12)
            end
        end
    end
    if updatePaneArrow then updatePaneArrow() end
    layingOut = false
    layoutFinished = layoutFinished + 1
end

local function Install()
    if not ready or diagnosticDisabled or installed then return end
    local character = CharacterFrame
    if not character then return end
    if not character.LeftPaneHost or not character.RightPaneHost then
        if select(4, GetBuildInfo()) == 16001 then return end
        if nativeShellInstalled or InCombatLockdown() then
            if InCombatLockdown() then pending = true end
            return
        end
        nativeShellInstalled = true
        SkinNativeTextTree(character)
        local stats = _G.CharacterStatsPane
        local paperDoll = _G.PaperDollFrame
        for _, frame in pairs({
            character.Inset,
            character.InsetRight,
            _G.CharacterFrameInset,
            _G.CharacterFrameInsetRight,
            _G.CharacterFrameInset2,
            paperDoll,
            _G.PaperDollSidebarTabs,
            stats,
            stats and stats.ItemLevelCategory,
            stats and stats.ItemLevelFrame,
            stats and stats.AttributesCategory,
            stats and stats.EnhancementsCategory,
            _G.CharacterStatsPanePet,
            _G.CharacterStatsPaneScrollBox,
            _G.CharacterStatsPanePetScrollBox,
            paperDoll and paperDoll.EquipmentManagerPane,
        }) do
            HideNativePanelArt(frame)
        end
        if stats and not stats.Resources then
            InstallResources(stats, "player")
            if stats.Resources then
                for _, resource in ipairs({stats.Resources.Health, stats.Resources.Power}) do
                    resource.Label:SetJustifyH("LEFT")
                    resource.Current:SetJustifyH("RIGHT")
                    resource.Maximum:SetJustifyH("RIGHT")
                end
            end
        end
        SkinNativeTabs(character)
        if not nativeTabSelectionHooked and type(PanelTemplates_SetTab) == "function" then
            nativeTabSelectionHooked = true
            hooksecurefunc("PanelTemplates_SetTab", UpdateNativeTabSelection)
        end
        SkinNativeSidebar(PaperDollSidebarTab1, "CharacterStatus")
        SkinNativeSidebar(PaperDollSidebarTab2, "EquipmentManager")
        SkinNativeSidebar(PaperDollSidebarTab3, "Titles")
        local function SkinNativeEquipmentSlot(button)
            if not button then return end
            if button.BorderFrame then HideArt(button.BorderFrame) end
            HideSlotFrame(button)
            addonEnv.ApplyButtonSkin(button, nil, "Equipment")
        end
        for _, slotName in ipairs(NATIVE_EQUIPMENT_SLOTS) do
            SkinNativeEquipmentSlot(_G[slotName])
        end
        if CharacterMainHandSlot and CharacterSecondaryHandSlot and character.Inset then
            CharacterMainHandSlot:ClearAllPoints()
            CharacterMainHandSlot:SetPoint("BOTTOM", character.Inset, "BOTTOM", -23, 14)
            CharacterSecondaryHandSlot:ClearAllPoints()
            CharacterSecondaryHandSlot:SetPoint("LEFT", CharacterMainHandSlot, "RIGHT", 5, 0)
        end
        HideArt(character, true)
        if character.NineSlice then HideNativeFrame(character.NineSlice) end
        if character.PortraitContainer then character.PortraitContainer:SetAlpha(0) end
        if character.TitleContainer then character.TitleContainer:SetAlpha(0) end
        local shell = Panel(character)
        addonEnv.RoundWindow(shell, true)
        local title = shell:CreateFontString(nil, "OVERLAY", "FFXIV_CharacterHeaderTitleTemplate")
        title:SetWidth(220)
        title:SetJustifyH("LEFT")
        title:SetWordWrap(false)
        title:SetText(CHARACTER or "Character")
        Font(title, 18, 0.88, 0.86, 0.8)
        Color(title, "SetTextColor", "text")
        local name = shell:CreateFontString(nil, "OVERLAY", "FFXIV_CharacterHeaderNameTemplate")
        name:SetPoint("LEFT", title, "RIGHT", 16, 0)
        name:SetJustifyH("RIGHT")
        name:SetWordWrap(false)
        Font(name, 14, 0.85, 0.75, 0.51)
        Color(name, "SetTextColor", "accent")
        local function UpdateName() name:SetText(UnitPVPName("player")) end
        if character.UpdateTitle then hooksecurefunc(character, "UpdateTitle", UpdateName) end
        UpdateName()
        local headerDivider = shell:CreateTexture(nil, "OVERLAY", "FFXIV_CharacterHeaderDividerTemplate")
        Themes.StyleDivider(headerDivider, shell, "OVERLAY")
        character.FFXIVUIHeaderDivider = headerDivider
        local close = character.CloseButton or CharacterFrameCloseButton
        if close then
            HideArt(close)
            close:ClearAllPoints()
            close:SetPoint("TOPRIGHT", character, "TOPRIGHT", -5, -4)
            close:SetSize(24, 24)
            addonEnv.SkinWindowClose(close)
        end
        local function RefreshNativeCharacter()
            SkinNativeTabs(character)
            ApplyNativeLayout()
        end
        if character.RefreshDisplay then
            hooksecurefunc(character, "RefreshDisplay", RefreshNativeCharacter)
        end
        if character.UpdateSize then
            hooksecurefunc(character, "UpdateSize", ApplyNativeLayout)
        end
        character:HookScript("OnShow", ApplyNativeLayout)
        if paperDoll then paperDoll:HookScript("OnShow", ApplyNativeLayout) end
        if type(PaperDollFrame_UpdateStats) == "function" then
            hooksecurefunc("PaperDollFrame_UpdateStats", function()
                if not nativeShellInstalled or not CharacterStatsPane then return end
                LayoutNativeStats(CharacterStatsPane)
            end)
        end
        local function RelayoutSoon()
            ApplyNativeLayout()
            C_Timer.After(0, ApplyNativeLayout)
        end
        for index = 1, 8 do
            local tab = _G["CharacterFrameTab" .. index]
            if tab then tab:HookScript("OnClick", RelayoutSoon) end
        end
        for _, pageName in ipairs({"ReputationFrame", "TokenFrame", "CurrencyFrame"}) do
            local page = _G[pageName]
            if page then page:HookScript("OnShow", RelayoutSoon) end
        end
        ApplyNativeLayout()
        return
    end
    if not character.ModeTabs or not character.ModeTabs.Tabs then return end
    if GeometryLocked(character) then pending = true; return end
    installed = true
    HideArt(character, true)
    if character.NineSlice then HideNativeFrame(character.NineSlice) end
    if character.PortraitContainer then character.PortraitContainer:SetAlpha(0) end
    if character.TitleContainer then character.TitleContainer:SetAlpha(0) end
    local shell = Panel(character)
    addonEnv.RoundWindow(shell, true)
    local title = shell:CreateFontString(nil, "OVERLAY", "FFXIV_CharacterHeaderTitleTemplate")
    title:SetText(CHARACTER)
    Font(title, 18, 0.88, 0.86, 0.8)
    Color(title, "SetTextColor", "text")
    local name = shell:CreateFontString(nil, "OVERLAY", "FFXIV_CharacterHeaderNameTemplate")
    name:SetPoint("LEFT", title, "RIGHT", 16, 0)
    name:SetJustifyH("RIGHT")
    name:SetWordWrap(false)
    Font(name, 14, 0.85, 0.75, 0.51)
    Color(name, "SetTextColor", "accent")
    local function UpdateName() name:SetText(UnitPVPName("player")) end
    hooksecurefunc(character, "UpdateTitle", UpdateName)
    UpdateName()
    local headerLine = shell:CreateTexture(nil, "OVERLAY", "FFXIV_CharacterHeaderDividerTemplate")
    Themes.StyleDivider(headerLine, shell, "OVERLAY")
    detailSeam = shell:CreateTexture(nil, "OVERLAY")
    detailSeam:SetWidth(1)
    detailSeam:SetPoint("TOPLEFT", shell, "TOPLEFT", PAGE_WIDTH - DETAIL_SEAM_INSET, -30)
    detailSeam:SetPoint("BOTTOMLEFT", shell, "BOTTOMLEFT", PAGE_WIDTH - DETAIL_SEAM_INSET, DETAIL_SEAM_BOTTOM_INSET)
    Themes.StyleDivider(detailSeam, shell, "OVERLAY", nil, true)
    detailSeam:Hide()
    local close = character.CloseButton
    HideArt(close)
    close:ClearAllPoints()
    close:SetPoint("TOPRIGHT", character, "TOPRIGHT", -5, -4)
    close:SetSize(24, 24)
    addonEnv.SkinWindowClose(close)

    for _, host in ipairs({character.LeftPaneHost, character.RightPaneHost}) do
        HideArt(host, true)
        for _, child in ipairs({host:GetChildren()}) do HideArt(child, true) end
    end
    if PaperDollFrame.TopBackgroundStripHost then
        HideNativeFrame(PaperDollFrame.TopBackgroundStripHost)
    end
    local model = PaperDollFrame.CharacterModelScene
    HideArt(model, true)
    model:ClearAllPoints()
    model:SetPoint("TOPLEFT", PaperDollLevelInfo, "BOTTOMLEFT", 0, -4)
    model:SetPoint("BOTTOMRIGHT", character.LeftPaneHost, "BOTTOMRIGHT", -8, 8)
    local outline = CreateFrame("Frame", nil, model)
    outline:SetAllPoints(model)
    addonEnv.RoundFill(model, outline, "inset")
    outline:SetFrameLevel(model:GetFrameLevel() + 5)
    outline:EnableMouse(false)
    addonEnv.RoundOutline(outline)
    for _, pane in ipairs({CharacterStatsPaneScrollBox, CharacterStatsPanePetScrollBox}) do
        HideArt(pane)
        pane:ClearAllPoints()
        pane:SetPoint("TOPLEFT", character.RightPaneHost, "TOPLEFT", 0, -48)
        pane:SetPoint("BOTTOMRIGHT", character.RightPaneHost, "BOTTOMRIGHT")
        pane.ScrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnUpdate, function() StyleStats(pane) end)
        InstallSections(pane)
        StyleStats(pane)
    end
    local equipmentPane = PaperDollFrame.EquipmentManagerPane
    HideArt(equipmentPane)
    for _, key in ipairs({"EquipSet", "SaveSet"}) do
        local button = equipmentPane[key]
        if button then
            HideArt(button)
            local panel = Panel(button)
            addonEnv.StyleWindowControl(panel, button, "Button")
            local label = button:GetFontString()
            if label then
                Font(label, 12)
                Color(label, "SetTextColor", "tabText")
            end
        end
    end
    equipmentPane:ClearAllPoints()
    equipmentPane:SetPoint("TOPLEFT", character.RightPaneHost, "TOPLEFT", 0, -48)
    equipmentPane:SetPoint("BOTTOMRIGHT", character.RightPaneHost, "BOTTOMRIGHT")
    equipmentPane.ScrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnUpdate, SetupEquipmentReturns)
    PaperDollSidebarTabs:SetHeight(46)
    SidebarIcon(PaperDollSidebarTab1, "CharacterStatus")
    SidebarIcon(PaperDollSidebarTab2, "EquipmentManager")
    SidebarIcon(PaperDollSidebarTab3, "Titles")
    PaperDollLevelInfo:ClearAllPoints()
    PaperDollLevelInfo:SetPoint("TOP", character.LeftPaneHost, "TOP", 0, -5)
    if CharacterLevelTextBackground then CharacterLevelTextBackground:SetAlpha(0) end
    Font(CharacterLevelText, 14, 0.85, 0.75, 0.51)
    Color(CharacterLevelText, "SetTextColor", "accent")
    StyleLevelBanner(character)
    model.ControlFrame:ClearAllPoints()
    model.ControlFrame:SetPoint("TOP", PaperDollLevelInfo, "BOTTOM", 0, -4)

    for _, tab in ipairs(character.ModeTabs.Tabs) do
        SkinTab(tab)
        tab:HookScript("OnShow", Layout)
        tab:HookScript("OnHide", Layout)
    end
    for _, method in ipairs({"RefreshDisplay", "UpdateSize", "UpdateTabLayout", "SetSelectedModeTabByFrame"}) do
        hooksecurefunc(character, method, Layout)
    end
    character:HookScript("OnShow", Layout)
    hooksecurefunc(character, "SetupGamepad", function()
        Layout()
        SetupNavigation()
    end)
    local function SkinSlot(button)
        if button.BorderFrame then HideArt(button.BorderFrame) end
        HideSlotFrame(button)
        addonEnv.ApplyButtonSkin(button, nil, "Equipment")
    end
    local function SkinEquipment()
        if InCombatLockdown() then pending = true; return end
        for _, slots in ipairs({PaperDollItemsFrame.EquipmentSlots, PaperDollItemsFrame.WeaponSlots, {CharacterAmmoSlot}}) do
            for _, button in ipairs(slots) do SkinSlot(button) end
        end
    end
    hooksecurefunc("PaperDollItemSlotButton_Update", function(button)
        if button:GetParent() == PaperDollItemsFrame then
            SkinSlot(button)
        end
    end)
    character:HookScript("OnShow", SkinEquipment)
    watcher.SkinEquipment = SkinEquipment
    SkinEquipment()
    SetupNavigation()
    layoutReady = true
    local activeSubframe = character.activeSubframe or "PaperDollFrame"
    for _, tab in ipairs(character.ModeTabs.Tabs) do
        UpdateTab(tab, tab.frameName == activeSubframe)
    end
    local function RelayoutSoon()
        Layout()
        C_Timer.After(0, Layout)
    end
    for _, tab in ipairs(character.ModeTabs.Tabs) do tab:HookScript("OnMouseUp", RelayoutSoon) end
    for _, pageName in ipairs({"PaperDollFrame", "ReputationFrame", "TokenFrame", "CurrencyFrame"}) do
        local page = _G[pageName]
        if page then page:HookScript("OnShow", RelayoutSoon) end
    end
    Layout()
end

Themes.Register(function(palette)
    for region, bindings in pairs(colors) do
        for method, token in pairs(bindings) do region[method](region, unpack(palette[token])) end
    end
    for tab in pairs(skins) do UpdateTab(tab) end
    for _, update in pairs(sidebarUpdates) do update() end
    if updatePaneArrow then updatePaneArrow() end
    for value in pairs(statColors) do
        ApplyStatColor(value, palette)
        ApplyStatText(value, palette)
    end
end)

local function Initialize()
    if ready then return end
    diagnosticDisabled = FFXIV_UI_DB and FFXIV_UI_DB.characterSkinDiagnosticDisabled or false
    diagnosticResourcesDisabled = FFXIV_UI_DB and FFXIV_UI_DB.characterResourcesDiagnosticDisabled or false
    ready = true
end
local handlers = {
    ADDON_LOADED = function(loadedAddon)
        if loadedAddon == addonName then Initialize() end
        Install()
    end,
    PLAYER_LOGIN = function()
        Initialize()
        Install()
    end,
    PLAYER_REGEN_ENABLED = function()
        Install()
        if nativeShellInstalled and pending then ApplyNativeLayout() end
        if installed and pending then
            Layout()
            watcher.SkinEquipment()
            SetupNavigation()
        end
    end,
}
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(_, event, ...)
    local handler = handlers[event]
    if handler then handler(...) end
end)

local function DescribePoints(frame)
    local parts = {}
    for index = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(index)
        local relativeName = relativeTo and (relativeTo.GetName and relativeTo:GetName()) or "?"
        parts[#parts + 1] = string.format("%s>%s:%s(%.0f,%.0f)", point, tostring(relativeName), relativePoint, x or 0, y or 0)
    end
    return table.concat(parts, " ")
end

if SlashCmdList then
    SLASH_FFXIVUICHARDEBUG1 = "/ffxivchardebug"
    SlashCmdList.FFXIVUICHARDEBUG = function(action)
        local function Say(...) print("|cff66ccffFFXIVUI|r", ...) end
        local character = CharacterFrame
        if (action or ""):lower():find("layout") and installed then
            local ok, err = pcall(Layout)
            layingOut = false
            Say("forced Layout ok=", tostring(ok), ok and "" or tostring(err))
        end
        Say("build", tostring(select(4, GetBuildInfo())), "installed", tostring(installed),
            "nativeShell", tostring(nativeShellInstalled), "ready", tostring(ready),
            "disabled", tostring(diagnosticDisabled), "layoutReady", tostring(layoutReady))
        Say("layoutCalls", layoutCalls, "finished", layoutFinished, "layingOut", tostring(layingOut),
            "pending", tostring(pending), "combat", tostring(InCombatLockdown()), "desiredWidth", tostring(desiredWidth))
        if not character then return Say("no CharacterFrame") end
        Say("activeSubframe", tostring(character.activeSubframe), "size",
            string.format("%.0fx%.0f", character:GetSize()))
        local left, right = character.LeftPaneHost, character.RightPaneHost
        if left then Say("left", string.format("w=%.0f shown=%s", left:GetWidth(), tostring(left:IsShown())), DescribePoints(left)) end
        if right then
            Say("right", string.format("w=%.0f alpha=%.1f shown=%s", right:GetWidth(), right:GetAlpha(), tostring(right:IsShown())),
                DescribePoints(right))
        end
        local tabs = character.ModeTabs
        if tabs then
            Say("ModeTabs", string.format("w=%.0f", tabs:GetWidth()), DescribePoints(tabs))
            for index, tab in ipairs(tabs.Tabs or {}) do
                Say("tab", index, tostring(tab.frameName), "shown", tostring(tab:IsShown()),
                    "skinned", tostring(skins[tab] ~= nil), string.format("%.0fx%.0f", tab:GetSize()), DescribePoints(tab))
            end
        end
        local page = character.activeSubframe and (character[character.activeSubframe] or _G[character.activeSubframe])
        if page then
            Say("page", tostring(character.activeSubframe), "shown", tostring(page:IsShown()),
                string.format("w=%.0f", page:GetWidth()), DescribePoints(page))
            local filter = page.filterDropdown or page.FilterDropdown
            if filter then Say("filter", DescribePoints(filter)) end
            for _, key in ipairs({"ScrollBox", "ScrollBar", "Inset"}) do
                local child = page[key]
                if child and child.GetNumPoints then
                    Say(key, string.format("%.0fx%.0f shown=%s", child:GetWidth(), child:GetHeight(), tostring(child:IsShown())),
                        DescribePoints(child))
                end
            end
        end
    end
end

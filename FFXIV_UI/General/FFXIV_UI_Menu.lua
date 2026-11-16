

local addonName, addonEnv = ...
local L = addonEnv.L or setmetatable({}, {__index = function(_, key) return key end})
local AXIS_FONT = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf"
if addonEnv.GetFont then AXIS_FONT = addonEnv.GetFont(AXIS_FONT) end
local Profiles = addonEnv.Profiles
local refreshProfileControls
    FFXIV_UI_Anchors = FFXIV_UI_Anchors or {}
    FFXIV_UI_DB = FFXIV_UI_DB or {}

    local anchorConfigs = {
        { key = "ExpBar",        label = "Experience Bar",     w = 800, h = 25,  scale = 1.0, pos = {"BOTTOM", 0, 30} },
        { key = "JobGauge",      label = "Job Gauge",          w = 150, h = 100,  scale = 1.0, pos = {"CENTER", 400, -150} },
        { key = "PlayerCast",    label = "Player Castbar",     w = 360, h = 100, scale = 1.0, pos = {"CENTER", 0, -170} },
        { key = "PlayerHP",      label = "Player Health",      w = 240, h = 86,  scale = 1.0, pos = {"BOTTOM", -120, 55} },
        { key = "PlayerPower",   label = "Player Power",       w = 240, h = 86,  scale = 1.0, pos = {"BOTTOM", 120, 55} },
        { key = "PlayerPowerSec",label = "Secondary Power",    w = 240, h = 86,  scale = 1.0, pos = {"BOTTOM", 360, 55} },
        { key = "TargetAuras",   label = "Target Buffs",       w = 850, h = 45,  scale = 1.0, pos = {"TOP", 90, -70} },
        { key = "TargetDebuffs", label = "Target Debuffs",     w = 850, h = 45,  scale = 1.0, pos = {"TOP", 90, -115} },
        { key = "TargetCast",    label = "Target Castbar",     w = 350, h = 30,  scale = 1.0, pos = {"TOP", 180, 0} },
        { key = "TargetHP",      label = "Target Health",      w = 670, h = 50,  scale = 1.0, pos = {"TOP", 0, -25} },
        { key = "TargetPower",   label = "Target Power",       w = 300, h = 16,  scale = 1.0, pos = {"TOP", 0, -78} },
        { key = "TargetOfTarget",label = "Target of Target",   w = 340, h = 50,  scale = 1.0, pos = {"TOP", 505, -25} },
        { key = "FocusTarget",   label = "Focus Target",       w = 340, h = 50,  scale = 1.0, pos = {"TOP", -505, -25} },
        { key = "EnemyList",     label = "Enemy List",         w = 284, h = 240, scale = 1.0, pos = {"CENTER", 450, 50} },
    }
    for _, config in ipairs(anchorConfigs) do config.label = L[config.label] end

    local visualBoxes = {}
    anchorsUnlocked = false  


    local soundOn  = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Open_Window.mp3"
    local soundOff = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Close_Window.mp3"



    function FFXIV_UI_SetAnchorsUnlocked(unlocked)
        anchorsUnlocked = unlocked
        for _, box in ipairs(visualBoxes) do
            box:SetShown(unlocked)
            box:EnableMouse(unlocked)
            box:EnableMouseWheel(unlocked)
        end
    end

    local function ClampToScreen(anchor)
        local scale = anchor:GetScale()
        local width, height = anchor:GetWidth() * scale, anchor:GetHeight() * scale
        local uiWidth, uiHeight = UIParent:GetWidth(), UIParent:GetHeight()
        local point, _, relativePoint, x, y = anchor:GetPoint()
        local halfW, halfH = width / 2, height / 2
        x = math.max(-uiWidth/2 + halfW, math.min(uiWidth/2 - halfW, x))
        y = math.max(-uiHeight/2 + halfH, math.min(uiHeight/2 - halfH, y))
        anchor:ClearAllPoints()
        anchor:SetPoint(point, UIParent, relativePoint, x, y)
    end

    local function SaveAnchorState(anchor, key)
        local point, _, relativePoint, x, y = anchor:GetPoint()
        Profiles.SaveAnchor(key, {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y,
            scale = anchor:GetScale(),
            width = anchor:GetWidth(),
            height = anchor:GetHeight(),
        })
    end



    local function CreateAnchor(data)
        local anchor = CreateFrame("Frame", "FFXIV_Anchor_" .. data.key, UIParent)
        anchor:SetSize(data.w, data.h)
        anchor:SetMovable(true)
        anchor:SetPoint(data.pos[1], UIParent, data.pos[1], data.pos[2], data.pos[3])
    
        anchor.key = data.key
        anchor.defaultData = data

        local visual = CreateFrame("Frame", nil, anchor, "FFXIV_AnchorVisualTemplate")
        visual:SetPoint("CENTER", anchor, "CENTER")
        visual:SetFrameStrata("TOOLTIP")
        visual:SetBackdrop({ 
            bgFile = "Interface\\Buttons\\WHITE8X8", 
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
            edgeSize = 14 
        })
        visual:SetBackdropColor(0.2, 0.2, 0.2, 0.25)
        visual:SetBackdropBorderColor(1, 1, 1, 1)

  
        visual.nameText:SetFont(AXIS_FONT, 14, "OUTLINE")
        visual.nameText:SetTextColor(1,1,1)
        visual.nameText:SetText(data.label)

        visual.percentText:SetFont(AXIS_FONT, 14, "OUTLINE")
        visual.percentText:SetTextColor(1,1,1)
        visual.percentText:SetText("100%")

        local btnInc, btnDec = visual.btnInc, visual.btnDec
        visual:RegisterForDrag("LeftButton")
        visual:Hide()
        table.insert(visualBoxes, visual)

        local function RefreshVisualLayout()
            local s = anchor:GetScale()
            visual:SetSize(anchor:GetWidth() * s, anchor:GetHeight() * s)
            visual:SetScale(1 / s)
            visual.percentText:SetText(math.floor(s * 100 + 0.5) .. "%")
        end

        local function UpdateScale(newScale)
            local oldScale = anchor:GetScale()
            local point, relativeTo, relativePoint, x, y = anchor:GetPoint()
            local ratio = oldScale / newScale
            anchor:SetScale(newScale)
            anchor:ClearAllPoints()
            anchor:SetPoint(point, relativeTo, relativePoint, x * ratio, y * ratio)
            RefreshVisualLayout()
            visual.percentText:SetText(math.floor(newScale * 100 + 0.5) .. "%")
            SaveAnchorState(anchor, data.key)
        end

        btnInc:SetScript("OnClick", function() UpdateScale(math.min(2.5, anchor:GetScale() + 0.05)) end)
        btnDec:SetScript("OnClick", function() UpdateScale(math.max(0.4, anchor:GetScale() - 0.05)) end)

        visual:SetScript("OnDragStart", function() if anchorsUnlocked then anchor:StartMoving() end end)
        visual:SetScript("OnDragStop", function() anchor:StopMovingOrSizing(); ClampToScreen(anchor); SaveAnchorState(anchor, data.key) end)
        visual:SetScript("OnMouseWheel", function(_, delta) if anchorsUnlocked then UpdateScale(math.max(0.4, math.min(2.5, anchor:GetScale() + (delta * 0.05)))) end end)


        visual:SetScript("OnEnter", function() visual:SetBackdropColor(1, 1, 0, 0.3) end) 
        visual:SetScript("OnLeave", function() visual:SetBackdropColor(0.2, 0.2, 0.2, 0.25) end)

        anchor.RefreshVisual = RefreshVisualLayout
        return anchor
    end



    for _, data in ipairs(anchorConfigs) do
        FFXIV_UI_Anchors[data.key] = CreateAnchor(data)
    end

    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnUpdate", function(self)
        if EditModeManager then
            SetupEditMode()
            self:SetScript("OnUpdate", nil)
        end
    end)

    loader:HookScript("OnEvent", function(self, event, addonName)
        if addonName == "FFXIV_UI" then
            FFXIV_UI_Profiles = FFXIV_UI_Profiles or {}
            Profiles.Initialize(anchorConfigs, FFXIV_UI_Profiles, FFXIV_UI_DB, UnitGUID("player"))
            Profiles.Apply(FFXIV_UI_Anchors)
            if refreshProfileControls then refreshProfileControls() end
        end
    end)





    SLASH_FFXIVUI1 = "/ffxivtoggle"
    SlashCmdList["FFXIVUI"] = function() 
        anchorsUnlocked = not anchorsUnlocked
        FFXIV_UI_SetAnchorsUnlocked(anchorsUnlocked) 
        if anchorsUnlocked then
            PlaySoundFile(soundOn, "Master")
        else
            PlaySoundFile(soundOff, "Master")
        end
    end

    local function resetAllAnchors()
        if InCombatLockdown() then
            print("FFXIV UI: Anchor layouts cannot be reset during combat.")
            return
        end
        Profiles.Reset()
        Profiles.Apply(FFXIV_UI_Anchors)
    end

 
   --Options--
local options = CreateFrame("Frame")
options.name = "FFXIV UI"

local title = options:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("FFXIV UI")

local profileLabel = options:CreateFontString(nil, "ARTWORK", "GameFontNormal")
profileLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 280, -16)
profileLabel:SetText(L["Anchor Profile"])

local profileDropdown = CreateFrame("Frame", "FFXIV_UI_ProfileDropdown", options, "UIDropDownMenuTemplate")
profileDropdown:SetPoint("TOPLEFT", profileLabel, "BOTTOMLEFT", -16, -6)
UIDropDownMenu_SetWidth(profileDropdown, 200)

refreshProfileControls = function()
    UIDropDownMenu_SetText(profileDropdown, Profiles.GetActiveName())
end
profileDropdown:SetScript("OnShow", refreshProfileControls)

local function changeProfile(operation, ...)
    if InCombatLockdown() then
        print("FFXIV UI: Profiles cannot be changed during combat.")
        return false
    end
    local success, message = operation(...)
    if not success then
        print("FFXIV UI: " .. message)
        return false
    end
    Profiles.Apply(FFXIV_UI_Anchors)
    refreshProfileControls()
    return true
end

local function getProfileEditBox(dialog)
    return dialog.EditBox or dialog.editBox
end

StaticPopupDialogs["FFXIV_UI_PROFILE_NAME"] = {
    text = L["Profile name"],
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 64,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self, data)
        local editBox = getProfileEditBox(self)
        editBox:SetText(data.rename and Profiles.GetActiveName() or "")
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    OnAccept = function(self, data)
        if data.expectedProfile ~= Profiles.GetActiveName() then return end
        local name = getProfileEditBox(self):GetText()
        if data.rename then
            changeProfile(Profiles.Rename, name)
        else
            changeProfile(Profiles.Add, name, data.copyCurrent)
        end
    end,
}

StaticPopupDialogs["FFXIV_UI_PROFILE_DELETE"] = {
    text = L["Delete anchor profile \"%s\"?"],
    button1 = DELETE,
    button2 = CANCEL,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function(self, name)
        if name == Profiles.GetActiveName() then changeProfile(Profiles.Delete) end
    end,
}

StaticPopupDialogs["FFXIV_UI_RESET_ANCHORS"] = {
    text = L["Reset all anchors to their default positions?"],
    button1 = L["Reset"],
    button2 = CANCEL,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = resetAllAnchors,
}

local function promptProfileName(rename, copyCurrent)
    StaticPopup_Show("FFXIV_UI_PROFILE_NAME", nil, nil, {
        rename = rename,
        copyCurrent = copyCurrent,
        expectedProfile = Profiles.GetActiveName(),
    })
end

UIDropDownMenu_Initialize(profileDropdown, function(self, level, menuList)
    level = level or 1
    if level == 2 and menuList == "FFXIV_UI_ADD_PROFILE" then
        for _, choice in ipairs({{text = L["From Default"], copyCurrent = false}, {text = L["Copy Current"], copyCurrent = true}}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = choice.text
            info.notCheckable = true
            info.disabled = InCombatLockdown()
            info.func = function() promptProfileName(false, choice.copyCurrent) end
            UIDropDownMenu_AddButton(info, level)
        end
        return
    end
    if level ~= 1 or not Profiles.GetAnchors() then return end
    for _, name in ipairs(Profiles.GetNames()) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = name
        info.checked = name == Profiles.GetActiveName()
        info.disabled = InCombatLockdown()
        info.func = function() changeProfile(Profiles.Select, name) end
        UIDropDownMenu_AddButton(info, level)
    end
    local add = UIDropDownMenu_CreateInfo()
    add.text = L["Add Profile"]
    add.notCheckable = true
    add.hasArrow = true
    add.menuList = "FFXIV_UI_ADD_PROFILE"
    add.disabled = InCombatLockdown()
    UIDropDownMenu_AddButton(add, level)

    local rename = UIDropDownMenu_CreateInfo()
    rename.text = L["Rename Profile"]
    rename.notCheckable = true
    rename.disabled = Profiles.GetActiveName() == "Default" or InCombatLockdown()
    rename.func = function() promptProfileName(true) end
    UIDropDownMenu_AddButton(rename, level)

    local delete = UIDropDownMenu_CreateInfo()
    delete.text = L["Delete Profile"]
    delete.notCheckable = true
    delete.disabled = Profiles.GetActiveName() == "Default" or InCombatLockdown()
    delete.func = function()
        local name = Profiles.GetActiveName()
        StaticPopup_Show("FFXIV_UI_PROFILE_DELETE", name, nil, name)
    end
    UIDropDownMenu_AddButton(delete, level)
end)

local soundOn  = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Open_Window.mp3"
local soundOff = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Close_Window.mp3"

local QuestAcceptSoundNames = {
    "None",
    "A Realm Reborn",
    "Heavensward",
    "Stormblood",
    "Shadowbringers",
    "Endwalker",
    "Dawntrail",
    "Island Sanctuary",
    "Tribal"
}

local QuestCompleteSoundNames = {
    "None",
    "A Realm Reborn",
    "Heavensward",
    "Stormblood",
    "Shadowbringers",
    "Endwalker",
    "Dawntrail",
    "Island Sanctuary"
}


local toggleAnchors = CreateFrame("Button", nil, options, "UIPanelButtonTemplate")
toggleAnchors:SetSize(160, 22)
toggleAnchors:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)

local function UpdateToggleButtonText()
    toggleAnchors:SetText(anchorsUnlocked and L["Hide Anchors"] or L["Show Anchors"])
end

UpdateToggleButtonText()

toggleAnchors:SetScript("OnClick", function()
    anchorsUnlocked = not anchorsUnlocked
    FFXIV_UI_SetAnchorsUnlocked(anchorsUnlocked)

    if anchorsUnlocked then
        PlaySoundFile(soundOn, "Master")
    else
        PlaySoundFile(soundOff, "Master")
    end

    UpdateToggleButtonText()
end)


local reset = CreateFrame("Button", nil, options, "UIPanelButtonTemplate")
reset:SetSize(160, 22)
reset:SetPoint("TOPLEFT", toggleAnchors, "BOTTOMLEFT", 0, -12)
reset:SetText(L["Reset All Anchors"])
reset:SetScript("OnClick", function()
    StaticPopup_Show("FFXIV_UI_RESET_ANCHORS")
end)

FFXIV_UI_DB.hideBlizzardHotbarBackground = FFXIV_UI_DB.hideBlizzardHotbarBackground ~= false
local hotbarBackgroundCB = CreateFrame("CheckButton", "FFXIV_UI_HotbarBackgroundCheck", options, "InterfaceOptionsCheckButtonTemplate")
hotbarBackgroundCB:SetPoint("TOPLEFT", reset, "BOTTOMLEFT", 0, -12)
hotbarBackgroundCB.Text:SetText(L["Hide WoW Hotbar Background"])
hotbarBackgroundCB.Text:SetFont(AXIS_FONT, 12)

hotbarBackgroundCB:SetScript("OnShow", function(self)
    self:SetChecked(FFXIV_UI_DB.hideBlizzardHotbarBackground)
end)

hotbarBackgroundCB:SetScript("OnClick", function(self)
    local hideBackground = self:GetChecked()
    FFXIV_UI_DB.hideBlizzardHotbarBackground = hideBackground
    addonEnv.SetHotbarBackgroundHidden(hideBackground)
end)

local themeLabel = options:CreateFontString(nil, "ARTWORK", "GameFontNormal")
themeLabel:SetPoint("TOPLEFT", profileDropdown, "BOTTOMLEFT", 16, -16)
themeLabel:SetText(L["Color Theme (Dark only)"])
local themeDropdown = CreateFrame("Frame", "FFXIV_UI_ThemeDropdown", options, "UIDropDownMenuTemplate")
themeDropdown:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", -16, -6)
UIDropDownMenu_SetWidth(themeDropdown, 200)
if UIDropDownMenu_DisableDropDown then UIDropDownMenu_DisableDropDown(themeDropdown) end
UIDropDownMenu_Initialize(themeDropdown, function(_, level)
    for _, name in ipairs(addonEnv.Themes.GetNames()) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = name
        info.checked = name == addonEnv.Themes.GetName()
        info.func = function() addonEnv.Themes.Set(name) end
        UIDropDownMenu_AddButton(info, level)
    end
end)
addonEnv.Themes.Register(function()
    UIDropDownMenu_SetText(themeDropdown, addonEnv.Themes.GetName())
end)

local inventoryLabel = options:CreateFontString(nil, "ARTWORK", "GameFontNormal")
inventoryLabel:SetPoint("TOPLEFT", themeDropdown, "BOTTOMLEFT", 16, -16)
inventoryLabel:SetText(L["Inventory Layout"])
local inventoryDropdown = CreateFrame("Frame", "FFXIV_UI_InventoryLayoutDropdown", options, "UIDropDownMenuTemplate")
inventoryDropdown:SetPoint("TOPLEFT", inventoryLabel, "BOTTOMLEFT", -16, -6)
UIDropDownMenu_SetWidth(inventoryDropdown, 200)
local inventoryLayouts = {
    {key = "unified", text = L["Unified grid"]},
    {key = "bags", text = L["Per-bag grids"]},
}
local function UpdateInventoryDropdown()
    for _, layout in ipairs(inventoryLayouts) do
        if layout.key == addonEnv.GetInventoryLayout() then
            UIDropDownMenu_SetText(inventoryDropdown, layout.text)
        end
    end
end
local function InitializeInventoryDropdown(_, level)
    for _, layout in ipairs(inventoryLayouts) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = layout.text
        info.checked = layout.key == addonEnv.GetInventoryLayout()
        info.func = function()
            addonEnv.SetInventoryLayout(layout.key)
            UpdateInventoryDropdown()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end
inventoryDropdown:SetScript("OnShow", function(self)
    UIDropDownMenu_Initialize(self, InitializeInventoryDropdown)
    UpdateInventoryDropdown()
end)

local enemyListLabel = options:CreateFontString(nil, "ARTWORK", "GameFontNormal")
enemyListLabel:SetPoint("TOPLEFT", inventoryDropdown, "BOTTOMLEFT", 16, -16)
enemyListLabel:SetText(L["Enemy List"])
local enemyListCB = CreateFrame("CheckButton", "FFXIV_UI_EnemyListCheck", options, "InterfaceOptionsCheckButtonTemplate")
enemyListCB:SetPoint("TOPLEFT", enemyListLabel, "BOTTOMLEFT", 0, -8)
enemyListCB.Text:SetText(L["Enable Enemy List (non-clickable)"])
enemyListCB.Text:SetFont(AXIS_FONT, 12)
local enemyListControls = {}
local function UpdateEnemyListControls()
    local enabled = FFXIV_UI_DB.enemyListEnabled == true
    enemyListCB:SetChecked(enabled)
    for _, control in ipairs(enemyListControls) do
        control:SetChecked(FFXIV_UI_DB[control.setting] ~= false)
        control:SetEnabled(enabled)
        local color = enabled and 1 or 0.5
        control.Text:SetTextColor(color, color, color)
    end
end
enemyListCB:SetScript("OnShow", UpdateEnemyListControls)
enemyListCB:SetScript("OnClick", function(self)
    addonEnv.SetEnemyListEnabled(self:GetChecked() == true)
    UpdateEnemyListControls()
end)

local previousEnemyControl = enemyListCB
for _, setting in ipairs({
    {key = "enemyListShowLabel", label = L["Show Enemy List label"]},
    {key = "enemyListShowLegend", label = L["Show icon legend"]},
    {key = "enemyListDynamicCasting", label = L["Dynamically size casting entries"]},
}) do
    local control = CreateFrame("CheckButton", nil, options, "InterfaceOptionsCheckButtonTemplate")
    control.setting = setting.key
    control:SetPoint("TOPLEFT", previousEnemyControl, "BOTTOMLEFT", previousEnemyControl == enemyListCB and 16 or 0, -4)
    control.Text:SetText(setting.label)
    control.Text:SetFont(AXIS_FONT, 12)
    control:SetScript("OnShow", UpdateEnemyListControls)
    control:SetScript("OnClick", function(self)
        addonEnv.SetEnemyListSetting(self.setting, self:GetChecked() == true)
        UpdateEnemyListControls()
    end)
    enemyListControls[#enemyListControls + 1] = control
    previousEnemyControl = control
end

local minimapQuestCB = CreateFrame("CheckButton", "FFXIV_UI_MinimapQuestOverlayCheck", options, "InterfaceOptionsCheckButtonTemplate")
minimapQuestCB:SetPoint("TOPLEFT", previousEnemyControl, "BOTTOMLEFT", -16, -16)
minimapQuestCB.Text:SetText(L["Minimap turn-in icons (experimental)"])
minimapQuestCB.Text:SetFont(AXIS_FONT, 12)
minimapQuestCB:SetScript("OnShow", function(self)
    self:SetChecked(FFXIV_UI_DB.minimapQuestOverlayEnabled == true)
end)
minimapQuestCB:SetScript("OnClick", function(self)
    addonEnv.SetMinimapQuestOverlayEnabled(self:GetChecked() == true)
end)

local cb = CreateFrame("CheckButton", "FFXIV_UI_SoundCheck", options, "InterfaceOptionsCheckButtonTemplate")
cb:SetPoint("TOPLEFT", hotbarBackgroundCB, "BOTTOMLEFT", 0, -8)
cb.Text:SetText(L["Enable Sound Effects"])
cb.Text:SetFont(AXIS_FONT, 12)

cb:SetScript("OnShow", function(self)
    self:SetChecked(FFXIV_UI_DB.sfxEnabled)
end)

cb:SetScript("OnClick", function(self)
    FFXIV_UI_DB.sfxEnabled = self:GetChecked()
end)


FFXIV_UI_DB.errorSfxEnabled = FFXIV_UI_DB.errorSfxEnabled ~= false
local errorCB = CreateFrame("CheckButton", "FFXIV_UI_ErrorSoundCheck", options, "InterfaceOptionsCheckButtonTemplate")
errorCB:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -8)
errorCB.Text:SetText(L["Enable Error Sound"])
errorCB.Text:SetFont(AXIS_FONT, 12)

errorCB:SetScript("OnShow", function(self)
    self:SetChecked(FFXIV_UI_DB.errorSfxEnabled)
end)

errorCB:SetScript("OnClick", function(self)
    FFXIV_UI_DB.errorSfxEnabled = self:GetChecked()
end)

local reduceAudioCB = CreateFrame("CheckButton", "FFXIV_UI_ReduceAudioVolumeCheck", options, "InterfaceOptionsCheckButtonTemplate")
reduceAudioCB:SetPoint("TOPLEFT", errorCB, "BOTTOMLEFT", 0, -8)
reduceAudioCB.Text:SetText(L["Reduce Audio Volume"])
reduceAudioCB.Text:SetFont(AXIS_FONT, 12)

reduceAudioCB:SetScript("OnShow", function(self)
    self:SetChecked(FFXIV_UI_DB.reduceAudioVolume ~= false)
    self:SetEnabled(FFXIV_UI_DB.sfxEnabled)
end)

reduceAudioCB:SetScript("OnClick", function(self)
    FFXIV_UI_DB.reduceAudioVolume = self:GetChecked() and true or false
end)


-- Quest Accept Dropdown

local acceptLabel = options:CreateFontString(nil, "ARTWORK", "GameFontNormal")
acceptLabel:SetPoint("TOPLEFT", reduceAudioCB, "BOTTOMLEFT", 0, -20)
acceptLabel:SetText(L["Quest Accept Sound"])

local acceptDropdown = CreateFrame("Frame", "FFXIV_UI_QuestAcceptDropdown", options, "UIDropDownMenuTemplate")
acceptDropdown:SetPoint("TOPLEFT", acceptLabel, "BOTTOMLEFT", -16, -6)

UIDropDownMenu_SetWidth(acceptDropdown, 180)

UIDropDownMenu_Initialize(acceptDropdown, function(self, level)

    for i, name in ipairs(QuestAcceptSoundNames) do

        local info = UIDropDownMenu_CreateInfo()
        info.text = name

        info.func = function()
            FFXIV_UI_DB.questAcceptSFX = i - 1
            FFXIV_UI.UpdateQuestSoundMutes()
            UIDropDownMenu_SetSelectedID(acceptDropdown, i)
        end

        info.checked = (FFXIV_UI_DB.questAcceptSFX == (i - 1))

        UIDropDownMenu_AddButton(info)
    end

end)

acceptDropdown:SetScript("OnShow", function(self)

    local current = (FFXIV_UI_DB.questAcceptSFX or 1) + 1
    UIDropDownMenu_SetSelectedID(self, current)
    UIDropDownMenu_SetText(self, QuestAcceptSoundNames[current])

end)


-- Quest Complete Dropdown

local completeLabel = options:CreateFontString(nil, "ARTWORK", "GameFontNormal")
completeLabel:SetPoint("TOPLEFT", acceptDropdown, "BOTTOMLEFT", 16, -16)
completeLabel:SetText(L["Quest Complete Sound"])

local completeDropdown = CreateFrame("Frame", "FFXIV_UI_QuestCompleteDropdown", options, "UIDropDownMenuTemplate")
completeDropdown:SetPoint("TOPLEFT", completeLabel, "BOTTOMLEFT", -16, -6)

UIDropDownMenu_SetWidth(completeDropdown, 180)

UIDropDownMenu_Initialize(completeDropdown, function(self, level)

    for i, name in ipairs(QuestCompleteSoundNames) do

        local info = UIDropDownMenu_CreateInfo()
        info.text = name

        info.func = function()
            FFXIV_UI_DB.questCompleteSFX = i - 1
            FFXIV_UI.UpdateQuestSoundMutes()
            UIDropDownMenu_SetSelectedID(completeDropdown, i)
        end

        info.checked = (FFXIV_UI_DB.questCompleteSFX == (i - 1))

        UIDropDownMenu_AddButton(info)
    end

end)

completeDropdown:SetScript("OnShow", function(self)

    local current = (FFXIV_UI_DB.questCompleteSFX or 1) + 1
    UIDropDownMenu_SetSelectedID(self, current)
    UIDropDownMenu_SetText(self, QuestCompleteSoundNames[current])

end)
local function UpdateAudioOptionsState()
    local enabled = FFXIV_UI_DB.sfxEnabled
    cb:SetChecked(enabled)

    -- Disable/enable the other audio options based on main SFX checkbox
    errorCB:SetEnabled(enabled)
    reduceAudioCB:SetEnabled(enabled)
    acceptDropdown:EnableMouse(enabled)
    completeDropdown:EnableMouse(enabled)
    
 
    errorCB.Text:SetTextColor(enabled and 1 or 0.5, enabled and 1 or 0.5, enabled and 1 or 0.5)
    reduceAudioCB.Text:SetTextColor(enabled and 1 or 0.5, enabled and 1 or 0.5, enabled and 1 or 0.5)
    acceptLabel:SetTextColor(enabled and 1 or 0.5, enabled and 1 or 0.5, enabled and 1 or 0.5)
    completeLabel:SetTextColor(enabled and 1 or 0.5, enabled and 1 or 0.5, enabled and 1 or 0.5)
end

 
cb:SetScript("OnClick", function(self)
    FFXIV_UI_DB.sfxEnabled = self:GetChecked()
    FFXIV_UI.UpdateQuestSoundMutes()
    UpdateAudioOptionsState()
end)

 
cb:SetScript("OnShow", function(self)
    UpdateAudioOptionsState()
end)

 
acceptDropdown:SetScript("OnShow", function(self)
    self:EnableMouse(FFXIV_UI_DB.sfxEnabled)
    local current = (FFXIV_UI_DB.questAcceptSFX or 1) + 1
    UIDropDownMenu_SetSelectedID(self, current)
    UIDropDownMenu_SetText(self, QuestAcceptSoundNames[current])
end)

completeDropdown:SetScript("OnShow", function(self)
    self:EnableMouse(FFXIV_UI_DB.sfxEnabled)
    local current = (FFXIV_UI_DB.questCompleteSFX or 1) + 1
    UIDropDownMenu_SetSelectedID(self, current)
    UIDropDownMenu_SetText(self, QuestCompleteSoundNames[current])
end)

-- Quest Accept Preview Button
local acceptPreview = CreateFrame("Button", nil, options, "UIPanelButtonTemplate")
acceptPreview:SetSize(60, 22)
acceptPreview:SetPoint("LEFT", acceptDropdown, "RIGHT", 8, 0)
acceptPreview:SetText(L["Preview"])
acceptPreview:SetScript("OnClick", function()
    if FFXIV_UI_DB.sfxEnabled then
        local idx = FFXIV_UI_DB.questAcceptSFX or 0
        local soundFile
        if idx == 0 then
            print("|cff00ff00[FFXIV UI]|r No sound selected for Quest Accept.")
            return
        elseif idx == 1 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Accepted.ogg" 
        elseif idx == 2 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Accepted_HW.ogg"
        elseif idx == 3 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Accepted_SB.ogg"
        elseif idx == 4 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Accepted_ShB.ogg"
        elseif idx == 5 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Accepted_EW.ogg"
        elseif idx == 6 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Accepted_DT.mp3"
        elseif idx == 7 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Accepted_Island.ogg"
        elseif idx == 8 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Accepted_Tribal.ogg"
        end
        if soundFile then PlaySoundFile(FFXIV_UI.GetCustomSFXPath(soundFile:match("[^\\]+$")), "Master") end
    end
end)

-- Quest Complete Preview Button
local completePreview = CreateFrame("Button", nil, options, "UIPanelButtonTemplate")
completePreview:SetSize(60, 22)
completePreview:SetPoint("LEFT", completeDropdown, "RIGHT", 8, 0)
completePreview:SetText(L["Preview"])
completePreview:SetScript("OnClick", function()
    if FFXIV_UI_DB.sfxEnabled then
        local idx = FFXIV_UI_DB.questCompleteSFX or 0
        local soundFile
               if idx == 0 then
            print("|cff00ff00[FFXIV UI]|r No sound selected for Quest Accept.")
            return
        elseif idx == 1 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Complete.ogg"  
        elseif idx == 2 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Complete_HW.ogg"
        elseif idx == 3 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Complete_SB.ogg"
        elseif idx == 4 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Complete_ShB.ogg"
        elseif idx == 5 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Complete_EW.ogg"
        elseif idx == 6 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Complete_DT.mp3"
        elseif idx == 7 then
            soundFile = "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Quest_Complete_Island.ogg"
        end
        if soundFile then PlaySoundFile(FFXIV_UI.GetCustomSFXPath(soundFile:match("[^\\]+$")), "Master") end
    end
end)

--Options end--







    local category = Settings.RegisterCanvasLayoutCategory(options, options.name)
    Settings.RegisterAddOnCategory(category)


    local font = CreateFont("CustomActionbarFont")
    font:SetFont("Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\EurostileExtendedBlack.ttf", 14, "")
    _G["NumberFontNormalSmallGray"]:SetFontObject(font)
    _G["NumberFontNormalSmallGray"]:SetTextColor(1, 1, 1)
    _G["NumberFontNormalSmallGray"]:SetShadowColor(0.2,0.2,0.2)
    _G["NumberFontNormalSmallGray"]:SetShadowOffset(1, -1)



    local escapeListener = CreateFrame("Frame", nil, UIParent)
    escapeListener:SetPropagateKeyboardInput(true)
    escapeListener:EnableKeyboard(true)

    escapeListener:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" and anchorsUnlocked then
            anchorsUnlocked = false
            FFXIV_UI_SetAnchorsUnlocked(false)
            PlaySoundFile(soundOff, "Master")
  
        end
    end)




    local combatListener = CreateFrame("Frame")
    combatListener:RegisterEvent("PLAYER_REGEN_DISABLED")
    combatListener:RegisterEvent("PLAYER_REGEN_ENABLED")

    combatListener:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
      
            if anchorsUnlocked then
                anchorsUnlocked = false
                FFXIV_UI_SetAnchorsUnlocked(false)
                PlaySoundFile(soundOff, "Master")
             
            end

        elseif event == "PLAYER_REGEN_ENABLED" then

        end
    end)



    local minimapButton = CreateFrame("Button", "FFXIVUIMinimapButton", Minimap)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 12, 32)

    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Minimap\\MinimapButton.tga")
    icon:SetSize(70, 70)
    icon:SetPoint("CENTER")


    local mask = minimapButton:CreateMaskTexture()
    mask:SetTexture("Interface\\Buttons\\WHITE8x8", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)


    minimapButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(minimapButton, "ANCHOR_LEFT")
        GameTooltip:SetText(L["FFXIV UI Options"])
        GameTooltip:AddLine("Left-click: Open Settings", 1,1,1)
        GameTooltip:AddLine("Right-click: Toggle Anchors", 1,1,1)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)


    minimapButton:SetScript("OnClick", function(self, button)

    
        if InCombatLockdown() then
            print("|cff00ff00[FFXIV UI]|r Cannot use minimap button while in combat.")

            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_REGEN_ENABLED")
            f:SetScript("OnEvent", function(self)
                print("|cff00ff00[FFXIV UI]|r Combat ended. You may now use the minimap button.")
                self:UnregisterAllEvents()
                self:SetScript("OnEvent", nil)
            end)

            return
        end

  
        if button == "LeftButton" then
            Settings.OpenToCategory(category.ID)
 
        elseif button == "RightButton" then
            anchorsUnlocked = not anchorsUnlocked
            FFXIV_UI_SetAnchorsUnlocked(anchorsUnlocked)

            if anchorsUnlocked then
                PlaySoundFile(soundOn, "Master")
            else
                PlaySoundFile(soundOff, "Master")
            end
        end
    end)




minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local highlight = minimapButton:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAlpha(0.8)
highlight:SetVertexColor(1,0.8,0)
highlight:ClearAllPoints()
highlight:SetPoint("CENTER", minimapButton, "CENTER")
highlight:SetSize(28,28)

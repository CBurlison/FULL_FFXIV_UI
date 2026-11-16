local addonName, addonEnv = ...
local ICON_ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Quests\\"
local QuestCache = addonEnv.QuestCache
local templates = {QuestPinTemplate = true, QuestOfferPinTemplate = true}
local skins = setmetatable({}, {__mode = "k"})
local installed = false
local logInstalled = false
local titleHooks = setmetatable({}, {__mode = "k"})

local function Restore(skin)
    skin.icon:Hide()
    for region, alpha in pairs(skin.regions) do region:SetAlpha(alpha) end
    skin.regions = {}
end

local function HideRegion(skin, region)
    if not region then return end
    if skin.regions[region] == nil then skin.regions[region] = region:GetAlpha() end
    region:SetAlpha(0)
end

local function UpdatePin(pin)
    local skin = skins[pin]
    local icon
    if skin.template == "QuestOfferPinTemplate" then
        if pin.questID then
            icon = pin.questClassification == Enum.QuestClassification.Recurring
                and "RepeatableQuest" or "NewQuest"
        end
    else
        local style = pin:GetStyle()
        if style == POIButtonUtil.Style.QuestComplete then
            icon = "CompleteQuest"
        elseif style == POIButtonUtil.Style.QuestInProgress then
            local questID = pin:GetQuestID()
            if questID then
                icon = QuestCache:Get(questID).isRepeatable and "RepeatableQuest" or "IncompleteQuest"
            end
        end
    end
    if not icon then
        Restore(skin)
        if pin.UpdateButtonAlpha then pin:UpdateButtonAlpha() end
        return
    end

    local selected = skin.hovered or (pin.IsSuperTracked and pin:IsSuperTracked())
    skin.icon:SetTexture(ICON_ROOT .. icon .. (selected and "_Blue_Icon.tga" or "_Icon.tga"))
    if skin.template == "QuestOfferPinTemplate" then
        if pin.pinAlpha then skin.regions[pin.Texture] = pin.pinAlpha end
        HideRegion(skin, pin.Texture)
        -- The native offer alpha includes low-priority/ignored quest fading.
        skin.icon:SetAlpha(pin.pinAlpha or skin.regions[pin.Texture])
    else
        HideRegion(skin, pin.NormalTexture)
        HideRegion(skin, pin.PushedTexture)
        HideRegion(skin, pin.HighlightTexture)
        HideRegion(skin, pin.Display)
        skin.icon:SetAlpha(1)
    end
    skin.icon:Show()
end

local function PreparePin(pin, template)
    if not skins[pin] then
        local skin = {template = template, regions = {}, icon = pin:CreateTexture(nil, "OVERLAY", nil, 7)}
        skins[pin] = skin
        skin.icon:SetSize(32, 32)
        skin.icon:SetPoint("CENTER", pin, "CENTER")
        for _, method in ipairs({"OnAcquired", "UpdateButtonStyle", "SetSelected", "SetSuperTracked", "EvaluateManagedHighlight"}) do
            if pin[method] then hooksecurefunc(pin, method, UpdatePin) end
        end
        pin:HookScript("OnEnter", function(self)
            skin.hovered = true
            UpdatePin(self)
        end)
        pin:HookScript("OnLeave", function(self)
            skin.hovered = false
            UpdatePin(self)
        end)
        pin:HookScript("OnHide", function()
            skin.hovered = false
            Restore(skin)
        end)
        pin:HookScript("OnShow", UpdatePin)
    end
    UpdatePin(pin)
end

local function PrepareTemplate(map, template)
    if not templates[template] then return end
    for pin in map:EnumeratePinsByTemplate(template) do PreparePin(pin, template) end
end

local function UpdateLogTitleHover(title, hovered)
    local owner = QuestScrollFrame.Contents
    local button = owner:FindButtonByQuestID(title.questID)
    if button and skins[button] then
        skins[button].hovered = hovered
        UpdatePin(button)
    end
end

local function PrepareQuestLog()
    local scroll = QuestScrollFrame
    for button in scroll.Contents.buttonPool:EnumerateActive() do
        PreparePin(button, "QuestLog")
    end
    for title in scroll.titleFramePool:EnumerateActive() do
        if not titleHooks[title] then
            title:HookScript("OnEnter", function(self) UpdateLogTitleHover(self, true) end)
            title:HookScript("OnLeave", function(self) UpdateLogTitleHover(self, false) end)
            titleHooks[title] = true
        end
    end
end

local function Install()
    if not logInstalled and QuestScrollFrame and QuestScrollFrame.Contents
        and QuestScrollFrame.Contents.buttonPool and QuestScrollFrame.titleFramePool
        and QuestLogQuests_Update then
        logInstalled = true
        hooksecurefunc("QuestLogQuests_Update", PrepareQuestLog)
        PrepareQuestLog()
    end
    if installed or not WorldMapFrame or not WorldMapFrame.EnumeratePinsByTemplate then return end
    installed = true
    hooksecurefunc(WorldMapFrame, "AcquirePin", PrepareTemplate)
    for template in pairs(templates) do PrepareTemplate(WorldMapFrame, template) end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("SUPER_TRACKING_CHANGED")
watcher:SetScript("OnEvent", function(_, event)
    Install()
    if installed and event == "SUPER_TRACKING_CHANGED" then
        for template in pairs(templates) do PrepareTemplate(WorldMapFrame, template) end
    end
end)
Install()

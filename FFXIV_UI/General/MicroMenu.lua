local addonName, addonEnv = ...
local images = {
    CharacterMicroButton = "Character",
    ProfessionMicroButton = "CraftingLog",
    SpellbookMicroButton = "Actions",
    PlayerSpellsMicroButton = "Talents",
    TalentMicroButton = "Talents",
    LegacyMicroButton = "Legacy",
    AchievementMicroButton = "Achievements",
    QuestLogMicroButton = "Journal",
    GuildMicroButton = "FreeCompany",
    LFDMicroButton = "DutyFinder",
    CollectionsMicroButton = "Collection",
    EJMicroButton = "AdventureGuide",
    HousingMicroButton = "Housing",
    StoreMicroButton = "Shop",
    MainMenuMicroButton = "GameMenu",
    HelpMicroButton = "GameMenu",
}
local skins, hidden = {}, setmetatable({}, {__mode = "k"})
local pending = false
local watcher = CreateFrame("Frame")
local function ApplySpacing(menu)
    if InCombatLockdown() then pending = true; return end
    menu.childXPadding = 2
    menu.childYPadding = 4
    menu:MarkDirty()
end

local function HideArt(region)
    if not region or hidden[region] then return end
    hidden[region] = true
    region:SetAlpha(0)
    hooksecurefunc(region, "SetAlpha", function(self, alpha)
        if alpha ~= 0 then self:SetAlpha(0) end
    end)
end

local function SuppressNative(button)
    local skin = skins[button]
    for _, region in ipairs({button:GetRegions()}) do
        if region:GetObjectType() == "Texture" and region ~= skin.icon and region ~= skin.ring
            and region ~= button.FlashBorder then
            HideArt(region)
        end
    end
    for _, method in ipairs({"GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture"}) do
        HideArt(button[method](button))
    end
    HideArt(button.Emblem)
end

local function Update(button)
    local skin = skins[button]
    local enabled = button:IsEnabled()
    local pushed = button:GetButtonState() == "PUSHED"
    local brightness = pushed and 0.7 or skin.hovered and enabled and 1.15 or 1
    skin.icon:SetVertexColor(brightness, brightness, brightness)
    skin.icon:SetDesaturated(not enabled)
    skin.ring:SetVertexColor(brightness, brightness, brightness)
end

local function SkinButton(button, image)
    if skins[button] then return end
    local skin = {}
    skins[button] = skin
    button.FFXIVUIMicroMenu = skin
    local size = math.min(button:GetWidth(), button:GetHeight())
    skin.icon = button:CreateTexture(nil, "ARTWORK", "FFXIV_MicroMenu" .. image .. "IconTemplate")
    skin.icon:SetSize(size, size)
    skin.mask = button:CreateMaskTexture()
    skin.mask:SetTexture("Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Menu\\CircleMask.tga",
        "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    skin.mask:SetAllPoints(skin.icon)
    skin.icon:AddMaskTexture(skin.mask)
    skin.ring = button:CreateTexture(nil, "OVERLAY", "FFXIV_MicroMenuRingTemplate", 1)
    skin.ring:ClearAllPoints()
    skin.ring:SetAllPoints(skin.icon)
    if button.FlashBorder then
        button.FlashBorder:SetTexture(skin.ring:GetTexture())
        button.FlashBorder:SetBlendMode("ADD")
        button.FlashBorder:ClearAllPoints()
        button.FlashBorder:SetPoint("CENTER", button, "CENTER")
        button.FlashBorder:SetSize(size, size)
    end
    SuppressNative(button)
    for _, method in ipairs({"SetNormalTexture", "SetPushedTexture", "SetDisabledTexture", "SetHighlightTexture",
        "SetNormalAtlas", "SetPushedAtlas", "SetDisabledAtlas", "SetHighlightAtlas"}) do
        hooksecurefunc(button, method, SuppressNative)
    end
    hooksecurefunc(button, "SetButtonState", Update)
    button:HookScript("OnEnter", function(self) skin.hovered = true; Update(self) end)
    button:HookScript("OnLeave", function(self) skin.hovered = false; Update(self) end)
    button:HookScript("OnEnable", Update)
    button:HookScript("OnDisable", Update)
    button:HookScript("OnShow", Update)
    Update(button)
end

local function Install()
    if not MicroMenu then return end
    if InCombatLockdown() then pending = true; return end
    pending = false
    ApplySpacing(MicroMenu)
    HideArt(MicroMenu.BorderArt)
    HideArt(MicroMenu.BackgroundArt)
    for name, image in pairs(images) do
        local button = _G[name]
        if button then SkinButton(button, image) end
    end
    if MicroMenuContainer then MicroMenuContainer:Layout() else MicroMenu:Layout() end
end

watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function(_, event)
    if event ~= "PLAYER_REGEN_ENABLED" or pending then Install() end
end)
Install()

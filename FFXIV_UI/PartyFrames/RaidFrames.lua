local addonName, addonEnv = ...

local TANK_ICON = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\Tank.tga"
local HEALER_ICON = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\Healer.tga"
local DPS_ICON = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\DPS.tga"
local FONT = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\MiedingerMedium.ttf"
local POWER_HEIGHT = 3
local skins, pending = {}, {}
local groups = {}
local hooksInstalled = false
local unavailableReported = false

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function IsRaidFrame(frame)
    if DefaultCompactMiniFrameOptions and frame.optionTable == DefaultCompactMiniFrameOptions then
        return false
    end
    return CompactRaidGroupTypeEnum and frame.groupType == CompactRaidGroupTypeEnum.Raid
        and frame.healthBar and frame.name
end

local function UpdatePower(frame)
    local skin = skins[frame]
    local unit = frame.displayedUnit or frame.unit
    if not skin or not unit then return end

    local powerType, token, altR, altG, altB = UnitPowerType(unit)
    local color = PowerBarColor[token] or PowerBarColor[powerType]
    local r, g, b
    if color then
        r, g, b = color.r, color.g, color.b
    elseif altR and altG and altB then
        r, g, b = altR, altG, altB
    else
        r, g, b = 1, 1, 1
    end
    skin.power:SetStatusBarColor(r, g, b)
    skin.power:SetMinMaxValues(0, UnitPowerMax(unit, powerType))
    skin.power:SetValue(UnitPower(unit, powerType))
end

local function UpdateRoleIcon(frame)
    if not frame.roleIcon then return end
    local unit = frame.displayedUnit or frame.unit
    if not unit then return end
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
    if role == "TANK" then
        frame.roleIcon:SetTexture(TANK_ICON)
        frame.roleIcon:SetTexCoord(0, 1, 0, 1)
        frame.roleIcon:Show()
    elseif role == "HEALER" then
        frame.roleIcon:SetTexture(HEALER_ICON)
        frame.roleIcon:SetTexCoord(0, 1, 0, 1)
        frame.roleIcon:Show()
    elseif role == "DAMAGER" then
        frame.roleIcon:SetTexture(DPS_ICON)
        frame.roleIcon:SetTexCoord(0, 1, 0, 1)
        frame.roleIcon:Show()
    end
end

local function UpdateClass(frame)
    local skin = skins[frame]
    if not skin or not frame.unit then return end
    local _, class = UnitClass(frame.unit)
    if not IsSecret(class) then
        local coords = CLASS_ICON_TCOORDS[class]
        if coords then
            skin.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            skin.icon:SetTexCoord(unpack(coords))
        else
            skin.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            skin.icon:SetTexCoord(0, 1, 0, 1)
        end
    end
    UpdateRoleIcon(frame)
end

local function UpdateHealth(frame)
    local skin = skins[frame]
    local unit = frame.displayedUnit or frame.unit
    if not skin or not unit then return end
    skin.health:SetMinMaxValues(0, UnitHealthMax(unit))
    skin.health:SetValue(UnitHealth(unit))
end

local function ApplyArt(frame)
    frame.healthBar:GetStatusBarTexture():SetAlpha(0)
    frame.name:SetAlpha(0)
    if frame.powerBar then frame.powerBar:SetAlpha(0) end
    if frame.background then
        frame.background:SetColorTexture(0.035, 0.045, 0.05, 0.95)
    end
end

local function ApplyLayout(frame)
    if InCombatLockdown() then
        pending[frame] = true
        return
    end
    pending[frame] = nil
    local skin = skins[frame]
    frame.healthBar:ClearAllPoints()
    frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -3)
    frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 4 + POWER_HEIGHT)
    skin.health:ClearAllPoints()
    skin.health:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -3)
    skin.health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 4 + POWER_HEIGHT)
    skin.power:ClearAllPoints()
    skin.power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 28, 3)
    skin.power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    skin.power:SetHeight(POWER_HEIGHT)
    if frame.roleIcon then
        frame.roleIcon:ClearAllPoints()
        frame.roleIcon:SetPoint("BOTTOMRIGHT", skin.icon, "BOTTOMRIGHT", 2, -2)
        frame.roleIcon:SetSize(9, 9)
    end
end

local function CreateBorder(parent, relativeTo, color)
    for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local edge = parent:CreateTexture(nil, "BORDER", "FFXIV_RaidBorder" .. side .. "Template")
        edge:SetColorTexture(unpack(color))
        if relativeTo ~= parent then
            edge:ClearAllPoints()
            if side == "TOP" or side == "BOTTOM" then
                edge:SetPoint(side .. "LEFT", relativeTo, side .. "LEFT")
                edge:SetPoint(side .. "RIGHT", relativeTo, side .. "RIGHT")
            else
                edge:SetPoint("TOP" .. side, relativeTo, "TOP" .. side)
                edge:SetPoint("BOTTOM" .. side, relativeTo, "BOTTOM" .. side)
            end
        end
    end
end

local function SkinFrame(frame)
    if not IsRaidFrame(frame) then return end
    if not skins[frame] then
        if InCombatLockdown() then
            pending[frame] = true
            return
        end
        local skin = {}
        skins[frame] = skin
        -- Leave Blizzard's status-bar color methods and texture color state untouched.
        skin.health = CreateFrame("StatusBar", nil, frame, "FFXIV_RaidHealthTemplate")
        skin.health:SetFrameLevel(frame.healthBar:GetFrameLevel())
        local iconBase = frame:CreateTexture(nil, "BACKGROUND", "FFXIV_RaidIconBaseTemplate")
        CreateBorder(frame, iconBase, {0.68, 0.55, 0.29, 1})
        skin.icon = frame:CreateTexture(nil, "ARTWORK", "FFXIV_RaidClassIconTemplate")
        skin.icon:ClearAllPoints()
        skin.icon:SetPoint("CENTER", iconBase, "CENTER")
        skin.icon:SetDesaturated(true)
        skin.icon:SetVertexColor(1, 0.84, 0.47)
        CreateBorder(frame, frame, {0.25, 0.25, 0.22, 1})

        skin.power = CreateFrame("StatusBar", nil, frame, "FFXIV_RaidPowerTemplate")
        skin.power:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)

        local shine = frame:CreateTexture(nil, "ARTWORK", "FFXIV_RaidHealthShineTemplate")
        shine:ClearAllPoints()
        shine:SetPoint("TOPLEFT", skin.health, "TOPLEFT")
        shine:SetPoint("TOPRIGHT", skin.health, "TOPRIGHT")
    end
    ApplyArt(frame)
    ApplyLayout(frame)
    UpdateClass(frame)
    UpdateHealth(frame)
    UpdatePower(frame)
end

local function SkinGroup(group)
    if not CompactRaidGroupTypeEnum or group.groupType ~= CompactRaidGroupTypeEnum.Raid then return end
    if InCombatLockdown() then return end
    if not groups[group] then
        groups[group] = true
        group:CreateTexture(nil, "BACKGROUND", "FFXIV_RaidGroupBackgroundTemplate", -2)
        CreateBorder(group, group, {0.5, 0.43, 0.29, 0.9})
    end
    if group.borderFrame and group.borderFrame.Background then
        group.borderFrame.Background:SetAlpha(0)
    end
    if group.title then
        local text = group.title:GetFontString()
        if text then
            text:SetFont(FONT, 11, "OUTLINE")
            text:SetTextColor(1, 0.9, 0.63)
        end
    end
end

local function Initialize()
    if not hooksInstalled then
        if type(DefaultCompactUnitFrameSetup) ~= "function" or not CompactRaidGroupTypeEnum then
            return
        end
        hooksecurefunc("DefaultCompactUnitFrameSetup", SkinFrame)
        hooksecurefunc("CompactUnitFrame_UpdateAll", SkinFrame)
        hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
            if skins[frame] then frame.name:SetAlpha(0) end
        end)
        hooksecurefunc("CompactRaidGroup_UpdateLayout", SkinGroup)
        hooksInstalled = true
    end
    if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
        CompactRaidFrameContainer:ApplyToFrames("normal", SkinFrame)
        CompactRaidFrameContainer:ApplyToFrames("group", SkinGroup)
    end
end

local handlers = {}
handlers.ADDON_LOADED = Initialize
handlers.GROUP_ROSTER_UPDATE = Initialize
handlers.PLAYER_ENTERING_WORLD = function()
    Initialize()
    if not hooksInstalled and not unavailableReported then
        print("FFXIV UI: Raid skin unavailable; Blizzard's compact raid frame API was not found.")
        unavailableReported = true
    end
end
handlers.PLAYER_REGEN_ENABLED = function()
    for frame in pairs(pending) do SkinFrame(frame) end
    Initialize()
end
local function UpdateUnit(_, unit)
    for frame in pairs(skins) do
        if unit == frame.unit or unit == frame.displayedUnit then
            UpdateClass(frame)
            UpdateHealth(frame)
            UpdatePower(frame)
        end
    end
end
for _, event in ipairs({
    "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER",
    "UNIT_DISPLAYPOWER", "UNIT_NAME_UPDATE",
}) do
    handlers[event] = UpdateUnit
end

local watcher = CreateFrame("Frame")
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(self, event, ...)
    handlers[event](self, ...)
end)

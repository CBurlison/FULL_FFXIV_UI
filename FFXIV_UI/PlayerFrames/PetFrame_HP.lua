local addonName, addonEnv = ...

local FONT_ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\"

local frame = PetFrame_HP
local skin = frame.visual
local health = frame.health
local power = frame.power

frame:RegisterForClicks("AnyUp")
frame:SetAttribute("unit", "pet")
frame:SetAttribute("type1", "target")
frame:SetAttribute("type2", "togglemenu")

skin:SetFrameLevel(frame:GetFrameLevel() + 1)
skin.icon:SetDesaturated(true)
skin.icon:SetVertexColor(1, 0.84, 0.47)

local function StyleText(text, font, size)
    text:SetFont(FONT_ROOT .. font .. ".ttf", size, "OUTLINE")
    text:SetTextColor(0.82, 0.94, 1)
    text:SetShadowColor(0, 0.12, 0.2, 1)
    text:SetShadowOffset(1, -1)
end

StyleText(skin.order, "AxisMedium", 11)
skin.order:SetPoint("CENTER", skin.badge, "CENTER")
skin.order:SetTextColor(1, 0.98, 0.87)
skin.order:SetText("P")
StyleText(skin.level, "AxisMedium", 11)
StyleText(skin.name, "AxisMedium", 13)
skin.name:SetWordWrap(false)
StyleText(skin.healthValue, "EurostileExtended", 11)
StyleText(skin.powerValue, "EurostileExtended", 11)

skin.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
skin.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

health:SetStatusBarColor(0.36, 0.78, 1)
local layoutPending = false
local hooksInstalled = false
local watchRegistered = false
local missingPartyReported = false

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function Update()
    health:SetMinMaxValues(0, UnitHealthMax("pet"))
    health:SetValue(UnitHealth("pet"))
    skin.healthValue:SetText(UnitHealth("pet"))
    skin.name:SetText(GetUnitName("pet", false))
    local level = UnitLevel("pet")
    if not IsSecret(level) and level <= 0 then
        skin.level:SetText("Lv??")
    else
        skin.level:SetFormattedText("Lv%s", level)
    end
    local dead = UnitIsDeadOrGhost("pet")
    if not IsSecret(dead) and dead then skin.healthValue:SetText(DEAD) end

    local powerType, token, alternateR, alternateG, alternateB = UnitPowerType("pet")
    local color = PowerBarColor[token] or PowerBarColor[powerType]
    if color then
        power:SetStatusBarColor(color.r, color.g, color.b)
    elseif alternateR and alternateG and alternateB then
        power:SetStatusBarColor(alternateR, alternateG, alternateB)
    else
        power:SetStatusBarColor(1, 1, 1)
    end
    power:SetMinMaxValues(0, UnitPowerMax("pet", powerType))
    power:SetValue(UnitPower("pet", powerType))
    skin.powerValue:SetText(UnitPower("pet", powerType))
end

local function UpdateLayout()
    if InCombatLockdown() then
        layoutPending = true
        return
    end
    if not PartyFrame then
        if not missingPartyReported then
            print("FFXIV UI: Cannot position the pet row; Blizzard's party frame was not found.")
            missingPartyReported = true
        end
        return
    end
    layoutPending = false
    frame:SetScale(PartyFrame:GetEffectiveScale() / UIParent:GetEffectiveScale())
    frame:ClearAllPoints()

    local lastMember
    if PartyFrame:IsShown() and PartyFrame.PartyMemberFramePool then
        for member in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            local exists = UnitExists(member.unitToken)
            if not IsSecret(exists) and exists and member:IsShown() then
                if not lastMember or member.layoutIndex > lastMember.layoutIndex then
                    lastMember = member
                end
            end
        end
    end
    if lastMember then
        frame:SetPoint("TOPLEFT", lastMember, "BOTTOMLEFT", 0, -(PartyFrame.spacing or 10))
    else
        frame:SetPoint("TOPLEFT", PartyFrame, "TOPLEFT", PartyFrame.leftPadding or 0, -(PartyFrame.topPadding or 0))
    end
    -- A separate parent lets the pet stay visible when Blizzard hides the solo party list.
    if not watchRegistered then
        RegisterUnitWatch(frame)
        watchRegistered = true
    end
    if not hooksInstalled then
        hooksecurefunc(PartyFrame, "Layout", UpdateLayout)
        hooksecurefunc(PartyFrame, "SetScale", UpdateLayout)
        PartyFrame:HookScript("OnShow", UpdateLayout)
        PartyFrame:HookScript("OnHide", UpdateLayout)
        PartyFrame:HookScript("OnSizeChanged", UpdateLayout)
        hooksInstalled = true
    end
end

frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetUnit("pet")
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", GameTooltip_Hide)
frame:SetScript("OnShow", Update)

local handlers = {}
handlers.PLAYER_ENTERING_WORLD = function()
    UpdateLayout()
    Update()
end
handlers.GROUP_ROSTER_UPDATE = UpdateLayout
handlers.PLAYER_REGEN_ENABLED = function()
    if layoutPending then UpdateLayout() end
end
handlers.UNIT_PET = function(_, unit)
    if unit == "player" then
        UpdateLayout()
        Update()
    end
end
local function UpdatePet(_, unit)
    if unit == "pet" then Update() end
end
for _, event in ipairs({
    "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER",
    "UNIT_DISPLAYPOWER", "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_FLAGS",
}) do
    handlers[event] = UpdatePet
end

local watcher = CreateFrame("Frame")
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(self, event, ...)
    handlers[event](self, ...)
end)

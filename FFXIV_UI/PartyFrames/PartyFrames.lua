local addonName, addonEnv = ...

local WHITE = "Interface\\Buttons\\WHITE8X8"
local TANK_ICON = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\Tank.tga"
local HEALER_ICON = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\Healer.tga"
local DPS_ICON = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Character\\DPS.tga"
local ROW_WIDTH, ROW_HEIGHT = 284, 32
local BAR_WIDTH, BAR_HEIGHT = 108, 5
local isForever = select(4, GetBuildInfo()) == 16001
local skins, pendingLayouts = {}, {}
local partyHooksInstalled = false
local unsupportedReported = false
local playerRow
local playerLayoutPending = false

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function SetPoint(region, point, relativeTo, relativePoint, x, y)
    region:ClearAllPoints()
    region:SetPoint(point, relativeTo, relativePoint, x, y)
end

local function UpdateValues(member)
    local skin = skins[member]
    local unit = member.unit
    if not skin or not unit then return end

    skin.healthValue:SetText(UnitHealth(unit))
    skin.powerValue:SetText(UnitPower(unit))

    local connected = UnitIsConnected(unit)
    local dead = UnitIsDeadOrGhost(unit)
    if not IsSecret(connected) and not connected then
        skin.healthValue:SetText(PLAYER_OFFLINE)
    elseif not IsSecret(dead) and dead then
        skin.healthValue:SetText(DEAD)
    end
end

local function UpdatePowerColor(member)
    local powerType, powerToken, alternateR, alternateG, alternateB = UnitPowerType(member.unit)
    local color = PowerBarColor[powerToken] or PowerBarColor[powerType]
    local r, g, b
    if color then
        r, g, b = color.r, color.g, color.b
    elseif alternateR and alternateG and alternateB then
        r, g, b = alternateR, alternateG, alternateB
    else
        r, g, b = 1, 1, 1
    end
    member.ManaBar:GetStatusBarTexture():SetVertexColor(r, g, b)
end

local function UpdateRoleIcon(member)
    local overlay = member.PartyMemberOverlay
    if not overlay or not overlay.RoleIcon then return end
    local unit = member.GetUnit and member:GetUnit() or member.unit
    if not unit then return end
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
    if role == "TANK" then
        overlay.RoleIcon:SetTexture(TANK_ICON)
        overlay.RoleIcon:SetTexCoord(0, 1, 0, 1)
        overlay.RoleIcon:Show()
    elseif role == "HEALER" then
        overlay.RoleIcon:SetTexture(HEALER_ICON)
        overlay.RoleIcon:SetTexCoord(0, 1, 0, 1)
        overlay.RoleIcon:Show()
    elseif role == "DAMAGER" then
        overlay.RoleIcon:SetTexture(DPS_ICON)
        overlay.RoleIcon:SetTexCoord(0, 1, 0, 1)
        overlay.RoleIcon:Show()
    end
end

local function UpdateIdentity(member)
    local skin = skins[member]
    local unit = member.GetUnit and member:GetUnit() or member.unit
    if not skin or not unit then return end

    if isForever then
        skin.name:SetText(GetUnitName(unit, false))
    else
        skin.name:SetText(UnitName(unit))
    end
    local level = UnitLevel(unit)
    if not IsSecret(level) and level <= 0 then
        skin.level:SetText("Lv??")
    else
        skin.level:SetFormattedText("Lv%s", level)
    end
    skin.order:SetText(member == playerRow and 1 or member.layoutIndex + 1)

    local _, class = UnitClass(unit)
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
    UpdatePowerColor(member)
    UpdateValues(member)
    UpdateRoleIcon(member)
end

local function ApplyBarArt(bar)
    bar:SetStatusBarTexture(WHITE)
    bar:GetStatusBarTexture():SetVertexColor(0.36, 0.78, 1)
    for _, key in ipairs({"CenterText", "LeftText", "RightText"}) do
        if bar[key] then bar[key]:SetAlpha(0) end
    end
end

local function ApplyArt(member)
    local healthContainer = member.HealthBarContainer
    ApplyBarArt(healthContainer.HealthBar)
    ApplyBarArt(member.ManaBar)
    UpdatePowerColor(member)
    healthContainer.HealthBarMask:SetTexture(WHITE)
    member.ManaBar.ManaBarMask:SetTexture(WHITE)

    member.Portrait:SetAlpha(0)
    member.Portrait:Hide()
    member.Texture:SetAlpha(0)
    member.VehicleTexture:SetAlpha(0)
    member.Flash:SetColorTexture(1, 0.2, 0.1, 0.12)
    member.Name:SetAlpha(0)
    member.PartyMemberOverlay.Status:SetColorTexture(0.5, 0.8, 1, 0.12)
    for _, key in ipairs({"CenterText", "LeftText", "RightText"}) do
        healthContainer[key]:SetAlpha(0)
    end
end

local function ApplyLayout(member)
    if InCombatLockdown() then
        pendingLayouts[member] = true
        return
    end
    pendingLayouts[member] = nil

    local skin = skins[member]
    local healthContainer = member.HealthBarContainer
    member:SetSize(ROW_WIDTH, ROW_HEIGHT)
    SetPoint(healthContainer, "TOPLEFT", member, "TOPLEFT", 34, -16)
    healthContainer:SetSize(BAR_WIDTH, BAR_HEIGHT)
    healthContainer.HealthBar:ClearAllPoints()
    healthContainer.HealthBar:SetAllPoints(healthContainer)
    healthContainer.HealthBarMask:ClearAllPoints()
    healthContainer.HealthBarMask:SetAllPoints(healthContainer)

    SetPoint(member.ManaBar, "TOPLEFT", member, "TOPLEFT", 152, -16)
    member.ManaBar:SetSize(BAR_WIDTH, BAR_HEIGHT)
    member.ManaBar.ManaBarMask:ClearAllPoints()
    member.ManaBar.ManaBarMask:SetAllPoints(member.ManaBar)

    SetPoint(member.AuraFrameContainer, "TOPLEFT", member, "TOPRIGHT", 6, -2)
    SetPoint(member.PetFrame, "TOPLEFT", member, "TOPLEFT", 34, -35)
    SetPoint(member.ReadyCheck, "CENTER", skin.icon, "CENTER", 0, 0)
    SetPoint(member.ResurrectableIndicator, "CENTER", skin.icon, "CENTER", 0, 0)
    local overlay = member.PartyMemberOverlay
    member.Flash:ClearAllPoints()
    member.Flash:SetAllPoints(member)
    overlay.Status:ClearAllPoints()
    overlay.Status:SetAllPoints(member)
    SetPoint(overlay.LeaderIcon, "BOTTOMLEFT", skin.icon, "TOPLEFT", -3, -4)
    SetPoint(overlay.GuideIcon, "BOTTOMLEFT", skin.icon, "TOPLEFT", -3, -4)
    SetPoint(overlay.RoleIcon, "TOPRIGHT", member, "TOPRIGHT", -4, -2)
    SetPoint(overlay.PVPIcon, "TOPRIGHT", member, "TOPRIGHT", -3, -17)
    overlay.PVPIcon:SetSize(14, 14)
    SetPoint(overlay.Disconnect, "CENTER", skin.icon, "CENTER", 0, 0)
    overlay.Disconnect:SetSize(26, 26)
    SetPoint(member.PowerBarAlt, "LEFT", member, "RIGHT", 6, 0)

    ApplyArt(member)
end

local function RefreshArt(member)
    ApplyArt(member)
    ApplyLayout(member)
    UpdateIdentity(member)
end

local function AddBarBackground(bar)
    bar:CreateTexture(nil, "BACKGROUND", "FFXIV_PartyBarEdgeTemplate", -2)
    bar:CreateTexture(nil, "BACKGROUND", "FFXIV_PartyBarBackgroundTemplate", -1)
    bar:CreateTexture(nil, "OVERLAY", "FFXIV_PartyBarShineTemplate")
end

local function CreateRowVisual(member)
    local visual = CreateFrame("Frame", nil, member, "FFXIV_PartyRowVisualTemplate")
    visual:SetFrameLevel(member:GetFrameLevel() + 1)
    visual.icon:SetDesaturated(true)
    visual.icon:SetVertexColor(1, 0.84, 0.47)
    visual.order:ClearAllPoints()
    visual.order:SetPoint("CENTER", visual.badge, "CENTER")
    return visual
end

addonEnv.PartyRowStyle = {
    CreateVisual = CreateRowVisual,
    AddBarBackground = AddBarBackground,
    width = ROW_WIDTH,
    height = ROW_HEIGHT,
    barWidth = BAR_WIDTH,
    barHeight = BAR_HEIGHT,
}

local function UpdatePlayer()
    if not playerRow then return end
    local health = playerRow.HealthBarContainer.HealthBar
    health:SetMinMaxValues(0, UnitHealthMax("player"))
    health:SetValue(UnitHealth("player"))
    local powerType = UnitPowerType("player")
    playerRow.ManaBar:SetMinMaxValues(0, UnitPowerMax("player", powerType))
    playerRow.ManaBar:SetValue(UnitPower("player", powerType))
    UpdateIdentity(playerRow)
end

local function LayoutPlayer()
    if InCombatLockdown() then
        playerLayoutPending = true
        return
    end
    if not playerRow then return end
    playerLayoutPending = false
    local firstMember
    for member in PartyFrame.PartyMemberFramePool:EnumerateActive() do
        if not firstMember or member.layoutIndex < firstMember.layoutIndex then
            firstMember = member
        end
    end
    playerRow:ClearAllPoints()
    if firstMember then
        playerRow:SetPoint("BOTTOMLEFT", firstMember, "TOPLEFT", 0, PartyFrame.spacing or 10)
    else
        playerRow:SetPoint("TOPLEFT", PartyFrame, "TOPLEFT")
    end
end

local function CreatePlayerRow()
    if playerRow or InCombatLockdown() then return end
    playerRow = CreateFrame("Button", "FFXIV_PartyPlayer", PartyFrame, "FFXIV_PartyPlayerTemplate")
    playerRow.ignoreLayout = true
    playerRow.unit = "player"
    playerRow:RegisterForClicks("AnyUp")
    playerRow:SetAttribute("unit", "player")
    playerRow:SetAttribute("type1", "target")
    playerRow:SetAttribute("type2", "togglemenu")
    skins[playerRow] = CreateRowVisual(playerRow)

    for _, bar in ipairs({playerRow.health, playerRow.ManaBar}) do
        bar:SetFrameLevel(playerRow:GetFrameLevel() + 1)
        AddBarBackground(bar)
    end
    playerRow.HealthBarContainer = {HealthBar = playerRow.health}
    playerRow:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetUnit("player")
        GameTooltip:Show()
    end)
    playerRow:SetScript("OnLeave", GameTooltip_Hide)
    playerRow:SetScript("OnShow", UpdatePlayer)
    LayoutPlayer()
    UpdatePlayer()
    RegisterStateDriver(playerRow, "visibility", "[group:raid] hide; [group:party] show; hide")
    hooksecurefunc(PartyFrame, "Layout", LayoutPlayer)
end

local function SkinMember(member)
    if skins[member] then
        RefreshArt(member)
        return
    end
    if InCombatLockdown() then
        pendingLayouts[member] = true
        return
    end

    skins[member] = CreateRowVisual(member)
    local health = member.HealthBarContainer.HealthBar
    AddBarBackground(health)
    AddBarBackground(member.ManaBar)
    for _, bar in ipairs({health, member.ManaBar}) do
        hooksecurefunc(bar, "SetStatusBarColor", function(self)
            if self == member.ManaBar then
                UpdatePowerColor(member)
            else
                self:GetStatusBarTexture():SetVertexColor(0.36, 0.78, 1)
            end
        end)
        hooksecurefunc(bar, "SetValue", function()
            UpdateValues(member)
        end)
    end
    -- Art switches also reset bar geometry, including when entering a vehicle.
    hooksecurefunc(member, "ToPlayerArt", RefreshArt)
    hooksecurefunc(member, "ToVehicleArt", RefreshArt)
    hooksecurefunc(member, "UpdateMember", UpdateIdentity)
    -- Low-health portrait pulsing must not bring the original portrait back.
    hooksecurefunc(member.Portrait, "Show", function(self) self:Hide() end)
    RefreshArt(member)
end

local function Initialize()
    if not PartyFrame or not PartyFrame.PartyMemberFramePool then
        if not unsupportedReported then
            print("FFXIV UI: Party frame skin unavailable; Blizzard's party frame API was not found.")
            unsupportedReported = true
        end
        return
    end
    if not partyHooksInstalled then
        hooksecurefunc(PartyFrame, "InitializePartyMemberFrames", Initialize)
        partyHooksInstalled = true
    end
    for member in PartyFrame.PartyMemberFramePool:EnumerateActive() do
        SkinMember(member)
    end
    CreatePlayerRow()
    if PartyFrame.Background then PartyFrame.Background:SetAlpha(0) end
    if not InCombatLockdown() then PartyFrame:Layout() end
end

local handlers = {}
handlers.PLAYER_ENTERING_WORLD = Initialize
handlers.GROUP_ROSTER_UPDATE = Initialize
handlers.PLAYER_REGEN_ENABLED = function()
    for member in pairs(pendingLayouts) do
        SkinMember(member)
    end
    Initialize()
    if playerLayoutPending then LayoutPlayer() end
end
local function UpdateUnit(_, unit)
    if unit == "player" then UpdatePlayer() end
    for member in pairs(skins) do
        if member ~= playerRow and (unit == member.unit or unit == member.unitToken or unit == member.overrideUnit) then
            UpdateIdentity(member)
        end
    end
end
handlers.UNIT_NAME_UPDATE = UpdateUnit
handlers.UNIT_LEVEL = UpdateUnit
handlers.UNIT_CONNECTION = UpdateUnit
handlers.UNIT_FLAGS = UpdateUnit
handlers.UNIT_DISPLAYPOWER = UpdateUnit
handlers.UNIT_HEALTH = UpdateUnit
handlers.UNIT_MAXHEALTH = UpdateUnit
handlers.UNIT_POWER_UPDATE = UpdateUnit
handlers.UNIT_MAXPOWER = UpdateUnit

local watcher = CreateFrame("Frame")
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(self, event, ...)
    handlers[event](self, ...)
end)

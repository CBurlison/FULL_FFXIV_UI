local addonName, addonEnv = ...

local style = addonEnv.PartyRowStyle
local rows, units, orderedUnits = {}, {}, {}
local plateVisuals = {}
local enabled, inCombat = false, InCombatLockdown()
local isForever = select(4, GetBuildInfo()) == 16001
local list = FFXIV_EnemyList
list:SetParent(FFXIV_UI_Anchors.EnemyList)
list:SetAllPoints()

local title = list.title
local status = list.status

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function MatchesUnit(unit, other)
    local matches = UnitIsUnit(unit, other)
    return not IsSecret(matches) and matches == true
end

local function CreatePlateVisual(plate)
    local unitFrame = plate.UnitFrame
    local health = unitFrame and unitFrame.healthBar
    local anchor = health or unitFrame or plate
    local visual = CreateFrame("Frame", nil, plate, "FFXIV_EnemyListPlateTemplate")
    visual:SetAllPoints(anchor)
    visual:SetFrameLevel(anchor:GetFrameLevel() + 10)
    local badge = visual.badge
    badge:ClearAllPoints()
    badge:SetPoint("TOPLEFT", visual.number, "TOPLEFT", -4, 2)
    badge:SetPoint("BOTTOMRIGHT", visual.number, "BOTTOMRIGHT", 4, -2)

    return visual
end

local function CreateRowOutline(row)
    local visual = row.outline
    visual:SetFrameLevel(row:GetFrameLevel() + 10)
    visual.edges = {visual.top, visual.bottom, visual.left, visual.right}
    for _, edge in ipairs(visual.edges) do
        edge:SetColorTexture(1, 0.8, 0.3, 0.95)
    end
    return visual
end

local CheckMouseover
local function RefreshRowOutlines()
    local hasMouseover = false
    for _, row in ipairs(rows) do
        local active = enabled and inCombat and row:IsShown()
        local targeted = active and MatchesUnit(row.unit, "target")
        local hovered = active and MatchesUnit(row.unit, "mouseover")
        for _, edge in ipairs(row.outline.edges) do
            edge:SetColorTexture(1, 0.8, 0.3, targeted and 0.95 or 0.3)
        end
        row.outline:SetShown(targeted or hovered)
        hasMouseover = hasMouseover or hovered
    end
    -- UPDATE_MOUSEOVER_UNIT does not reliably fire when the cursor leaves a unit.
    list:SetScript("OnUpdate", hasMouseover and CheckMouseover or nil)
end

CheckMouseover = function()
    RefreshRowOutlines()
end

local function RefreshPlateVisuals()
    RefreshRowOutlines()
    for _, visual in pairs(plateVisuals) do
        if not visual:IsForbidden() then visual:Hide() end
    end
    if not enabled or not inCombat or not C_NamePlate.GetNamePlateForUnit then return end
    for index, row in ipairs(rows) do
        if row:IsShown() then
            local plate = C_NamePlate.GetNamePlateForUnit(row.unit)
            if plate and not plate:IsForbidden() then
                local visual = plateVisuals[plate]
                if not visual then
                    visual = CreatePlateVisual(plate)
                    plateVisuals[plate] = visual
                end
                local unitFrame = plate.UnitFrame
                local anchor = (unitFrame and unitFrame.healthBar) or unitFrame or plate
                visual:ClearAllPoints()
                visual:SetAllPoints(anchor)
                visual:SetFrameLevel(anchor:GetFrameLevel() + 10)
                visual.number:SetText(index)
                visual:Show()
            end
        end
    end
end

local function AttackingPlayer(unit)
    local exists = UnitExists(unit .. "target")
    if IsSecret(exists) or not exists then return nil end
    local attacking = UnitIsUnit(unit .. "target", "player")
    if IsSecret(attacking) then return nil end
    return attacking
end

local function IsEngaged(unit)
    local attackable = UnitCanAttack("player", unit)
    if IsSecret(attackable) then return nil end
    if not attackable then return false end
    local dead = UnitIsDeadOrGhost(unit)
    if not IsSecret(dead) and dead then return false end

    -- A threat-table entry proves player involvement; generic combat flags do not.
    local threat = UnitThreatSituation("player", unit)
    local attacking = AttackingPlayer(unit)
    if attacking == true then return true end
    if IsSecret(threat) then return nil end
    return threat ~= nil
end

local function CreateRow(unit)
    local row = CreateFrame("Frame", nil, list, "FFXIV_EnemyListRowTemplate")
    row:SetSize(style.width, style.height)
    row.unit = unit
    row.skin = style.CreateVisual(row)
    row.skin.icon:SetTexture("Interface\\Icons\\Ability_Creature_Cursed_02")
    row.skin.powerValue:Hide()
    row.skin.healthValue:ClearAllPoints()
    row.skin.healthValue:SetPoint("TOPRIGHT", row, "TOPLEFT", 260, -22)
    row.skin.healthValue:SetTextColor(1, 0.7, 0.7)
    row.health:SetSize(226, style.barHeight)
    row.health:SetFrameLevel(row:GetFrameLevel() + 1)
    style.AddBarBackground(row.health)

    row.marker = row.skin.icon:GetParent():CreateFontString(nil, "OVERLAY", "FFXIV_EnemyListMarkerTemplate")
    row.marker:ClearAllPoints()
    row.marker:SetPoint("CENTER", row.skin.icon, "CENTER")
    local function GetUnit() return row.unit end
    local auras = addonEnv.CreateUnitAuraRow(row, GetUnit, "buffs", AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful), "Buffs", 6, 0, 18, 4)
    addonEnv.CreateUnitAuraRow(row, GetUnit, "debuffs", AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful), "Debuffs", 6, 0, 18, 8, auras)
    row.auras = {auras}
    local cast = row.cast
    cast:SetFrameLevel(row:GetFrameLevel() + 1)
    style.AddBarBackground(cast)
    row.outline = CreateRowOutline(row)
    return row
end

local function UpdateCast(row)
    local duration = UnitCastingDuration(row.unit)
    local name, icon, notInterruptible
    local direction = 0
    if duration then
        local _
        name, _, icon, _, _, _, _, notInterruptible = UnitCastingInfo(row.unit)
    else
        duration = UnitChannelDuration(row.unit)
        if duration then
            local _
            name, _, icon, _, _, _, notInterruptible = UnitChannelInfo(row.unit)
            direction = 1
        end
    end
    local cast = row.cast
    if not duration then
        cast:Hide()
        row:SetHeight(FFXIV_UI_DB.enemyListDynamicCasting ~= false and style.height or 54)
        return
    end
    cast:SetTimerDuration(duration, 0, direction)
    cast.name:SetText(name)
    cast.icon:SetTexture(icon)
    -- The native color setter accepts secret interruptibility without branching on it.
    cast.interrupt:SetVertexColorFromBoolean(notInterruptible,
        CreateColor(1, 0.3, 0.2, 1), CreateColor(1, 0.3, 0.2, 0))
    cast:GetStatusBarTexture():SetVertexColorFromBoolean(notInterruptible,
        CreateColor(0.6, 0.6, 0.6, 1), CreateColor(1, 0.8, 0.3, 1))
    cast:Show()
    row:SetHeight(54)
end

local function LayoutRows()
    local y = 0
    if title:IsShown() then y = y - 18 end
    status:ClearAllPoints()
    status:SetPoint("TOPLEFT", list, "TOPLEFT", 0, y)
    if status:IsShown() then y = y - 18 end
    for _, row in ipairs(rows) do
        if row:IsShown() then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, y)
            y = y - row:GetHeight() - 4
        end
    end
end

local function UpdateHealth(row)
    row.health:SetMinMaxValues(0, UnitHealthMax(row.unit))
    row.health:SetValue(UnitHealth(row.unit))
    row.skin.healthValue:SetText(UnitHealth(row.unit))
end

local function UpdateRow(row, index)
    if isForever then
        row.skin.name:SetText(GetUnitName(row.unit, false))
    else
        row.skin.name:SetText(UnitName(row.unit))
    end
    local level = UnitLevel(row.unit)
    if not IsSecret(level) and level <= 0 then
        row.skin.level:SetText("Lv??")
    else
        row.skin.level:SetFormattedText("Lv%s", level)
    end
    row.skin.order:SetText(index)
    local attacking = AttackingPlayer(row.unit)
    if attacking == nil then
        row.marker:SetText("?")
        row.marker:SetTextColor(1, 0.8, 0.3)
    elseif attacking then
        row.marker:SetText("!")
        row.marker:SetTextColor(1, 0.2, 0.2)
    else
        row.marker:SetText("-")
        row.marker:SetTextColor(0.65, 0.65, 0.65)
    end
    UpdateHealth(row)
    UpdateCast(row)
end

local function Refresh()
    title:SetShown(FFXIV_UI_DB.enemyListShowLabel ~= false)
    list:SetShown(enabled and inCombat)
    if not enabled or not inCombat then
        for _, row in ipairs(rows) do
            row:Hide()
            row.cast:Hide()
            for _, aura in ipairs(row.auras) do aura:SetEnabled(false) end
        end
        RefreshPlateVisuals()
        return
    end
    local engaged, unknown = {}, false
    for _, unit in ipairs(orderedUnits) do
        local included = IsEngaged(unit)
        if included then
            engaged[#engaged + 1] = unit
        elseif included == nil then
            unknown = true
        end
    end
    status:SetText(unknown and "Some combat data unavailable" or "! Targeting you   - Other target   ? Unknown")
    if #engaged == 0 and not unknown then status:SetText("No engaged enemies with visible nameplates") end
    status:SetShown(unknown or #engaged == 0 or FFXIV_UI_DB.enemyListShowLegend ~= false)
    for index, unit in ipairs(engaged) do
        local row = rows[index]
        if not row then
            row = CreateRow(unit)
            rows[index] = row
        end
        local changed = row.unit ~= unit
        row.unit = unit
        for _, aura in ipairs(row.auras) do
            if changed then aura:SetUnit(unit) end
            aura:SetEnabled(true)
            if changed or not row:IsShown() then aura:UpdateAllAuras() end
        end
        UpdateRow(row, index)
        row:Show()
    end
    for index = #engaged + 1, #rows do
        rows[index]:Hide()
        rows[index].cast:Hide()
        for _, aura in ipairs(rows[index].auras) do aura:SetEnabled(false) end
    end
    LayoutRows()
    RefreshPlateVisuals()
end

local function AddUnit(unit)
    if IsSecret(unit) or type(unit) ~= "string" or not unit:match("^nameplate%d+$") or units[unit] then return end
    units[unit] = true
    orderedUnits[#orderedUnits + 1] = unit
end

local function Scan()
    units, orderedUnits = {}, {}
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if not plate:IsForbidden() then
            local unit
            if plate.GetUnit then
                unit = plate:GetUnit()
            else
                unit = plate.namePlateUnitToken
            end
            AddUnit(unit)
        end
    end
    Refresh()
end

function addonEnv.SetEnemyListEnabled(value)
    if not C_NamePlate or not C_NamePlate.GetNamePlates then
        print("FFXIV UI: Enemy List unavailable: this client has no nameplate API.")
        return
    end
    enabled = value == true
    FFXIV_UI_DB.enemyListEnabled = enabled
    Scan()
end

local settings = {
    enemyListShowLabel = true,
    enemyListShowLegend = true,
    enemyListDynamicCasting = true,
}

function addonEnv.SetEnemyListSetting(key, value)
    if not settings[key] or type(value) ~= "boolean" then
        print("FFXIV UI: Invalid Enemy List setting.")
        return
    end
    FFXIV_UI_DB[key] = value
    Refresh()
end

local handlers = {
    ADDON_LOADED = function(_, name)
        if name ~= addonName then return end
        if FFXIV_UI_DB.enemyListEnabled == nil then FFXIV_UI_DB.enemyListEnabled = true end
        for key in pairs(settings) do
            if FFXIV_UI_DB[key] == nil then FFXIV_UI_DB[key] = true end
        end
        addonEnv.SetEnemyListEnabled(FFXIV_UI_DB.enemyListEnabled == true)
    end,
    PLAYER_ENTERING_WORLD = function() inCombat = InCombatLockdown(); Scan() end,
    NAME_PLATE_UNIT_ADDED = function(_, unit) AddUnit(unit); Refresh() end,
    NAME_PLATE_UNIT_REMOVED = function(_, unit)
        if IsSecret(unit) then return end
        units[unit] = nil
        for index, current in ipairs(orderedUnits) do
            if current == unit then table.remove(orderedUnits, index); break end
        end
        Refresh()
    end,
    PLAYER_REGEN_DISABLED = function() inCombat = true; Refresh() end,
    PLAYER_REGEN_ENABLED = function() inCombat = false; Refresh() end,
    UNIT_THREAT_LIST_UPDATE = Refresh,
    UNIT_THREAT_SITUATION_UPDATE = Refresh,
    UNIT_TARGET = Refresh,
    UNIT_FLAGS = Refresh,
    UNIT_FACTION = Refresh,
    UNIT_NAME_UPDATE = Refresh,
    PLAYER_TARGET_CHANGED = RefreshPlateVisuals,
    UPDATE_MOUSEOVER_UNIT = RefreshPlateVisuals,
}
local function HealthChanged(_, unit)
    if IsSecret(unit) or not enabled or not inCombat then return end
    for _, row in ipairs(rows) do
        if row.unit == unit and row:IsShown() then
            if IsEngaged(unit) ~= true then
                Refresh()
            else
                UpdateHealth(row)
            end
            return
        end
    end
end
handlers.UNIT_HEALTH = HealthChanged
handlers.UNIT_MAXHEALTH = HealthChanged
local function CastChanged(_, unit)
    if IsSecret(unit) or not enabled or not inCombat then return end
    for _, row in ipairs(rows) do
        if row.unit == unit and row:IsShown() then
            UpdateCast(row)
            LayoutRows()
            return
        end
    end
end
for _, event in ipairs({
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
    "UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_UPDATE", "UNIT_SPELLCAST_EMPOWER_STOP",
}) do
    handlers[event] = CastChanged
end
local watcher = CreateFrame("Frame")
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(self, event, ...)
    handlers[event](self, ...)
end)

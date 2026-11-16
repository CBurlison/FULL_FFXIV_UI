local methods, frames, allRows, auraRows = {}, {}, {}, {}
local watcher, list
local combat = false
local data, plates = {}, {}
local target, mouseover
local targetRestricted, mouseoverRestricted = false, false
local secret = setmetatable({secret = true}, {
    __lt = function() error("Compared secret") end,
    __le = function() error("Compared secret") end,
    __tostring = function() error("Formatted secret") end,
})
local function object()
    return setmetatable({shown = true, scripts = {}, events = {}}, {__index = methods})
end
function methods:SetPoint(...)
    self.point = {...}
    self.points = self.points or {}
    self.points[self.point[1]] = self.point
end
function methods:ClearAllPoints() self.point = nil; self.points = {} end
function methods:SetAllPoints(anchor) self.anchor = anchor end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(value) self.width = value end
function methods:SetHeight(value) self.height = value end
function methods:GetHeight() return self.height end
function methods:SetFrameLevel(value) self.frameLevel = value end
function methods:GetFrameLevel() return self.frameLevel or 1 end
function methods:IsForbidden() return false end
function methods:CreateTexture() return object() end
function methods:SetColorTexture(...) self.color = {...} end
function methods:EnableMouse(value) self.mouse = value end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:SetShown(value) self.shown = value end
function methods:IsShown() return self.shown end
function methods:GetParent() return self.parent end
function methods:SetParent(parent) self.parent = parent end
function methods:SetText(value) self.text = value end
function methods:SetFormattedText(format, value)
    self.text = value == secret and value or string.format(format, value)
end
function methods:SetFont() end
function methods:SetTextColor(...) self.color = {...} end
function methods:SetTexture(value) self.texture = value end
function methods:SetTexCoord(...) end
function methods:SetJustifyH() end
function methods:SetWordWrap() end
function methods:SetVertexColorFromBoolean(value, yes, no) self.boolean, self.yesColor, self.noColor = value, yes, no end
function methods:GetStatusBarTexture() return self end
function methods:SetTimerDuration(duration, interpolation, direction) self.duration, self.direction = duration, direction end
function methods:CreateFontString(_, layer, template)
    local text = object()
    text.parent, text.layer, text.template = self, layer, template
    if template then
        assert(template == "FFXIV_EnemyListMarkerTemplate")
        text:SetPoint("TOPLEFT", self, "TOPLEFT")
    end
    self.texts = self.texts or {}
    self.texts[#self.texts + 1] = text
    return text
end
function methods:SetStatusBarTexture(value) self.texture = value end
function methods:SetStatusBarColor(...) self.color = {...} end
function methods:SetMinMaxValues(low, high) self.low, self.high = low, high end
function methods:SetValue(value) self.value = value end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetScript(script, callback) self.scripts[script] = callback end
function methods:SetUnit(unit) self.unit = unit end
function methods:SetEnabled(value) self.enabled = value end
function methods:UpdateAllAuras() self.refreshes = (self.refreshes or 0) + 1 end
function CreateFrame(kind, name, parent, template)
    assert(not template or template == "FFXIV_EnemyListRowTemplate"
        or template == "FFXIV_EnemyListPlateTemplate", "Enemy visuals must not be secure buttons")
    local frame = object()
    frame.parent, frame.kind = parent, kind
    frames[#frames + 1] = frame
    if template == "FFXIV_EnemyListPlateTemplate" then
        assert(kind == "Frame" and parent ~= list)
        frame.template, frame.mouse = template, false
        frame.number, frame.badge = object(), object()
        frame.number:SetPoint("RIGHT", frame, "LEFT", -6, 0)
        frame.badge:SetColorTexture(0.08, 0.06, 0.03, 0.9)
        frame.badge:SetPoint("CENTER", frame, "CENTER")
    elseif template == "FFXIV_EnemyListRowTemplate" then
        assert(kind == "Frame" and parent == list)
        frame.template, frame.mouse = template, false
        frame.health, frame.cast = object(), object()
        frame.health.parent, frame.cast.parent = frame, frame
        frame.health:SetPoint("TOPLEFT", 34, -16)
        frame.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        frame.health:SetStatusBarColor(0.85, 0.12, 0.16)
        local cast = frame.cast
        cast:SetSize(206, 13)
        cast:SetPoint("TOPLEFT", 54, -37)
        cast:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        cast:SetStatusBarColor(1, 1, 1)
        cast.icon, cast.name, cast.interrupt = object(), object(), object()
        cast.icon:SetSize(16, 16)
        cast.interrupt:SetSize(12, 12)
        cast:Hide()
        frame.outline = object()
        frame.outline.parent, frame.outline.mouse = frame, false
        frame.outline:SetAllPoints(frame)
        for _, key in ipairs({"top", "bottom", "left", "right"}) do
            frame.outline[key] = object()
        end
    end
    if name == "FFXIV_EnemyList" then list = frame end
    if not parent then watcher = frame end
    return frame
end
function InCombatLockdown() return combat end
function GetBuildInfo() return "", "", "", 16001 end
function issecretvalue(value) return value == secret end
function UnitCanAttack(_, unit) return data[unit].attackable end
function UnitIsDeadOrGhost(unit) return data[unit].dead end
function UnitThreatSituation(player, unit)
    assert(player == "player")
    return data[unit].threat
end
function UnitExists(unit)
    local enemy = unit:match("^(nameplate%d+)target$")
    return data[enemy].targetExists
end
function UnitIsUnit(unit, player)
    if player == "target" then return targetRestricted and secret or unit == target end
    if player == "mouseover" then return mouseoverRestricted and secret or unit == mouseover end
    assert(player == "player")
    return data[unit:match("^(nameplate%d+)target$")].targetPlayer
end
function UnitHealth(unit) return data[unit].health end
function UnitHealthMax(unit) return data[unit].maximum end
function UnitLevel(unit) return data[unit].level end
function UnitName(unit) return data[unit].name end
function GetUnitName(unit) return data[unit].fullName end
function CreateColor(r, g, b, a) return {r = r, g = g, b = b, a = a} end
function UnitCastingDuration(unit) return data[unit].castDuration end
function UnitChannelDuration(unit) return data[unit].channelDuration end
function UnitCastingInfo(unit)
    local enemy = data[unit]
    return enemy.spellName, nil, enemy.spellIcon, secret, secret, nil, nil, enemy.notInterruptible
end
function UnitChannelInfo(unit)
    local enemy = data[unit]
    return enemy.spellName, nil, enemy.spellIcon, secret, secret, nil, enemy.notInterruptible
end
C_NamePlate = {
    GetNamePlates = function() return plates end,
    GetNamePlateForUnit = function(unit)
        for _, frame in ipairs(plates) do
            if frame.token == unit then return frame end
        end
    end,
}
FFXIV_UI_Anchors = {EnemyList = object()}
FFXIV_UI_DB = {}
AuraUtil = {
    AuraFilters = {Helpful = "HELPFUL", Harmful = "HARMFUL"},
    CreateFilterString = function(filter) return filter end,
}
local ns = {
    PartyRowStyle = {
        width = 284, height = 32, barHeight = 5,
        CreateVisual = function(row)
            allRows[#allRows + 1] = row
            local icon = object()
            icon.parent = row
            return {icon = icon, order = object(), level = object(), name = object(),
                healthValue = object(), powerValue = object()}
        end,
        AddBarBackground = function() end,
    },
    CreateUnitAuraRow = function(parent, getUnit, group, filter, style, x, y, size, limit, container)
        if container then
            assert(container.parent == parent and container.x == x and container.y == y)
            assert(group == "debuffs" and filter == "HARMFUL" and style == "Debuffs" and limit == 8)
            container.combined = true
            return container
        end
        local aura = object()
        aura.parent, aura.getUnit, aura.unit = parent, getUnit, getUnit()
        aura.group, aura.filter, aura.style = group, filter, style
        aura.x, aura.y, aura.size, aura.limit = x, y, size, limit
        auraRows[#auraRows + 1] = aura
        return aura
    end,
}
local function plate(unit, modern, forbidden)
    local frame = {
        token = unit,
        GetFrameLevel = function() return 2 end,
        IsForbidden = function() return forbidden end,
        SetPoint = function() error("Moved native nameplate") end,
        SetParent = function() error("Reparented native nameplate") end,
        Hide = function() error("Hid native nameplate") end,
    }
    if modern then frame.GetUnit = function() return unit end else frame.namePlateUnitToken = unit end
    return frame
end
local function enemy(overrides)
    local value = {attackable = true, health = 700, maximum = 1000,
        level = 10, name = "Enemy", fullName = "Enemy Fullname", targetExists = true, targetPlayer = false}
    for key, field in pairs(overrides or {}) do value[key] = field end
    return value
end
local function event(name, ...) watcher.scripts.OnEvent(watcher, name, ...) end
local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end
local xml = readFile("FFXIV_UI\\PartyFrames\\EnemyList.xml")
local markerTemplate = assert(xml:match('<FontString name="FFXIV_EnemyListMarkerTemplate".-</FontString>'))
for _, text in ipairs({
    'virtual="true"',
    'font="Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisMedium.ttf" outline="NORMAL"',
    '<FontHeight val="18"/>',
    '<Color r="1" g="0.86" b="0.55"/>',
}) do assert(markerTemplate:find(text, 1, true), "Marker template missing: " .. text) end
for _, text in ipairs({
    '<Frame name="FFXIV_EnemyList" parent="UIParent" enableMouse="false" hidden="true">',
    'parentKey="title" text="Enemy List"',
    'parentKey="status"',
    'font="Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisMedium.ttf" outline="NORMAL"',
    '<FontHeight val="14"/>', '<FontHeight val="10"/>',
    '<Anchor point="TOPLEFT"/>', '<Anchor point="TOPLEFT" x="0" y="-18"/>',
    '<Color r="1" g="0.86" b="0.55"/>', '<Color r="0.8" g="0.8" b="0.8"/>',
    '<Frame name="FFXIV_EnemyListRowTemplate" virtual="true" enableMouse="false">',
    '<StatusBar parentKey="health">',
    '<Anchor point="TOPLEFT" x="34" y="-16"/>',
    '<BarColor r="0.85" g="0.12" b="0.16"/>',
    '<StatusBar parentKey="cast" hidden="true">',
    '<Size x="206" y="13"/>',
    '<Anchor point="TOPLEFT" x="54" y="-37"/>',
    '<BarTexture file="Interface\\Buttons\\WHITE8X8"/>',
    '<Texture parentKey="icon">',
    '<Size x="16" y="16"/>',
    '<Anchor point="RIGHT" relativePoint="LEFT" x="-3" y="0"/>',
    '<TexCoords left="0.08" right="0.92" top="0.08" bottom="0.92"/>',
    'justifyH="LEFT" wordwrap="false"',
    '<Anchor point="LEFT" x="3" y="0"/>',
    '<Anchor point="RIGHT" x="-18" y="0"/>',
    '<Texture parentKey="interrupt" file="Interface\\Buttons\\UI-GroupLoot-Pass-Up">',
    '<Size x="12" y="12"/>',
    '<Anchor point="RIGHT" x="-2" y="0"/>',
}) do assert(xml:find(text, 1, true), "XML missing: " .. text) end
local plateTemplate = assert(xml:match('<Frame name="FFXIV_EnemyListPlateTemplate".-</Frame>'))
for _, text in ipairs({
    'virtual="true" enableMouse="false"',
    '<Layer level="BACKGROUND">',
    '<Texture parentKey="badge" file="Interface\\Buttons\\WHITE8X8">',
    '<Color r="0.08" g="0.06" b="0.03" a="0.9"/>',
    '<Layer level="OVERLAY">',
    '<FontString parentKey="number" font="Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisMedium.ttf" outline="NORMAL">',
    '<FontHeight val="16"/>',
    '<Anchor point="RIGHT" relativePoint="LEFT" x="-6" y="0"/>',
    '<Color r="1" g="0.86" b="0.55"/>',
}) do assert(plateTemplate:find(text, 1, true), "Plate template missing: " .. text) end
assert(xml:find('<Frame parentKey="outline" setAllPoints="true" enableMouse="false">', 1, true))
for _, specification in ipairs({
    {"top", "y", "TOPLEFT", "TOPRIGHT", 0, 2, 0, 2},
    {"bottom", "y", "BOTTOMLEFT", "BOTTOMRIGHT", 0, -2, 0, -2},
    {"left", "x", "TOPLEFT", "BOTTOMLEFT", -2, 2, -2, -2},
    {"right", "x", "TOPRIGHT", "BOTTOMRIGHT", 2, 2, 2, -2},
}) do
    local key, axis, point1, point2, x1, y1, x2, y2 = unpack(specification)
    local region = assert(xml:match('<Texture parentKey="' .. key .. '".-</Texture>'),
        "Missing outline edge: " .. key)
    for _, text in ipairs({
        'file="Interface\\Buttons\\WHITE8X8"',
        '<Size ' .. axis .. '="2"/>',
        string.format('<Anchor point="%s" x="%d" y="%d"/>', point1, x1, y1),
        string.format('<Anchor point="%s" x="%d" y="%d"/>', point2, x2, y2),
    }) do assert(region:find(text, 1, true), key .. " edge missing: " .. text) end
end
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do index = index + 1; lines[line] = index end
    assert(assert(lines["PartyFrames/EnemyList.xml"]) < assert(lines["PartyFrames/EnemyList.lua"]))
end
list = object()
list:Hide()
list:EnableMouse(false)
list.title, list.status = list:CreateFontString(), list:CreateFontString()
list.title:SetText("Enemy List")
FFXIV_EnemyList = list
assert(loadfile("FFXIV_UI\\PartyFrames\\EnemyList.lua"))("FFXIV_UI", ns)
assert(list == FFXIV_EnemyList and list.parent == FFXIV_UI_Anchors.EnemyList and not list.mouse)
assert(list.title.text == "Enemy List")
print("PASS: enemy list XML header, hidden non-clickable container, anchor binding, and TOC orders")
event("ADDON_LOADED", "Unrelated")
assert(FFXIV_UI_DB.enemyListEnabled == nil)
event("ADDON_LOADED", "FFXIV_UI")
assert(FFXIV_UI_DB.enemyListEnabled == true and not list.shown)
assert(FFXIV_UI_DB.enemyListShowLabel and FFXIV_UI_DB.enemyListShowLegend and FFXIV_UI_DB.enemyListDynamicCasting)
print("PASS: enemy list defaults on without changing unrelated addon settings")

data.nameplate1 = enemy({threat = 0})
data.nameplate2 = enemy({targetPlayer = true})
data.nameplate3 = enemy()
data.nameplate4 = enemy({attackable = false, threat = 3})
data.nameplate5 = enemy({dead = true, threat = 3})
plates = {plate("nameplate1", true), plate("nameplate2"), plate("nameplate3"),
    plate("nameplate4"), plate("nameplate5"), plate("nameplate99", true, true)}
ns.SetEnemyListEnabled(true)
assert(FFXIV_UI_DB.enemyListEnabled and not list.shown and #allRows == 0)
combat = true
event("PLAYER_REGEN_DISABLED")
assert(list.shown and #allRows == 2)
for _, row in ipairs(allRows) do
    assert(row.template == "FFXIV_EnemyListRowTemplate")
    assert(row.health.width == 226 and row.health.height == ns.PartyRowStyle.barHeight)
    assert(row.health.frameLevel == row:GetFrameLevel() + 1)
    assert(row.cast.frameLevel == row:GetFrameLevel() + 1)
    assert(row.cast.width == 206 and row.cast.height == 13)
    assert(row.cast.icon.width == 16 and row.cast.interrupt.width == 12)
    assert(row.outline.parent == row and row.outline.mouse == false)
    assert(row.outline.anchor == row and row.outline.frameLevel == row:GetFrameLevel() + 10)
    assert(#row.outline.edges == 4)
    for index, key in ipairs({"top", "bottom", "left", "right"}) do
        assert(row.outline.edges[index] == row.outline[key], "Outline must bind the XML edges in order")
    end
end
assert(allRows[1].unit == "nameplate1" and allRows[2].unit == "nameplate2")
assert(allRows[1].marker.text == "-" and allRows[2].marker.text == "!")
for _, row in ipairs(allRows) do
    assert(row.marker.template == "FFXIV_EnemyListMarkerTemplate" and row.marker.layer == "OVERLAY")
    assert(row.marker.parent == row.skin.icon:GetParent())
    assert(row.marker.points.TOPLEFT == nil and row.marker.points.CENTER)
    assert(row.marker.point[2] == row.skin.icon and row.marker.point[3] == "CENTER")
end
assert(allRows[1].marker.color[1] == 0.65 and allRows[2].marker.color[2] == 0.2)
assert(allRows[1].skin.name.text == "Enemy Fullname")
assert(allRows[1].health.color[1] == 0.85 and allRows[1].health.value == 700)
assert(allRows[2].point[5] == -72 and allRows[1].mouse == false)
print("PASS: zero-threat entries and player targets qualify; unrelated, friendly, dead, and forbidden plates do not")

ns.SetEnemyListSetting("enemyListShowLabel", false)
assert(not list.texts[1].shown and list.texts[2].shown and allRows[1].point[5] == -18)
ns.SetEnemyListSetting("enemyListShowLegend", false)
assert(not list.texts[2].shown and allRows[1].point[5] == 0 and allRows[2].point[5] == -36)
ns.SetEnemyListSetting("enemyListDynamicCasting", false)
assert(allRows[1].height == 54 and allRows[2].height == 54 and allRows[2].point[5] == -58)
data.nameplate1.castDuration = {}
event("UNIT_SPELLCAST_START", "nameplate1")
assert(allRows[1].cast.shown and allRows[2].point[5] == -58)
data.nameplate1.castDuration = nil
event("UNIT_SPELLCAST_STOP", "nameplate1")
assert(not allRows[1].cast.shown and allRows[1].height == 54 and allRows[2].point[5] == -58)
ns.SetEnemyListEnabled(false)
assert(not FFXIV_UI_DB.enemyListShowLabel and not FFXIV_UI_DB.enemyListShowLegend and not FFXIV_UI_DB.enemyListDynamicCasting)
ns.SetEnemyListEnabled(true)
assert(not list.texts[1].shown and not list.texts[2].shown and allRows[1].height == 54)
data.nameplate3.threat = secret
event("UNIT_THREAT_LIST_UPDATE", "nameplate3")
assert(list.texts[2].shown and list.texts[2].text == "Some combat data unavailable" and allRows[1].point[5] == -18)
data.nameplate3.threat = nil
for _, key in ipairs({"enemyListShowLabel", "enemyListShowLegend", "enemyListDynamicCasting"}) do
    ns.SetEnemyListSetting(key, true)
end
assert(list.texts[1].shown and list.texts[2].shown and allRows[1].height == 32 and allRows[2].point[5] == -72)
print("PASS: label/legend settings reclaim space, warnings remain, fixed cast spacing persists, and options survive disabling")

assert(not allRows[1].cast.shown and allRows[1].height == 32)
local caster = data.nameplate1
caster.castDuration, caster.spellName, caster.spellIcon = {}, secret, secret
caster.notInterruptible = secret
event("UNIT_SPELLCAST_START", "nameplate1")
local cast = allRows[1].cast
assert(cast.shown and cast.duration == caster.castDuration and cast.direction == 0)
assert(allRows[1].height == 54 and allRows[2].height == 32 and allRows[2].point[5] == -94)
data.nameplate2.channelDuration = {}
event("UNIT_SPELLCAST_CHANNEL_START", "nameplate2")
assert(allRows[1].height == 54 and allRows[2].height == 54 and allRows[2].point[5] == -94)
assert(cast.name.text == secret and cast.icon.texture == secret)
assert(cast.interrupt.boolean == secret and cast.interrupt.yesColor.a == 1 and cast.interrupt.noColor.a == 0)
caster.notInterruptible = false
event("UNIT_SPELLCAST_INTERRUPTIBLE", "nameplate1")
assert(cast.boolean == false and cast.interrupt.boolean == false)
caster.notInterruptible = true
event("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "nameplate1")
assert(cast.boolean == true and cast.interrupt.boolean == true)
caster.castDuration = {}
event("UNIT_SPELLCAST_DELAYED", "nameplate1")
assert(cast.duration == caster.castDuration)
caster.castDuration, caster.channelDuration = nil, {}
event("UNIT_SPELLCAST_CHANNEL_START", "nameplate1")
assert(cast.duration == caster.channelDuration and cast.direction == 1)
caster.channelDuration = nil
event("UNIT_SPELLCAST_CHANNEL_STOP", "nameplate1")
assert(not cast.shown)
assert(allRows[1].height == 32 and allRows[2].height == 54 and allRows[2].point[5] == -72)
data.nameplate2.channelDuration = nil
event("UNIT_SPELLCAST_CHANNEL_STOP", "nameplate2")
assert(allRows[2].height == 32 and allRows[2].point[5] == -72)
for _, stopEvent in ipairs({"UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED"}) do
    caster.castDuration = {}
    event("UNIT_SPELLCAST_START", "nameplate1")
    assert(cast.shown)
    caster.castDuration = nil
    event(stopEvent, "nameplate1")
    assert(not cast.shown)
    assert(allRows[1].height == 32 and allRows[2].point[5] == -72)
end
print("PASS: casts and channels show native progress, secret spell details and interrupt indicators, then hide on stop")

local function visualFor(plateFrame)
    for _, frame in ipairs(frames) do
        if frame.parent == plateFrame and frame.number then return frame end
    end
end
local firstVisual, secondVisual = visualFor(plates[1]), visualFor(plates[2])
assert(firstVisual.number.text == 1 and secondVisual.number.text == 2)
assert(firstVisual.mouse == false and secondVisual.mouse == false)
for _, visual in ipairs({firstVisual, secondVisual}) do
    assert(visual.template == "FFXIV_EnemyListPlateTemplate")
    assert(visual.number.point[1] == "RIGHT" and visual.number.point[2] == visual
        and visual.number.point[3] == "LEFT" and visual.number.point[4] == -6)
    assert(visual.frameLevel == visual.anchor:GetFrameLevel() + 10)
    assert(visual.badge.points.CENTER == nil, "Badge must clear implicit XML anchors")
    for _, spec in ipairs({{"TOPLEFT", -4, 2}, {"BOTTOMRIGHT", 4, -2}}) do
        local point = visual.badge.points[spec[1]]
        assert(point and point[2] == visual.number and point[3] == spec[1]
            and point[4] == spec[2] and point[5] == spec[3])
    end
end
assert(not visualFor(plates[3]) and not visualFor(plates[6]))
target, mouseover = "nameplate2", "nameplate1"
event("PLAYER_TARGET_CHANGED")
event("UPDATE_MOUSEOVER_UNIT")
assert(not firstVisual.edges and not secondVisual.edges and not firstVisual.hover and not secondVisual.hover)
assert(allRows[1].outline.shown and allRows[2].outline.shown)
assert(allRows[1].outline.parent == allRows[1] and allRows[1].outline.mouse == false)
for _, edge in ipairs(allRows[1].outline.edges) do assert(edge.color[4] == 0.3) end
for _, edge in ipairs(allRows[2].outline.edges) do assert(edge.color[4] == 0.95) end
assert(list.scripts.OnUpdate)
mouseover = nil
list.scripts.OnUpdate(list, 0.016)
assert(not allRows[1].outline.shown and allRows[2].outline.shown)
assert(list.scripts.OnUpdate == nil)
mouseover = "nameplate2"
event("UPDATE_MOUSEOVER_UNIT")
assert(list.scripts.OnUpdate and allRows[2].outline.shown)
mouseover = nil
list.scripts.OnUpdate(list, 0.016)
assert(allRows[2].outline.shown and list.scripts.OnUpdate == nil)
for _, edge in ipairs(allRows[2].outline.edges) do assert(edge.color[4] == 0.95) end
mouseover = "nameplate1"
event("UPDATE_MOUSEOVER_UNIT")
print("PASS: mouseover loss without an event removes the soft outline, preserves target outline, and stops polling")
targetRestricted, mouseoverRestricted = true, true
event("PLAYER_TARGET_CHANGED")
event("UPDATE_MOUSEOVER_UNIT")
assert(not allRows[1].outline.shown and not allRows[2].outline.shown)
assert(firstVisual.shown and secondVisual.shown)
targetRestricted, mouseoverRestricted = false, false
target, mouseover = nil, nil
event("PLAYER_TARGET_CHANGED")
assert(not allRows[1].outline.shown and not allRows[2].outline.shown)
print("PASS: world nameplates only receive numbers; list-row target and soft mouseover outlines are secret-safe")

for _, aura in ipairs(auraRows) do
    assert(aura.size == 18 and aura.y == 0 and aura.enabled)
    assert(aura.x > 0 and aura.getUnit() == aura.parent.unit)
    assert(aura.limit == (aura.group == "buffs" and 4 or 8))
    assert(aura.combined and #aura.parent.auras == 1)
end
data.nameplate1.health, data.nameplate1.maximum, data.nameplate1.level = secret, secret, secret
data.nameplate1.fullName = secret
event("UNIT_NAME_UPDATE", "nameplate1")
assert(allRows[1].skin.name.text == secret and allRows[1].skin.level.text == secret)
event("UNIT_HEALTH", "nameplate1")
assert(allRows[1].health.value == secret and allRows[1].health.high == secret)
assert(allRows[1].skin.healthValue.text == secret)
print("PASS: right-side aura rows follow units and secret names/health/levels pass directly to renderers")

data.nameplate1.targetExists = secret
data.nameplate3.threat = secret
event("UNIT_TARGET", "nameplate1")
assert(allRows[1].marker.text == "?")
assert(list.texts[2].text == "Some combat data unavailable")
assert(#allRows == 2)
data.nameplate1.attackable = secret
caster.castDuration = {}
event("UNIT_SPELLCAST_START", "nameplate1")
assert(allRows[1].cast.shown)
target = "nameplate2"
event("UNIT_FACTION", "nameplate1")
assert(allRows[1].unit == "nameplate2" and not allRows[2].shown)
assert(allRows[1].auras[1].unit == "nameplate2")
assert(allRows[1].auras[1].getUnit() == "nameplate2")
assert(allRows[1].auras[1].refreshes > 0 and allRows[2].auras[1].enabled == false)
assert(not firstVisual.shown and secondVisual.shown and secondVisual.number.text == 1)
assert(allRows[1].outline.shown and not allRows[2].outline.shown)
assert(not allRows[1].cast.shown and not allRows[2].cast.shown)
assert(allRows[1].height == 32 and allRows[1].point[5] == -36)
target = nil
event("PLAYER_TARGET_CHANGED")
print("PASS: restricted membership is reported, unknown targets are marked, and recycled rows rebind their auras")

event("NAME_PLATE_UNIT_ADDED", "nameplate2")
event("NAME_PLATE_UNIT_REMOVED", "nameplate2")
assert(not allRows[1].shown and list.shown)
assert(not secondVisual.shown)
assert(not allRows[1].outline.shown)
data.nameplate6 = enemy({threat = 1})
event("NAME_PLATE_UNIT_ADDED", "nameplate6")
assert(allRows[1].shown and allRows[1].unit == "nameplate6")
combat = false
event("PLAYER_REGEN_ENABLED")
assert(not list.shown and not allRows[1].shown and not allRows[1].auras[1].enabled)
assert(not allRows[1].cast.shown)
combat = true
event("PLAYER_REGEN_DISABLED")
assert(list.shown)
ns.SetEnemyListEnabled(false)
assert(not list.shown and FFXIV_UI_DB.enemyListEnabled == false)
assert(not firstVisual.shown and not secondVisual.shown)
for _, row in ipairs(allRows) do assert(not row.outline.shown) end
print("PASS: plate removal, duplicate adds, combat exit, and toggling cleanly hide/reuse rows and aura subscriptions")

ns.SetEnemyListEnabled(true)
assert(list.shown and allRows[1].unit == "nameplate2")
combat = false
event("PLAYER_ENTERING_WORLD")
assert(not list.shown)
combat = true
event("PLAYER_ENTERING_WORLD")
assert(list.shown and allRows[1].unit == "nameplate2")
print("PASS: enabling mid-combat scans both nameplate API layouts and world entry resynchronizes combat")

ns.SetEnemyListEnabled(false)
assert(not secondVisual.shown)
ns.SetEnemyListEnabled(true)
assert(secondVisual.shown and secondVisual.number.text == 1)
combat = false
event("PLAYER_REGEN_ENABLED")
assert(not secondVisual.shown)
combat = true
event("PLAYER_REGEN_DISABLED")
assert(secondVisual.shown)
event("NAME_PLATE_UNIT_REMOVED", "nameplate2")
assert(not secondVisual.shown)
plates[2].token = "nameplate6"
plates[2].UnitFrame = {healthBar = object()}
target, mouseover = "nameplate6", "nameplate6"
event("NAME_PLATE_UNIT_ADDED", "nameplate6")
assert(visualFor(plates[2]) == secondVisual and secondVisual.shown)
assert(secondVisual.anchor == plates[2].UnitFrame.healthBar)
assert(secondVisual.number.text == 1 and allRows[1].outline.shown)
for _, edge in ipairs(allRows[1].outline.edges) do assert(edge.color[4] == 0.95) end
event("NAME_PLATE_UNIT_REMOVED", "nameplate6")
plates[2].token, plates[2].UnitFrame = "nameplate2", nil
target, mouseover = nil, nil
event("NAME_PLATE_UNIT_ADDED", "nameplate2")
assert(secondVisual.shown and not allRows[1].outline.shown)
print("PASS: disabling, combat exit, and pooled plate reuse clear stale highlights and reanchor the existing overlay")

data.nameplate2.targetPlayer = secret
event("UNIT_TARGET", "nameplate2")
assert(not allRows[1].shown and list.texts[2].text == "Some combat data unavailable")
data.nameplate2.threat = 3
event("UNIT_THREAT_LIST_UPDATE", "nameplate2")
assert(allRows[1].shown and allRows[1].marker.text == "?")
data.nameplate2.dead = true
event("UNIT_HEALTH", "nameplate2")
assert(not allRows[1].shown)
print("PASS: secret target comparisons never become membership proof, and death removes a listed enemy on health update")

assert(FFXIV_UI_DB.enemyListEnabled == true)
ns.SetEnemyListSetting("enemyListShowLabel", false)
ns.SetEnemyListSetting("enemyListShowLegend", false)
ns.SetEnemyListSetting("enemyListDynamicCasting", false)
assert(loadfile("FFXIV_UI\\PartyFrames\\EnemyList.lua"))("FFXIV_UI", ns)
event("ADDON_LOADED", "FFXIV_UI")
assert(list.shown and FFXIV_UI_DB.enemyListEnabled == true)
assert(not FFXIV_UI_DB.enemyListShowLabel and not FFXIV_UI_DB.enemyListShowLegend and not FFXIV_UI_DB.enemyListDynamicCasting)
assert(not list.texts[1].shown and list.texts[2].shown)
print("PASS: the enabled setting is restored on subsequent addon loads")

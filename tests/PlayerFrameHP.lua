local methods = {}
local function widget()
    return setmetatable({scripts = {}, events = {}, shown = true, level = 10}, {__index = methods})
end
for _, name in ipairs({"SetAllPoints", "SetTexture", "EnableMouse", "SetSize", "ClearAllPoints",
    "RegisterForClicks", "SetFrameStrata", "SetJustifyH", "SetFont"}) do
    methods[name] = function(self, ...) self[name] = {...} end
end
function methods:SetAttribute(key, value)
    self.attributes = self.attributes or {}
    self.attributes[key] = value
end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(level) self.level = level end
function methods:SetParent(parent) self.parent = parent end
function methods:SetPoint(...) self.point = {...} end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetMinMaxValues(low, high) self.min, self.max = low, high end
function methods:SetValue(value, interpolation) self.value, self.interpolation = value, interpolation end
function methods:SetText(value) self.text = value end
function methods:GetStatusBarTexture() return self end
function methods:RegisterEvent(event) self.events[#self.events + 1] = event end
function methods:SetScript(name, callback) self.scripts[name] = callback end

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function assertContains(content, text, label)
    assert(content:find(text, 1, true), label .. " missing: " .. text)
end

local hpXml = readFile("FFXIV_UI\\PlayerFrames\\PlayerFrame_HP.xml")
assertContains(hpXml, 'name="Playerframe_HP"', "HP frame global")
for _, key in ipairs({"bg", "combatTexture", "outOfCombatTexture", "bar", "cutawayBar",
    "outlineFrame", "outline", "text", "hpLabel", "clickFrame"}) do
    assertContains(hpXml, 'parentKey="' .. key .. '"', "HP parentKey")
end
assertContains(hpXml, 'inherits="SecureUnitButtonTemplate"', "click frame template")
assertContains(hpXml, 'hidden="true"', "combat texture starts hidden")
for _, asset in ipairs({"PlayerFrame\\Health", "PlayerFrame\\Cutaway", "PlayerFrame\\FFInCombat",
    "PlayerFrame\\FFOutOfCombat", "PlayerFrame\\Frame", "EurostileExtended.ttf", "MiedingerMedium.ttf"}) do
    assertContains(hpXml, asset, "HP asset")
end

local powerXml = readFile("FFXIV_UI\\PlayerFrames\\PlayerFrame_Power.xml")
assertContains(powerXml, 'name="PlayerFrame_Power"', "power frame global")
for _, key in ipairs({"bg", "bar", "outlineFrame", "outline", "text", "powerLabel"}) do
    assertContains(powerXml, 'parentKey="' .. key .. '"', "power parentKey")
end

local function assertLoadOrder(tocPath)
    local lines = {}
    for line in readFile(tocPath):gmatch("[^\r\n]+") do
        lines[#lines + 1] = (line:gsub("%s+$", ""))
    end
    local function indexOf(target)
        for i, line in ipairs(lines) do
            if line == target then return i end
        end
        error(tocPath .. " is missing " .. target)
    end
    local hpXmlIndex = indexOf("PlayerFrames/PlayerFrame_HP.xml")
    local hpLuaIndex = indexOf("PlayerFrames/PlayerFrame_HP.lua")
    local powerXmlIndex = indexOf("PlayerFrames/PlayerFrame_Power.xml")
    local powerLuaIndex = indexOf("PlayerFrames/PlayerFrame_Power.lua")
    assert(hpXmlIndex < hpLuaIndex, tocPath .. " must load the HP XML before its Lua")
    assert(powerXmlIndex < powerLuaIndex, tocPath .. " must load the power XML before its Lua")
    assert(hpLuaIndex < powerXmlIndex, tocPath .. " must keep HP before power")
end
assertLoadOrder("FFXIV_UI\\FFXIV_UI.toc")
assertLoadOrder("FFXIV_UI\\FFXIV_UI_Camelot.toc")

local function child(parent, ...)
    local node = parent
    for _, key in ipairs({...}) do
        node[key] = node[key] or widget()
        node = node[key]
    end
    return node
end

PlayerFrame = widget()
hooksecurefunc = function() end
Enum = {StatusBarInterpolation = {ExponentialEaseOut = "EASE"}}
local hp, maxHp, inCombat = 150, 300, false
UnitHealth = function() return hp end
UnitHealthMax = function() return maxHp end
InCombatLockdown = function() return inCombat end
FFXIV_UI_Anchors = {PlayerHP = widget()}

Playerframe_HP = widget()
local f = Playerframe_HP
child(f, "bar")
child(f, "cutawayBar")
child(f, "combatTexture")
child(f, "outOfCombatTexture")
child(f, "outlineFrame", "outline")
child(f, "outlineFrame", "text")
child(f, "outlineFrame", "hpLabel")
child(f, "outlineFrame", "clickFrame")
f.combatTexture.shown = true
f.outOfCombatTexture.shown = true

local source = readFile("FFXIV_UI\\PlayerFrames\\PlayerFrame_HP.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "PlayerFrame_HP.lua"))("FFXIV_UI", {})

assert(f.parent == FFXIV_UI_Anchors.PlayerHP, "frame must be parented to the PlayerHP anchor")
assert(f.point[1] == "CENTER" and f.point[2] == FFXIV_UI_Anchors.PlayerHP, "frame must be centered on the anchor")
assert(f.bar.level == 12, "health bar level must be frame + 2")
assert(f.cutawayBar.level == 11, "cutaway level must be frame + 1")
assert(f.outlineFrame.level == 15, "outline level must be frame + 5")
local click = f.outlineFrame.clickFrame
assert(click.level == 25, "click frame level must be outline + 10")
assert(click.RegisterForClicks[1] == "AnyUp", "click frame must register AnyUp")
assert(click.EnableMouse[1] == true, "click frame must receive mouse input")
assert(click.attributes.unit == "player", "click frame unit attribute")
assert(click.attributes.type1 == "target", "left click targets")
assert(click.attributes.type2 == "togglemenu", "right click opens menu")

f.scripts.OnEvent(f, "PLAYER_LOGIN")
assert(f.bar.min == 0 and f.bar.max == 300 and f.bar.value == 150, "health bar values")
assert(f.outlineFrame.text.text == 150, "health text")
assert(f.cutawayBar.min == 0 and f.cutawayBar.max == 300, "cutaway bounds")
assert(f.cutawayBar.value == 150 and f.cutawayBar.interpolation == "EASE", "cutaway value and interpolation")
assert(f.combatTexture.shown == false and f.outOfCombatTexture.shown == true, "starts out of combat")

local function event(name, unit)
    local registered = false
    for _, e in ipairs(f.events) do
        if e == name then registered = true end
    end
    assert(registered, "unregistered event: " .. name)
    f.scripts.OnEvent(f, name, unit)
end

hp = 200
event("UNIT_HEALTH", "target")
assert(f.bar.value == 150, "other unit must not update player health")
event("UNIT_HEALTH", "player")
assert(f.bar.value == 200 and f.outlineFrame.text.text == 200, "player health update")

maxHp = 400
event("UNIT_MAXHEALTH", "player")
assert(f.bar.max == 400 and f.cutawayBar.max == 400, "max health update")

event("PLAYER_REGEN_DISABLED")
assert(f.combatTexture.shown and not f.outOfCombatTexture.shown, "combat art on entering combat")
event("PLAYER_REGEN_ENABLED")
assert(not f.combatTexture.shown and f.outOfCombatTexture.shown, "out of combat art on leaving combat")

inCombat = true
event("PLAYER_LOGIN")
assert(f.combatTexture.shown and not f.outOfCombatTexture.shown, "login reads combat lockdown state")

print("PlayerFrameHP tests passed")

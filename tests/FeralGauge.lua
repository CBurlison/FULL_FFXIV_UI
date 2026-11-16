local methods = {}
local function newObject(name)
    return setmetatable({name = name, scripts = {}, events = {}, shown = true, alpha = 1}, {__index = methods})
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetPoint(...) self.point = {...} end
function methods:ClearAllPoints() self.point = nil end
function methods:SetAllPoints() self.allPoints = true end
function methods:SetParent(parent) self.parent = parent end
function methods:SetTexture(file) self.file = file end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return self.alpha end
function methods:IsShown() return self.shown end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterAllEvents() self.events = {} end
function methods:SetScript(name, callback) self.scripts[name] = callback end

CreateFrame = function()
    return newObject("waiter")
end

UIFrameFadeIn = function(frame, _, _, target) frame.shown = true; frame.alpha = target end
UIFrameFadeOut = function(frame, _, _, target) frame.shown = false; frame.alpha = target end
C_Timer = {After = function() end}

UnitClass = function() return "Druid", "DRUID" end
local inCat = true
GetShapeshiftFormID = function() return inCat and 1 or 0 end
local comboPoints = 0
UnitPowerMax = function(unit, powerType)
    assert(unit == "player" and powerType == 4)
    return 5
end
UnitPower = function(unit, powerType)
    assert(unit == "player" and powerType == 4)
    return comboPoints
end
UnitExists = function() return true end
UnitCanAttack = function() return true end
local sounds = {}
PlaySoundFile = function(file) sounds[#sounds + 1] = file end
FFXIV_UI_DB = {sfxEnabled = true}
FFXIV_UI_Anchors = {JobGauge = newObject("JobGauge")}

-- Stub tree mirroring JobGauges/FeralGauge.xml: the frame and every texture start hidden.
ComboTrackerFrame = newObject("ComboTrackerFrame")
ComboTrackerFrame.shown = false
ComboTrackerFrame.base = newObject("base")
ComboTrackerFrame.base.shown = false
ComboTrackerFrame.base.alpha = 0
for i = 1, 5 do
    local orb = newObject("orb" .. i)
    orb.shown = false
    orb.alpha = 0
    ComboTrackerFrame["orb" .. i] = orb
end

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function assertContains(content, text, label)
    assert(content:find(text, 1, true), label .. " missing: " .. text)
end

local xml = readFile("FFXIV_UI\\JobGauges\\FeralGauge.xml")
assertContains(xml, '<Frame name="ComboTrackerFrame" parent="UIParent" hidden="true">', "frame hidden at load")
assertContains(xml, '<Size x="350" y="350"/>', "frame size")
assertContains(xml, 'parentKey="base" setAllPoints="true" hidden="true" alpha="0"', "base starts hidden at alpha 0")
assertContains(xml, "JobGauges\\Druid\\FeralGauge\"", "base artwork")
for i = 1, 5 do
    assertContains(xml, 'parentKey="orb' .. i .. '" hidden="true" alpha="0"', "orb hidden at load")
    assertContains(xml, "JobGauges\\Druid\\FeralCombo" .. i .. "\"", "orb artwork")
end
print("PASS: XML names, parent keys, hidden frame and orbs, and artwork match the old Lua")

local function readLines(path)
    local lines = {}
    local index = 0
    for line in readFile(path):gmatch("[^\r\n]+") do
        index = index + 1
        lines[line] = index
    end
    return lines
end

for _, tocPath in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines = readLines(tocPath)
    assert(lines["JobGauges/FeralGauge.xml"], tocPath .. " should list the XML")
    assert(lines["JobGauges/FeralGauge.xml"] < lines["JobGauges/FeralGauge.lua"],
        tocPath .. " should load the XML before the Lua")
end
print("PASS: both TOCs load the XML before the Lua")

local addonEnv = {}
local powerSource = readFile("FFXIV_UI\\General\\PowerAvailability.lua"):gsub("^\239\187\191", "")
assert(loadstring(powerSource, "PowerAvailability.lua"))("FFXIV_UI", addonEnv)

local source = readFile("FFXIV_UI\\JobGauges\\FeralGauge.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "FeralGauge.lua"))("FFXIV_UI", addonEnv)

local frame = ComboTrackerFrame
assert(frame.parent == FFXIV_UI_Anchors.JobGauge, "frame should move to the JobGauge anchor")
for i = 1, 5 do
    assert(frame.orbs[i] == frame["orb" .. i], "orbs should map to the XML children")
end
print("PASS: frame reparents to the JobGauge anchor and orbs map to the XML children")

assert(frame.shown, "frame should show in cat form on login")
assert(frame.base.shown, "base should fade in when a druid is in cat form with a target")
print("PASS: frame shows in cat form on login")

local onEvent = frame.scripts.OnEvent
assert(onEvent, "frame should register an OnEvent handler")
assert(frame.events["UNIT_POWER_UPDATE"] and frame.events["UPDATE_SHAPESHIFT_FORM"], "should listen for power and form changes")

comboPoints = 2
onEvent(frame, "UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
for i = 1, 5 do
    assert(frame["orb" .. i].shown == (i <= 2), "orb" .. i .. " visibility at 2 combo points")
end
print("PASS: orbs fade in for current combo points")

comboPoints = 5
onEvent(frame, "UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
assert(#sounds == 1 and sounds[1] == "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg",
    "reaching five combo points should play the full sound once")
print("PASS: full sound plays at five combo points")

onEvent(frame, "UNIT_POWER_UPDATE", "target", "COMBO_POINTS")
onEvent(frame, "UNIT_POWER_UPDATE", "player", "ARCANE_CHARGES")
assert(#sounds == 1, "other units and power types should not replay the sound")

inCat = false
onEvent(frame, "UPDATE_SHAPESHIFT_FORM", "player")
assert(not frame.shown, "leaving cat form should hide the gauge")
print("PASS: leaving cat form hides the gauge")

inCat = true
onEvent(frame, "UPDATE_SHAPESHIFT_FORM", "player")
assert(frame.shown, "returning to cat form should show the gauge")
print("PASS: returning to cat form shows the gauge")

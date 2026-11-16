local calls = {}
local function record(name, ...)
    calls[#calls + 1] = {name = name, args = {...}}
end

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
function methods:Show() self.shown = true; record("Show", self.name) end
function methods:Hide() self.shown = false; record("Hide", self.name) end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterAllEvents() self.events = {} end
function methods:SetScript(name, callback) self.scripts[name] = callback end

local frames = {}
CreateFrame = function()
    local frame = newObject("waiter")
    frames[#frames + 1] = frame
    return frame
end

UnitClass = function() return "Paladin", "PALADIN" end
Enum = {PowerType = {HolyPower = 9}}
local holyPower = 0
local maxPower = 5
UnitPowerMax = function(unit, powerType)
    assert(unit == "player" and powerType == 9)
    return maxPower
end
UnitPower = function(unit, powerType)
    assert(unit == "player" and powerType == 9)
    return holyPower
end
UIFrameFadeIn = function(frame, _, _, target) frame.faded = target end
UIFrameFadeOut = function(frame, _, _, target) frame.faded = target end
local sounds = {}
PlaySoundFile = function(file) sounds[#sounds + 1] = file end
FFXIV_UI_DB = {sfxEnabled = true}
FFXIV_UI_Anchors = {JobGauge = newObject("JobGauge")}

-- Stub tree mirroring JobGauges/PaladinGauge.xml.
HolyPowerTrackerFrame = newObject("HolyPowerTrackerFrame")
HolyPowerTrackerFrame.shown = false
HolyPowerTrackerFrame.base = newObject("base")
for i = 1, 5 do
    local orb = newObject("orb" .. i)
    orb.shown = false
    HolyPowerTrackerFrame["orb" .. i] = orb
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

local xml = readFile("FFXIV_UI\\JobGauges\\PaladinGauge.xml")
assertContains(xml, 'name="HolyPowerTrackerFrame"', "frame global")
assertContains(xml, 'hidden="true"', "hidden until power is ready")
assertContains(xml, 'parentKey="base"', "base texture")
assertContains(xml, "JobGauges\\Paladin\\FFPaladinFrame", "base artwork")
for i = 1, 5 do
    assertContains(xml, 'parentKey="orb' .. i .. '"', "orb parentKey")
    assertContains(xml, "JobGauges\\Paladin\\HolyPower" .. i .. ".tga", "orb artwork")
end
print("PASS: XML names, parent keys, and artwork match the old Lua")

local function assertLoadOrder(tocPath)
    local index, position = {}, 0
    for line in readFile(tocPath):gmatch("[^\r\n]+") do
        position = position + 1
        index[line] = position
    end
    assert(index["JobGauges/PaladinGauge.xml"], tocPath .. " should list the XML")
    assert(index["JobGauges/PaladinGauge.xml"] < index["JobGauges/PaladinGauge.lua"],
        tocPath .. " should load the XML before the Lua")
end
assertLoadOrder("FFXIV_UI\\FFXIV_UI.toc")
assertLoadOrder("FFXIV_UI\\FFXIV_UI_Camelot.toc")
print("PASS: both TOCs load the XML before the Lua")

-- Run the Lua against the stub tree.
local addonEnv = {}
local powerSource = readFile("FFXIV_UI\\General\\PowerAvailability.lua"):gsub("^\239\187\191", "")
assert(loadstring(powerSource, "PowerAvailability.lua"))("FFXIV_UI", addonEnv)

local source = readFile("FFXIV_UI\\JobGauges\\PaladinGauge.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "PaladinGauge.lua"))("FFXIV_UI", addonEnv)

assert(HolyPowerTrackerFrame.parent == FFXIV_UI_Anchors.JobGauge, "frame should move to the JobGauge anchor")
assert(HolyPowerTrackerFrame.shown, "frame should show once power is ready")
print("PASS: frame reparents to the JobGauge anchor and shows once power is ready")

local onEvent = HolyPowerTrackerFrame.scripts.OnEvent
assert(onEvent, "frame should register an OnEvent handler")
assert(HolyPowerTrackerFrame.events.UNIT_POWER_UPDATE and HolyPowerTrackerFrame.events.PLAYER_ENTERING_WORLD,
    "frame should listen for power and login events")

holyPower = 3
onEvent(HolyPowerTrackerFrame, "UNIT_POWER_UPDATE", "player", "HOLY_POWER")
for i = 1, 5 do
    local orb = HolyPowerTrackerFrame["orb" .. i]
    assert(orb.shown == (i <= 3), "orb" .. i .. " visibility at 3 HolyPower")
    assert(orb.faded == (i <= 3 and 1 or 0), "orb" .. i .. " fade target at 3 HolyPower")
end
print("PASS: orbs show and fade for the current HolyPower")

onEvent(HolyPowerTrackerFrame, "UNIT_POWER_UPDATE", "target", "HOLY_POWER")
onEvent(HolyPowerTrackerFrame, "UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
holyPower = 5
onEvent(HolyPowerTrackerFrame, "UNIT_POWER_UPDATE", "player", "HOLY_POWER")
assert(HolyPowerTrackerFrame.orb5.shown, "orb5 should show at full HolyPower")
assert(#sounds == 1 and sounds[1] == "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg",
    "full gauge should play the full sound once")
print("PASS: other units and power types are ignored and full gauge plays its sound once")

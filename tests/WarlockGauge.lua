local calls = {}

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
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterAllEvents() self.events = {} end
function methods:SetScript(name, callback) self.scripts[name] = callback end

CreateFrame = function()
    return newObject("waiter")
end

UnitClass = function() return "Warlock", "WARLOCK" end
Enum = {PowerType = {SoulShards = 7}}
local soulShards = 0
UnitPowerMax = function(unit, powerType)
    assert(unit == "player" and powerType == 7)
    return 5
end
UnitPower = function(unit, powerType)
    assert(unit == "player" and powerType == 7)
    return soulShards
end
UIFrameFadeIn = function(frame, _, _, target) frame.faded = target end
UIFrameFadeOut = function(frame, _, _, target) frame.faded = target end
local sounds = {}
PlaySoundFile = function(file) sounds[#sounds + 1] = file end
FFXIV_UI_DB = {sfxEnabled = true}
FFXIV_UI_Anchors = {JobGauge = newObject("JobGauge")}

-- Stub tree mirroring JobGauges/WarlockGauge.xml.
SoulShardTrackerFrame = newObject("SoulShardTrackerFrame")
SoulShardTrackerFrame.shown = false
SoulShardTrackerFrame.base = newObject("base")
for i = 1, 5 do
    local orb = newObject("orb" .. i)
    orb.shown = false
    SoulShardTrackerFrame["orb" .. i] = orb
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

local xml = readFile("FFXIV_UI\\JobGauges\\WarlockGauge.xml")
assertContains(xml, 'name="SoulShardTrackerFrame"', "frame global")
assertContains(xml, 'hidden="true"', "hidden until power is ready")
assertContains(xml, 'parentKey="base"', "base texture")
assertContains(xml, "JobGauges\\Warlock\\FFLockFrame", "base artwork")
for i = 1, 5 do
    assertContains(xml, 'parentKey="orb' .. i .. '"', "orb parentKey")
    assertContains(xml, "JobGauges\\Warlock\\FFLock" .. i, "orb artwork")
end
print("PASS: XML names, parent keys, and artwork match the old Lua")

local function readLines(path)
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do
        index = index + 1
        lines[line] = index
    end
    return lines
end

for _, tocPath in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines = readLines(tocPath)
    assert(lines["JobGauges/WarlockGauge.xml"], tocPath .. " should list the XML")
    assert(lines["JobGauges/WarlockGauge.xml"] < lines["JobGauges/WarlockGauge.lua"],
        tocPath .. " should load the XML before the Lua")
end
print("PASS: both TOCs load the XML before the Lua")

local addonEnv = {}
local powerSource = readFile("FFXIV_UI\\General\\PowerAvailability.lua"):gsub("^\239\187\191", "")
assert(loadstring(powerSource, "PowerAvailability.lua"))("FFXIV_UI", addonEnv)

local source = readFile("FFXIV_UI\\JobGauges\\WarlockGauge.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "WarlockGauge.lua"))("FFXIV_UI", addonEnv)

local frame = SoulShardTrackerFrame
assert(frame.parent == FFXIV_UI_Anchors.JobGauge, "frame should move to the JobGauge anchor")
assert(frame.shown, "frame should show once power is ready")
print("PASS: frame reparents to the JobGauge anchor and shows once power is ready")

local onEvent = frame.scripts.OnEvent
assert(onEvent, "frame should register an OnEvent handler")
assert(frame.events.UNIT_POWER_UPDATE and frame.events.PLAYER_ENTERING_WORLD,
    "frame should listen for power and login events")

soulShards = 3
onEvent(frame, "UNIT_POWER_UPDATE", "player", "SOUL_SHARDS")
for i = 1, 5 do
    local orb = frame["orb" .. i]
    assert(orb.shown == (i <= 3), "orb" .. i .. " visibility at 3 shards")
    assert(orb.faded == (i <= 3 and 1 or 0), "orb" .. i .. " fade target at 3 shards")
end
print("PASS: orbs show and fade for the current soul shards")

onEvent(frame, "UNIT_POWER_UPDATE", "target", "SOUL_SHARDS")
onEvent(frame, "UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
assert(#sounds == 0, "non-player or other power events should not play the sound")

soulShards = 5
onEvent(frame, "UNIT_POWER_UPDATE", "player", "SOUL_SHARDS")
assert(frame.orb5.shown, "orb5 should show at full soul shards")
assert(#sounds == 1 and sounds[1] == "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg",
    "full gauge should play the full sound once")
print("PASS: other units and power types are ignored and full gauge plays its sound once")

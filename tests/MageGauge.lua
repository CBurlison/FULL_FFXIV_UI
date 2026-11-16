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

UnitClass = function() return "Mage", "MAGE" end
Enum = {PowerType = {ArcaneCharges = 16}}
local charges = 0
UnitPowerMax = function(unit, powerType)
    assert(unit == "player" and powerType == 16)
    return 4
end
UnitPower = function(unit, powerType)
    assert(unit == "player" and powerType == 16)
    return charges
end
local sounds = {}
PlaySoundFile = function(file) sounds[#sounds + 1] = file end
FFXIV_UI_DB = {sfxEnabled = true}
FFXIV_UI_Anchors = {JobGauge = newObject("JobGauge")}

-- Stub tree mirroring JobGauges/MageGauge.xml: the base is shown and every orb starts hidden.
ArcaneChargeFrame = newObject("ArcaneChargeFrame")
ArcaneChargeFrame.shown = false
ArcaneChargeFrame.base = newObject("base")
ArcaneChargeFrame.base.file = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\MAGE\\FFArcaneFrame"
for i = 1, 4 do
    local orb = newObject("orb" .. i)
    orb.shown = false
    ArcaneChargeFrame["orb" .. i] = orb
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

local xml = readFile("FFXIV_UI\\JobGauges\\MageGauge.xml")
assertContains(xml, 'name="ArcaneChargeFrame"', "frame global")
assertContains(xml, '<Size x="300" y="300"/>', "frame size")
assertContains(xml, '<Frame name="ArcaneChargeFrame" parent="UIParent" hidden="true">', "frame hidden at load")
assertContains(xml, 'parentKey="base"', "base texture")
assertContains(xml, "JobGauges\\MAGE\\FFArcaneFrame\"", "base artwork")
for i = 1, 4 do
    assertContains(xml, 'parentKey="orb' .. i .. '" hidden="true"', "orb hidden at load")
    assertContains(xml, "JobGauges\\Mage\\FFArcaneCharge" .. i .. ".tga\"", "orb artwork")
end
print("PASS: XML names, parent keys, hidden orbs, and artwork match the old Lua")

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
    assert(lines["JobGauges/MageGauge.xml"], tocPath .. " should list the XML")
    assert(lines["JobGauges/MageGauge.xml"] < lines["JobGauges/MageGauge.lua"],
        tocPath .. " should load the XML before the Lua")
end
print("PASS: both TOCs load the XML before the Lua")

local addonEnv = {}
local powerSource = readFile("FFXIV_UI\\General\\PowerAvailability.lua"):gsub("^\239\187\191", "")
assert(loadstring(powerSource, "PowerAvailability.lua"))("FFXIV_UI", addonEnv)

local source = readFile("FFXIV_UI\\JobGauges\\MageGauge.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "MageGauge.lua"))("FFXIV_UI", addonEnv)

local frame = ArcaneChargeFrame
assert(frame.parent == FFXIV_UI_Anchors.JobGauge, "frame should move to the JobGauge anchor")
for i = 1, 4 do
    assert(frame.orbs[i] == frame["orb" .. i], "orbs should map to the XML children")
    assert(not frame["orb" .. i].shown, "orb" .. i .. " should start hidden at zero charges")
end
print("PASS: frame reparents to the JobGauge anchor and orbs map to the XML children")

assert(frame.shown, "frame should show once arcane charges are readable")

local onEvent = frame.scripts.OnEvent
assert(onEvent, "frame should register an OnEvent handler")
assert(frame.events["UNIT_POWER_UPDATE"] and frame.events["PLAYER_ENTERING_WORLD"], "should listen for power and entering world")

charges = 2
onEvent(frame, "UNIT_POWER_UPDATE", "player", "ARCANE_CHARGES")
for i = 1, 4 do
    assert(frame["orb" .. i].shown == (i <= 2), "orb" .. i .. " visibility at 2 charges")
end
print("PASS: orbs fade in for current arcane charges")

charges = 4
onEvent(frame, "UNIT_POWER_UPDATE", "player", "ARCANE_CHARGES")
assert(#sounds == 1 and sounds[1] == "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg",
    "reaching four charges should play the full sound once")
print("PASS: full sound plays at four arcane charges")

onEvent(frame, "UNIT_POWER_UPDATE", "target", "ARCANE_CHARGES")
onEvent(frame, "UNIT_POWER_UPDATE", "player", "HOLY_POWER")
assert(#sounds == 1, "other units and power types should not replay the sound")

charges = 3
onEvent(frame, "UNIT_POWER_UPDATE", "player", "ARCANE_CHARGES")
assert(not frame.orb4.shown and frame.orb3.shown, "orb4 fades out when charges drop below four")
charges = 4
onEvent(frame, "UNIT_POWER_UPDATE", "player", "ARCANE_CHARGES")
assert(#sounds == 2, "regaining four charges should play the full sound again")
print("PASS: sound plays again when the gauge refills to four")

-- Fire and frost: the spec check hides the gauge even when arcane charge max reads 4.
local specFrame = newObject("ArcaneChargeFrameSpec")
specFrame.shown = true
specFrame.base = newObject("base")
for i = 1, 4 do
    specFrame["orb" .. i] = newObject("orb" .. i)
end
ArcaneChargeFrame = specFrame
local currentSpec = 63
GetSpecialization = function() return 2 end
GetSpecializationInfo = function(index)
    assert(index == 2)
    return currentSpec
end
sounds = {}
charges = 4
local specSource = readFile("FFXIV_UI\\JobGauges\\MageGauge.lua"):gsub("^\239\187\191", "")
local specEnv = {}
assert(loadstring(readFile("FFXIV_UI\\General\\PowerAvailability.lua"):gsub("^\239\187\191", ""), "PowerAvailability.lua"))("FFXIV_UI", specEnv)
assert(loadstring(specSource, "MageGauge.lua"))("FFXIV_UI", specEnv)
assert(not specFrame.shown, "fire or frost should hide the gauge")
assert(#sounds == 0, "fire or frost should not play the gauge sound")
print("PASS: fire and frost hide the gauge")

currentSpec = 62
specFrame.scripts.OnEvent(specFrame, "PLAYER_SPECIALIZATION_CHANGED", "player")
assert(specFrame.shown, "switching to arcane should show the gauge")
print("PASS: switching to arcane shows the gauge")

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

-- The fade helpers show the frame and set its target alpha, like the client does.
UIFrameFadeIn = function(frame, _, _, target) frame.shown = true; frame.alpha = target end
UIFrameFadeOut = function(frame, _, _, target) frame.shown = false; frame.alpha = target end

UnitClass = function() return "Rogue", "ROGUE" end
Enum = {PowerType = {ComboPoints = 4}}
local comboPoints = 0
local maxComboPoints = 5
local targetAttackable = false
UnitPowerMax = function(unit, powerType)
    assert(unit == "player" and powerType == 4)
    return maxComboPoints
end
UnitPower = function(unit, powerType)
    assert(unit == "player" and powerType == 4)
    return comboPoints
end
UnitExists = function(unit) return unit == "target" and targetAttackable end
UnitCanAttack = function(_, unit) return unit == "target" and targetAttackable end
local sounds = {}
PlaySoundFile = function(file) sounds[#sounds + 1] = file end
FFXIV_UI_DB = {sfxEnabled = true}
FFXIV_UI_Anchors = {JobGauge = newObject("JobGauge")}

-- Stub tree mirroring JobGauges/RogueGauge.xml: the base starts hidden at zero alpha and every orb is hidden.
ComboPointTrackerFrame = newObject("ComboPointTrackerFrame")
ComboPointTrackerFrame.base = newObject("base")
ComboPointTrackerFrame.base.file = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Rogue\\FFRogueFrame"
ComboPointTrackerFrame.base.shown = false
ComboPointTrackerFrame.base.alpha = 0
for i = 1, 7 do
    local orb = newObject("orb" .. i)
    orb.shown = false
    ComboPointTrackerFrame["orb" .. i] = orb
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

local xml = readFile("FFXIV_UI\\JobGauges\\RogueGauge.xml")
assertContains(xml, 'name="ComboPointTrackerFrame"', "frame global")
assertContains(xml, 'parentKey="base"', "base texture")
assertContains(xml, 'hidden="true" alpha="0"', "base starts hidden at zero alpha")
assertContains(xml, "JobGauges\\Rogue\\FFRogueFrame\"", "base artwork")
for i = 1, 7 do
    assertContains(xml, 'parentKey="orb' .. i .. '"', "orb parentKey")
    assertContains(xml, "JobGauges\\Rogue\\RogueCombo" .. i .. '"', "orb artwork")
end
print("PASS: XML names, parent keys, hidden base, and artwork match the old Lua")

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
    assert(lines["JobGauges/RogueGauge.xml"], tocPath .. " should list the XML")
    assert(lines["JobGauges/RogueGauge.xml"] < lines["JobGauges/RogueGauge.lua"],
        tocPath .. " should load the XML before the Lua")
end
print("PASS: both TOCs load the XML before the Lua")

local addonEnv = {}
local powerSource = readFile("FFXIV_UI\\General\\PowerAvailability.lua"):gsub("^\239\187\191", "")
assert(loadstring(powerSource, "PowerAvailability.lua"))("FFXIV_UI", addonEnv)

local source = readFile("FFXIV_UI\\JobGauges\\RogueGauge.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "RogueGauge.lua"))("FFXIV_UI", addonEnv)

local frame = ComboPointTrackerFrame
assert(frame.parent == FFXIV_UI_Anchors.JobGauge, "frame should move to the JobGauge anchor")
for i = 1, 7 do
    assert(frame.orbs[i] == frame["orb" .. i], "orbs should map to the XML children")
end
print("PASS: frame reparents to the JobGauge anchor and orbs map to the XML children")

local onEvent = frame.scripts.OnEvent
assert(onEvent, "frame should register an OnEvent handler")
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "UNIT_FACTION",
    "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "TRAIT_CONFIG_UPDATED", "SPELLS_CHANGED", "PLAYER_TALENT_UPDATE"}) do
    assert(frame.events[event], "should listen for " .. event)
end

-- A targeted enemy with combo points shows the base and the matching orbs.
comboPoints = 3
targetAttackable = true
onEvent(frame, "PLAYER_ENTERING_WORLD")
assert(frame.base.shown and frame.base.alpha == 1, "base should fade in with combo points")
for i = 1, 7 do
    assert(frame["orb" .. i].shown == (i <= 3), "orb" .. i .. " visibility at 3 combo points")
end
print("PASS: base and orbs fade in for current combo points")

-- Losing the target and points fades the base out.
comboPoints = 0
targetAttackable = false
onEvent(frame, "PLAYER_TARGET_CHANGED")
assert(not frame.base.shown and frame.base.alpha == 0, "base should fade out with no points or target")
print("PASS: base fades out with no points or target")

-- Reaching five points plays the full sound.
comboPoints = 5
onEvent(frame, "UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
assert(frame.orb5.shown and not frame.orb6.shown, "orb5 shows and orb6 stays hidden at 5 points")
assert(#sounds == 1 and sounds[1] == "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg",
    "reaching five points should play the full sound once")
print("PASS: full sound plays at five combo points")

onEvent(frame, "UNIT_POWER_UPDATE", "target", "COMBO_POINTS")
onEvent(frame, "UNIT_POWER_UPDATE", "player", "HOLY_POWER")
assert(#sounds == 1, "other units and power types should not replay the sound")

-- A six-point rogue raises the cap and swaps the base texture.
maxComboPoints = 6
comboPoints = 6
targetAttackable = true
onEvent(frame, "PLAYER_TALENT_UPDATE")
assert(frame.base.file == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Rogue\\FFRogueFrame6",
    "six-point base texture")
assert(frame.orb6.shown, "orb6 shows at six points")
assert(#sounds == 2, "reaching the six-point cap should play the full sound")
print("PASS: six-point max swaps the base texture and plays the full sound at the cap")

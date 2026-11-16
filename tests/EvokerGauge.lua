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

UnitClass = function() return "Evoker", "EVOKER" end
Enum = {PowerType = {Essence = 19}}
local essence = 0
local maxEssence = 5
local nexus = false
UnitPowerMax = function(unit, powerType)
    assert(unit == "player" and powerType == 19)
    return maxEssence
end
UnitPower = function(unit, powerType)
    assert(unit == "player" and powerType == 19)
    return essence
end
IsPlayerSpell = function(spellId)
    assert(spellId == 369908)
    return nexus
end
local sounds = {}
PlaySoundFile = function(file) sounds[#sounds + 1] = file end
FFXIV_UI_DB = {sfxEnabled = true}
FFXIV_UI_Anchors = {JobGauge = newObject("JobGauge")}

-- Stub tree mirroring JobGauges/EvokerGauge.xml: the base is shown and every orb starts hidden.
EssenceTrackerFrame = newObject("EssenceTrackerFrame")
EssenceTrackerFrame.base = newObject("base")
EssenceTrackerFrame.base.file = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Evoker\\FFEvokerFrame.tga"
for i = 1, 6 do
    local orb = newObject("orb" .. i)
    orb.shown = false
    EssenceTrackerFrame["orb" .. i] = orb
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

local xml = readFile("FFXIV_UI\\JobGauges\\EvokerGauge.xml")
assertContains(xml, 'name="EssenceTrackerFrame"', "frame global")
assertContains(xml, 'parentKey="base"', "base texture")
assertContains(xml, "JobGauges\\Evoker\\FFEvokerFrame.tga\"", "base artwork")
assertContains(xml, '<Size x="375" y="375"/>', "frame size")
for i = 1, 6 do
    assertContains(xml, 'parentKey="orb' .. i .. '" hidden="true"', "orb hidden at load")
    assertContains(xml, "JobGauges\\Evoker\\FFEssence" .. i .. ".tga\"", "orb artwork")
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
    assert(lines["JobGauges/EvokerGauge.xml"], tocPath .. " should list the XML")
    assert(lines["JobGauges/EvokerGauge.xml"] < lines["JobGauges/EvokerGauge.lua"],
        tocPath .. " should load the XML before the Lua")
end
print("PASS: both TOCs load the XML before the Lua")

local addonEnv = {}
local powerSource = readFile("FFXIV_UI\\General\\PowerAvailability.lua"):gsub("^\239\187\191", "")
assert(loadstring(powerSource, "PowerAvailability.lua"))("FFXIV_UI", addonEnv)

local source = readFile("FFXIV_UI\\JobGauges\\EvokerGauge.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "EvokerGauge.lua"))("FFXIV_UI", addonEnv)

local frame = EssenceTrackerFrame
assert(frame.parent == FFXIV_UI_Anchors.JobGauge, "frame should move to the JobGauge anchor")
for i = 1, 6 do
    assert(frame.orbs[i] == frame["orb" .. i], "orbs should map to the XML children")
end
print("PASS: frame reparents to the JobGauge anchor and orbs map to the XML children")

local onEvent = frame.scripts.OnEvent
assert(onEvent, "frame should register an OnEvent handler")
for _, event in ipairs({"UNIT_POWER_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_TALENT_UPDATE",
    "TRAIT_CONFIG_UPDATED", "SPELLS_CHANGED"}) do
    assert(frame.events[event], "should listen for " .. event)
end

-- Three essence shows the first three orbs and leaves the rest hidden.
essence = 3
onEvent(frame, "UNIT_POWER_UPDATE", "player", "ESSENCE")
for i = 1, 6 do
    assert(frame["orb" .. i].shown == (i <= 3), "orb" .. i .. " visibility at 3 essence")
end
print("PASS: orbs fade in for current essence")

-- Reaching five essence without Power Nexus plays the full sound once.
essence = 5
onEvent(frame, "UNIT_POWER_UPDATE", "player", "ESSENCE")
assert(frame.orb5.shown and not frame.orb6.shown, "orb6 stays hidden without Power Nexus")
assert(#sounds == 1 and sounds[1] == "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg",
    "reaching five essence should play the full sound once")
print("PASS: full sound plays at five essence without Power Nexus")

-- Other units and power types do not replay the sound.
onEvent(frame, "UNIT_POWER_UPDATE", "target", "ESSENCE")
onEvent(frame, "UNIT_POWER_UPDATE", "player", "HOLY_POWER")
assert(#sounds == 1, "other units and power types should not change the sound state")

-- Power Nexus raises the cap to six and swaps the base texture.
nexus = true
maxEssence = 6
essence = 6
onEvent(frame, "PLAYER_TALENT_UPDATE")
assert(frame.base.file == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Evoker\\FFEvokerFrame6.tga",
    "Power Nexus base texture")
assert(frame.orb6.shown, "orb6 shows at six essence with Power Nexus")
assert(#sounds == 2, "reaching the six-essence cap should play the full sound")
print("PASS: Power Nexus raises the cap, swaps the base texture, and plays the sound at six")

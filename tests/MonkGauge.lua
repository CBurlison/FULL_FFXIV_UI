local methods = {}
local function newObject(name)
    return setmetatable({name = name, scripts = {}, events = {}, shown = true, alpha = 1, level = 1}, {__index = methods})
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetPoint(...) self.point = {...} end
function methods:ClearAllPoints() self.point = nil end
function methods:SetAllPoints() self.allPoints = true end
function methods:SetParent(parent) self.parent = parent end
function methods:SetTexture(file) self.file = file end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:GetAlpha() return self.alpha end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(level) self.level = level end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterAllEvents() self.events = {} end
function methods:SetScript(name, callback) self.scripts[name] = callback end

CreateFrame = function()
    return newObject("waiter")
end

UnitClass = function() return "Monk", "MONK" end
Enum = {PowerType = {Chi = 12}}
local specialization = 3
local hasAscension = false
GetSpecialization = function() return specialization end
IsPlayerSpell = function(spellId)
    assert(spellId == 115396, "Ascension spell id")
    return hasAscension
end
local chi = 0
UnitPowerMax = function(unit, powerType)
    assert(unit == "player" and powerType == 12)
    return 6
end
UnitPower = function(unit, powerType)
    assert(unit == "player" and powerType == 12)
    return chi
end
UIFrameFadeIn = function(frame, _, _, target) frame.faded = target end
UIFrameFadeOut = function(frame, _, _, target) frame.faded = target end
local sounds = {}
PlaySoundFile = function(file) sounds[#sounds + 1] = file end
FFXIV_UI_DB = {sfxEnabled = true}
FFXIV_UI_Anchors = {JobGauge = newObject("JobGauge")}

-- Stub tree mirroring JobGauges/MonkGauge.xml.
ChiTrackerFrame = newObject("ChiTrackerFrame")
ChiTrackerFrame.base = newObject("base")
for i = 1, 6 do
    local orb = newObject("orb" .. i)
    orb.shown = false
    ChiTrackerFrame["orb" .. i] = orb
end
OverlayFrame = newObject("OverlayFrame")
OverlayFrame.base = newObject("base")

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function assertContains(content, text, label)
    assert(content:find(text, 1, true), label .. " missing: " .. text)
end

local xml = readFile("FFXIV_UI\\JobGauges\\MonkGauge.xml")
assertContains(xml, 'name="ChiTrackerFrame"', "frame global")
assertContains(xml, 'name="OverlayFrame"', "overlay global")
assertContains(xml, 'parentKey="base"', "base texture")
assertContains(xml, "JobGauges\\Monk\\FFMonkFrame.tga", "base artwork")
for i = 1, 6 do
    assertContains(xml, 'parentKey="orb' .. i .. '"', "orb parentKey")
    assertContains(xml, "JobGauges\\Monk\\FFMonkChi" .. i .. ".tga", "orb artwork")
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
    assert(lines["JobGauges/MonkGauge.xml"], tocPath .. " should list the XML")
    assert(lines["JobGauges/MonkGauge.xml"] < lines["JobGauges/MonkGauge.lua"],
        tocPath .. " should load the XML before the Lua")
end
print("PASS: both TOCs load the XML before the Lua")

local addonEnv = {}
local powerSource = readFile("FFXIV_UI\\General\\PowerAvailability.lua"):gsub("^\239\187\191", "")
assert(loadstring(powerSource, "PowerAvailability.lua"))("FFXIV_UI", addonEnv)

local source = readFile("FFXIV_UI\\JobGauges\\MonkGauge.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "MonkGauge.lua"))("FFXIV_UI", addonEnv)

local frame, overlay = ChiTrackerFrame, OverlayFrame
assert(frame.parent == FFXIV_UI_Anchors.JobGauge, "chi frame should move to the JobGauge anchor")
assert(overlay.parent == FFXIV_UI_Anchors.JobGauge, "overlay should move to the JobGauge anchor")
assert(overlay.level == frame.level + 1, "overlay should sit one level above the chi frame")
print("PASS: frames reparent to the JobGauge anchor and the overlay sits above")

local onEvent = frame.scripts.OnEvent
assert(onEvent, "chi frame should register an OnEvent handler")
for _, event in ipairs({"UNIT_POWER_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED",
    "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED", "SPELLS_CHANGED"}) do
    assert(frame.events[event], "should listen for " .. event)
end

-- Windwalker without Ascension: five orbs, normal textures.
chi = 4
onEvent(frame, "PLAYER_SPECIALIZATION_CHANGED")
assert(frame.shown and overlay.shown, "frames should show for Windwalker")
assert(frame.base.file == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Monk\\FFMonkFrame.tga",
    "normal base texture")
assert(overlay.base.file == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Monk\\FFMonkFrameOverlay.tga",
    "normal overlay texture")
for i = 1, 6 do
    assert(frame["orb" .. i].shown == (i <= 4), "orb" .. i .. " visibility at 4 chi")
end
print("PASS: Windwalker shows the normal gauge and orbs for current chi")

chi = 5
onEvent(frame, "UNIT_POWER_UPDATE", "player", "CHI")
assert(frame.orb5.shown and not frame.orb6.shown, "orb5 shows and orb6 stays hidden at 5 chi without Ascension")
assert(#sounds == 1, "reaching 5 chi should play the full sound")
print("PASS: full sound plays at 5 chi without Ascension")

onEvent(frame, "UNIT_POWER_UPDATE", "target", "CHI")
onEvent(frame, "UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
assert(#sounds == 1, "other units and power types should not replay the sound")

-- Non-Windwalker hides both frames.
specialization = 1
onEvent(frame, "PLAYER_ENTERING_WORLD")
assert(not frame.shown and not overlay.shown, "frames should hide for a non-Windwalker")
print("PASS: non-Windwalker hides the gauge")

-- Ascension raises the cap to six and swaps textures.
specialization = 3
hasAscension = true
chi = 6
onEvent(frame, "PLAYER_TALENT_UPDATE")
assert(frame.base.file == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Monk\\FFMonkFrameAsc.tga",
    "Ascension base texture")
assert(overlay.base.file == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\Monk\\FFMonkFrameAscOverlay.tga",
    "Ascension overlay texture")
assert(frame.orb6.shown, "orb6 shows at 6 chi with Ascension")
assert(#sounds == 2, "reaching the Ascension cap should play the full sound")
print("PASS: Ascension adds a sixth orb and swaps textures")

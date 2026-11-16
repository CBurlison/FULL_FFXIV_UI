local methods = {}
local function newObject(name)
    return setmetatable({name = name, scripts = {}, events = {}, shown = true, alpha = 1}, {__index = methods})
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetHeight(h) self.height = h end
function methods:SetPoint(...) self.point = {...} end
function methods:ClearAllPoints() self.point = nil end
function methods:SetAllPoints() self.allPoints = true end
function methods:SetParent(parent) self.parent = parent end
function methods:SetTexture(file) self.file = file end
function methods:SetTexCoord(...) self.texCoord = {...} end
function methods:SetVertexColor(...) self.color = {...} end
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

UnitClass = function() return "Death Knight", "DEATHKNIGHT" end
GetSpecialization = function() return 1 end
local now = 0
GetTime = function() return now end
local runeReady = {true, true, true, true, true, true}
GetRuneCooldown = function(i)
    if runeReady[i] then return 0, 0, true end
    return 0, 10, false
end
local sounds = {}
PlaySoundFile = function(file) sounds[#sounds + 1] = file end
FFXIV_UI_DB = {sfxEnabled = true}
FFXIV_UI_Anchors = {JobGauge = newObject("JobGauge")}

-- Stub tree mirroring JobGauges/DeathKnightGauge.xml: the frame and six rune children.
DKRuneFrame = newObject("DKRuneFrame")
DKRuneFrame.base = newObject("base")
for i = 1, 6 do
    local rune = newObject("rune" .. i)
    rune.frameTex = newObject("frameTex" .. i)
    rune.fill = newObject("fill" .. i)
    DKRuneFrame["rune" .. i] = rune
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

local xml = readFile("FFXIV_UI\\JobGauges\\DeathKnightGauge.xml")
assertContains(xml, '<Frame name="DKRuneFrame" parent="UIParent" hidden="true">', "frame global")
assertContains(xml, '<Size x="300" y="300"/>', "frame size")
assertContains(xml, '<Anchor point="CENTER" relativeTo="UIParent" relativePoint="CENTER" x="0" y="-200"/>', "frame anchor")
assertContains(xml, 'parentKey="base" setAllPoints="true"', "base texture")
assertContains(xml, "JobGauges\\DeathKnight\\FFDeathKnightBG\"", "base artwork")
local offsets = {
    {-50, -10}, {0, -10}, {50, -10}, {-25, -60}, {25, -60}, {75, -60},
}
for i = 1, 6 do
    assertContains(xml, 'parentKey="rune' .. i .. '"', "rune frame")
    assertContains(xml, '<Anchor point="CENTER" x="' .. offsets[i][1] .. '" y="' .. offsets[i][2] .. '"/>', "rune offset " .. i)
end
assertContains(xml, 'parentKey="frameTex" setAllPoints="true" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\DeathKnight\\FFRuneFrame.tga"', "rune frame artwork")
assertContains(xml, 'parentKey="fill" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\JobGauges\\DeathKnight\\FFRuneFill.tga"', "rune fill artwork")
print("PASS: XML names, parent keys, rune offsets, and artwork match the old Lua")

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
    assert(lines["JobGauges/DeathKnightGauge.xml"], tocPath .. " should list the XML")
    assert(lines["JobGauges/DeathKnightGauge.xml"] < lines["JobGauges/DeathKnightGauge.lua"],
        tocPath .. " should load the XML before the Lua")
end
print("PASS: both TOCs load the XML before the Lua")

local addonEnv = {}
local source = readFile("FFXIV_UI\\JobGauges\\DeathKnightGauge.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "DeathKnightGauge.lua"))("FFXIV_UI", addonEnv)

local frame = DKRuneFrame
assert(frame.parent == FFXIV_UI_Anchors.JobGauge, "frame should move to the JobGauge anchor")
assert(frame.shown, "frame should show for a Death Knight")
for i = 1, 6 do
    assert(frame.runes[i] == frame["rune" .. i], "runes should map to the XML children")
    assert(frame["rune" .. i].fill.height == 0, "fill should start empty")
end
print("PASS: frame reparents to the JobGauge anchor and runes map to the XML children")

local onEvent = frame.scripts.OnEvent
assert(onEvent, "frame should register an OnEvent handler")
assert(frame.events["RUNE_POWER_UPDATE"] and frame.events["PLAYER_ENTERING_WORLD"], "should listen for rune and entering world")

onEvent(frame, "PLAYER_ENTERING_WORLD")
assert(frame.rune1.fill.height == 90, "ready rune should fill to full height")
assert(frame.rune1.fill.color[4] == 1.0, "spec 1 ready color should apply")
print("PASS: ready runes fill on entering world")

runeReady[1] = false
onEvent(frame, "RUNE_POWER_UPDATE")
assert(frame.rune1.fill.color[4] == 0.5, "recharging rune should use the dark fill color")
assert(#sounds == 0, "no sound while runes are not full")
print("PASS: recharging rune uses the dark fill color")

runeReady[1] = true
onEvent(frame, "RUNE_POWER_UPDATE")
assert(#sounds == 1 and sounds[1] == "Interface\\AddOns\\FFXIV_UI\\Media\\Audio\\FFXIV_Gauge_Full.ogg",
    "all six runes ready should play the full sound once")
print("PASS: full sound plays when all six runes are ready")

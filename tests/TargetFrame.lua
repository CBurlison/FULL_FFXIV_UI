local frames, units = {}, {}
local methods = {}
local function object()
    return setmetatable({events = {}, children = {}, textures = {}}, {__index = methods})
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetPoint(...) self.point = {...} end
function methods:SetAllPoints() end
function methods:SetParent() end
function methods:ClearAllPoints() end
function methods:SetFrameStrata() end
function methods:GetFrameStrata() return "MEDIUM" end
function methods:EnableMouse() end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:SetAlpha() end
function methods:UnregisterAllEvents() end
function methods:SetAttribute() end
function methods:RegisterForClicks() end
function methods:CreateTexture() 
    local tex = object()
    self.textures[#self.textures + 1] = tex
    return tex
end
function methods:CreateFontString() return object() end
function methods:SetTexture(path) self.texturePath = path end
function methods:SetTexCoord() end
function methods:SetDrawLayer() end
function methods:SetFont() end
function methods:SetTextColor() end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetText(value) self.text = value end
function methods:SetJustifyH() end
function methods:SetFrameLevel() end
function methods:GetFrameLevel() return 1 end
function methods:SetStatusBarTexture() self.texture = object() end
function methods:GetStatusBarTexture() return self.texture end
function methods:SetStatusBarColor(...) self.color = {...} end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetMinMaxValues(low, high) self.maximum = high end
function methods:SetValue(value) self.value = value end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetScript(_, callback) self.callback = callback end
TargetFrame = object()

-- Stub tree mirroring TargetFrames/TargetFrame_HP.xml.
local targetFrame = object()
FFTargetFrame = targetFrame
frames.FFTargetFrame = targetFrame
targetFrame.bg = object()
targetFrame.bar = object()
local outlineFrame = object()
targetFrame.outlineFrame = outlineFrame
targetFrame.children = {outlineFrame}
local function xmlTexture(key, shown)
    local tex = object()
    tex.shown = shown
    outlineFrame[key] = tex
    outlineFrame.textures[#outlineFrame.textures + 1] = tex
end
xmlTexture("classificationIcon", false)
xmlTexture("raidIcon", false)
xmlTexture("outline", true)
for _, key in ipairs({"LLabel", "vLabel", "levelText", "nameText", "hpPercentText"}) do
    outlineFrame[key] = object()
end
outlineFrame.clickFrame = object()
frames.FFXIV_TargetClick = outlineFrame.clickFrame
Enum = {StatusBarInterpolation = {ExponentialEaseOut = 1}}
FFXIV_UI_Anchors = {TargetHP = object()}
GetBuildInfo = function() return "Retail", "", "", 110005 end
GetCVar = function(cvar) return "0" end
UnitExists = function(unit) return units[unit] ~= nil end
UnitHealth = function(unit) return units[unit].health or 100 end
UnitHealthMax = function(unit) return units[unit].maxHealth or 100 end
UnitName = function(unit) return units[unit].name or "TestTarget" end
UnitLevel = function(unit) return units[unit].level or 60 end
UnitClassification = function(unit) return units[unit].classification or "normal" end
UnitIsUnit = function() return false end
UnitIsPlayer = function() return false end
UnitAffectingCombat = function() return false end
UnitCanAttack = function() return true end
UnitIsDeadOrGhost = function() return false end
UnitReaction = function() return 4 end
GetRaidTargetIndex = function() return nil end

assert(loadfile("FFXIV_UI\\TargetFrames\\TargetFrame_HP.lua"))("FFXIV_UI", {})

local function event(name, unit)
    for _, frame in pairs(frames) do
        if frame.events[name] then frame.callback(frame, name, unit) end
    end
end

targetFrame:Show()
assert(outlineFrame.classificationIcon.shown == false, "classification icon starts hidden")
assert(outlineFrame.raidIcon.shown == false, "raid icon starts hidden")

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function assertContains(content, text, label)
    assert(content:find(text, 1, true), label .. " missing: " .. text)
end

local xml = readFile("FFXIV_UI\\TargetFrames\\TargetFrame_HP.xml")
assertContains(xml, '<Frame name="FFTargetFrame" parent="UIParent" frameStrata="MEDIUM">', "frame global")
assertContains(xml, '<Size x="669.5" y="669.5"/>', "frame size")
assertContains(xml, 'parentKey="bg" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Background"', "background artwork")
assertContains(xml, '<StatusBar parentKey="bar">', "health bar")
assertContains(xml, '<BarTexture file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Health"/>', "health bar texture")
assertContains(xml, 'parentKey="outlineFrame"', "outline frame")
assertContains(xml, 'parentKey="classificationIcon" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Normal-Icon" hidden="true"', "classification icon")
assertContains(xml, 'parentKey="raidIcon" file="Interface\\TargetingFrame\\UI-RaidTargetingIcons" hidden="true"', "raid icon")
assertContains(xml, 'parentKey="outline" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Frame6"', "outline artwork")
assertContains(xml, '<FontString parentKey="LLabel" text="L"', "L label")
assertContains(xml, '<FontString parentKey="vLabel" text="v"', "v label")
assertContains(xml, 'parentKey="levelText"', "level text")
assertContains(xml, 'parentKey="nameText"', "name text")
assertContains(xml, 'parentKey="hpPercentText"', "hp percent text")
assertContains(xml, '<Button parentKey="clickFrame" name="FFXIV_TargetClick" inherits="SecureUnitButtonTemplate"', "click frame")
print("PASS: XML names, parent keys, hidden flags, and artwork match the old Lua")

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
    assert(lines["TargetFrames/TargetFrame_HP.xml"], tocPath .. " should list the XML")
    assert(lines["TargetFrames/TargetFrame_HP.xml"] < lines["TargetFrames/TargetFrame_HP.lua"],
        tocPath .. " should load the XML before the Lua")
end
print("PASS: both TOCs load the XML before the Lua")

-- Test Normal target classification
units.target = {name = "Normal Mob", classification = "normal"}
event("PLAYER_TARGET_CHANGED")
assert(targetFrame.shown)
local foundNormal = false
for _, tex in ipairs(outlineFrame.textures) do
    if tex.texturePath and string.match(tex.texturePath, "Normal%-Icon") and tex.shown then
        foundNormal = true
    end
end
assert(foundNormal, "Normal-Icon should be shown for normal classification")
print("PASS: normal target classification icon displayed")

-- Test Elite target classification
units.target = {name = "Elite Mob", classification = "elite"}
event("PLAYER_TARGET_CHANGED")
local foundElite = false
for _, tex in ipairs(outlineFrame.textures) do
    if tex.texturePath and string.match(tex.texturePath, "Elite%-Icon") and tex.shown then
        foundElite = true
    end
end
assert(foundElite, "Elite-Icon should be shown for elite classification")
print("PASS: elite target classification icon displayed")

-- Test Rare target classification
units.target = {name = "Rare Mob", classification = "rare"}
event("PLAYER_TARGET_CHANGED")
local foundRare = false
for _, tex in ipairs(outlineFrame.textures) do
    if tex.texturePath and string.match(tex.texturePath, "Rare%-Icon") and tex.shown then
        foundRare = true
    end
end
assert(foundRare, "Rare-Icon should be shown for rare classification")
print("PASS: rare target classification icon displayed")

-- Test Boss target classification
units.target = {name = "Boss Mob", classification = "worldboss"}
event("PLAYER_TARGET_CHANGED")
local foundBoss = false
for _, tex in ipairs(outlineFrame.textures) do
    if tex.texturePath and string.match(tex.texturePath, "Boss%-Icon") and tex.shown then
        foundBoss = true
    end
end
assert(foundBoss, "Boss-Icon should be shown for worldboss classification")
print("PASS: boss target classification icon displayed")

-- Test Rare Elite (Rare Boss) target classification
units.target = {name = "Rare Boss Mob", classification = "rareelite"}
event("PLAYER_TARGET_CHANGED")
local foundRareBoss = false
for _, tex in ipairs(outlineFrame.textures) do
    if tex.texturePath and string.match(tex.texturePath, "Rare%-Boss%-Icon") and tex.shown then
        foundRareBoss = true
    end
end
assert(foundRareBoss, "Rare-Boss-Icon should be shown for rareelite classification")
print("PASS: rare boss target classification icon displayed")

-- Test Player target classification
units.target = {name = "Player", classification = "player"}
event("PLAYER_TARGET_CHANGED")
local foundPlayer = false
for _, tex in ipairs(outlineFrame.textures) do
    if tex.texturePath and string.match(tex.texturePath, "Elite%-Icon") and tex.shown then
        foundPlayer = true
    end
end
assert(foundPlayer, "Elite-Icon should be shown for player classification")
print("PASS: player target classification icon displayed")

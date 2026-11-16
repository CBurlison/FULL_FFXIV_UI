local addonName, ns = ...

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end
local xml = readFile("FFXIV_UI\\TargetFrames\\FocusTargetFrame.xml")
local function contains(text)
    assert(xml:find(text, 1, true), "XML missing: " .. text)
end
contains('<Frame name="FFFocusTargetFrame" parent="UIParent" frameStrata="MEDIUM">')
contains('<Size x="650" y="650"/>')
contains('<Anchor point="TOPLEFT" x="215" y="-4"/>')
contains('<Anchor point="BOTTOMRIGHT" x="-215" y="0"/>')
contains('<Frame parentKey="outlineFrame" frameStrata="MEDIUM" setAllPoints="true" enableMouse="false">')
contains('<Layer level="OVERLAY" textureSubLevel="3">')
contains('<Layer level="OVERLAY" textureSubLevel="7">')
contains('font="Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisMedium.ttf" justifyH="LEFT"')
contains('<FontHeight val="15"/>')
contains('<Anchor point="LEFT" x="220" y="16"/>')
contains('<Offset x="1" y="-1"/>')
contains('<Color r="1" g="0.87" b="0"/>')
contains('inherits="SecureUnitButtonTemplate" frameStrata="MEDIUM" enableMouse="true"')
contains('<Size x="233.3333333333333" y="68"/>')
contains('<Anchor point="CENTER" x="0" y="5"/>')
for _, key in ipairs({"bg", "bar", "outlineFrame", "outline", "nameText", "clickFrame"}) do
    contains('parentKey="' .. key .. '"')
end
for _, artwork in ipairs({"Background", "Health", "FocusTarget"}) do
    contains('file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\' .. artwork .. '"')
end
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do
        index = index + 1
        lines[line] = index
    end
    assert(assert(lines["TargetFrames/FocusTargetFrame.xml"]) < assert(lines["TargetFrames/FocusTargetFrame.lua"]))
end
print("PASS: focus XML layout, artwork, and both TOC load orders")

local methods = {}
local function object()
    return setmetatable({events = {}, attributes = {}}, {__index = methods})
end
function methods:SetPoint(...) self.point = {...} end
function methods:ClearAllPoints() self.point = nil end
function methods:SetParent(parent) self.parent = parent end
function methods:GetFrameLevel() return 1 end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameStrata() return "MEDIUM" end
function methods:SetFrameStrata(strata) self.strata = strata end
function methods:GetStatusBarTexture() return self.texture end
function methods:SetDrawLayer(...) self.layer = {...} end
function methods:SetTexCoord(...) self.texCoord = {...} end
function methods:RegisterForClicks(...) self.clicks = {...} end
function methods:SetAttribute(key, value) self.attributes[key] = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetStatusBarColor(...) self.color = {...} end
methods.SetVertexColor = methods.SetStatusBarColor
methods.SetTextColor = methods.SetStatusBarColor
function methods:SetShadowColor(...) self.shadow = {...} end
function methods:SetText(text) self.text = text end
function methods:SetMinMaxValues(low, high) self.low, self.high = low, high end
function methods:SetValue(value, interpolation) self.value, self.interpolation = value, interpolation end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetScript(script, callback) self[script] = callback end
function methods:Hide() self.hidden = true end
function methods:UnregisterAllEvents() self.events = {}; self.unregistered = true end

FFFocusTargetFrame, FFTargetFrame, FocusFrame = object(), object(), object()
local frame = FFFocusTargetFrame
frame.bg, frame.bar, frame.outlineFrame = object(), object(), object()
frame.bar.texture = object()
local overlay = frame.outlineFrame
overlay.outline, overlay.nameText, overlay.clickFrame = object(), object(), object()
UIParent = object()
FFXIV_UI_Anchors = {FocusTarget = object()}
Enum = {StatusBarInterpolation = {ExponentialEaseOut = 1}}
local exists, reaction, player, dead, fighting, selfUnit, party, raid = false, 4, false, false, false, false, false, false
UnitExists = function(unit) assert(unit == "focus"); return exists end
UnitHealth = function(unit) assert(unit == "focus"); return 37 end
UnitHealthMax = function(unit) assert(unit == "focus"); return 80 end
UnitName = function(unit) assert(unit == "focus"); return "Focus name" end
UnitReaction = function() return reaction end
UnitIsPlayer = function() return player end
UnitIsDeadOrGhost = function() return dead end
UnitAffectingCombat = function() return fighting end
UnitCanAttack = function() return true end
UnitIsUnit = function() return selfUnit end
UnitInParty = function() return party end
UnitInRaid = function() return raid end
CreateFrame = function() error("Focus frames must come from XML") end
assert(loadstring(readFile("FFXIV_UI\\TargetFrames\\FocusTargetFrame.lua")))("FFXIV_UI", {})
assert(frame.alpha == 0 and FocusFrame.hidden and FocusFrame.unregistered)
FocusFrame:Show()
assert(FocusFrame.hidden, "Default focus frame must stay disabled")
assert(frame.parent == FFXIV_UI_Anchors.FocusTarget)
assert(frame.point[1] == "CENTER" and frame.point[2] == frame.parent and frame.point[5] == -15)
assert(overlay.level == 6 and overlay.clickFrame.level == 0)
assert(overlay.clickFrame.clicks[1] == "AnyUp")
assert(overlay.clickFrame.attributes.unit == "focus")
assert(overlay.clickFrame.attributes.type1 == "target" and overlay.clickFrame.attributes.type2 == "togglemenu")
local function event(name, unit)
    assert(frame.events[name])
    frame.OnEvent(frame, name, unit)
end
local function colors(background, fill, text)
    text = text or fill
    for i = 1, 3 do
        assert(math.abs(frame.bg.color[i] - background[i]) < 0.000001)
        assert(math.abs(overlay.outline.color[i] - background[i]) < 0.000001)
        assert(math.abs(frame.bar.color[i] - fill[i]) < 0.000001)
        assert(math.abs(overlay.nameText.color[i] - text[i]) < 0.000001)
    end
end
exists = true
event("PLAYER_FOCUS_CHANGED")
assert(frame.alpha == 1 and frame.bar.value == 37 and frame.bar.high == 80)
assert(frame.bar.interpolation == Enum.StatusBarInterpolation.ExponentialEaseOut)
assert(overlay.nameText.text == "Focus name")
colors({1, 0.87, 0}, {235/255, 222/255, 129/255})
reaction = 2
event("UNIT_HEALTH", "focus")
colors({200/255, 50/255, 8/255}, {1, 0.8, 0.8})
reaction = 5
event("UNIT_MAXHEALTH", "focus")
colors({113/255, 214/255, 64/255}, {228/255, 1, 204/255})
player = true
event("UNIT_HEALTH", "focus")
colors({0.6, 0.8, 1}, {0.6, 0.8, 1})
fighting = true
event("UNIT_HEALTH", "focus")
colors({200/255, 50/255, 8/255}, {1, 0.8, 0.8})
dead = true
event("UNIT_HEALTH", "focus")
colors({0.35, 0.35, 0.35}, {0.4, 0.4, 0.4})
for _, membership in ipairs({"self", "party", "raid"}) do
    selfUnit, party, raid = membership == "self", membership == "party", membership == "raid"
    event("UNIT_HEALTH", "focus")
    colors({0.6, 0.8, 1}, {1, 1, 1}, {0.6, 0.8, 1})
end
frame.bar.value = -1
event("UNIT_HEALTH", "target")
assert(frame.bar.value == -1)
exists = false
event("PLAYER_FOCUS_CHANGED")
assert(frame.alpha == 0)
print("PASS: focus binding, clicks, anchoring, health/name, colors, filtering, and visibility")

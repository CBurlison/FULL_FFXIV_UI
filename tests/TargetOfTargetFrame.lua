local addonName, ns = ...

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local xml = readFile("FFXIV_UI\\TargetFrames\\TargetOfTargetFrame.xml")
local function contains(text)
    assert(xml:find(text, 1, true), "XML missing: " .. text)
end
contains('<Frame name="FFTargetOfTargetFrame" parent="UIParent" frameStrata="MEDIUM">')
contains('<Size x="650" y="650"/>')
contains('<Anchor point="TOPLEFT" x="215" y="-4"/>')
contains('<Anchor point="BOTTOMRIGHT" x="-215" y="0"/>')
contains('<Layer level="ARTWORK" textureSubLevel="5">')
for _, key in ipairs({"bg", "bar", "arrow", "arrow2", "outlineFrame", "outline", "nameText", "clickFrame"}) do
    contains('parentKey="' .. key .. '"')
end
for _, artwork in ipairs({"Background", "Health", "Arrow", "Arrow2", "TargetTarget"}) do
    contains('file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\' .. artwork .. '"')
end
contains('<Size x="70" y="70"/>')
contains('<Color r="1" g="0.87" b="0"/>')
contains('<Frame parentKey="outlineFrame" frameStrata="MEDIUM" setAllPoints="true" enableMouse="false">')
contains('<Layer level="OVERLAY" textureSubLevel="3">')
contains('<Layer level="OVERLAY" textureSubLevel="7">')
contains('font="Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisMedium.ttf" justifyH="LEFT"')
contains('<FontHeight val="20"/>')
contains('<Anchor point="LEFT" x="220" y="16"/>')
contains('<Offset x="1" y="-1"/>')
contains('inherits="SecureUnitButtonTemplate" frameStrata="MEDIUM" enableMouse="true"')
contains('<Size x="233.3333333333333" y="68"/>')
contains('<Anchor point="CENTER" x="0" y="5"/>')
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do
        index = index + 1
        lines[line] = index
    end
    local xmlLine = assert(lines["TargetFrames/TargetOfTargetFrame.xml"])
    assert(xmlLine < assert(lines["TargetFrames/TargetOfTargetFrame.lua"]))
end
print("PASS: target-of-target XML layout, artwork, and both TOC load orders")

local methods = {}
local function object()
    return setmetatable({events = {}, attributes = {}, animations = {}}, {__index = methods})
end
function methods:SetPoint(...)
    self.point = {...}
    self.points = self.points or {}
    self.points[self.point[1]] = self.point
end
function methods:GetPoint() return unpack(self.point) end
function methods:ClearAllPoints() self.point = nil; self.points = {} end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetParent(parent) self.parent = parent end
function methods:GetFrameLevel() return self.level or 1 end
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
function methods:CreateAnimationGroup() self.group = object(); return self.group end
function methods:CreateAnimation(kind)
    local animation = object()
    animation.kind = kind
    self.animations[#self.animations + 1] = animation
    return animation
end
function methods:SetLooping(looping) self.looping = looping end
function methods:SetDuration(duration) self.duration = duration end
function methods:SetSmoothing(smoothing) self.smoothing = smoothing end
function methods:SetOffset(...) self.offset = {...} end
function methods:SetOrder(order) self.order = order end
function methods:SetFromAlpha(alpha) self.fromAlpha = alpha end
function methods:SetToAlpha(alpha) self.toAlpha = alpha end
function methods:Play() self.playing = true end

FFTargetOfTargetFrame = object()
local frame = FFTargetOfTargetFrame
frame.bg, frame.bar, frame.arrow, frame.arrow2 = object(), object(), object(), object()
for _, arrow in ipairs({frame.arrow, frame.arrow2}) do
    arrow:SetSize(650, 650)
    arrow:SetPoint("TOPLEFT", frame, "TOPLEFT")
    arrow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
end
frame.bar.texture = object()
frame.outlineFrame = object()
local overlay = frame.outlineFrame
overlay.outline, overlay.nameText, overlay.clickFrame = object(), object(), object()
FFTargetFrame = object()
UIParent = object()
FFXIV_UI_Anchors = {TargetOfTarget = object()}
Enum = {StatusBarInterpolation = {ExponentialEaseOut = 1}}
local units, reaction, player, dead, fighting = {}, 4, false, false, false
UnitExists = function(unit) return units[unit] ~= nil end
UnitHealth = function() return 37 end
UnitHealthMax = function() return 80 end
UnitName = function() return "Target's target" end
UnitReaction = function() return reaction end
UnitIsPlayer = function() return player end
UnitIsDeadOrGhost = function() return dead end
UnitAffectingCombat = function() return fighting end
UnitCanAttack = function() return true end
CreateFrame = function() error("All target-of-target frames should come from XML") end
C_Timer = {After = function() error("Zero-stagger arrows should start immediately") end}

assert(loadstring(readFile("FFXIV_UI\\TargetFrames\\TargetOfTargetFrame.lua")))("FFXIV_UI", {})
assert(frame.alpha == 0)
assert(frame.parent == FFXIV_UI_Anchors.TargetOfTarget)
assert(frame.point[1] == "CENTER" and frame.point[2] == frame.parent and frame.point[5] == -15)
assert(overlay.level == 6 and overlay.clickFrame.level == 0)
assert(overlay.clickFrame.clicks[1] == "AnyUp")
assert(overlay.clickFrame.attributes.unit == "targettarget")
assert(overlay.clickFrame.attributes.type1 == "target")
assert(overlay.clickFrame.attributes.type2 == "togglemenu")
assert(frame.arrow.point[2] == frame.bar and frame.arrow.point[4] == -22)
assert(frame.arrow2.point[2] == frame.bar and frame.arrow2.point[4] == -18)
for _, arrow in ipairs({frame.arrow, frame.arrow2}) do
    assert(arrow.width == 70 and arrow.height == 70, "Arrow size must remain 70x70")
    local pointCount = 0
    for _ in pairs(arrow.points) do pointCount = pointCount + 1 end
    assert(pointCount == 1 and arrow.points.RIGHT,
        "Arrow must have only its right anchor, without competing XML anchors")
    assert(arrow.point[1] == "RIGHT" and arrow.point[3] == "LEFT" and arrow.point[5] == 0)
    local group = arrow.group
    assert(group.playing and group.looping == "REPEAT" and #group.animations == 4)
    local slide, fade, pause, reset = unpack(group.animations)
    assert(slide.kind == "Translation" and slide.duration == 0.5 and slide.smoothing == "OUT")
    assert(slide.offset[1] == 25 and slide.offset[2] == 0 and slide.order == 1)
    assert(fade.kind == "Alpha" and fade.toAlpha == 1 and fade.duration == 0.5 and fade.order == 1)
    assert(pause.fromAlpha == 1 and pause.toAlpha == 1 and pause.duration == 1 and pause.order == 2)
    assert(reset.offset[1] == -25 and reset.duration == 0 and reset.order == 3)
end
assert(frame.arrow.group.animations[2].fromAlpha == 1)
assert(frame.arrow2.group.animations[2].fromAlpha == 0)
print("PASS: XML binding, secure click attributes, anchoring, and arrow animations")

local function event(eventName, unit)
    assert(frame.events[eventName], "Missing event: " .. eventName)
    frame.OnEvent(frame, eventName, unit)
end
units.target, units.targettarget = {}, {}
event("PLAYER_TARGET_CHANGED")
assert(frame.alpha == 1 and frame.bar.value == 37 and frame.bar.high == 80)
assert(frame.bar.interpolation == Enum.StatusBarInterpolation.ExponentialEaseOut)
assert(overlay.nameText.text == "Target's target")
local function close(actual, expected)
    assert(math.abs(actual - expected) < 0.000001)
end
local function colors(bg, bar)
    for i = 1, 3 do
        close(frame.bg.color[i], bg[i])
        close(overlay.outline.color[i], bg[i])
        close(frame.bar.color[i], bar[i])
        close(overlay.nameText.color[i], bar[i])
    end
end
colors({1, 0.87, 0}, {235/255, 222/255, 129/255})
reaction = 2
event("UNIT_HEALTH", "targettarget")
colors({200/255, 50/255, 8/255}, {1, 0.8, 0.8})
reaction = 5
event("UNIT_MAXHEALTH", "targettarget")
colors({113/255, 214/255, 64/255}, {228/255, 1, 204/255})
player = true
event("UNIT_TARGET", "target")
colors({0.6, 0.8, 1}, {0.6, 0.8, 1})
fighting = true
event("UNIT_HEALTH", "target")
colors({200/255, 50/255, 8/255}, {1, 0.8, 0.8})
dead = true
event("UNIT_HEALTH", "targettarget")
colors({0.35, 0.35, 0.35}, {0.4, 0.4, 0.4})
frame.bar.value = -1
event("UNIT_HEALTH", "unrelated")
assert(frame.bar.value == -1, "Unrelated health events must be ignored")
units.targettarget = nil
event("UNIT_TARGET", "target")
assert(frame.alpha == 0)
units.targettarget, units.target = {}, nil
event("PLAYER_TARGET_CHANGED")
assert(frame.alpha == 0)
print("PASS: target-of-target health, name, reaction colors, event filtering, and visibility")

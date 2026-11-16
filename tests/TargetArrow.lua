local addonName, ns = ...

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end
local xml = readFile("FFXIV_UI\\TargetFrames\\TargetArrow.xml")
local function contains(text)
    assert(xml:find(text, 1, true), "XML missing: " .. text)
end
contains('<Frame name="FFTargetArrow" parent="UIParent" hidden="true">')
contains('<Size x="90" y="90"/>')
contains('<Layer level="OVERLAY" textureSubLevel="1">')
contains('<Layer level="OVERLAY" textureSubLevel="2">')
contains('<Texture parentKey="baseTexture" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetArrow.tga" setAllPoints="true"/>')
contains('<Texture parentKey="overlayTexture" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetArrow2.tga" setAllPoints="true">')
contains('<Color r="1" g="1" b="1"/>')
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do
        index = index + 1
        lines[line] = index
    end
    assert(assert(lines["TargetFrames/TargetArrow.xml"]) < assert(lines["TargetFrames/TargetArrow.lua"]))
end
print("PASS: target arrow XML artwork, size, layers, hidden state, and TOC ordering")

local methods = {}
local function object()
    return setmetatable({scripts = {}, events = {}, animations = {}}, {__index = methods})
end
function methods:SetPoint(...)
    self.point = {...}
    self.points = self.points or {}
    self.points[self.point[1]] = self.point
end
function methods:ClearAllPoints() self.point = nil; self.points = {} end
function methods:SetParent(parent) self.parent = parent end
function methods:GetParent() return self.parent end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:SetVertexColor(...) self.color = {...} end
function methods:CreateAnimationGroup() self.group = object(); return self.group end
function methods:CreateAnimation(kind)
    local animation = object()
    animation.kind = kind
    self.animations[#self.animations + 1] = animation
    return animation
end
function methods:SetDuration(duration) self.duration = duration end
function methods:SetSmoothing(smoothing) self.smoothing = smoothing end
function methods:SetFromAlpha(alpha) self.fromAlpha = alpha end
function methods:SetToAlpha(alpha) self.toAlpha = alpha end
function methods:SetToFinalAlpha(value) self.finalAlpha = value end
function methods:SetOffset(...) self.offset = {...} end
function methods:Stop() self.playing = false end
function methods:Play() self.playing = true end
function methods:SetScript(script, callback) self.scripts[script] = callback end
function methods:RegisterEvent(event) self.events[event] = true end

UIParent = object()
FFTargetArrow = object()
local arrow = FFTargetArrow
arrow.parent, arrow.shown = UIParent, false
arrow.baseTexture, arrow.overlayTexture = object(), object()
arrow.overlayTexture:SetVertexColor(1, 1, 1)
arrow:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
arrow:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT")
local watcher, creates = nil, 0
CreateFrame = function(kind, name, parent)
    creates = creates + 1
    assert(kind == "Frame" and name == nil and parent == nil, "Only the event watcher should be Lua-created")
    watcher = object()
    return watcher
end
local exists, plate, reaction = false, nil, 4
local player, dead, fighting, selfUnit, party, raid = false, false, false, false, false, false
UnitExists = function(unit) assert(unit == "target"); return exists end
UnitIsUnit = function() return selfUnit end
UnitInParty = function() return party end
UnitInRaid = function() return raid end
UnitAffectingCombat = function() return fighting end
UnitCanAttack = function() return true end
UnitIsDeadOrGhost = function() return dead end
UnitIsPlayer = function() return player end
UnitReaction = function() return reaction end
C_NamePlate = {GetNamePlateForUnit = function(unit) assert(unit == "target"); return plate end}
assert(loadstring(readFile("FFXIV_UI\\TargetFrames\\TargetArrow.lua")))("FFXIV_UI", {})
assert(creates == 1 and not arrow.shown and next(arrow.points) == nil)
local group = arrow.group
local slide, fade = unpack(group.animations)
assert(#group.animations == 2 and group.finalAlpha)
assert(slide.kind == "Translation" and slide.duration == 0.30 and slide.smoothing == "OUT")
assert(fade.kind == "Alpha" and fade.duration == 0.30 and fade.smoothing == "OUT")
assert(fade.fromAlpha == 0 and fade.toAlpha == 1)
local function event(name, unit)
    assert(watcher.events[name])
    watcher.scripts.OnEvent(watcher, name, unit)
end
local function color(expected)
    for i = 1, 3 do
        assert(math.abs(arrow.baseTexture.color[i] - expected[i]) < 0.000001)
        assert(arrow.overlayTexture.color[i] == 1, "Overlay must remain white")
    end
end
event("PLAYER_TARGET_CHANGED")
assert(not arrow.shown)
exists = true
event("PLAYER_TARGET_CHANGED")
assert(not arrow.shown, "Target without a nameplate must not show the arrow")
plate = object()
event("PLAYER_TARGET_CHANGED")
assert(arrow.shown and arrow.parent == plate and arrow.alpha == 0 and group.playing)
assert(arrow.point[1] == "BOTTOM" and arrow.point[2] == plate and arrow.point[3] == "TOP")
assert(arrow.point[4] == 0 and arrow.point[5] == 45)
assert(slide.offset[1] == 0 and slide.offset[2] == -25)
group.scripts.OnFinished()
assert(arrow.point[2] == plate and arrow.point[5] == 20)
color({235/255, 222/255, 129/255})
reaction = 2
event("UNIT_FACTION", "target")
color({1, 0.2, 0.2})
reaction = 5
event("UNIT_FACTION", "target")
color({113/255, 214/255, 64/255})
player = true
event("UNIT_FLAGS", "target")
color({0.3, 0.6, 1})
fighting = true
event("PLAYER_REGEN_DISABLED")
color({1, 0.2, 0.2})
dead = true
event("UNIT_FLAGS", "target")
color({0.4, 0.4, 0.4})
for _, membership in ipairs({"self", "party", "raid"}) do
    selfUnit, party, raid = membership == "self", membership == "party", membership == "raid"
    event("UNIT_FLAGS", "target")
    color({0.3, 0.6, 1})
end
selfUnit, party, raid, player, dead, fighting, reaction = false, false, false, false, false, false, nil
event("PLAYER_REGEN_ENABLED")
color({235/255, 222/255, 129/255})
plate = object()
event("PLAYER_TARGET_CHANGED")
assert(arrow.parent == plate and group.playing and arrow.point[5] == 45)
exists = false
event("PLAYER_TARGET_CHANGED")
assert(not arrow.shown)
print("PASS: target arrow binding, nameplate parenting, animation, colors, and visibility")

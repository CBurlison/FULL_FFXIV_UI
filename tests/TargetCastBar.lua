local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return (content:gsub("\r\n", "\n"))
end

local function assertContains(content, text, label)
    assert(content:find(text, 1, true), label .. " missing: " .. text)
end

local xml = readFile("FFXIV_UI\\TargetFrames\\TargetFrame_CastBar.xml")
assertContains(xml, '<StatusBar name="FFTargetCastBar" parent="UIParent" hidden="true">', "cast bar root")
assertContains(xml, '<Size x="293.55" y="648.9"/>', "cast bar size")
assertContains(xml, '<BarTexture file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Health"/>', "bar texture")
assertContains(xml, '<Texture parentKey="bg" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Health" setAllPoints="true">', "background")
assertContains(xml, '<Color r="0.259" g="0.188" b="0.024" a="1"/>', "background color")
assertContains(xml, '<Frame parentKey="outlineFrame" setAllPoints="true">', "outline frame")
assertContains(xml, '<Texture parentKey="staticOutline" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\TargetTarget" hidden="true">', "static outline")
assertContains(xml, '<Size x="880.65" y="648.9"/>', "static outline size")
assertContains(xml, '<Frame parentKey="textFrame" frameStrata="HIGH" setAllPoints="true">', "text frame")
assertContains(xml, '<FontString parentKey="text" font="Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisMedium.ttf">', "cast text")
assertContains(xml, '<FontHeight val="20.6"/>', "cast text height")
assertContains(xml, '<Anchor point="RIGHT" x="0" y="-4.12"/>', "cast text anchor")
assertContains(xml, '<Frame parentKey="gifFrame" frameStrata="HIGH">', "gif frame")
assertContains(xml, '<Size x="381.615" y="324.45"/>', "gif frame size")
assertContains(xml, '<Anchor point="CENTER"/>', "gif frame anchor")
assertContains(xml, '<Texture parentKey="gifTexture" setAllPoints="true" hidden="true">', "gif texture")
print("PASS: XML cast bar tree, sizes, artwork, and colors match the old Lua")

local function readLines(path)
    local lines = {}
    local index = 0
    for line in readFile(path):gmatch("[^\n]+") do
        index = index + 1
        lines[line] = index
    end
    return lines
end

for _, tocPath in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines = readLines(tocPath)
    assert(lines["TargetFrames/TargetFrame_CastBar.xml"], tocPath .. " should list the XML")
    assert(lines["TargetFrames/TargetFrame_CastBar.xml"] < lines["TargetFrames/TargetFrame_CastBar.lua"],
        tocPath .. " should load the XML before the Lua")
end
print("PASS: both TOCs load the XML before the Lua")

local frames, units = {}, {}
local methods = {}
local function object()
    return setmetatable({events = {}, children = {}}, {__index = methods})
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...)
    self.point = {...}
    self.points = self.points or {}
    self.points[self.point[1]] = self.point
end
function methods:ClearAllPoints() self.point = nil; self.points = {} end
function methods:SetAllPoints() end
function methods:SetFrameStrata(strata) self.strata = strata end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameLevel() return self.level or 1 end
function methods:EnableMouse() end
function methods:SetParent(parent) self.parent = parent end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:IsShown() return self.shown == true end
function methods:CreateTexture() return object() end
function methods:CreateFontString() return object() end
function methods:SetTexture(file) self.file = file end
function methods:SetTexCoord() end
function methods:SetDrawLayer() end
function methods:SetBlendMode() end
function methods:SetFont() end
function methods:SetTextColor() end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetText(value) self.text = value end
function methods:SetStatusBarTexture() end
function methods:GetStatusBarTexture() return self.texture end
function methods:SetStatusBarColor(...) self.color = {...} end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetVertexColorFromBoolean() end
function methods:SetMinMaxValues(low, high) self.minimum, self.maximum = low, high end
function methods:SetTimerDuration() end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetScript(script, callback) self.scripts = self.scripts or {}; self.scripts[script] = callback end

local function xmlCastBar()
    local castBar = object()
    local width, height = xml:match('<StatusBar.-<Size x="([%d.]+)" y="([%d.]+)"/>')
    castBar:SetSize(tonumber(width), tonumber(height))
    castBar.texture = object()
    castBar.bg = object()
    castBar.outlineFrame = object()
    castBar.outlineFrame.staticOutline = object()
    -- Simulate implicit XML anchors to ensure Lua restores a single center anchor.
    castBar.outlineFrame.staticOutline:SetPoint("TOPLEFT", castBar.outlineFrame, "TOPLEFT")
    castBar.outlineFrame.staticOutline:SetPoint("BOTTOMRIGHT", castBar.outlineFrame, "BOTTOMRIGHT")
    castBar.textFrame = object()
    castBar.textFrame.text = object()
    castBar.gifFrame = object()
    castBar.gifFrame.gifTexture = object()
    castBar.gifFrame.gifTexture.Hide = function(self) self.shown = false end
    return castBar
end

local xmlBar = xmlCastBar()
_G.FFTargetCastBar = xmlBar
FFXIV_UI_Anchors = {TargetCast = object()}
CreateFrame = function() return object() end
CreateColor = function(...) return {...} end
C_Timer = {
    After = function(_, callback) callback() end,
    NewTicker = function(_, callback)
        return {Cancel = function() end, tick = callback}
    end,
}
UnitCanAttack = function() return true end
UnitCastingInfo = function(unit)
    local info = units[unit] and units[unit].casting
    if info then return info.name, nil, nil, 0, 1, false, 1, info.notInterruptible, 1 end
end
UnitChannelInfo = function(unit)
    local info = units[unit] and units[unit].channeling
    if info then return info.name, nil, nil, 0, 1, false, info.notInterruptible, 1 end
end
UnitCastingDuration = function() return nil end
UnitChannelDuration = function() return nil end

local eventFrame
CreateFrame = function(...)
    eventFrame = object()
    return eventFrame
end

local source = readFile("FFXIV_UI\\TargetFrames\\TargetFrame_CastBar.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "TargetFrame_CastBar.lua"))("FFXIV_UI", {})

assert(xmlBar.outlineFrame.staticOutline.point, "static outline should be anchored in Lua")
assert(xmlBar.outlineFrame.staticOutline.point[1] == "CENTER", "static outline should anchor to the cast bar center")
local outline = xmlBar.outlineFrame.staticOutline
assert(outline.point[2] == xmlBar and outline.point[3] == "CENTER"
    and outline.point[4] == 0 and outline.point[5] == 2, "outline center must match the original offset")
assert(outline.points.TOPLEFT == nil and outline.points.BOTTOMRIGHT == nil,
    "implicit XML anchors must not constrain the outline width")
assert(outline.width == xmlBar.width * 3 and outline.height == xmlBar.height,
    "padded outline artwork must span three times the full cast bar width")
assert(xmlBar.parent == FFXIV_UI_Anchors.TargetCast, "cast bar should be parented to the TargetCast anchor")
assert(xmlBar.gifFrame.level == 21, "gif frame level should be cast bar level + 20")
assert(xmlBar.textFrame.level == xmlBar.gifFrame.level + 5, "text frame should sit above the gif frame")
print("PASS: Lua binds to the XML cast bar and sets layering")

local function event(name, unit)
    eventFrame.scripts.OnEvent(eventFrame, name, unit)
end

units.target = {casting = {name = "Fireball", notInterruptible = false}}
event("UNIT_SPELLCAST_START", "target")
assert(xmlBar.shown == true, "a cast should show the cast bar")
assert(xmlBar.textFrame.text.text == "Fireball", "the cast name should be displayed")

units.target = nil
event("UNIT_SPELLCAST_STOP", "target")
assert(xmlBar.shown == false, "stopping a cast should hide the cast bar")

units.target = {channeling = {name = "Mind Flay", notInterruptible = true}}
event("UNIT_SPELLCAST_CHANNEL_START", "target")
assert(xmlBar.shown == true, "a channel should show the cast bar")
assert(xmlBar.textFrame.text.text == "Mind Flay", "the channel name should be displayed")

units.target = nil
event("UNIT_SPELLCAST_CHANNEL_STOP", "target")
assert(xmlBar.shown == false, "stopping a channel should hide the cast bar")
print("PASS: casts and channels show and hide the cast bar")

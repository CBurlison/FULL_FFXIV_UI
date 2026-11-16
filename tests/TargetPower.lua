local frames, units = {}, {}
local methods = {}
local function object()
    return setmetatable({events = {}, children = {}}, {__index = methods})
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetPoint(...) self.point = {...} end
function methods:SetAllPoints() end
function methods:SetFrameStrata() end
function methods:EnableMouse() end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:CreateTexture() return object() end
function methods:CreateFontString() return object() end
function methods:SetTexture() end
function methods:SetTexCoord() end
function methods:SetDrawLayer() end
function methods:SetFont() end
function methods:SetTextColor() end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetText(value) self.text = value end
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
function methods:SetParent() end
function methods:ClearAllPoints() end
local function xmlResourceBar(name, width)
    local frame = object()
    frame.width, frame.height = width, 16
    frame.background = object()
    frame.bar = object()
    frame.textFrame = object()
    frame.textFrame.outline = object()
    frame.textFrame.label = object()
    frame.textFrame.valueText = object()
    frames[name] = frame
    _G[name] = frame
    return frame
end
xmlResourceBar("FFTargetPowerFrame", 300)
xmlResourceBar("FFFocusPowerFrame", 220)
xmlResourceBar("FFTargetOfTargetPowerFrame", 220)
FFXIV_UI_Anchors = {TargetPower = object(), FocusTarget = object(), TargetOfTarget = object()}
PowerBarColor = {MANA = {r = 0, g = 0, b = 1}, RAGE = {r = 1, g = 0, b = 0}}
function issecretvalue(value) return type(value) == "table" and value.secret end
function UnitExists(unit) return units[unit] ~= nil end
function UnitPowerType(unit) return 0, units[unit].token end
function UnitPowerMax(unit) return units[unit].maximum end
function UnitPower(unit) return units[unit].power end
assert(loadfile("FFXIV_UI\\TargetFrames\\TargetFrame_Power.lua"))("FFXIV_UI", {})
local function event(name, unit)
    for _, frame in pairs(frames) do
        if frame.events[name] then frame.callback(frame, name, unit) end
    end
end
local target, focus, tot = frames.FFTargetPowerFrame, frames.FFFocusPowerFrame, frames.FFTargetOfTargetPowerFrame

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return (content:gsub("\r\n", "\n"))
end

local function assertContains(content, text, label)
    assert(content:find(text, 1, true), label .. " missing: " .. text)
end

local xml = readFile("FFXIV_UI\\TargetFrames\\TargetFrame_Power.xml")
assertContains(xml, '<Frame name="FFResourceBarTemplate" virtual="true" frameStrata="MEDIUM" enableMouse="false">', "template")
assertContains(xml, 'parentKey="background" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Background"', "background artwork")
assertContains(xml, '<TexCoords left="0.005859375" right="0.99609375" top="0.490234375" bottom="0.505859375"/>', "background tex coords")
assertContains(xml, '<StatusBar parentKey="bar" enableMouse="false">', "power bar")
assertContains(xml, '<BarTexture file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\PowerFill"/>', "power bar texture")
assertContains(xml, 'parentKey="textFrame"', "text frame")
assertContains(xml, 'parentKey="outline" file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\TargetFrame\\Frame6"', "outline artwork")
assertContains(xml, '<FontString parentKey="label"', "label")
assertContains(xml, '<FontString parentKey="valueText"', "value text")
assertContains(xml, '<Frame name="FFTargetPowerFrame" parent="UIParent" inherits="FFResourceBarTemplate" hidden="true">\n        <Size x="300" y="16"/>', "target size")
assertContains(xml, '<Frame name="FFFocusPowerFrame" parent="UIParent" inherits="FFResourceBarTemplate" hidden="true">\n        <Size x="220" y="16"/>', "focus size")
assertContains(xml, '<Frame name="FFTargetOfTargetPowerFrame" parent="UIParent" inherits="FFResourceBarTemplate" hidden="true">\n        <Size x="220" y="16"/>', "target of target size")
print("PASS: XML template, instances, sizes, and artwork match the old Lua")

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
    assert(lines["TargetFrames/TargetFrame_Power.xml"], tocPath .. " should list the XML")
    assert(lines["TargetFrames/TargetFrame_Power.xml"] < lines["TargetFrames/TargetFrame_Power.lua"],
        tocPath .. " should load the XML before the Lua")
end
print("PASS: both TOCs load the XML before the Lua")

event("PLAYER_ENTERING_WORLD")
assert(not target.shown and not focus.shown and not tot.shown)
print("PASS: absent units hide all resource bars")
units.target = {token = "MANA", power = 100, maximum = 200}
units.focus = {token = "RAGE", power = 0, maximum = 100}
units.targettarget = {token = "MANA", power = 40, maximum = 80}
event("PLAYER_ENTERING_WORLD")
assert(target.shown and focus.shown and tot.shown)
assert(target.width == 300 and focus.width == 220 and tot.width == 220)
assert(focus.point[2] == FFXIV_UI_Anchors.FocusTarget)
assert(tot.point[2] == FFXIV_UI_Anchors.TargetOfTarget)
assert(focus.bar.color[1] == 1 and focus.bar.value == 0)
print("PASS: layout follows each anchor and zero rage stays visible")
units.focus.power = 30
event("UNIT_POWER_UPDATE", "focus")
assert(focus.bar.value == 30)
units.targettarget = {token = "RAGE", power = 70, maximum = 100}
event("UNIT_TARGET", "target")
assert(tot.bar.value == 70 and tot.bar.color[1] == 1)
units.focus = nil
event("PLAYER_FOCUS_CHANGED")
assert(not focus.shown)
units.targettarget.maximum = 0
event("UNIT_MAXPOWER", "targettarget")
assert(not tot.shown)
print("PASS: focus changes, target-of-target switches, and resource events refresh bars")
local secret = setmetatable({secret = true}, {
    __le = function() error("Compared secret power") end,
})
units.targettarget.maximum, units.targettarget.power = secret, secret
event("UNIT_POWER_UPDATE", "targettarget")
assert(tot.shown and tot.bar.value == secret and tot.bar.maximum == secret)
print("PASS: secret resource values pass directly to rendering APIs")

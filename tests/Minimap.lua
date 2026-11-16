local addonName, ns = ...
local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end
local xml = readFile("FFXIV_UI\\General\\Minimap.xml")
for _, text in ipairs({
    'name="FFXIV_MinimapTemplate" virtual="true" frameStrata="MEDIUM"',
    '<Size x="245" y="245"/>', '<Anchor point="CENTER" x="-5" y="0"/>',
    'parentKey="texture"', 'parentKey="texture2"', 'parentKey="coordsText"',
    'parentKey="coordsFrame"', 'parentKey="xInt"', 'parentKey="xDec"',
    'parentKey="yInt"', 'parentKey="yDec"',
    'file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Minimap\\FFMap.tga"',
    'file="Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Minimap\\FFCoordsBG.tga"',
    '<TexCoords left="0.08" right="0.92" top="0.08" bottom="0.92"/>',
    '<Anchor point="BOTTOM" x="0" y="-20"/>',
    '<Size x="120" y="20"/>', '<Anchor point="BOTTOM" x="0" y="-8"/>',
    '<Anchor point="LEFT" x="15" y="0"/>',
    '<FontHeight val="14"/>', '<FontHeight val="12"/>', '<FontHeight val="10"/>',
    '<Color r="0.866666667" g="0.847058824" b="0.792156863"/>',
}) do assert(xml:find(text, 1, true), "XML missing: " .. text) end
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do index = index + 1; lines[line] = index end
    assert(assert(lines["General/Minimap.xml"]) < assert(lines["General/Minimap.lua"]))
end
local methods = {}
local function object() return setmetatable({events = {}}, {__index = methods}) end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetScript(_, callback) self.callback = callback end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:SetParent(parent) self.parent = parent end
function methods:ClearAllPoints() self.point = nil; self.cleared = true end
function methods:SetPoint(...) self.point = {...} end
function methods:SetScale(scale) self.scale = scale end
function methods:GetFrameLevel() return 5 end
function methods:SetFrameLevel(level) self.level = level end
function methods:SetText(text) self.text = text end
Minimap = object()
Minimap.ZoomIn, Minimap.ZoomOut = object(), object()
for _, key in ipairs({"MinimapBorder", "MinimapBorderTop", "MiniMapTracking",
    "MiniMapMailFrame", "MinimapZoneTextButton", "TimeManagerClockButton"}) do
    _G[key] = object()
end
local watcher, creates, ticker, tickers = nil, 0, nil, 0
CreateFrame = function(kind, name, parent, template)
    creates = creates + 1
    if not name then assert(not template); watcher = object(); return watcher end
    assert(kind == "Frame" and name == "FFXIV_MinimapFrame" and parent == Minimap)
    assert(template == "FFXIV_MinimapTemplate")
    local frame = object()
    frame.texture2, frame.coordsFrame = object(), object()
    for _, key in ipairs({"xInt", "xDec", "yInt", "yDec"}) do frame.coordsFrame[key] = object() end
    _G[name] = frame
    return frame
end
C_Timer = {NewTicker = function(interval, callback)
    assert(interval == 0.2); ticker = callback; tickers = tickers + 1
end}
local dead, map, position = false, 1, true
UnitIsDeadOrGhost = function() return dead end
C_Map = {
    GetBestMapForUnit = function() return map end,
    GetPlayerMapPosition = function()
        if position then return {GetXY = function() return 0.125, 0.375 end} end
    end,
}
assert(loadstring(readFile("FFXIV_UI\\General\\Minimap.lua")))("FFXIV_UI", {})
assert(creates == 1 and watcher.events.PLAYER_LOGIN and not FFXIV_MinimapFrame)
watcher.callback(watcher, "PLAYER_LOGIN")
local frame = FFXIV_MinimapFrame
assert(creates == 2 and frame.shown and tickers == 1)
assert(not MinimapBorder.shown and not TimeManagerClockButton.shown)
for _, button in ipairs({Minimap.ZoomIn, Minimap.ZoomOut}) do
    assert(button.parent == frame and button.scale == 1.2 and button.level == 7)
    assert(button.point[1] == "RIGHT" and button.point[2] == Minimap and button.point[4] == 9)
end
assert(Minimap.ZoomIn.point[5] == 20 and Minimap.ZoomOut.point[5] == -18)
local coords = frame.coordsFrame
for _, key in ipairs({"xDec", "yInt", "yDec"}) do assert(coords[key].cleared) end
assert(coords.xDec.point[2] == coords.xInt and coords.yInt.point[2] == coords.xDec)
assert(coords.yInt.point[4] == 8 and coords.yDec.point[2] == coords.yInt)
ticker()
assert(frame.texture2.shown)
assert(coords.xInt.text == "X: 12" and coords.xDec.text == ".5")
assert(coords.yInt.text == "Y: 37" and coords.yDec.text == ".5")
local function hidden()
    ticker()
    assert(not frame.texture2.shown)
    for _, key in ipairs({"xInt", "xDec", "yInt", "yDec"}) do assert(coords[key].text == "") end
end
dead = true; hidden()
dead, map = false, nil; hidden()
map, position = 1, false; hidden()
position = true; ticker(); assert(frame.texture2.shown)
watcher.callback(watcher, "PLAYER_LOGIN")
assert(creates == 2 and tickers == 1, "Repeated initialization must not create frames or tickers")
print("PASS: minimap XML, TOC ordering, login initialization, zoom controls, and coordinate updates")

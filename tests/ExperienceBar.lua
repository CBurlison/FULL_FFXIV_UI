local methods = {}
local function widget()
    return setmetatable({scripts = {}, events = {}, shown = true, level = 10}, {__index = methods})
end
for _, name in ipairs({
    "SetAllPoints", "SetTexture", "EnableMouse", "SetSize", "SetFont",
    "SetShadowOffset", "SetShadowColor", "ClearAllPoints", "SetAlpha",
}) do methods[name] = function() end end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(level) self.level = level end
function methods:SetParent(parent) self.parent = parent end
function methods:SetPoint(...) self.point = {...} end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetShown(shown) self.shown = shown and true or false end
function methods:IsShown() return self.shown end
function methods:SetMinMaxValues(low, high) self.min, self.max = low, high end
function methods:SetValue(value) self.value = value end
function methods:SetText(value) self.text = tostring(value) end
function methods:SetDrawLayer(layer, sub) self.drawLayer = {layer, sub} end
function methods:GetStatusBarTexture()
    self.texture = self.texture or widget()
    return self.texture
end
function methods:RegisterEvent(event) self.events[#self.events + 1] = event end
function methods:UnregisterAllEvents() self.unregistered = true end
function methods:SetScript(name, callback) self.scripts[name] = callback end

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function assertContains(content, text, label)
    assert(content:find(text, 1, true), label .. " missing: " .. text)
end

local xml = readFile("FFXIV_UI\\General\\ExperienceBar.xml")
assertContains(xml, 'name="FFPlayerXPFrame"', "frame global")
for _, key in ipairs({
    "restedIndicator", "restedBar", "xpBar", "outlineFrame", "classLabel",
    "LLabel", "vLabel", "levelText", "xpNumbers", "xpPercent",
}) do
    assertContains(xml, 'parentKey="' .. key .. '"', "parentKey")
end
for _, texture in ipairs({"XPBG", "FFRested", "XPRested", "XPBar"}) do
    assertContains(xml, "ExperienceBar\\" .. texture, "texture")
end
for _, font in ipairs({"MavenPro-Bold.ttf", "EurostileExtendedBlack.ttf", "AxisMedium.ttf"}) do
    assertContains(xml, font, "font")
end
assertContains(xml, 'text="L"', "L label")
assertContains(xml, 'text="v"', "v label")

local function assertLoadOrder(tocPath)
    local index = {}
    local position = 0
    for line in readFile(tocPath):gmatch("[^\r\n]+") do
        position = position + 1
        if line:find("ExperienceBar%.") then index[#index + 1] = line:gsub("%s+$", "") end
    end
    assert(#index == 2, tocPath .. " must list ExperienceBar.xml and .lua once each")
    assert(index[1] == "General/ExperienceBar.xml", tocPath .. " must load the XML first")
    assert(index[2] == "General/ExperienceBar.lua", tocPath .. " must load the Lua second")
end
assertLoadOrder("FFXIV_UI\\FFXIV_UI.toc")
assertLoadOrder("FFXIV_UI\\FFXIV_UI_Camelot.toc")

local state
UnitXP = function() return state.xp end
UnitXPMax = function() return state.max end
GetXPExhaustion = function() return state.rested end
UnitLevel = function() return state.level end
UnitClass = function() return "Mage", "MAGE" end
IsResting = function() return state.resting end
UIParent = widget()

FFXIV_UI_Anchors = {ExpBar = widget()}
FFPlayerXPFrame = widget()
local f = FFPlayerXPFrame
f.restedBar = widget()
f.restedBar.shown = false
f.xpBar = widget()
f.restedIndicator = widget()
f.restedIndicator.shown = false
f.outlineFrame = widget()
for _, key in ipairs({"classLabel", "LLabel", "vLabel", "levelText", "xpNumbers", "xpPercent"}) do
    f.outlineFrame[key] = widget()
end
f.level = 10

MainMenuExpBar = widget()
StatusTrackingBarManager = widget()

state = {xp = 500, max = 1000, rested = 200, resting = true, level = 20}
local source = readFile("FFXIV_UI\\General\\ExperienceBar.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "ExperienceBar.lua"))("FFXIV_UI", {})

assert(f.parent == FFXIV_UI_Anchors.ExpBar, "bar must be parented to the ExpBar anchor")
assert(f.point[1] == "CENTER" and f.point[2] == FFXIV_UI_Anchors.ExpBar, "bar must be centered on the anchor")
assert(f.outlineFrame.level == 15, "outline frame must sit 5 levels above the bar")
assert(f.xpBar.texture.drawLayer[1] == "ARTWORK" and f.xpBar.texture.drawLayer[2] == 0, "XP fill draw layer")
assert(f.restedBar.texture.drawLayer[2] == -1, "rested fill draw layer")
assert(MainMenuExpBar.unregistered and not MainMenuExpBar.shown, "Blizzard XP bar must be disabled")
assert(StatusTrackingBarManager.unregistered and not StatusTrackingBarManager.shown, "Blizzard tracking bars must be disabled")

local events = table.concat(f.events, ",")
assert(events == "PLAYER_ENTERING_WORLD,PLAYER_XP_UPDATE,PLAYER_LEVEL_UP,PLAYER_UPDATE_RESTING,ZONE_CHANGED,ZONE_CHANGED_NEW_AREA", "events: " .. events)
assert(f.scripts.OnEvent ~= nil, "OnEvent handler missing")

local outline = f.outlineFrame
assert(outline.levelText.text == "20", "level text")
assert(outline.classLabel.text == "MAG", "class label")
assert(outline.xpNumbers.text == "EXP 500/1000", "XP numbers: " .. tostring(outline.xpNumbers.text))
assert(outline.xpPercent.text == "(50%)", "XP percent: " .. tostring(outline.xpPercent.text))

assert(f.xpBar.min == 0 and f.xpBar.max == 1000 and f.xpBar.value == 500, "XP bar values")
assert(f.restedBar.shown and f.restedBar.value == 700, "rested bar must show current plus rested XP")
assert(f.restedIndicator.shown, "rested indicator must show while resting")

state = {xp = 100, max = 1000, rested = 0, resting = false, level = 5}
f.scripts.OnEvent(f, "PLAYER_XP_UPDATE")
assert(not f.restedBar.shown, "rested bar must hide without rested XP")
assert(not f.restedIndicator.shown, "rested indicator must hide when not resting")
assert(outline.xpPercent.text == "(10%)", "percent updates on event")
assert(outline.levelText.text == "5", "level updates on event")

print("ExperienceBar tests passed")

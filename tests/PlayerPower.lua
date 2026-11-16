local methods = {}
local frames, fonts = {}, {}
local function object()
    return setmetatable({events = {}, scripts = {}, shown = true}, {__index = methods})
end
for _, name in ipairs({"SetSize", "SetPoint", "SetFrameStrata", "SetAllPoints", "SetDrawLayer",
    "SetTexCoord", "SetFrameLevel", "EnableMouse", "SetFont", "SetJustifyH", "SetTextColor",
    "SetShadowColor", "SetShadowOffset", "SetParent", "ClearAllPoints"}) do
    methods[name] = function() end
end
function methods:GetFrameLevel() return 1 end
function methods:GetWidth() return 232 end
function methods:GetHeight() return 230 end
function methods:CreateTexture() return object() end
function methods:SetTexture(value) self.texture = value end
function methods:SetStatusBarTexture(value) self.texture = value end
function methods:GetStatusBarTexture() return self end
function methods:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
function methods:SetValue(value) self.value = value end
function methods:SetText(value) self.text = value end
function methods:CreateFontString()
    local font = object()
    fonts[#fonts + 1] = font
    return font
end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function CreateFrame(kind)
    local frame = object()
    frame.kind = kind
    frames[#frames + 1] = frame
    return frame
end
UIParent = object()
FFXIV_UI_Anchors = {PlayerPower = object(), PlayerPowerSec = object()}
Enum = {PowerType = {Mana = 0}}
local token, powerType, power, maximum = "MANA", 0, 250, 400
local class, form = "MAGE", nil
local spec, staggerAmount, maxHealthAmount = 1, 0, 1000
local buildNumber = 120000
function GetBuildInfo() return "", "", "", buildNumber end
function UnitStagger() return staggerAmount end
function UnitHealthMax() return maxHealthAmount end
function UnitPowerType() return powerType, token end
function UnitPower() return power end
function UnitPowerMax() return maximum end
function UnitClass() return class, class end
function GetSpecialization() return spec end
function GetShapeshiftFormID() return form end
local function statusBar()
    local bar = object()
    bar.kind = "StatusBar"
    return bar
end
PlayerFrame_Power = object()
PlayerFrame_Power.bg = object()
PlayerFrame_Power.bar = statusBar()
PlayerFrame_Power.outlineFrame = object()
PlayerFrame_Power.outlineFrame.outline = object()
PlayerFrame_Power.outlineFrame.text = object()
PlayerFrame_Power.outlineFrame.powerLabel = object()
local mainBar = PlayerFrame_Power.bar
local mainText, mainLabel = PlayerFrame_Power.outlineFrame.text, PlayerFrame_Power.outlineFrame.powerLabel
assert(loadfile("FFXIV_UI\\PlayerFrames\\PlayerFrame_Power.lua"))()
local secondaryMain = object()
secondaryMain.bg = object()
secondaryMain.bar = statusBar()
secondaryMain.outlineFrame = object()
secondaryMain.outlineFrame.outline = object()
secondaryMain.outlineFrame.text = object()
secondaryMain.outlineFrame.powerLabel = object()
PlayerFrame_Power_Secondary = secondaryMain
assert(loadfile("FFXIV_UI\\PlayerFrames\\PlayerFrame_Power_Secondary.lua"))()
local function readFile(path)
    local handle = assert(io.open(path, "rb"))
    local body = handle:read("*a")
    handle:close()
    return body
end
local secondaryXml = readFile("FFXIV_UI\\PlayerFrames\\PlayerFrame_Power_Secondary.xml")
for _, needle in ipairs({'name="PlayerFrame_Power_Secondary"', 'parentKey="bar"', 'parentKey="outlineFrame"',
    'parentKey="text"', 'parentKey="powerLabel"', 'textureSubLevel="7"'}) do
    assert(secondaryXml:find(needle, 1, true), "missing XML: " .. needle)
end
for _, toc in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local body = readFile(toc)
    local xmlAt = body:find("PlayerFrames/PlayerFrame_Power_Secondary.xml", 1, true)
    local luaAt = body:find("PlayerFrames/PlayerFrame_Power_Secondary.lua", 1, true)
    assert(xmlAt and luaAt and xmlAt < luaAt, "XML must load before Lua in " .. toc)
end
print("PASS secondary XML names and TOC order")
local main, secondary = PlayerFrame_Power, PlayerFrame_Power_Secondary
local secondaryBar = secondary.bar
local secondaryLabel = secondary.outlineFrame.powerLabel
local secondaryText = secondary.outlineFrame.text
local function event(frame, name, ...)
    assert(frame.events[name], "unregistered event: " .. name)
    frame.scripts.OnEvent(frame, name, ...)
end
event(main, "PLAYER_ENTERING_WORLD", true, false)
assert(mainBar.texture:match("Primary\\Mana$") and mainBar.value == 250 and mainBar.maximum == 400)
assert(mainText.text == 250 and mainLabel.text == "MP")
event(secondary, "PLAYER_ENTERING_WORLD", true, false)
assert(not secondary.shown, "secondary bar must hide on initial login for a mage")
print("PASS fresh-login boolean payload initializes primary mana and hides unused secondary bar")

power = 180
event(main, "PLAYER_ENTERING_WORLD", false, true)
assert(mainBar.value == 180)
power = 160
event(main, "PLAYER_ENTERING_WORLD", false, false)
assert(mainBar.value == 160)
power = 150
event(main, "PLAYER_LOGIN")
assert(mainBar.value == 150)
assert(secondary.events.PLAYER_LOGIN)
print("PASS reload, zone transition and login refreshes")

token, powerType, power, maximum = "ENERGY", 3, 70, 100
event(main, "UNIT_DISPLAYPOWER", "player")
assert(mainBar.texture:match("Primary\\Energy$") and mainBar.value == 70 and mainLabel.text == "EP")
power = 60
event(main, "UNIT_POWER_UPDATE", "target")
assert(mainBar.value == 70, "other unit updated player power")
event(main, "UNIT_POWER_UPDATE", "player")
assert(mainBar.value == 60)
maximum = 120
event(main, "UNIT_MAXPOWER", "player")
assert(mainBar.maximum == 120)
print("PASS resource type/value/max updates and non-player event filtering")

class, form, power, maximum = "DRUID", 1, 300, 500
event(secondary, "PLAYER_ENTERING_WORLD", true, false)
assert(secondary.shown and secondaryBar.texture:match("Primary\\Mana$"))
assert(secondaryBar.value == 300 and secondaryBar.maximum == 500 and secondaryLabel.text == "MP")
form = nil
event(secondary, "UPDATE_SHAPESHIFT_FORM")
assert(not secondary.shown)
print("PASS secondary mana initializes on fresh login and retains shapeshift visibility")

class, spec = "SHAMAN", 1
event(secondary, "PLAYER_ENTERING_WORLD", true, false)
assert(secondary.shown and secondaryBar.texture:match("Primary\\Mana$"),
    "Restoration Shaman mana fallback must remain enabled on Retail")
buildNumber = 16001
assert(loadfile("FFXIV_UI\\PlayerFrames\\PlayerFrame_Power_Secondary.lua"))()
event(secondary, "PLAYER_ENTERING_WORLD", true, false)
assert(not secondary.shown, "Shaman mana fallback must be disabled on Forever")
class, spec = "PRIEST", 3
event(secondary, "PLAYER_ENTERING_WORLD", true, false)
assert(not secondary.shown, "Priest mana fallback must be disabled on Forever")
buildNumber = 120000
assert(loadfile("FFXIV_UI\\PlayerFrames\\PlayerFrame_Power_Secondary.lua"))()
event(secondary, "PLAYER_ENTERING_WORLD", true, false)
assert(secondary.shown and secondaryBar.texture:match("Primary\\Mana$"),
    "Shadow Priest mana fallback must remain enabled on Retail")
print("PASS Shaman and Priest mana fallbacks are restricted to non-Forever clients")

class, spec, staggerAmount, maxHealthAmount = "MONK", 1, 120, 900
event(secondary, "PLAYER_ENTERING_WORLD", true, false)
assert(secondary.shown and secondaryBar.texture:match("ClassResources\\Primary\\Stagger$"))
assert(secondaryBar.value == 120 and secondaryBar.maximum == 900 and secondaryLabel.text == "SP")
assert(secondaryText.text == 120)
staggerAmount = 45
event(secondary, "UNIT_HEALTH", "player")
assert(secondaryBar.value == 45)
event(secondary, "UNIT_HEALTH", "target")
assert(secondaryBar.value == 45, "other unit updated Brewmaster stagger")
spec = 2
event(secondary, "PLAYER_SPECIALIZATION_CHANGED", "player")
assert(not secondary.shown, "non-Brewmaster Monk must hide the secondary bar")
print("PASS Brewmaster stagger uses the stagger texture, health max and SP label")

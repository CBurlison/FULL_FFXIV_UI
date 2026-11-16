local methods = {}
local function widget()
    return setmetatable({scripts = {}, events = {}, shown = true, level = 10, calls = {}}, {__index = methods})
end
for _, name in ipairs({"SetAllPoints", "SetTexture", "EnableMouse", "SetSize", "SetFrameStrata",
    "SetJustifyH", "SetFont", "SetShadowColor", "SetShadowOffset", "SetTextColor", "SetDrawLayer",
    "SetTexCoord", "SetStatusBarTexture"}) do
    methods[name] = function(self, ...) self.calls[name] = {...} end
end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(level) self.level = level end
function methods:SetPoint(...) self.point = {...} end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetMinMaxValues(low, high) self.min, self.max = low, high end
function methods:SetValue(value) self.value = value end
function methods:SetText(value) self.text = value end
function methods:GetStatusBarTexture() return self end
function methods:RegisterEvent(event) self.events[#self.events + 1] = event end
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

local xml = readFile("FFXIV_UI\\PlayerFrames\\PlayerFrame_Power_SoulFragments.xml")
assertContains(xml, 'name="PlayerFrame_Power_SoulFragments"', "soul fragments global")
assertContains(xml, 'relativeTo="PlayerFrame_Power"', "anchor to main power frame")
assertContains(xml, 'frameStrata="MEDIUM"', "strata")
for _, key in ipairs({"bg", "bar", "outlineFrame", "outline", "text", "powerLabel"}) do
    assertContains(xml, 'parentKey="' .. key .. '"', "soul fragments parentKey")
end
assertContains(xml, 'text="SF"', "static SF label")
assertContains(xml, "PlayerFrame\\Health", "initial bar texture matches original Lua")

local function child(parent, ...)
    local node = parent
    for _, key in ipairs({...}) do
        node[key] = node[key] or widget()
        node = node[key]
    end
    return node
end

local dh = true
local power, maxPower = 3, 5
local shownSpecialization = nil
UnitClass = function() return "", dh and "DEMONHUNTER" or "WARRIOR" end
UnitPower = function() return power end
UnitPowerMax = function() return maxPower end
SPELL_POWER_SOUL_SHARDS = 7

PlayerFrame_Power = widget()
PlayerFrame_Power_SoulFragments = widget()
local f = PlayerFrame_Power_SoulFragments
child(f, "bar")
child(f, "outlineFrame", "outline")
child(f, "outlineFrame", "text")
child(f, "outlineFrame", "powerLabel")

local source = readFile("FFXIV_UI\\PlayerFrames\\PlayerFrame_Power_SoulFragments.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "PlayerFrame_Power_SoulFragments.lua"))("FFXIV_UI", {})

assert(f.outlineFrame.level == 15, "outline level must be frame + 5")
assert(f.bar.min == 0 and f.bar.max == 5, "bar min/max must follow soul shard max")
assert(f.bar.value == 3, "bar value must follow soul shard count")
assert(f.outlineFrame.text.text == 3, "count text must show soul shard count")

assert(f.bar.calls.SetDrawLayer[1] == "ARTWORK" and f.bar.calls.SetDrawLayer[2] == 0, "bar texture must draw on ARTWORK 0")
assert(f.bar.calls.SetTexCoord[1] == 0.5 and f.bar.calls.SetTexCoord[2] == 1, "texcoord left must be 0.5 to 1")
assert(f.bar.calls.SetStatusBarTexture[1] == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\PlayerFrame\\ClassResources\\Primary\\Health",
    "bar must use the soul fragment texture")
assert(f.shown == true, "frame must show for demon hunter")

local registered = {}
for _, event in ipairs(f.events) do registered[event] = true end
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER"}) do
    assert(registered[event], "missing event " .. event)
end

local onEvent = f.scripts.OnEvent
power = 4
onEvent(f, "UNIT_POWER_UPDATE", "player", SPELL_POWER_SOUL_SHARDS)
assert(f.bar.value == 4, "UNIT_POWER_UPDATE must refresh the value")
assert(f.outlineFrame.text.text == 4, "UNIT_POWER_UPDATE must refresh the count text")

power = 9
onEvent(f, "UNIT_POWER_UPDATE", "target", SPELL_POWER_SOUL_SHARDS)
assert(f.bar.value == 4, "non-player unit must be ignored")

power = 9
onEvent(f, "UNIT_POWER_UPDATE", "player", "MANA")
assert(f.bar.value == 4, "other power types must be ignored")

onEvent(f, "UNIT_POWER_UPDATE", "player", SPELL_POWER_SOUL_SHARDS)
assert(f.bar.value == 9, "soul shard event must refresh")

dh = false
onEvent(f, "UNIT_DISPLAYPOWER", "player")
assert(f.shown == false, "frame must hide when class is not demon hunter")

print("PlayerFrameSoulFragments tests passed")

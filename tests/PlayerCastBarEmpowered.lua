local methods = {}
local noop = function() end

local function widget()
    local w = {scripts = {}, events = {}, shown = false, level = 10}
    return setmetatable(w, {__index = function(_, k)
        if methods[k] then return methods[k] end
        if type(k) == "string" and k:match("^%u") then return noop end
    end})
end

function methods:SetText(v) self.text = v end
function methods:SetValue(v) self.value = v end
function methods:SetMinMaxValues(lo, hi) self.min, self.max = lo, hi end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(l) self.level = l end
function methods:SetPoint(...) self.point = {...} end
function methods:ClearAllPoints() self.point = nil end
function methods:SetParent(p) self.parent = p end
function methods:SetScript(name, cb) self.scripts[name] = cb end
function methods:RegisterEvent(e) self.events[#self.events + 1] = e end
function methods:SetTexture(t) self.texture = t end
function methods:SetVertexColor(r, g, b, a) self.vertex = {r, g, b, a} end
function methods:GetStatusBarTexture()
    self.barTexture = self.barTexture or widget()
    return self.barTexture
end

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function assertContains(content, text, label)
    assert(content:find(text, 1, true), label .. " missing: " .. text)
end

local xml = readFile("FFXIV_UI\\PlayerFrames\\PlayerCastBar_Empowered.xml")
assertContains(xml, 'name="PlayerCastBarEmpoweredFrame"', "empowered global")
assert(not xml:find('name="PlayerCastBarFrame"', 1, true), "empowered frame must not reuse the cast bar global")
assertContains(xml, 'frameStrata="MEDIUM"', "empowered strata")
assertContains(xml, 'Primary\\Default', "empowered bar texture")
assertContains(xml, 'text="CASTING"', "static CASTING label")
assertContains(xml, 'inherits="CooldownFrameTemplate"', "cooldown template")
for _, key in ipairs({"bg", "castBar", "outlineFrame", "outline", "spellButton", "icon", "cooldown",
    "spellText", "hpLabel", "castTimeText"}) do
    assertContains(xml, 'parentKey="' .. key .. '"', "empowered parentKey")
end

for _, tocName in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local toc = readFile(tocName)
    local xmlAt = toc:find("PlayerFrames/PlayerCastBar_Empowered.xml", 1, true)
    local luaAt = toc:find("PlayerFrames/PlayerCastBar_Empowered.lua", 1, true)
    assert(xmlAt and luaAt and xmlAt < luaAt, tocName .. " must load PlayerCastBar_Empowered.xml before its Lua")
end

local function child(parent, ...)
    local node = parent
    for _, key in ipairs({...}) do
        node[key] = rawget(node, key) or widget()
        node = node[key]
    end
    return node
end

local function colorObject(r, g, b)
    return {GetRGB = function() return r, g, b end}
end

local fontOfPower = false
local curves = {}
local function newCurve()
    local curve = {points = {}}
    function curve:SetType(t) self.curveType = t end
    function curve:AddPoint(p, c) self.points[#self.points + 1] = {p, c} end
    function curve:Evaluate(p) self.lastProgress = p return colorObject(0.1, 0.2, 0.3) end
    curves[#curves + 1] = curve
    return curve
end

local now = 1
GetTime = function() return now end
local castStartMS, castEndMS = 1000, 4000
function UnitCastingInfo()
    return "Empower", nil, 123, castStartMS, castEndMS
end
C_Spell = {GetSpellInfo = function(id)
    if id == 1 then return {name = "Empower Fire", iconID = 555} end
end}
GetSpellInfo = function(id)
    if id == 2 then return "Fallback Name", nil, 999 end
end
C_Traits = {
    GetKnownTreeIDs = function() return {} end,
    GetTreeNodes = function() return {} end,
    GetNodeInfo = function() return nil end,
}
function IsPlayerSpell(id) return fontOfPower and id == 411212 end
C_CurveUtil = {CreateColorCurve = newCurve}
Enum = {LuaCurveType = {Step = 1}}
CreateColor = function(r, g, b, a) return colorObject(r, g, b) end
PlayerCastingBarFrame = nil
FFXIV_UI_Anchors = {PlayerCast = widget()}

local skinned
local frame = widget()
frame.level = 10
frame.castBar = child(frame, "castBar")
child(frame, "outlineFrame", "spellButton", "icon")
child(frame, "outlineFrame", "spellButton", "cooldown")
child(frame, "outlineFrame", "spellButton")
child(frame, "outlineFrame", "spellText")
child(frame, "outlineFrame", "hpLabel")
child(frame, "outlineFrame", "castTimeText")
child(frame, "outlineFrame")
PlayerCastBarEmpoweredFrame = frame

local source = readFile("FFXIV_UI\\PlayerFrames\\PlayerCastBar_Empowered.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "PlayerCastBar_Empowered.lua"))("FFXIV_UI", {
    ApplyButtonSkin = function(button, parts)
        skinned = {button = button, icon = parts.Icon, cooldown = parts.Cooldown}
    end,
})

local castBar = frame.castBar
local outlineFrame = frame.outlineFrame
local spellButton = outlineFrame.spellButton
local spellText = outlineFrame.spellText
local hpLabel = outlineFrame.hpLabel
local castTimeText = outlineFrame.castTimeText

assert(outlineFrame.level == 15, "outline level must be frame + 5")
assert(castTimeText.point[1] == "LEFT" and castTimeText.point[2] == hpLabel and castTimeText.point[3] == "RIGHT",
    "cast time must anchor to the right of the label")
assert(frame.parent == FFXIV_UI_Anchors.PlayerCast, "frame must parent to the PlayerCast anchor")
assert(frame.point[2] == FFXIV_UI_Anchors.PlayerCast, "frame must anchor to the PlayerCast anchor")
assert(skinned and skinned.button == spellButton and skinned.icon == spellButton.icon
    and skinned.cooldown == spellButton.cooldown, "spell button must be skinned")
assert(castTimeText.text == "00.00", "time must start at zero")

local onEvent = frame.scripts.OnEvent
local registered = {}
for _, e in ipairs(frame.events) do registered[e] = true end
for _, e in ipairs({"UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_STOP",
    "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED"}) do
    assert(registered[e], "missing event " .. e)
end

onEvent(frame, "UNIT_SPELLCAST_EMPOWER_START", "target", "guid", 1)
assert(not frame.shown, "non-player empower must be ignored")

now = 1
onEvent(frame, "UNIT_SPELLCAST_EMPOWER_START", "player", "guid", 1)
assert(frame.shown and castBar.shown and spellButton.shown, "start must show the frame, bar, and icon")
assert(spellText.text == "Empower Fire", "spell name must come from C_Spell")
assert(spellButton.icon.texture == 555, "spell icon must come from C_Spell")
assert(castBar.isEmpowered, "cast must be flagged empowered")
assert(#curves[#curves].points == 5, "curve without Font of Power has five points")

now = 2
castBar.scripts.OnUpdate(castBar, 1)
assert(math.abs(castBar.value - 1 / 3) < 1e-9, "bar must follow cast progress")
assert(castTimeText.text == "02.00", "remaining time must count down")
assert(math.abs(curves[#curves].lastProgress - 1 / 3) < 1e-9, "curve must be evaluated at progress")
assert(castBar.barTexture.vertex[1] == 0.1 and castBar.barTexture.vertex[3] == 0.3, "bar must take curve color")

now = 4
castBar.scripts.OnUpdate(castBar, 1)
assert(not frame.shown and not castBar.isEmpowered, "completed empower must hide the frame")
assert(castTimeText.text == "00.00" and spellText.text == "", "completion must reset text")

fontOfPower = true
now = 5
castStartMS, castEndMS = 5000, 8000
onEvent(frame, "UNIT_SPELLCAST_EMPOWER_START", "player", "guid", 1)
local fopCurve = curves[#curves]
assert(#fopCurve.points == 6, "Font of Power must add the orange stage")
assert(fopCurve.points[6][1] == 0.6, "Font of Power stage must sit at 0.6")
fontOfPower = false

onEvent(frame, "UNIT_SPELLCAST_EMPOWER_STOP", "player", "guid", 1)
assert(not frame.shown and not castBar.shown and not spellButton.shown, "stop must hide everything")
assert(spellText.text == "" and castTimeText.text == "00.00", "stop must reset text")
assert(castBar.startTime == nil and castBar.endTime == nil, "stop must clear timing")

onEvent(frame, "UNIT_SPELLCAST_EMPOWER_START", "player", "guid", 2)
assert(spellText.text == "Fallback Name" and spellButton.icon.texture == 999, "must fall back to GetSpellInfo")
onEvent(frame, "UNIT_SPELLCAST_FAILED", "player", "guid", 2)

C_Spell.GetSpellInfo = function() return nil end
GetSpellInfo = function() return nil end
onEvent(frame, "UNIT_SPELLCAST_EMPOWER_START", "player", "guid", 3)
assert(spellText.text == "Empowered Cast" and spellButton.icon.texture == 136243, "must use default name and icon")
onEvent(frame, "UNIT_SPELLCAST_INTERRUPTED", "player", "guid", 3)
assert(not frame.shown, "interrupt must hide the frame")

print("PlayerCastBar_Empowered tests passed")

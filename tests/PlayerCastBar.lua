local methods = {}
local noop = function() end

local function widget()
    local w = {scripts = {}, events = {}, shown = true, level = 10}
    return setmetatable(w, {__index = function(_, k) return methods[k] or noop end})
end

function methods:SetText(v) self.text = v end
function methods:SetValue(v) self.value = v end
function methods:SetMinMaxValues(lo, hi) self.min, self.max = lo, hi end
function methods:SetAlpha(a) self.alpha = a end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(l) self.level = l end
function methods:SetPoint(...) self.point = {...} end
function methods:SetParent(p) self.parent = p end
function methods:SetScript(name, cb) self.scripts[name] = cb end
function methods:RegisterEvent(e) self.events[#self.events + 1] = e end
function methods:SetTexture(t) self.texture = t end
function methods:SetStatusBarColor(r, g, b) self.color = {r, g, b} end

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

local function assertContains(content, text, label)
    assert(content:find(text, 1, true), label .. " missing: " .. text)
end

local xml = readFile("FFXIV_UI\\PlayerFrames\\PlayerCastBar.xml")
assertContains(xml, 'name="PlayerCastBarFrame"', "cast bar global")
assertContains(xml, 'frameStrata="MEDIUM"', "cast bar strata")
assertContains(xml, 'frameStrata="HIGH"', "interrupt strata")
for _, key in ipairs({"bg", "castBar", "outlineFrame", "outline", "spellButton", "icon", "cooldown",
    "spellText", "hpLabel", "castTimeText", "interruptedFrame", "interruptedText"}) do
    assertContains(xml, 'parentKey="' .. key .. '"', "cast bar parentKey")
end
assertContains(xml, 'text="CASTING"', "static CASTING label")
assertContains(xml, 'text="INTERRUPTED"', "static INTERRUPTED label")
assertContains(xml, 'inherits="CooldownFrameTemplate"', "cooldown template")

for _, tocName in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local toc = readFile(tocName)
    local xmlAt = toc:find("PlayerFrames/PlayerCastBar.xml", 1, true)
    local luaAt = toc:find("PlayerFrames/PlayerCastBar.lua", 1, true)
    assert(xmlAt and luaAt and xmlAt < luaAt, tocName .. " must load PlayerCastBar.xml before its Lua")
end

local function child(parent, ...)
    local node = parent
    for _, key in ipairs({...}) do
        node[key] = rawget(node, key) or widget()
        node = node[key]
    end
    return node
end

local now = 1
GetTime = function() return now end
local castName, channeling = nil, false
local castStartMS, castEndMS = 1000, 5000
function UnitCastingInfo()
    if not channeling and castName then return castName, nil, 123, castStartMS, castEndMS, nil, nil, nil, 7620 end
end
function UnitChannelInfo()
    if channeling and castName then return castName, nil, 123, castStartMS, castEndMS, nil, nil, 7620 end
end
local secret = setmetatable({}, {__index = function() error("secret string inspected") end})
function issecretvalue(value) return value == secret end

PlayerCastingBarFrame = widget()
PlayerCastBarFrame = widget()
local frame = PlayerCastBarFrame
frame.shown = false
child(frame, "bg")
child(frame, "castBar").shown = false
child(frame, "outlineFrame", "outline")
child(frame, "outlineFrame", "spellButton").shown = false
child(frame, "outlineFrame", "spellButton", "icon")
child(frame, "outlineFrame", "spellButton", "cooldown")
child(frame, "outlineFrame", "spellText")
child(frame, "outlineFrame", "hpLabel")
child(frame, "outlineFrame", "castTimeText")
child(frame, "interruptedFrame", "interruptedText").shown = false
FFXIV_UI_Anchors = {PlayerCast = widget()}

local source = readFile("FFXIV_UI\\PlayerFrames\\PlayerCastBar.lua"):gsub("^\239\187\191", "")
assert(loadstring(source, "PlayerCastBar.lua"))("FFXIV_UI", {
    ApplyButtonSkin = noop,
})

local castBar = frame.castBar
local outlineFrame = frame.outlineFrame
local spellButton = outlineFrame.spellButton
local spellText = outlineFrame.spellText
local hpLabel = outlineFrame.hpLabel
local castTimeText = outlineFrame.castTimeText
local interruptedFrame = frame.interruptedFrame
local interruptedText = interruptedFrame.interruptedText

assert(outlineFrame.level == 15, "outline level must be frame + 5")
assert(interruptedFrame.level == 60, "interrupt level must be frame + 50")
assert(castTimeText.point[1] == "LEFT" and castTimeText.point[2] == hpLabel and castTimeText.point[3] == "RIGHT",
    "cast time must anchor to the right of the label")
assert(frame.parent == FFXIV_UI_Anchors.PlayerCast, "frame must parent to the PlayerCast anchor")
assert(frame.point[2] == FFXIV_UI_Anchors.PlayerCast, "frame must anchor to the PlayerCast anchor")

local onEvent = frame.scripts.OnEvent
local registered = {}
for _, e in ipairs(frame.events) do registered[e] = true end
for _, e in ipairs({"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_EMPOWER_START"}) do
    assert(registered[e], "missing event " .. e)
end

local cases = {
    {"Opening - No Name", "Opening"},
    {"Mining - No Name", "Mining"},
    {"Opening - Ancient Chest", "Opening - Ancient Chest"},
    {"Fireball", "Fireball"},
    {"No Name", "No Name"},
    {"Opening - No Name Extra", "Opening - No Name Extra"},
    {"Opening - No Name - Chest", "Opening - No Name - Chest"},
    {secret, secret},
}
for _, event in ipairs({"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START"}) do
    for _, case in ipairs(cases) do
        channeling = event == "UNIT_SPELLCAST_CHANNEL_START"
        castName = case[1]
        onEvent(frame, event, "player")
        assert(spellText.text == case[2], event .. ": incorrect cast label")
    end
    print("PASS " .. event .. ": placeholder removed; real names and secret values preserved")
end
castName = "Opening - No Name"
onEvent(frame, "UNIT_SPELLCAST_START", "target")
assert(spellText.text == secret, "non-player event changed player label")
print("PASS non-player casts ignored")

channeling = false
castName = "Fireball - No Name"
castStartMS, castEndMS = 1000, 3000
now = 1
onEvent(frame, "UNIT_SPELLCAST_START", "player")
assert(frame.shown and castBar.shown, "start must show the frame and bar")
assert(spellText.text == "Fireball", "suffix must be stripped from the cast label")
assert(spellButton.shown and spellButton.icon.texture == 123, "start must show the spell icon")
assert(castBar.value == 0, "start must reset the bar")

now = 2
castBar.scripts.OnUpdate(castBar, 1)
assert(math.abs(castBar.value - 0.5) < 1e-9, "bar must follow cast progress")
assert(castTimeText.text == "01.00", "remaining time must count down")

now = 3
castBar.scripts.OnUpdate(castBar, 1)
assert(not castBar.shown and not frame.shown, "completed cast must hide the bar")

channeling = false
castName = "Frostbolt"
castStartMS, castEndMS = 10000, 12000
now = 10
onEvent(frame, "UNIT_SPELLCAST_START", "player")
now = 11
castBar.scripts.OnUpdate(castBar, 0.5)
castName = nil
onEvent(frame, "UNIT_SPELLCAST_INTERRUPTED", "player")
assert(interruptedText.shown and interruptedText.isAnimating, "interrupt must start the flash animation")
assert(castBar.color[1] == 0.5, "interrupt must darken the bar")

interruptedFrame.scripts.OnUpdate(interruptedFrame, 0.1)
assert(math.abs(interruptedText.currentOffsetX - 20) < 1e-9, "interrupt text must slide left")
interruptedFrame.scripts.OnUpdate(interruptedFrame, 0.2)
assert(interruptedText.currentOffsetX == 0 and not interruptedText.isAnimating, "slide must stop at target")
assert(interruptedText.isFlashing, "slide end must start flashing")

castBar.scripts.OnUpdate(castBar, 2.3)
castBar.scripts.OnUpdate(castBar, 0.3)
assert(not frame.shown, "fade-out must hide the frame")
assert(castBar.color[1] == 1, "hide must restore bar color")

channeling = false
castName = "Pyroblast"
castStartMS, castEndMS = 20000, 22000
now = 20
onEvent(frame, "UNIT_SPELLCAST_START", "player")
now = 21
castBar.scripts.OnUpdate(castBar, 1)
castEndMS = 23000
now = 21.5
onEvent(frame, "UNIT_SPELLCAST_DELAYED", "player")
castBar.scripts.OnUpdate(castBar, 10)
assert(math.abs(castBar.value - 0.5) < 1e-9, "cast pushback must keep progress on the delayed timeline")
assert(castTimeText.text == "01.50", "cast pushback must extend the remaining time")

channeling = true
castName = "Mind Flay"
castStartMS, castEndMS = 30000, 33000
now = 30
onEvent(frame, "UNIT_SPELLCAST_CHANNEL_START", "player")
castEndMS = 32000
now = 31
onEvent(frame, "UNIT_SPELLCAST_CHANNEL_UPDATE", "player")
castBar.scripts.OnUpdate(castBar, 10)
assert(math.abs(castBar.value - 0.5) < 1e-9, "channel update must keep progress on the shortened timeline")
assert(castTimeText.text == "01.00", "channel update must shorten the remaining time")

print("PlayerCastBar tests passed")

local addonName, ns = ...

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end
local xml = readFile("FFXIV_UI\\General\\EventText.xml")
for _, text in ipairs({
    '<Frame name="EventTexturesFrame" parent="UIParent">',
    '<Layer level="OVERLAY">',
    '<Texture parentKey="texture" alpha="0" hidden="true">',
    '<Size x="1200" y="1200"/>',
    '<Anchor point="CENTER" relativeTo="UIParent" relativePoint="CENTER" x="0" y="250"/>',
    '<Frame name="FFEventTextAnimationFrame" parent="UIParent" hidden="true"/>',
}) do
    assert(xml:find(text, 1, true), "XML missing: " .. text)
end
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do
        index = index + 1
        lines[line] = index
    end
    assert(assert(lines["General/EventText.xml"]) < assert(lines["General/EventText.lua"]))
end
local methods = {}
local function object()
    return setmetatable({scripts = {}, events = {}, shown = false}, {__index = methods})
end
function methods:SetScript(script, callback) self.scripts[script] = callback end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetTexture(path) self.path = path end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:SetScale(scale) self.scale = scale end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
EventTexturesFrame, FFEventTextAnimationFrame = object(), object()
EventTexturesFrame.texture = object()
local tex, anim = EventTexturesFrame.texture, FFEventTextAnimationFrame
local time = 0
GetTime = function() return time end
CreateFrame = function() error("Event text widgets must come from XML") end
C_QuestLog = {
    IsOnQuest = function(id) return id == 10 or id == 20 end,
    IsWorldQuest = function(id) return id == 20 end,
}
assert(loadstring(readFile("FFXIV_UI\\General\\EventText.lua")))("FFXIV_UI", {})
local function event(name, ...)
    assert(EventTexturesFrame.events[name])
    EventTexturesFrame.scripts.OnEvent(EventTexturesFrame, name, ...)
end
local function close(actual, expected)
    assert(math.abs(actual - expected) < 0.000001)
end
event("PLAYER_ENTERING_WORLD")
time = 1
event("QUEST_TURNED_IN")
assert(not tex.shown and not anim.shown, "World-entry delay must suppress notifications")
time = 2
for _, id in ipairs({0, 20}) do
    event("QUEST_ACCEPTED", id)
    assert(not tex.shown, "Unavailable and world quests must not show quest-accept artwork")
end
event("QUEST_ACCEPTED")
assert(not tex.shown)
event("QUEST_ACCEPTED", 10)
assert(tex.shown and anim.shown and tex.alpha == 0 and tex.scale == 1)
assert(tex.path == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\FFQuestAccept.tga")
time = 2.075
anim.scripts.OnUpdate(anim)
close(tex.alpha, 0.5)
close(tex.scale, 0.95)
time = 3
anim.scripts.OnUpdate(anim)
close(tex.alpha, 1)
close(tex.scale, 0.9)
time = 4.275
anim.scripts.OnUpdate(anim)
close(tex.alpha, 0.5)
time = 4.5
anim.scripts.OnUpdate(anim)
assert(not tex.shown and not anim.shown and anim.startTime == nil)
for eventName, artwork in pairs({PLAYER_LEVEL_UP = "FFLevelUp", QUEST_TURNED_IN = "FFQuestComplete"}) do
    event(eventName)
    assert(tex.shown and tex.alpha == 0 and tex.scale == 1 and anim.startTime == time)
    assert(tex.path == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\" .. artwork .. ".tga")
end
time = 5
event("QUEST_ACCEPTED", 10)
assert(anim.startTime == 5 and tex.alpha == 0, "A new notification must restart the animation")
event("PLAYER_ENTERING_WORLD")
time = 6
local priorPath = tex.path
event("PLAYER_LEVEL_UP")
assert(tex.path == priorPath, "World entry must reset the notification delay")
print("PASS: event text XML, TOC order, artwork, quest filters, delay, fade/scale timings, and restart")

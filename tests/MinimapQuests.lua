local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end
local xml = readFile("FFXIV_UI\\General\\Minimap.xml")
assert(xml:find('<Frame name="FFXIV_MinimapQuestOverlayTemplate" virtual="true" setAllPoints="true" enableMouse="false"/>', 1, true))
local markerXml = assert(xml:match('<Texture name="FFXIV_MinimapQuestMarkerTemplate".-</Texture>'))
assert(markerXml:find('virtual="true"', 1, true))
assert(markerXml:find('<Size x="24" y="24"/>', 1, true))
for _, path in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local lines, index = {}, 0
    for line in readFile(path):gmatch("[^\r\n]+") do index = index + 1; lines[line] = index end
    assert(assert(lines["General/Minimap.xml"]) < assert(lines["General/MinimapQuests.lua"]))
end
local frame, probes, soft, countThisFrame = nil, 0, false, 0
local combat, speed, hover, visible, facing, zoom = false, 0, false, true, 0, 1
local secret = {}
function issecretvalue(value) return value == secret end
local quests = {{title = "Protect the Frontier", questID = 52}}
local complete = {[52] = true}
local tracked = 0
local markers = {{title = "Protect the Frontier", x = 48, y = 64}}
local textures = {}
local methods = {}
function methods:SetAllPoints(parent) self.allPoints = parent end
function methods:SetFrameLevel(level) self.level = level end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:CreateTexture(_, layer, template)
    assert(not combat and template == "FFXIV_MinimapQuestMarkerTemplate")
    local texture = {shown = false, parent = self, layer = layer, template = template}
    function texture:SetSize(w, h) self.width, self.height = w, h end
    function texture:SetTexture(value) self.texture = value end
    function texture:ClearAllPoints() end
    function texture:SetPoint(_, _, _, x, y) self.x, self.y = x, y end
    function texture:Show() self.shown = true end
    function texture:Hide() self.shown = false end
    texture:SetSize(24, 24)
    textures[#textures + 1] = texture
    return texture
end
function CreateFrame(_, _, parent, template)
    assert(template == "FFXIV_MinimapQuestOverlayTemplate")
    frame = setmetatable({scripts = {}, events = {}, parent = parent, template = template}, {__index = methods})
    frame:SetAllPoints(parent)
    frame:EnableMouse(false)
    return frame
end
Minimap = {}
function Minimap:GetFrameLevel() return 2 end
function Minimap:GetLeft() return 100 end
function Minimap:GetBottom() return 200 end
function Minimap:GetWidth() return 160 end
function Minimap:GetHeight() return 160 end
function Minimap:GetEffectiveScale() return 2 end
function Minimap:GetZoom() return zoom end
function Minimap:IsVisible() return visible end
function Minimap:IsMouseOver() return hover end
function Minimap:SetUsingSoftCursor(value) soft = value end
local px, py
function Minimap:UpdateMouseoverAtPoint(x, y)
    assert(soft, "probe needs soft cursor")
    probes, countThisFrame = probes + 1, countThisFrame + 1
    px, py = x / 2 - 100, y / 2 - 200
end
C_TooltipInfo = {GetMinimapMouseover = function()
    for _, marker in ipairs(markers) do
        if (px - marker.x)^2 + (py - marker.y)^2 <= 12^2 then
            return {lines = {{leftText = marker.title}}}
        end
    end
    return {lines = {}}
end}
C_QuestLog = {
    GetNumQuestLogEntries = function() return #quests end,
    GetInfo = function(index) return quests[index] end,
    IsComplete = function(id) return complete[id] end,
}
C_SuperTrack = {GetSuperTrackedQuestID = function() return tracked end}
function InCombatLockdown() return combat end
function GetUnitSpeed() return speed end
function GetPlayerFacing() return facing end
FFXIV_UI_DB = {}
local namespace = {}
assert(loadfile("FFXIV_UI\\General\\MinimapQuests.lua"))("FFXIV_UI", namespace)
assert(frame.parent == Minimap and frame.allPoints == Minimap and frame.level == 7
    and frame.mouse == false, "Quest overlay must retain coverage, level and mouse passthrough")
local function event(name) frame.scripts.OnEvent(frame, name) end
local function tick(count)
    for _ = 1, count or 1 do
        countThisFrame = 0
        if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 0.016) end
        assert(not soft, "scanner left soft cursor enabled")
        assert(countThisFrame <= 24, "probe budget exceeded")
    end
end
local function shown()
    local count = 0
    for _, texture in ipairs(textures) do if texture.shown then count = count + 1 end end
    return count
end
event("PLAYER_LOGIN")
tick(100)
assert(probes == 0 and not frame.scripts.OnUpdate)
assert(frame.mouse == false)
print("PASS off-by-default prototype performs no scanning")
namespace.SetMinimapQuestOverlayEnabled(true)
tick(100)
assert(shown() == 1 and probes > 0)
local icon = textures[1]
assert(icon.parent == frame and icon.layer == "OVERLAY"
    and icon.template == "FFXIV_MinimapQuestMarkerTemplate")
assert(math.abs(icon.x - 48) <= 4 and math.abs(icon.y - 64) <= 4, "incorrect scaled marker center")
assert(icon.texture:match("CompleteQuest_Icon.tga$"))
assert(icon.width == 24 and icon.height == 24)
tracked = 52
event("SUPER_TRACKING_CHANGED")
assert(shown() == 0)
tick(100)
assert(icon.texture:match("CompleteQuest_Blue_Icon.tga$"))
print("PASS completed-title matching, probe budget, screen scaling, clustering and blue tracking icon")

hover = true
local beforeHover, hoverX, hoverY = probes, icon.x, icon.y
tick(100)
assert(shown() == 1 and icon.x == hoverX and icon.y == hoverY, "hover removed or moved confirmed icon")
assert(probes == beforeHover, "hover must pause scanning for native tooltips")
hover = false
tick(100)
assert(shown() == 1 and probes > beforeHover, "scanning did not resume after hover")
print("PASS minimap hover preserves confirmed icons without scanning and resumes after leaving")

for _, reason in ipairs({"combat", "speed", "visible"}) do
    local before = probes
    if reason == "combat" then combat = true
    elseif reason == "speed" then speed = 1
    else visible = false end
    tick(1)
    assert(shown() == 0 and probes == before, "scan continued while blocked by " .. reason)
    combat, speed, hover, visible = false, 0, false, true
    tick(100)
    assert(shown() == 1)
end
hover = true
local beforeTurn = probes
facing = 1
tick(1)
assert(shown() == 0, "turning retained stale overlay")
assert(probes == beforeTurn, "turning while hovered resumed scanning")
hover = false
tick(100)
assert(shown() == 1)
zoom = 2
tick(1)
assert(shown() == 0, "zoom retained stale overlay")
tick(100)
print("PASS movement, turning (including while hovered), zoom, combat and map visibility clear stale overlays")

local mapX, mapY, mapID, radius, rotating = 0.5, 0.5, 1, 100, false
C_Map = {
    GetBestMapForUnit = function() return mapID end,
    GetPlayerMapPosition = function() return {GetXY = function() return mapX, mapY end} end,
    GetMapWorldSize = function() return 1000, 1000 end,
}
C_Minimap = {GetViewRadius = function() return radius end}
C_CVar = {GetCVar = function() return rotating and "1" or "0" end}
event("QUEST_LOG_UPDATE")
tick(100)
local originX, originY = icon.x, icon.y
local beforeMove = probes
speed, hover = 7, true
mapX = mapX + 0.01
tick(1)
assert(shown() == 1 and math.abs(icon.x - (originX - 8)) < 0.001)
assert(icon.y == originY and probes == beforeMove, "movement must track without tooltip probes")
mapY = mapY - 0.01
tick(1)
assert(shown() == 1 and math.abs(icon.y - (originY - 8)) < 0.001)
local east, north = icon.x - 80, icon.y - 80
rotating, facing = true, math.pi / 2
tick(1)
assert(shown() == 1 and math.abs(icon.x - (80 + north)) < 0.001)
assert(math.abs(icon.y - (80 - east)) < 0.001, "rotating minimap projection incorrect")
radius = 200
tick(1)
assert(math.abs(icon.x - (80 + north / 2)) < 0.001 and math.abs(icon.y - (80 - east / 2)) < 0.001)
mapX = 0.9
tick(1)
assert(shown() == 0, "out-of-range marker must hide")
mapX = 0.51
tick(1)
assert(shown() == 1, "in-range known marker should return")
mapID = 2
tick(1)
assert(shown() == 0, "marker leaked into another map")
mapID, mapX, mapY, radius, rotating, facing, speed, hover = 1, 0.5, 0.5, 100, false, 0, 0, false
event("QUEST_LOG_UPDATE")
tick(100)
assert(shown() == 1)
mapX = secret
speed = 7
tick(1)
assert(shown() == 0, "restricted position left stale moving marker visible")
mapX, speed = 0.5, 0
tick(100)
assert(shown() == 1)
print("PASS known markers follow movement, map rotation and zoom without scanning; range/map/restricted positions are guarded")

local stableX, stableY = icon.x, icon.y
speed = 7
mapX = 0.505
tick(1)
local stoppedX, stoppedY = icon.x, icon.y
speed = 0
for _, x in ipairs({46, 48, 42, 46}) do
    markers[1].x = x
    for _ = 1, 100 do
        tick(1)
        assert(shown() == 1 and math.abs(icon.x - stoppedX) < 0.001
            and math.abs(icon.y - stoppedY) < 0.001, "stationary rescan jittered a confirmed marker")
    end
end
markers[1].x = 72
tick(100)
assert(shown() == 1 and math.abs(icon.x - 72) <= 4, "larger marker relocation was ignored")
markers = {}
tick(100)
assert(shown() == 0, "stabilization retained a marker absent from the scan")
markers = {{title = "Protect the Frontier", x = 48, y = 64}}
mapX = 0.5
event("QUEST_LOG_UPDATE")
tick(100)
assert(shown() == 1 and math.abs(icon.x - stableX) < 0.001 and math.abs(icon.y - stableY) < 0.001)
print("PASS stopping and repeated noisy rescans preserve position; larger corrections and missing markers still update")

quests[2] = {title = "Protect the Frontier", questID = 53}
event("QUEST_LOG_UPDATE")
tick(100)
assert(shown() == 0, "duplicate quest titles must not be guessed")
quests[2] = nil
complete[52] = false
event("QUEST_LOG_UPDATE")
tick(100)
assert(shown() == 0, "incomplete quest shown as turn-in")
complete[52] = secret
event("QUEST_LOG_UPDATE")
tick(100)
assert(shown() == 0, "secret completion treated as completed")
complete[52] = true
markers = {{title = "Ormin Pelford", x = 48, y = 64}}
event("QUEST_LOG_UPDATE")
tick(100)
assert(shown() == 0, "available NPC guessed from its name")
markers = {{title = secret, x = 48, y = 64}}
event("QUEST_LOG_UPDATE")
tick(100)
assert(shown() == 0)
markers = {
    {title = "Protect the Frontier", x = 48, y = 64},
    {title = "Protect the Frontier", x = 112, y = 96},
}
event("QUEST_LOG_UPDATE")
tick(100)
assert(shown() == 0, "multiple separated markers for one title must be omitted")
print("PASS available, incomplete, duplicate, secret and spatially ambiguous matches are omitted")

namespace.SetMinimapQuestOverlayEnabled(false)
local before = probes
tick(100)
assert(probes == before and shown() == 0 and not frame.scripts.OnUpdate)
assert(FFXIV_UI_DB.minimapQuestOverlayEnabled == false)
namespace.SetMinimapQuestOverlayEnabled(true)
assert(FFXIV_UI_DB.minimapQuestOverlayEnabled == true)
local oldPrint, messages = print, {}
print = function(message) messages[#messages + 1] = message end
Minimap.UpdateMouseoverAtPoint = nil
namespace.SetMinimapQuestOverlayEnabled(true)
namespace.SetMinimapQuestOverlayEnabled(true)
print = oldPrint
assert(#messages == 1 and messages[1]:match("unavailable") and not frame.scripts.OnUpdate)
print("PASS disabling removes work and artwork; missing APIs report explicitly once")

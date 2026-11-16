local namespace, lastFrame = {}, nil

function CreateFrame()
    local frame = {scripts = {}}
    function frame:RegisterEvent() end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    lastFrame = frame
    return frame
end

function hooksecurefunc(target, method, callback)
    local original = assert(target[method], "missing native method: " .. method)
    target[method] = function(...)
        original(...)
        callback(...)
    end
end

ScrollBoxListMixin = {Event = {OnInitializedFrame = "init", OnDataRangeChanged = "range"}}
local buildNumber
function GetBuildInfo() return "", "", "", buildNumber end

local arrows = {}
namespace.StyleCircularArrowButton = function(button, direction)
    arrows[button] = arrows[button] or {calls = 0}
    arrows[button].direction = direction
    arrows[button].calls = arrows[button].calls + 1
    button.FFXIVUICircularArrow = arrows[button]
    return arrows[button]
end

local function texture()
    return {alpha = 1, SetAlpha = function(self, value) self.alpha = value end, SetAtlas = function(self, atlas) self.atlas = atlas end}
end

local function header() return {Name = {}, StateIcon = {}} end

-- StatisticsSubHeaderTemplate: the toggle's RefreshIcon swaps the campaign atlas from treeNode:IsCollapsed().
local function subHeader(collapsed)
    local row = {Content = {Name = {}, Value = {}}, treeNode = {collapsed = collapsed}}
    function row.treeNode:IsCollapsed() return self.collapsed end
    local normal, pushed, highlight = texture(), texture(), texture()
    local toggle = {}
    function toggle:GetParent() return row end
    function toggle:GetNormalTexture() return normal end
    function toggle:GetPushedTexture() return pushed end
    function toggle:GetHighlightTexture() return highlight end
    function toggle:RefreshIcon()
        local isCollapsed = row.treeNode:IsCollapsed()
        normal:SetAtlas(isCollapsed and "campaign_headericon_closed" or "campaign_headericon_open")
    end
    function toggle:OnClick()
        row.treeNode.collapsed = not row.treeNode.collapsed
        self:RefreshIcon()
    end
    toggle.textures = {normal, pushed, highlight}
    row.ToggleCollapseButton = toggle
    return row
end

local function entry() return {Content = {Name = {}, Value = {}}} end

local styledHeaders, callbacks, registrations
local function load(build, frames)
    buildNumber = build
    styledHeaders, callbacks, registrations = {}, {}, 0
    namespace.StyleForeverCollapsibleHeader = function(row) styledHeaders[#styledHeaders + 1] = row end
    _G.StatisticsFrame = frames and {
        ScrollBox = {
            ForEachFrame = function(_, callback) for _, frame in ipairs(frames) do callback(frame) end end,
            RegisterCallback = function(_, event, callback)
                callbacks[event] = callback
                registrations = registrations + 1
            end,
        },
    }
    assert(loadfile("FFXIV_UI\\General\\Statistics.lua"))("FFXIV_UI", namespace)
    return lastFrame
end

local retailSub = subHeader(true)
local retail = load(110005, {header(), retailSub})
retail.scripts.OnEvent(retail, "PLAYER_LOGIN")
assert(#styledHeaders == 0 and arrows[retailSub.ToggleCollapseButton] == nil, "Retail has no Statistics tab to style")
print("PASS Statistics styling is Forever only")

local top, collapsed, expanded, row = header(), subHeader(true), subHeader(false), entry()
local watcher = load(16001, nil)
watcher.scripts.OnEvent(watcher, "PLAYER_LOGIN")
assert(registrations == 0, "nothing to style before Blizzard_Statistics loads")
_G.StatisticsFrame = {
    ScrollBox = {
        ForEachFrame = function(_, callback)
            for _, frame in ipairs({top, collapsed, expanded, row}) do callback(frame) end
        end,
        RegisterCallback = function(_, event, callback)
            callbacks[event] = callback
            registrations = registrations + 1
        end,
    },
}
watcher.scripts.OnEvent(watcher, "ADDON_LOADED", "Blizzard_Statistics")
assert(#styledHeaders == 1 and styledHeaders[1] == top, "top-level headers use the Forever ComboBox header")
assert(top.ToggleCollapseButton == nil and arrows[top] == nil, "headers get no separate circle arrow (D4)")
print("PASS Statistics section headers use the Forever ComboBox header")

local toggle = collapsed.ToggleCollapseButton
for _, native in ipairs(toggle.textures) do
    assert(native.alpha == 0, "the native campaign +/- toggle art must be hidden")
end
assert(arrows[toggle].direction == "right", "a collapsed item points right")
assert(arrows[expanded.ToggleCollapseButton].direction == "down", "an expanded item points down")
assert(row.ToggleCollapseButton == nil, "statistic value rows have no toggle")
print("PASS Statistics item toggles use the circle arrow: right collapsed, down expanded")

toggle:OnClick()
assert(collapsed.treeNode.collapsed == false and toggle.textures[1].atlas == "campaign_headericon_open",
    "the native toggle action must keep working")
assert(arrows[toggle].direction == "down", "expanding an item turns its arrow down")
toggle:OnClick()
assert(arrows[toggle].direction == "right", "collapsing an item turns its arrow right")
assert(toggle.textures[1].alpha == 0, "RefreshIcon must not bring the native art back")
print("PASS Statistics circle arrows follow the native collapse state")

-- ScrollBox recycles rows: a reused sub-header is re-initialised for another node without re-hooking.
collapsed.treeNode.collapsed = false
callbacks.init(nil, collapsed)
assert(arrows[toggle].direction == "down", "a recycled row must pick up its new node's state")
local before = arrows[toggle].calls
toggle:RefreshIcon()
assert(arrows[toggle].calls == before + 1, "RefreshIcon must be hooked only once per toggle")
watcher.scripts.OnEvent(watcher, "ADDON_LOADED", "Other")
assert(registrations == 2, "re-running the watcher must not re-register ScrollBox callbacks")
print("PASS Statistics styles recycled rows once")

for _, file in ipairs({"FFXIV_UI\\FFXIV_UI.toc", "FFXIV_UI\\FFXIV_UI_Camelot.toc"}) do
    local handle = assert(io.open(file, "r"))
    local toc = handle:read("*a")
    handle:close()
    assert(assert(toc:find("General/WindowControls.lua", 1, true)) < assert(toc:find("General/Statistics.lua", 1, true)),
        file .. " must load Statistics.lua after WindowControls.lua")
end
print("PASS Statistics.lua loads after the shared header and arrow styling in both TOCs")

local addonName, ns = ...
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local objects, methods, combat, timers = {}, {}, false, {}
local selectedTab = 1
local ns = {}

local function object(kind, parent)
    local value = setmetatable({kind = kind or "Frame", parent = parent, regions = {}, children = {}, scripts = {},
        points = {}, shown = true, alpha = 1, width = 40, height = 32, level = 5, id = 0},
        {__index = methods})
    objects[#objects + 1] = value
    if parent and (kind == "Texture" or kind == "FontString") then
        parent.regions[#parent.regions + 1] = value
    elseif parent then
        parent.children[#parent.children + 1] = value
    end
    return value
end

function CreateFrame(kind, _, parent)
    return object(kind, parent)
end
function methods:CreateTexture() return object("Texture", self) end
function methods:CreateFontString(_, _, template)
    local fontString = object("FontString", self)
    fontString.hasFont = template ~= nil
    return fontString
end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetChildren() return unpack(self.children) end
function methods:GetNumPoints() return #self.points end
function methods:GetPoint(index)
    local p = self.points[index or 1]
    if not p then return nil end
    return p[1], p[2], p[3], p[4], p[5]
end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(point, rel, relPoint, x, y)
    self.points[#self.points + 1] = {point, rel, relPoint or point, x or 0, y or 0}
end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetHeight(h) self.height = h end
function methods:SetWidth(w) self.width = w end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetID() return self.id end
function methods:GetText() return self.text end
function methods:SetText(t)
    if self.kind == "FontString" and not self.hasFont then error("FontString:SetText(): Font not set") end
    self.text = t
end
function methods:IsShown() return self.shown end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetShown(v) self.shown = v end
function methods:SetAlpha(a) self.alpha = a end
function methods:GetAlpha() return self.alpha end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetTexture(v) self.texture = v end
function methods:SetVertexColor() end
function methods:SetTextColor() end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetJustifyH() end
function methods:SetFont() self.hasFont = true end
function methods:GetFont() return "native", 12, "" end
function methods:SetAllPoints() end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetBackdropBorderColor() end
function methods:EnableMouse() end
function methods:SetFrameLevel(l) self.level = l end
function methods:GetFrameLevel() return self.level end
function methods:IsEnabled() return self.enabled ~= false end
function methods:GetFontString() return self.fontString end
function methods:HookScript(name, fn)
    if self.kind == "Frame" and name == "OnClick" then
        error("Frame:HookScript(): Cannot assign script handler for 'onclick' (script type not supported by this object)")
    end
    self.scripts[name] = fn
end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
function methods:UnregisterEvent() end
function methods:SetAlpha(a) self.alpha = a end
function methods:SetDrawLayer() end
function methods:SetBlendMode() end

function InCombatLockdown() return combat end
function hooksecurefunc(target, method, func)
    if type(target) == "string" then
        func = method
        local original = _G[target]
        _G[target] = function(...)
            local result = original(...)
            func(...)
            return result
        end
    elseif type(target) == "table" and type(target[method]) == "function" then
        local original = target[method]
        target[method] = function(...)
            original(...)
            func(...)
        end
    end
end
function PanelTemplates_GetSelectedTab(frame) return frame.selectedTab end
function PanelTemplates_SetTab(frame, id)
    selectedTab = id
    frame.selectedTab = id
end
function CollectionsJournal_GetTab(frame)
    if frame.TabContainer then return frame.TabContainer.selectedTab end
    return PanelTemplates_GetSelectedTab(frame)
end
function CollectionsJournal_SetTab(frame, id)
    if frame.TabContainer then
        frame.TabContainer.selectedTab = id
    else
        PanelTemplates_SetTab(frame, id)
    end
end
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
local function flushTimers()
    while #timers > 0 do table.remove(timers, 1)() end
end

local function fire(event)
    for _, frame in ipairs(objects) do
        if frame.events and frame.events[event] and frame.scripts.OnEvent then
            frame.scripts.OnEvent(frame, event)
        end
    end
end

local function assertEq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

ns.RoundWindow = function(frame) frame.rounded = true end
ns.SkinWindowClose = function(button) button.skinned = true end
ns.CreateExtractedTabArtwork = function(panel) return {panel = panel} end
ns.UpdateExtractedTabArtwork = function(art, selected) art.selected = selected end
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", ns)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", ns)
function ToggleCollectionsJournal() end
assert(loadfile("FFXIV_UI\\General\\Collections.lua"))("FFXIV_UI", ns)

local function makeTab(parent, id, name, kind)
    local tab = object(kind or "Button", parent)
    tab.id = id
    tab.tooltipText = name
    if kind ~= "Frame" then
        tab.fontString = tab:CreateFontString()
        tab.fontString.text = name
        tab.Text = tab.fontString
    end
    return tab
end

local function makeJournal(kind)
    local journal = object("Frame")
    journal.height = 606
    journal.width = 703
    journal.selectedTab = selectedTab
    journal.SetTab = function() end
    journal.TitleContainer = object("Frame", journal)
    journal.TitleContainer.TitleText = object("FontString", journal.TitleContainer)
    journal.TitleContainer.TitleText.text = "Collections"
    journal.NineSlice = object("Frame", journal)
    journal.PortraitContainer = object("Frame", journal)
    journal.CloseButton = object("Button", journal)
    object("Texture", journal.CloseButton)
    if kind == "forever" then
        journal.TabContainer = object("Frame", journal)
        journal.TabContainer.selectedTab = selectedTab
        journal.TabContainer.children = {}
        makeTab(journal.TabContainer, 1, "Mounts", "Frame")
        makeTab(journal.TabContainer, 2, "Pets", "Frame")
        makeTab(journal.TabContainer, 3, "Toys", "Frame")
        makeTab(journal.TabContainer, 4, "Heirlooms", "Frame")
        makeTab(journal.TabContainer, 5, "Appearances", "Frame")
    else
        journal.MountsTab = makeTab(journal, 1, "Mounts")
        journal.PetsTab = makeTab(journal, 2, "Pets")
        journal.ToysTab = makeTab(journal, 3, "Toys")
        journal.HeirloomsTab = makeTab(journal, 4, "Heirlooms")
        journal.WardrobeTab = makeTab(journal, 5, "Appearances")
        journal.WarbandScenesTab = makeTab(journal, 6, "Warband Scenes")
    end
    return journal
end

local function tabsOf(journal)
    local tabs = {}
    for _, child in ipairs({journal.TabContainer and journal.TabContainer:GetChildren()}) do tabs[#tabs + 1] = child end
    return tabs
end

local function tabList(journal)
    local tabs = {}
    if journal.MountsTab then
        for _, key in ipairs({"MountsTab", "PetsTab", "ToysTab", "HeirloomsTab", "WardrobeTab", "WarbandScenesTab"}) do
            tabs[#tabs + 1] = journal[key]
        end
    else
        tabs = {journal.TabContainer:GetChildren()}
    end
    return tabs
end

-- Test: Forever-style journal shell build
_G.CollectionsJournal = makeJournal("forever")
flushTimers()
fire("ADDON_LOADED")
flushTimers()
local journal = _G.CollectionsJournal

assertEq(journal.height, 606 + 36, "journal height grows by the tab row shift")
assertEq(journal.TitleContainer.TitleText.alpha, 0, "native title hidden")

local close = journal.CloseButton
assertEq(close.skinned, true, "close button skinned")
assertEq(close.width, 24, "close width")
assertEq(close.points[1][1], "TOPRIGHT", "close anchor point")
assertEq(close.points[1][4], -5, "close anchor x")
assertEq(close.points[1][5], -4, "close anchor y")

local tabs = tabList(journal)
assertEq(#tabs, 5, "forever tab count")
for index, tab in ipairs(tabs) do
    assertEq(tab.height, 30, "tab " .. index .. " height")
    assertEq(tab.points[1][1], "TOPLEFT", "tab " .. index .. " anchored TOPLEFT")
    if index > 1 then
        local step = tab.points[1][4] - tabs[index - 1].points[1][4]
        assertEq(step > 0, true, "tab " .. index .. " placed right of previous")
    end
end
assertEq(tabs[1].FFXIVUILabel.text, "Mounts", "forever tab label from tooltip name")
assertEq(tabs[5].FFXIVUILabel.text, "Appearances", "forever tab label from tooltip name")
assertEq(tabs[1].FFXIVUIArt.selected, true, "initial forever selected tab art on")
assertEq(tabs[2].FFXIVUIArt.selected, false, "initial forever inactive tab art off")

-- Test: hidden tab leaves no gap in the row
tabs[4]:Hide()
fire("ADDON_LOADED")
flushTimers()
assertEq(tabs[5].points[1][4], 3 * tabs[1].width, "hidden tab takes no row space")
tabs[4]:Show()
fire("ADDON_LOADED")
flushTimers()
assertEq(tabs[5].points[1][4], 4 * tabs[1].width, "restored tab returns to its slot")

-- Test: native close textures are hidden, the addon icon stays
assertEq(journal.CloseButton.regions[1].alpha, 0, "native close texture hidden")
assertEq(journal.CloseButton.skinned, true, "close button skinned")

-- Test: selected tab art
CollectionsJournal_SetTab(journal, 2)
flushTimers()
assertEq(tabs[2].FFXIVUIArt.selected, true, "selected tab art on")
assertEq(tabs[1].FFXIVUIArt.selected, false, "unselected tab art off")

-- Test: body content shifts once, and re-shifts only after a Blizzard reset
local body = object("Frame", journal)
body:SetPoint("TOP", journal, "TOP", 0, -40)
fire("ADDON_LOADED")
flushTimers()
assertEq(body.points[1][5], -76, "body shifted by row height")
fire("ADDON_LOADED")
flushTimers()
assertEq(body.points[1][5], -76, "repeat refresh does not double shift")
body:ClearAllPoints()
body:SetPoint("TOP", journal, "TOP", 0, -40)
fire("ADDON_LOADED")
flushTimers()
assertEq(body.points[1][5], -76, "blizzard reset re-shifted once")

-- Test: combat defers geometry until PLAYER_REGEN_ENABLED
local second = makeJournal("retail")
second.SetTab = function() end
combat = true
_G.CollectionsJournal = second
fire("ADDON_LOADED")
flushTimers()
assertEq(second.height, 606, "no geometry in combat")
assertEq(second.MountsTab.points[1] == nil, true, "no tab anchors in combat")
combat = false
fire("PLAYER_REGEN_ENABLED")
flushTimers()
assertEq(second.height, 606 + 36, "pending geometry applied after combat")
assertEq(second.MountsTab.points[1][1], "TOPLEFT", "retail named tab anchored after combat")
assertEq(#tabList(second), 6, "retail named tab count")
assertEq(second.MountsTab.FFXIVUIArt.selected, true, "initial retail selected tab art on")
CollectionsJournal_SetTab(second, 2)
flushTimers()
assertEq(second.PetsTab.FFXIVUIArt.selected, true, "retail selected tab updates")
assertEq(second.MountsTab.FFXIVUIArt.selected, false, "retail previous tab becomes inactive")

-- Test: journal swap rebuilds the shell
assertEq(journal.height, 606 + 36, "old journal left untouched by swap")

-- Test: a journal created on demand is built when the open path runs
local late = makeJournal("forever")
_G.CollectionsJournal = late
ToggleCollectionsJournal()
flushTimers()
assertEq(late.height, 606 + 36, "on-demand journal built from the open hook")
assertEq(late.TitleContainer.TitleText.alpha, 0, "on-demand native title hidden")

print("Collections tests passed")

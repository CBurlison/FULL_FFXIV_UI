local addonName, ns = ...
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local objects, methods, combat, timers = {}, {}, false, {}
local mountSelectCalls = {}
local pickupCalls = {}
local MOUNT_COUNT = 93
local SELECTED_MOUNT = 1003
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
function methods:CreateFontString() return object("FontString", self) end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetChildren() return unpack(self.children) end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(point, rel, relPoint, x, y)
    self.points[#self.points + 1] = {point, rel, relPoint or point, x or 0, y or 0}
end
function methods:SetAllPoints() end
function methods:GetText() return self.text or "" end
function methods:SetText(text)
    self.text = text
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetHeight(h) self.height = h end
function methods:SetWidth(w) self.width = w end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:IsShown() return self.shown end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetShown(v) self.shown = v end
function methods:SetAlpha(a) self.alpha = a end
function methods:GetAlpha() return self.alpha end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetVertexColor(...) self.vertexColor = {...} end
function methods:SetTexture(v) self.texture = v end
function methods:SetDesaturated(v) self.desaturated = v end
function methods:SetChecked(v) self.checked = v and true or false end
function methods:GetChecked() return self.checked end
function methods:SetFrameLevel(l) self.level = l end
function methods:GetFrameLevel() return self.level end
function methods:EnableMouse() end
function methods:EnableMouseWheel(v) self.wheel = v end
function methods:SetScrollChild(child) self.scrollChild = child end
function methods:SetVerticalScroll(v) self.verticalScroll = v end
function methods:GetVerticalScroll() return self.verticalScroll or 0 end
function methods:HookScript(name, fn) self.scripts[name] = fn end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
function methods:RegisterForDrag(...) self.dragButtons = {...} end
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

C_MountJournal = {
    GetNumDisplayedMounts = function() return MOUNT_COUNT end,
    GetDisplayedMountInfo = function(index)
        local collected = index % 2 == 1
        return "Mount " .. index, 100 + index, 5000 + index, false, true, 1, false, false, 0, false,
            collected, 1000 + index
    end,
}
C_MountJournal.Pickup = function(index) pickupCalls[#pickupCalls + 1] = index end
function MountJournal_Select(index) mountSelectCalls[#mountSelectCalls + 1] = index end

ns.ApplyButtonSkin = function(button, parts, style)
    button.skinStyle = style
    button.skinIcon = parts.Icon
end
ns.StyleEditBox = function(box) box.styled = true end
ns.RoundWindow = function(frame) frame.rounded = true end
ns.SkinWindowClose = function(button) button.skinned = true end
ns.CreateExtractedTabArtwork = function(panel) return {panel = panel} end
ns.UpdateExtractedTabArtwork = function(art, selected) art.selected = selected end
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", ns)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", ns)
function ToggleCollectionsJournal() end
assert(loadfile("FFXIV_UI\\General\\Mounts.lua"))("FFXIV_UI", ns)

local function makeJournal()
    local journal = object("Frame")
    journal.TitleContainer = object("Frame", journal)
    journal.TitleContainer.TitleText = object("FontString", journal.TitleContainer)
    journal.TitleContainer.TitleText.text = "Collections"
    journal.CloseButton = object("Button", journal)
    local mj = object("Frame", journal)
    mj.selectedMountID = SELECTED_MOUNT
    mj.ScrollBox = object("Frame", mj)
    mj.ScrollBar = object("Frame", mj)
    mj.LeftInset = object("Frame", mj)
    object("Texture", mj.LeftInset)
    mj.LeftInset.NineSlice = object("Frame", mj.LeftInset)
    mj.RightInset = object("Frame", mj)
    object("Texture", mj.RightInset)
    mj.RightInset.NineSlice = object("Frame", mj.RightInset)
    mj.MountDisplay = object("Frame", mj)
    mj.MountDisplay.ModelScene = object("Frame", mj.MountDisplay)
    mj.searchBox = object("EditBox", mj)
    _G.MountJournal = mj
    return journal, mj
end

local function gridOf(mj)
    for _, child in ipairs({mj:GetChildren()}) do
        if child.kind == "ScrollFrame" then return child end
    end
end

local function cellsOf(scroll)
    local cells = {}
    for _, child in ipairs({scroll.scrollChild:GetChildren()}) do
        if child.kind == "CheckButton" then cells[#cells + 1] = child end
    end
    return cells
end

-- Test: combat defers the grid build
combat = true
_G.CollectionsJournal = (makeJournal())
fire("ADDON_LOADED")
flushTimers()
assertEq(gridOf(_G.MountJournal), nil, "no grid built in combat")
combat = false
fire("PLAYER_REGEN_ENABLED")
flushTimers()

local journal, mj = makeJournal()
_G.CollectionsJournal = journal
fire("ADDON_LOADED")
flushTimers()

local scroll = gridOf(mj)
assertEq(scroll ~= nil, true, "grid scroll frame built")
assertEq(scroll.wheel, true, "mouse wheel enabled")

-- Test: native list and bar are hidden, insets are cleared
assertEq(mj.ScrollBox.shown, false, "native ScrollBox hidden")
assertEq(mj.ScrollBar.shown, false, "native ScrollBar hidden")
assertEq(mj.LeftInset.regions[1].alpha, 0, "left inset texture hidden")
assertEq(mj.RightInset.regions[1].alpha, 0, "right inset texture hidden")
assertEq(mj.LeftInset.NineSlice.shown, false, "left inset frame border hidden")
assertEq(mj.RightInset.NineSlice.shown, false, "right inset frame border hidden")
assertEq(mj.MountDisplay.ModelScene.shown, true, "model scene kept")

-- Test: Blizzard re-showing the native list is undone immediately
mj.ScrollBox:Show()
mj.ScrollBox.scripts.OnShow(mj.ScrollBox)
assertEq(mj.ScrollBox.shown, false, "native ScrollBox re-hidden on show")
mj.ScrollBar:Show()
mj.ScrollBar.scripts.OnShow(mj.ScrollBar)
assertEq(mj.ScrollBar.shown, false, "native ScrollBar re-hidden on show")
mj.LeftInset.NineSlice:Show()
fire("ADDON_LOADED")
flushTimers()
assertEq(mj.LeftInset.NineSlice.shown, false, "border re-hidden on refresh")
assertEq(mj.ScrollBox.shown, false, "native ScrollBox stays hidden on refresh")
assertEq(mj.searchBox.styled, true, "search box styled")

-- Test: one cell per displayed mount, 46px icons, no text
local cells = cellsOf(scroll)
assertEq(#cells, MOUNT_COUNT, "one cell per displayed mount")
for index, cell in ipairs(cells) do
    assertEq(cell.width, 46, "cell " .. index .. " width")
    assertEq(cell.height, 46, "cell " .. index .. " height")
    assertEq(cell.skinStyle, "Equipment", "cell " .. index .. " uses the action-button skin")
    for _, child in ipairs({cell:GetChildren()}) do
        error("cell " .. index .. " has an unexpected child frame")
    end
    for _, region in ipairs(cell.regions) do
        assertEq(region.kind, "Texture", "cell " .. index .. " has only textures")
    end
end

-- Test: positions follow the 5-wide grid with 4px / 6px gaps
local x, y = ns.MountGridPosition(1)
assertEq(x, 0, "cell 1 x")
assertEq(y, 0, "cell 1 y")
x, y = ns.MountGridPosition(2)
assertEq(x, 50, "cell 2 x")
assertEq(y, 0, "cell 2 y")
x, y = ns.MountGridPosition(6)
assertEq(x, 0, "cell 6 wraps to column 1")
assertEq(y, -52, "cell 6 row 2")
x, y = ns.MountGridPosition(93)
assertEq(x, 2 * 50, "cell 93 column 3")
assertEq(y, -18 * 52, "cell 93 row 19")
assertEq(cells[2].points[1][4], 50, "cell 2 placed at column step")
assertEq(cells[6].points[1][5], -52, "cell 6 placed at row step")

-- Test: icons, desaturation and selection
assertEq(cells[1].Icon.texture, 5001, "cell 1 icon")
assertEq(cells[1].Icon.desaturated, false, "owned mount in colour")
assertEq(cells[2].Icon.desaturated, true, "unowned mount desaturated")
assertEq(cells[3].checked, true, "selected mount checked")
assertEq(cells[4].checked, false, "other mounts unchecked")

-- Test: search refresh hides cells whose mount names do not match
mj.searchBox:SetText("MOUNT 93")
assertEq(cells[93].shown, true, "case-insensitive mount-name match stays visible")
assertEq(cells[1].shown, false, "non-matching mount is hidden")
mj.searchBox:SetText("")
assertEq(cells[1].shown, true, "clearing search shows all mounts")

-- Test: hovering shows the mount name and collection state; leaving hides it
GameTooltip = {log = {}}
function GameTooltip:SetOwner(owner, anchor) self.log[#self.log + 1] = {"owner", owner, anchor} end
function GameTooltip:SetText(text) self.log[#self.log + 1] = {"text", text} end
function GameTooltip:SetSpellByID(id) self.log[#self.log + 1] = {"spell", id} end
function GameTooltip:AddLine(text) self.log[#self.log + 1] = {"line", text} end
function GameTooltip:Show() self.shown = true end
function GameTooltip:Hide() self.shown = false end
cells[8].scripts.OnEnter(cells[8])
assertEq(GameTooltip.shown, true, "tooltip shown on hover")
assertEq(GameTooltip.log[2][1], "spell", "tooltip uses the native spell tooltip")
assertEq(GameTooltip.log[2][2], 108, "tooltip uses the mount's spell id")
assertEq(GameTooltip.log[3][2], "Not collected", "tooltip shows not collected for even index")
cells[8].scripts.OnLeave(cells[8])
assertEq(GameTooltip.shown, false, "tooltip hidden on leave")

-- Test: cells can be dragged onto action bars via the native pickup
assertEq(cells[5].dragButtons[1], "LeftButton", "cells register left-button drag")
cells[5].scripts.OnDragStart(cells[5])
assertEq(pickupCalls[#pickupCalls], 5, "drag picks up the displayed mount index")

-- Test: clicking selects the displayed index
cells[7].scripts.OnClick(cells[7])
assertEq(mountSelectCalls[#mountSelectCalls], 7, "click selects displayed index")

-- Test: wheel scroll is clamped to the content range
scroll.height = 400
local content = scroll.scrollChild
assertEq(content.height, 19 * 52 - 6, "content height covers all rows")
scroll.scripts.OnMouseWheel(scroll, -1)
scroll.scripts.OnMouseWheel(scroll, -1)
scroll.scripts.OnMouseWheel(scroll, -1)
assertEq(scroll.verticalScroll, 3 * 52, "wheel scrolls one row per notch")
scroll.scripts.OnMouseWheel(scroll, -100)
assertEq(scroll.verticalScroll, content.height - 400, "wheel clamps at bottom")
scroll.scripts.OnMouseWheel(scroll, 100)
assertEq(scroll.verticalScroll, 0, "wheel clamps at top")

-- Test: the divider uses the shared theme
local dividerFound = false
for _, region in ipairs(mj.regions) do
    if region.color and region.color[4] == 0.85 then dividerFound = true end
end
assertEq(dividerFound, true, "divider styled by theme")

print("Mounts tests passed")

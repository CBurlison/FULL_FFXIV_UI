local addonName, ns = ...

-- Forever only (build 16001): the Camelot TokenFrame (Currency tab) from load-on-demand Blizzard_TokenUI.
-- Top-level headers use the Forever ComboBox header; currency rows and sub-headers stay native.
-- The native header height (26) already matches the ComboBox header, so no extent calculator is set.
local installed = false

local function StyleEntry(frame)
    if frame.Name and frame.StateIcon and ns.StyleForeverCollapsibleHeader then
        ns.StyleForeverCollapsibleHeader(frame)
    end
end

local function Install()
    local box = _G.TokenFrame and _G.TokenFrame.ScrollBox
    if installed or not box or type(box.ForEachFrame) ~= "function" then return end
    installed = true
    if ns.StyleListScrollBar then ns.StyleListScrollBar(_G.TokenFrame) end
    local owner = {}
    local events = ScrollBoxListMixin and ScrollBoxListMixin.Event
    local function StyleAll() box:ForEachFrame(StyleEntry) end
    if events and events.OnInitializedFrame then
        box:RegisterCallback(events.OnInitializedFrame, function(_, frame) StyleEntry(frame) end, owner)
    end
    if events and events.OnDataRangeChanged then
        box:RegisterCallback(events.OnDataRangeChanged, StyleAll, owner)
    end
    StyleAll()
end

local function StyleDetail()
    local frame = _G.TokenFrame and _G.TokenFrame.DetailFrame
    if frame and ns.StyleDetailPanel then ns.StyleDetailPanel(frame) end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:SetScript("OnEvent", function()
    if select(4, GetBuildInfo()) ~= 16001 then return end
    StyleDetail()
    Install()
end)

local addonName, ns = ...

-- Forever only (build 16001): Blizzard_Statistics (Camelot/StatisticsFrame.xml), a tree list of
-- top-level headers (StatisticsHeaderTemplate), sub-headers (StatisticsSubHeaderTemplate) and entries.
-- Headers use the Forever ComboBox header (its art carries the arrow, D4). Each sub-header's native
-- campaign +/- toggle is replaced by the circle arrow: right when collapsed, down when expanded (Req 7).
-- Native header height (26) already matches the ComboBox header, so no extent calculator is set.
local installed = false

local function ArrowDirection(toggle)
    local header = toggle:GetParent()
    local node = header and header.treeNode
    return node and node:IsCollapsed() and "right" or "down"
end

local function StyleToggle(toggle)
    if toggle.FFXIVUIStatisticsToggle then
        ns.StyleCircularArrowButton(toggle, ArrowDirection(toggle))
        return
    end
    toggle.FFXIVUIStatisticsToggle = true
    -- RefreshIcon only swaps atlases, so zero alpha on the native textures persists.
    for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetHighlightTexture"}) do
        local texture = toggle[getter] and toggle[getter](toggle)
        if texture then texture:SetAlpha(0) end
    end
    ns.StyleCircularArrowButton(toggle, ArrowDirection(toggle))
    hooksecurefunc(toggle, "RefreshIcon", function(self)
        ns.StyleCircularArrowButton(self, ArrowDirection(self))
    end)
end

local function StyleEntry(frame)
    if frame.Name and frame.StateIcon then
        if ns.StyleForeverCollapsibleHeader then ns.StyleForeverCollapsibleHeader(frame) end
        return
    end
    local toggle = frame.ToggleCollapseButton
    if toggle and type(toggle.RefreshIcon) == "function" and ns.StyleCircularArrowButton then
        StyleToggle(toggle)
    end
end

local function Install()
    local box = _G.StatisticsFrame and _G.StatisticsFrame.ScrollBox
    if installed or not box or type(box.ForEachFrame) ~= "function" then return end
    installed = true
    if ns.StyleListScrollBar then ns.StyleListScrollBar(_G.StatisticsFrame) end
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

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:SetScript("OnEvent", function()
    if select(4, GetBuildInfo()) ~= 16001 then return end
    Install()
end)

local addonName, ns = ...
local addonEnv = ns
local Themes = addonEnv.Themes
local Skin = addonEnv.Skin

local HEADER_TEMPLATE = "FFXIV_SpellbookHeaderTemplate"
local TITLE_TEMPLATE = "FFXIV_SpellbookHeaderTitleTemplate"
local DIVIDER_TEMPLATE = "FFXIV_SpellbookHeaderDividerTemplate"
local TAB_HEIGHT = 30
local TAB_GAP = 6
local SHIFT = TAB_HEIGHT + TAB_GAP
local MARGIN = 8
local TAB_KEYS = {"MountsTab", "PetsTab", "ToysTab", "HeirloomsTab", "WardrobeTab", "WarbandScenesTab"}
local CHROME_KEYS = {"NineSlice", "PortraitContainer", "TitleContainer"}
local TOP_POINTS = {TOP = true, TOPLEFT = true, TOPRIGHT = true}

local shell, pending, queued
local Queue

local function FindTabs(journal)
    local tabs = {}
    for _, key in ipairs(TAB_KEYS) do
        if journal[key] then tabs[#tabs + 1] = journal[key] end
    end
    if #tabs == 0 and journal.TabContainer then
        for _, child in ipairs({journal.TabContainer:GetChildren()}) do
            if child.SetPoint and child.GetObjectType and child.SetSize then tabs[#tabs + 1] = child end
        end
    end
    return tabs
end

local function HideTabArt(owner, depth)
    for _, region in ipairs({owner:GetRegions()}) do
        if region:GetObjectType() == "Texture" then Skin.KeepHidden(region) end
    end
    if depth <= 0 then return end
    for _, child in ipairs({owner:GetChildren()}) do HideTabArt(child, depth - 1) end
end

local function UpdateTab(state, tab, selected)
    local disabled = tab.IsEnabled and not tab:IsEnabled()
    addonEnv.UpdateExtractedTabArtwork(tab.FFXIVUIArt, selected, state.hovered[tab], disabled)
    local native = state.natives[tab]
    tab.FFXIVUILabel:SetText(native and native:GetText() or tab.tooltipText or "")
    Skin.Text(tab.FFXIVUILabel, selected and "text" or "tabText", 12)
end

local function SkinTab(state, tab)
    HideTabArt(tab, 2)
    local native = tab.GetFontString and tab:GetFontString() or tab.Text
    state.natives[tab] = native
    Skin.Hide(native)
    tab.FFXIVUIArt = addonEnv.CreateExtractedTabArtwork(tab)
    local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", tab, "CENTER", 0, 0)
    tab.FFXIVUILabel = label
    state.hovered[tab] = false
    state.owned[tab] = true
    tab:HookScript("OnShow", function() Queue() end)
    tab:HookScript("OnHide", function() Queue() end)
    tab:HookScript("OnEnter", function()
        state.hovered[tab] = true
        UpdateTab(state, tab, state.selected[tab])
    end)
    tab:HookScript("OnLeave", function()
        state.hovered[tab] = false
        UpdateTab(state, tab, state.selected[tab])
    end)
end

local function ReadPoints(frame)
    local points = {}
    for index = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(index)
        points[index] = {point, relativeTo, relativePoint, x or 0, y or 0}
    end
    return points
end

local function SamePoints(a, b)
    if not a or not b or #a ~= #b then return false end
    for index = 1, #a do
        for field = 1, 5 do
            if a[index][field] ~= b[index][field] then return false end
        end
    end
    return true
end

-- Returns the points with top anchors to the journal moved up by the row height, or nil when none move.
local function Shifted(points, journal)
    local result, moved = {}, false
    for index, point in ipairs(points) do
        local shift = point[2] == journal and TOP_POINTS[point[1]]
        if shift then moved = true end
        result[index] = {point[1], point[2], point[3], point[4], point[5] - (shift and SHIFT or 0)}
    end
    return moved and result or nil
end

local function ApplyPoints(frame, points)
    frame:ClearAllPoints()
    for _, point in ipairs(points) do frame:SetPoint(point[1], point[2], point[3], point[4], point[5]) end
end

-- Blizzard may reset a child's points on tab changes, so each pass compares against what was last written.
local function ShiftContent(state)
    local journal = state.journal
    for _, child in ipairs({journal:GetChildren()}) do
        if not state.owned[child] then
            local current = ReadPoints(child)
            local record = state.content[child]
            if not (record and SamePoints(current, record.written)) then
                local written = Shifted(current, journal)
                if written then ApplyPoints(child, written) end
                state.content[child] = {written = written or current}
            end
        end
    end
end

local function LayoutTabs(state)
    local visible = {}
    for _, tab in ipairs(state.tabs) do
        if tab:IsShown() then visible[#visible + 1] = tab end
    end
    local count = #visible
    if count == 0 then return end
    local width = state.row:GetWidth()
    if not width or width <= 0 then width = state.journal:GetWidth() - MARGIN * 2 end
    local tabWidth = width / count
    for index, tab in ipairs(visible) do
        tab:ClearAllPoints()
        tab:SetSize(tabWidth, TAB_HEIGHT)
        tab:SetPoint("TOPLEFT", state.row, "TOPLEFT", (index - 1) * tabWidth, 0)
    end
end

local function UpdateTabs(state)
    local journal = state.journal
    local tabContainer = journal.TabContainer
    local tabOwner = tabContainer or journal
    local selectedId = type(CollectionsJournal_GetTab) == "function" and CollectionsJournal_GetTab(journal)
        or type(PanelTemplates_GetSelectedTab) == "function" and PanelTemplates_GetSelectedTab(tabOwner)
        or (tabContainer and tabContainer.selectedTab)
        or journal.selectedTab
    for index, tab in ipairs(state.tabs) do
        local id = tab.GetID and tab:GetID() or index
        state.selected[tab] = id == selectedId
        UpdateTab(state, tab, state.selected[tab])
    end
end

local function Geometry(state)
    local journal = state.journal
    LayoutTabs(state)
    if state.close then
        state.close:SetSize(24, 24)
        state.close:ClearAllPoints()
        state.close:SetPoint("TOPRIGHT", journal, "TOPRIGHT", -5, -4)
    end
    local height = journal:GetHeight()
    if state.heightWritten == nil or height ~= state.heightWritten then
        state.heightWritten = height + SHIFT
        journal:SetHeight(state.heightWritten)
    end
    ShiftContent(state)
end

local Refresh

Queue = function()
    if queued or not (C_Timer and C_Timer.After) then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        Refresh()
    end)
end

local function Build(journal)
    local state = {journal = journal, tabs = {}, hovered = {}, selected = {}, natives = {}, content = {}, owned = {}}
    shell = state

    Skin.HideTextures(journal)
    for _, key in ipairs(CHROME_KEYS) do
        local region = journal[key]
        if region then Skin.HideArt(region, true) end
    end
    local panel = Skin.Panel(journal, "surface")
    addonEnv.RoundWindow(panel, true)
    state.owned[panel] = true

    local title = journal.TitleContainer and journal.TitleContainer.TitleText or journal.TitleText
    Skin.Hide(title)
    local header = CreateFrame("Frame", nil, journal, HEADER_TEMPLATE)
    header:EnableMouse(false)
    local label = header:CreateFontString(nil, "OVERLAY", TITLE_TEMPLATE)
    Skin.Text(label, "text", 18)
    local divider = header:CreateTexture(nil, "BACKGROUND", DIVIDER_TEMPLATE)
    Themes.StyleDivider(divider, header)
    state.header, state.label, state.owned[header] = header, label, true

    local row = CreateFrame("Frame", nil, journal)
    row:EnableMouse(false)
    row:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -TAB_GAP)
    row:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -TAB_GAP)
    row:SetHeight(TAB_HEIGHT)
    state.row, state.owned[row] = row, true

    state.close = journal.CloseButton
    if state.close then
        addonEnv.SkinWindowClose(state.close)
        Skin.HideTextures(state.close, state.close.FFXIVUICloseIcon)
        state.owned[state.close] = true
    end

    state.tabs = FindTabs(journal)
    for _, tab in ipairs(state.tabs) do SkinTab(state, tab) end

    journal:HookScript("OnShow", function() Refresh() Queue() end)
    Skin.Hook(journal, "SetTab", Refresh)
    if type(PanelTemplates_SetTab) == "function" then
        hooksecurefunc("PanelTemplates_SetTab", function(frame)
            if frame == journal then Refresh() Queue() end
        end)
    end
    if journal.TabContainer and type(CollectionsJournal_SetTab) == "function" then
        hooksecurefunc("CollectionsJournal_SetTab", function(frame)
            if frame == journal then Refresh() Queue() end
        end)
    end
    return state
end

Refresh = function()
    local journal = _G.CollectionsJournal
    if not journal then return end
    if InCombatLockdown() then
        pending = true
        return
    end
    if not shell or shell.journal ~= journal then Build(journal) end
    pending = false
    Geometry(shell)
    UpdateTabs(shell)
    shell.label:SetText(journal.TitleContainer and journal.TitleContainer.TitleText
        and journal.TitleContainer.TitleText:GetText() or "")
end

Themes.Register(function()
    if shell then UpdateTabs(shell) end
end)

local handlers = {
    ADDON_LOADED = Refresh,
    PLAYER_LOGIN = Refresh,
    PLAYER_REGEN_ENABLED = function() if pending then Refresh() end end,
}
local watcher = CreateFrame("Frame")
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(_, event)
    local handler = handlers[event]
    if handler then handler() end
end)
for _, name in ipairs({"CollectionsJournal_LoadUI", "ToggleCollectionsJournal"}) do
    if type(_G[name]) == "function" then hooksecurefunc(name, Refresh) end
end
Refresh()

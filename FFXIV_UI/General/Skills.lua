local addonName, ns = ...

-- Forever only (build 16001): the Camelot SkillsFrame. Retail has no Skills tab.
local ProgressBars = ns.ProgressBars
local ENTRY_EXTENT, HEADER_EXTENT = 56, 26
local installed = false

local function IsForever()
    return select(4, GetBuildInfo()) == 16001
end

-- Skill rows show only the progress number below the track, left-aligned; skills have no named rank.
local function StyleEntry(frame)
    if frame.Name and frame.StateIcon then
        if ns.StyleForeverCollapsibleHeader then ns.StyleForeverCollapsibleHeader(frame) end
        return
    end
    local content, bar = frame.Content, frame.Content and frame.Content.SkillsBar
    if not content or not bar then return end

    if not frame.FFXIVUISkillStyled then
        frame.FFXIVUISkillStyled = true
        ProgressBars.Skin(bar)
        ProgressBars.Font(content.Name, 14)
        local toggle = frame.ToggleCollapseButton
        if toggle then
            toggle:ClearAllPoints()
            toggle:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -1)
        end
    end

    ProgressBars.LayoutRow(content, bar, frame.ToggleCollapseButton and 30 or 8, false)
end

-- Sub-headers inherit SkillsEntryTemplate and keep their bar, so they use the entry extent.
local function Extent(_, elementData)
    if elementData.isHeader and not elementData.isChild then return HEADER_EXTENT end
    return ENTRY_EXTENT
end

local function Install()
    local page = _G.SkillsFrame
    local box = page and page.ScrollBox
    local view = box and type(box.GetView) == "function" and box:GetView()
    if installed or not view or type(view.SetElementExtentCalculator) ~= "function" then return end
    installed = true
    if ns.StyleListScrollBar then ns.StyleListScrollBar(page) end
    view:SetElementExtentCalculator(Extent)
    local owner = {}
    local events = ScrollBoxListMixin and ScrollBoxListMixin.Event
    local function StyleAll() box:ForEachFrame(StyleEntry) end
    if events and events.OnInitializedFrame then
        box:RegisterCallback(events.OnInitializedFrame, function(_, frame) StyleEntry(frame) end, owner)
    end
    if events and events.OnDataRangeChanged then
        box:RegisterCallback(events.OnDataRangeChanged, StyleAll, owner)
    end
    if ScrollBoxConstants and type(box.FullUpdate) == "function" then
        box:FullUpdate(ScrollBoxConstants.UpdateImmediately)
    end
    StyleAll()
end

local function StyleDetail()
    local frame = _G.SkillsFrame and _G.SkillsFrame.SkillDetailFrame
    if not frame then return end
    if ns.StyleDetailPanel then ns.StyleDetailPanel(frame) end
    ProgressBars.StyleDetailBar(frame, frame.RankBar)
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:SetScript("OnEvent", function()
    if not IsForever() then return end
    StyleDetail()
    Install()
end)

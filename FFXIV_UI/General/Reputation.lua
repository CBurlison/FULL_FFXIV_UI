local addonName, ns = ...

local ProgressBars = ns.ProgressBars
local ENTRY_EXTENT, HEADER_EXTENT, SUBHEADER_EXTENT = 56, 26, 22
local installed = false

local function StyleEntry(frame)
    if frame.Name and frame.StateIcon then
        if ns.StyleForeverCollapsibleHeader then ns.StyleForeverCollapsibleHeader(frame) end
        return
    end
    local content, bar = frame.Content, frame.Content and frame.Content.ReputationBar
    if not content or not bar then return end

    if not frame.FFXIVUIReputationStyled then
        frame.FFXIVUIReputationStyled = true
        ProgressBars.Skin(bar)
        ProgressBars.Font(content.Name, 14)
        local toggle = frame.ToggleCollapseButton
        if toggle then
            toggle:ClearAllPoints()
            toggle:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -1)
        end
        local icon = content.AccountWideIcon
        icon:ClearAllPoints()
        icon:SetPoint("TOPRIGHT", content, "TOPRIGHT", -2, -1)
    end

    ProgressBars.LayoutRow(content, bar, frame.ToggleCollapseButton and 30 or 8, true)
end
local function Extent(_, elementData)
    if not elementData.isHeader then return ENTRY_EXTENT end
    if not elementData.isChild then return HEADER_EXTENT end
    return elementData.isHeaderWithRep and ENTRY_EXTENT or SUBHEADER_EXTENT
end

local function Install()
    local page = _G.ReputationFrame
    local box = page and page.ScrollBox
    local view = box and type(box.GetView) == "function" and box:GetView()
    if installed or not view or type(view.SetElementExtentCalculator) ~= "function" then return end
    installed = true
    if ns.StyleListScrollBar then ns.StyleListScrollBar(page) end
    view:SetElementExtentCalculator(Extent)
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

-- Restyles CheckButtons directly under the panel or one frame deeper (At War, Move to Inactive, Show as Experience Bar).
local function StyleDetailCheckButtons(parent, depth)
    for _, child in ipairs({parent:GetChildren()}) do
        if child:GetObjectType() == "CheckButton" then
            if ns.StyleCheckButton then ns.StyleCheckButton(child) end
        elseif depth > 0 then
            StyleDetailCheckButtons(child, depth - 1)
        end
    end
end

-- Forever only: Retail keeps its own expanded-frame look.
local function StyleDetail()
    local frame = _G.ReputationFrame and _G.ReputationFrame.ReputationDetailFrame
    if frame and select(4, GetBuildInfo()) == 16001 then
        if ns.StyleDetailPanel then ns.StyleDetailPanel(frame) end
        ProgressBars.StyleDetailBar(frame, frame.StandingBar)
        StyleDetailCheckButtons(frame, 1)
        if not frame.FFXIVUICheckButtonsHook then
            frame.FFXIVUICheckButtonsHook = true
            frame:HookScript("OnShow", function() StyleDetailCheckButtons(frame, 1) end)
        end
    end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("ADDON_LOADED")
watcher:SetScript("OnEvent", function(...)
    StyleDetail()
    Install()
end)

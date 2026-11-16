local addonName, ns = ...
local addonEnv = ns
local Themes = addonEnv.Themes
local Skin = addonEnv.Skin

local COLUMNS = 5
local CELL = 46
local GAP_X = 4
local GAP_Y = 6
local STEP_X = CELL + GAP_X
local STEP_Y = CELL + GAP_Y
local MARGIN = 6
local SEARCH_PROMPT_SIZE = 11

local grid, pending
local Refresh

function addonEnv.MountGridPosition(index)
    local zero = index - 1
    local column = zero % COLUMNS
    local row = math.floor(zero / COLUMNS)
    return column * STEP_X, -row * STEP_Y
end

local function ScrollGrid(g, delta)
    local range = math.max(0, g.content:GetHeight() - g.scroll:GetHeight())
    local target = g.scroll:GetVerticalScroll() - delta * STEP_Y
    g.scroll:SetVerticalScroll(math.min(math.max(target, 0), range))
end

local function ShowTooltip(cell)
    local name, spellID, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetDisplayedMountInfo(cell.index)
    if not name then return end
    GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
    if spellID then
        GameTooltip:SetSpellByID(spellID)
    else
        GameTooltip:SetText(name)
    end
    if not isCollected then
        GameTooltip:AddLine(NOT_COLLECTED or "Not collected", 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

local function MakeCell(g, index)
    local cell = CreateFrame("CheckButton", nil, g.content)
    cell:SetSize(CELL, CELL)
    local x, y = addonEnv.MountGridPosition(index)
    cell:SetPoint("TOPLEFT", g.content, "TOPLEFT", x, y)
    cell.Icon = cell:CreateTexture(nil, "ARTWORK")
    cell.Icon:SetAllPoints()
    addonEnv.ApplyButtonSkin(cell, {Icon = cell.Icon}, "Equipment")
    cell:SetScript("OnClick", function() MountJournal_Select(cell.index) end)
    cell:RegisterForDrag("LeftButton")
    cell:SetScript("OnDragStart", function() C_MountJournal.Pickup(cell.index) end)
    cell:SetScript("OnEnter", ShowTooltip)
    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return cell
end

local hooked = setmetatable({}, {__mode = "k"})

local function HideNative(mj)
    for _, key in ipairs({"ScrollBox", "ScrollBar"}) do
        local frame = mj[key]
        if frame then
            frame:Hide()
            if not hooked[frame] then
                hooked[frame] = true
                frame:HookScript("OnShow", function(self) self:Hide() end)
            end
        end
    end
    for _, key in ipairs({"LeftInset", "RightInset"}) do
        local inset = mj[key]
        if inset then
            Skin.HideTextures(inset)
            if inset.NineSlice then inset.NineSlice:Hide() end
        end
    end
end

local function Build(mj)
    if grid and grid.journal == mj then return grid end

    if mj.searchBox then
        addonEnv.StyleEditBox(mj.searchBox, SEARCH_PROMPT_SIZE)
        mj.searchBox:HookScript("OnTextChanged", function(self, _) Refresh() end)
    end
    if not hooked[mj] then
        hooked[mj] = true
        mj:HookScript("OnShow", function() Refresh() end)
    end

    local divider = mj:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", mj.RightInset, "TOPLEFT", 0, 0)
    divider:SetPoint("BOTTOMLEFT", mj.RightInset, "BOTTOMLEFT", 0, 0)
    Themes.StyleDivider(divider, mj, "ARTWORK", 0, true)

    local scroll = CreateFrame("ScrollFrame", nil, mj)
    local anchor, anchorPoint = mj.LeftInset, "TOPLEFT"
    if mj.searchBox then anchor, anchorPoint = mj.searchBox, "BOTTOMLEFT" end
    scroll:SetPoint("TOPLEFT", anchor, anchorPoint, MARGIN, -MARGIN)
    scroll:SetPoint("BOTTOMRIGHT", mj.LeftInset, "BOTTOMRIGHT", -MARGIN, MARGIN)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    scroll:SetScrollChild(content)

    grid = {journal = mj, scroll = scroll, content = content, cells = {}}
    scroll:SetScript("OnMouseWheel", function(_, delta) ScrollGrid(grid, delta) end)
    return grid
end

local function UpdateCells(mj, g)
    local count = C_MountJournal.GetNumDisplayedMounts()
    local selected = mj.selectedMountID
    local searchText = mj.searchBox and mj.searchBox:GetText() or ""
    searchText = searchText:lower()
    for index = 1, count do
        local cell = g.cells[index] or MakeCell(g, index)
        g.cells[index] = cell
        cell.index = index
        local name, _, icon, _, isUsable, _, _, _, _, _, isCollected, mountID = C_MountJournal.GetDisplayedMountInfo(index)
        cell.Icon:SetTexture(icon)
        cell.Icon:SetDesaturated(not isCollected)
        cell.Icon:SetVertexColor(isUsable and 1 or 0.9, isUsable and 1 or 0.1, isUsable and 1 or 0.1)
        cell:SetChecked(mountID ~= nil and mountID == selected)
        if searchText == "" or (name and string.find(name:lower(), searchText, 1, true)) then
            cell:Show()
        else
            cell:Hide()
        end
    end
    for index = count + 1, #g.cells do
        g.cells[index]:Hide()
    end
    local rows = math.ceil(count / COLUMNS)
    g.content:SetSize(COLUMNS * STEP_X - GAP_X, math.max(rows * STEP_Y - GAP_Y, 0))
end

Refresh = function()
    local journal = _G.CollectionsJournal
    local mj = _G.MountJournal or (journal and journal.MountJournal)
    if not mj then return end
    HideNative(mj)
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false
    UpdateCells(mj, Build(mj))
    addonEnv.StyleButton(MountJournalMountButton)
end

Themes.Register(Refresh)

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
for _, name in ipairs({"CollectionsJournal_LoadUI", "ToggleCollectionsJournal", "CollectionsJournal_SetTab", "MountJournal_UpdateMountList", "MountJournal_Select"}) do
    if type(_G[name]) == "function" then hooksecurefunc(name, Refresh) end
end
Refresh()

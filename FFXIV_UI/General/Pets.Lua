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

local function ScrollGrid(g, delta)
    local range = math.max(0, g.content:GetHeight() - g.scroll:GetHeight())
    local target = g.scroll:GetVerticalScroll() - delta * STEP_Y
    g.scroll:SetVerticalScroll(math.min(math.max(target, 0), range))
end

local function ShowTooltip(cell)
    if not cell.name then return end
    GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
    GameTooltip:SetText(cell.name)
    if not cell.owned then
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
    cell:SetScript("OnClick", function()
        PetJournal_ShowPetCard(cell.index)
        Refresh()
    end)
    cell:RegisterForDrag("LeftButton")
    cell:SetScript("OnDragStart", function()
        if cell.petID then C_PetJournal.PickupPet(cell.petID) end
    end)
    cell:SetScript("OnEnter", ShowTooltip)
    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return cell
end

local hooked = setmetatable({}, {__mode = "k"})

local function HideNative(pj)
    for _, key in ipairs({"ScrollBox", "ScrollBar"}) do
        local frame = pj[key]
        if frame then
            frame:Hide()
            if not hooked[frame] then
                hooked[frame] = true
                frame:HookScript("OnShow", function(self) self:Hide() end)
            end
        end
    end
    for _, key in ipairs({"LeftInset", "RightInset"}) do
        local inset = pj[key]
        if inset then
            Skin.HideTextures(inset)
            if inset.NineSlice then inset.NineSlice:Hide() end
        end
    end
end

local function Build(pj)
    if grid and grid.journal == pj then return grid end

    if pj.searchBox then
        addonEnv.StyleEditBox(pj.searchBox, SEARCH_PROMPT_SIZE)
        pj.searchBox:HookScript("OnTextChanged", function(self, _) Refresh() end)
    end
    if not hooked[pj] then
        hooked[pj] = true
        pj:HookScript("OnShow", function() Refresh() end)
    end

    local divider = pj:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", pj.RightInset, "TOPLEFT", 0, 0)
    divider:SetPoint("BOTTOMLEFT", pj.RightInset, "BOTTOMLEFT", 0, 0)
    Themes.StyleDivider(divider, pj, "ARTWORK", 0, true)

    local scroll = CreateFrame("ScrollFrame", nil, pj)
    local anchor, anchorPoint = pj.LeftInset, "TOPLEFT"
    if pj.searchBox then anchor, anchorPoint = pj.searchBox, "BOTTOMLEFT" end
    scroll:SetPoint("TOPLEFT", anchor, anchorPoint, MARGIN, -MARGIN)
    scroll:SetPoint("BOTTOMRIGHT", pj.LeftInset, "BOTTOMRIGHT", -MARGIN, MARGIN)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    scroll:SetScrollChild(content)

    grid = {journal = pj, scroll = scroll, content = content, cells = {}}
    scroll:SetScript("OnMouseWheel", function(_, delta) ScrollGrid(grid, delta) end)
    return grid
end

local function UpdateCells(pj, g)
    local count = C_PetJournal.GetNumPets()
    local selected = _G.PetJournalPetCard and _G.PetJournalPetCard.petIndex
    local searchText = pj.searchBox and pj.searchBox:GetText() or ""
    searchText = searchText:lower()
    for index = 1, count do
        local cell = g.cells[index] or MakeCell(g, index)
        g.cells[index] = cell
        cell.index = index
        local petID, speciesID, owned, customName, _, _, _, name, icon = C_PetJournal.GetPetInfoByIndex(index)
        cell.petID = petID
        cell.speciesID = speciesID
        cell.owned = owned
        cell.name = customName or name
        cell.Icon:SetTexture(icon)
        cell.Icon:SetDesaturated(not owned)
        cell.Icon:SetVertexColor(1, 1, 1)
        cell:SetChecked(index == selected)
        local matchesName = name and string.find(name:lower(), searchText, 1, true)
        local matchesCustomName = customName and string.find(customName:lower(), searchText, 1, true)
        if searchText == "" or matchesName or matchesCustomName then
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
    local pj = _G.PetJournal or (journal and journal.PetJournal)
    if not pj then return end
    HideNative(pj)
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false
    UpdateCells(pj, Build(pj))
    addonEnv.StyleButton(PetJournalSummonButton)
end

Themes.Register(Refresh)

local handlers = {
    ADDON_LOADED = Refresh,
    PLAYER_LOGIN = Refresh,
    PET_JOURNAL_LIST_UPDATE = Refresh,
    PLAYER_REGEN_ENABLED = function() if pending then Refresh() end end,
}
local watcher = CreateFrame("Frame")
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(_, event)
    local handler = handlers[event]
    if handler then handler() end
end)
for _, name in ipairs({"CollectionsJournal_LoadUI", "ToggleCollectionsJournal", "CollectionsJournal_SetTab", "PetJournal_UpdatePetList"}) do
    if type(_G[name]) == "function" then hooksecurefunc(name, Refresh) end
end
Refresh()

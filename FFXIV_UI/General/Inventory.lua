local _, addonEnv = ...
local FONT = "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf"
local COLUMNS, SIZE, GAP, PADDING, GRID_TOP = 5, 40, 3, 16, 108
local GRID_ROWS = 7
local BLOCK_SLOTS = COLUMNS * GRID_ROWS -- 35 slots per 5x7 block
local GRID_WIDTH = COLUMNS * SIZE + (COLUMNS - 1) * GAP
local GRID_HEIGHT = GRID_ROWS * (SIZE + GAP) - GAP
local INTER_GRID_GAP = 16
local Themes = addonEnv.Themes
local installed, pending, refreshing = false, false, false
local bindings = {}
local containers = {}
-- Addon-owned art per native container; Blizzard frame tables stay untouched so their secure reads are not tainted.
local frameArt = setmetatable({}, {__mode = "k"})
local function FrameArt(frame)
    local art = frameArt[frame]
    if not art then
        art = {bagHeaders = {}}
        frameArt[frame] = art
    end
    return art
end
-- Exposed so the test harness can inspect per-container art.
addonEnv.InventoryFrameArt = frameArt
local watcher = CreateFrame("Frame")
local Refresh
local layoutNames = {unified = "Unified grid", bags = "Per-bag grids"}

local function GetLayout()
    return FFXIV_UI_DB and layoutNames[FFXIV_UI_DB.inventoryLayout] and FFXIV_UI_DB.inventoryLayout or "unified"
end

local function GetMaxXGrids()
    local n = FFXIV_UI_DB and FFXIV_UI_DB.inventoryMaxXGrids
    return type(n) == "number" and math.max(1, math.min(4, math.floor(n))) or 2
end

addonEnv.GetInventoryLayout = GetLayout
addonEnv.SetInventoryLayout = function(layout)
    if not layoutNames[layout] then
        print("FFXIV UI: unknown inventory layout: " .. tostring(layout))
        return false
    end
    FFXIV_UI_DB = FFXIV_UI_DB or {}
    FFXIV_UI_DB.inventoryLayout = layout
    if Refresh then Refresh() end
    return true
end

addonEnv.GetInventoryMaxXGrids = GetMaxXGrids
addonEnv.SetInventoryMaxXGrids = function(n)
    local val = tonumber(n)
    if not val or val < 1 or val > 4 then
        print("FFXIV UI: inventory max X grids must be between 1 and 4: " .. tostring(n))
        return false
    end
    FFXIV_UI_DB = FFXIV_UI_DB or {}
    FFXIV_UI_DB.inventoryMaxXGrids = math.floor(val)
    if Refresh then Refresh() end
    return true
end

local Skin = addonEnv.Skin
local Color, Panel, HideTextures = Skin.Color, Skin.Panel, Skin.HideTextures
local function Text(parent, size, token, text, template)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    label:SetText(text or "")
    Skin.Text(label, token, size)
    return label
end

-- Native bag frames and item buttons are unprotected, so Blizzard re-lays them out in combat;
-- only defer our geometry if the client actually protects one of them.
local function Locked(frame)
    if not InCombatLockdown() then return false end
    if frame:IsProtected() then return true end
    for _, button in ipairs(frame.Items or {}) do
        if button:IsProtected() then return true end
    end
    return false
end

local function IsCarriedBag(id)
    return type(id) == "number" and (id >= 0 and id <= NUM_TOTAL_BAG_FRAMES or id == KEYRING_CONTAINER)
end

local function IsCombined(frame)
    return frame == ContainerFrameCombinedBags
end

local function HasSearch(frame)
    return IsCombined(frame) or frame:IsBackpack()
end

local function GridTop(frame)
    return HasSearch(frame) and GRID_TOP or 76
end

local function FrameWidth(frame)
    if not IsCombined(frame) then return PADDING * 2 + GRID_WIDTH end
    local maxX = GetMaxXGrids()
    return PADDING * 2 + maxX * GRID_WIDTH + (maxX - 1) * INTER_GRID_GAP
end

local function ExtraHeight(frame)
    local tracker = ContainerFrameSettingsManager:GetTokenTrackerIfShown(frame)
    return tracker and tracker:GetHeight() or 0
end

local function BagLayout(frame)
    if not IsCombined(frame) then
        local height = math.max(1, math.ceil(frame:GetBagSize() / COLUMNS)) * (SIZE + GAP) - GAP
        return {[frame:GetBagID()] = {x = PADDING, top = GridTop(frame), height = height, offset = 0}}, height
    end
    local maxX = GetMaxXGrids()
    local unified = GetLayout() == "unified"
    local layout, rowHeights = {}, {}

    if unified then
        local totalSlots, offset = 0, 0
        local bagOffsets = {}
        for bag = 0, NUM_TOTAL_BAG_FRAMES do
            if frame:MatchesBagID(bag) then
                local slots = C_Container.GetContainerNumSlots(bag)
                bagOffsets[bag] = offset
                offset = offset + slots
                totalSlots = totalSlots + slots
            end
        end
        layout.bagOffsets = bagOffsets

        local numBlocks = math.ceil(totalSlots / BLOCK_SLOTS)
        for b = 0, numBlocks - 1 do
            local row = math.floor(b / maxX)
            local slotsInBlock = math.min(BLOCK_SLOTS, totalSlots - b * BLOCK_SLOTS)
            local rowsInBlock = math.ceil(slotsInBlock / COLUMNS)
            local height = rowsInBlock * (SIZE + GAP) - GAP
            rowHeights[row] = math.max(rowHeights[row] or 0, height)
        end

        local rowOffsets = {[0] = GRID_TOP}
        for r = 1, math.ceil(numBlocks / maxX) - 1 do
            rowOffsets[r] = rowOffsets[r - 1] + rowHeights[r - 1] + 20
        end
        layout.rowOffsets = rowOffsets
        layout.rowHeights = rowHeights

        local maxBottom = 0
        for b = 0, numBlocks - 1 do
            local row = math.floor(b / maxX)
            local slotsInBlock = math.min(BLOCK_SLOTS, totalSlots - b * BLOCK_SLOTS)
            local rowsInBlock = math.ceil(slotsInBlock / COLUMNS)
            local gridHeight = rowsInBlock * (SIZE + GAP) - GAP
            local blockBottom = (rowOffsets[row] - GRID_TOP) + gridHeight
            if blockBottom > maxBottom then maxBottom = blockBottom end
        end
        return layout, math.max(1, maxBottom)
    else
        local bagList = {}
        for bag = 0, NUM_TOTAL_BAG_FRAMES do
            local slots = frame:MatchesBagID(bag) and ContainerFrame_GetContainerNumSlots(bag) or 0
            if slots > 0 then
                bagList[#bagList + 1] = {bag = bag, slots = slots}
            end
        end

        for i, info in ipairs(bagList) do
            local row = math.floor((i - 1) / maxX)
            local rows = math.ceil(info.slots / COLUMNS)
            local height = rows * (SIZE + GAP) - GAP
            rowHeights[row] = math.max(rowHeights[row] or 0, height)
        end

        local rowOffsets = {[0] = GRID_TOP}
        for r = 1, math.ceil(#bagList / maxX) - 1 do
            rowOffsets[r] = rowOffsets[r - 1] + rowHeights[r - 1] + 20
        end

        for i, info in ipairs(bagList) do
            local col = (i - 1) % maxX
            local row = math.floor((i - 1) / maxX)
            local x = PADDING + col * (GRID_WIDTH + INTER_GRID_GAP)
            local top = rowOffsets[row]
            local rows = math.ceil(info.slots / COLUMNS)
            local height = rows * (SIZE + GAP) - GAP
            layout[info.bag] = {x = x, top = top, height = height}
        end

        local maxBottom = 0
        for i, info in ipairs(bagList) do
            local row = math.floor((i - 1) / maxX)
            local rows = math.ceil(info.slots / COLUMNS)
            local gridHeight = rows * (SIZE + GAP) - GAP
            local bagBottom = (rowOffsets[row] - GRID_TOP) + 24 + gridHeight
            if bagBottom > maxBottom then maxBottom = bagBottom end
        end
        return layout, math.max(1, maxBottom)
    end
end

local function UpdateCount(frame)
    local total, free = 0, 0
    local first, last = frame:GetBagID(), frame:GetBagID()
    if IsCombined(frame) then first, last = 0, NUM_TOTAL_BAG_FRAMES end
    for bag = first, last do
        if frame:MatchesBagID(bag) then
            total = total + C_Container.GetContainerNumSlots(bag)
            free = free + C_Container.GetContainerNumFreeSlots(bag)
        end
    end
    FrameArt(frame).count:SetText((total - free) .. "/" .. total)
end

local function UpdateItemVisibility(button)
    local occupied = button.hasItem ~= nil and button.hasItem ~= false
    local icon = button.icon or button.Icon
    if icon then icon:SetShown(occupied) end
    -- Forever draws the desaturated bag icon in empty slots; keep them as plain themed wells.
    if button.EmptyBagIcon then button.EmptyBagIcon:Hide() end
    local state = addonEnv.GetButtonSkinState(button)
    if state and state.overlay then state.overlay.Gloss:SetShown(occupied) end
end

local function StyleItems(frame)
    local locked = Locked(frame)
    for _, button in ipairs(frame.Items or {}) do
        if not locked then
            button:SetSize(SIZE, SIZE)
            addonEnv.ApplyButtonSkin(button, nil, "Equipment")
            if button.ItemSlotBackground then button.ItemSlotBackground:SetAlpha(0) end
            local state = addonEnv.GetButtonSkinState(button)
            if state then
                Color(state.backdrop, "SetVertexColor", "inset")
                Color(state.normal, "SetVertexColor", "border")
            end
        end
        UpdateItemVisibility(button)
    end
    if locked then pending = true end
end

local function LayoutItems(frame)
    if Locked(frame) then pending = true; return end
    local layout = BagLayout(frame)
    local combined = IsCombined(frame)
    local unified = combined and GetLayout() == "unified"
    local headings = combined and not unified
    local maxX = GetMaxXGrids()

    local bagHeaders = FrameArt(frame).bagHeaders
    for bag, header in pairs(bagHeaders) do header:SetShown(headings and layout[bag] ~= nil) end
    for bag, grid in pairs(layout) do
        if headings and bag ~= "unified" and bag ~= "rowOffsets" and bag ~= "rowHeights" and bag ~= "bagOffsets" and type(bag) == "number" then
            local header = bagHeaders[bag]
            if not header then
                header = CreateFrame("Frame", nil, frame)
                header:EnableMouse(false)
                header.Title = Text(header, 12, "muted")
                header.Title:SetPoint("TOPLEFT", header, "TOPLEFT", 5, -3)
                header.Title:SetPoint("TOPRIGHT", header, "TOPRIGHT", -5, -3)
                header.Title:SetWordWrap(false)
                bagHeaders[bag] = header
            end
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", frame, "TOPLEFT", grid.x - 4, -grid.top)
            header:SetSize(GRID_WIDTH + 8, grid.height + 4)
            header.Title:SetText(bag == 0 and BAG_NAME_BACKPACK or C_Container.GetBagName(bag))
            header:Show()
        end
    end

    if unified then
        for _, button in ipairs(frame.Items or {}) do
            local bag = button:GetBagID()
            local bagOffset = layout.bagOffsets[bag] or 0
            local globalIndex = (button:GetID() - 1) + bagOffset
            local blockIdx = math.floor(globalIndex / BLOCK_SLOTS)
            local localIdx = globalIndex % BLOCK_SLOTS
            local colInBlock = localIdx % COLUMNS
            local rowInBlock = math.floor(localIdx / COLUMNS)
            local blockCol = blockIdx % maxX
            local blockRow = math.floor(blockIdx / maxX)

            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", frame, "TOPLEFT",
                PADDING + blockCol * (GRID_WIDTH + INTER_GRID_GAP) + colInBlock * (SIZE + GAP),
                -layout.rowOffsets[blockRow] - rowInBlock * (SIZE + GAP))
        end
    else
        for _, button in ipairs(frame.Items or {}) do
            local grid = layout[button:GetBagID()]
            if grid then
                local index = button:GetID() - 1
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", frame, "TOPLEFT",
                    grid.x + (index % COLUMNS) * (SIZE + GAP),
                    -grid.top - (headings and 24 or 0) - math.floor(index / COLUMNS) * (SIZE + GAP))
            end
        end
    end
    StyleItems(frame)
    frame:LayoutAddSlots()
end

local function StyleTokenTracker(frame)
    local tracker = ContainerFrameSettingsManager and ContainerFrameSettingsManager.GetTokenTrackerIfShown
        and ContainerFrameSettingsManager:GetTokenTrackerIfShown(frame)
    if not tracker then return end
    local function StyleButton(button)
        if not button then return end
        for _, key in ipairs({"Border", "IconBorder", "Background", "BorderFrame", "CountContainer", "IconContainer"}) do
            local part = button[key]
            if part then
                if type(part.SetAlpha) == "function" then part:SetAlpha(0) end
                if type(part.Hide) == "function" then part:Hide() end
            end
        end
        for _, region in ipairs({button:GetRegions()}) do
            if region:GetObjectType() == "Texture" then
                local icon = button.icon or button.Icon
                local count = button.count or button.Count or button.Text
                if region ~= icon and region ~= count then
                    region:SetAlpha(0)
                end
            end
        end
        local icon = button.icon or button.Icon
        if icon then
            icon:Show()
            icon:SetAlpha(1)
        end
    end
    if tracker.tokenButtons then
        for _, button in ipairs(tracker.tokenButtons) do
            StyleButton(button)
        end
    end
    if type(tracker.GetChildren) == "function" then
        for _, child in ipairs({tracker:GetChildren()}) do
            StyleButton(child)
            if type(child.GetChildren) == "function" then
                for _, subChild in ipairs({child:GetChildren()}) do
                    StyleButton(subChild)
                end
            end
        end
    end
end

local function LayoutControls(frame)
    if Locked(frame) then pending = true; return end
    local search = BagItemSearchBox
    if search:GetParent() == frame then
        search:ClearAllPoints()
        search:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING + 6, -73)
        search:SetWidth(FrameWidth(frame) - PADDING * 2 - 46)
    end
    local sort = BagItemAutoSortButton
    if sort:GetParent() == frame then
        sort:ClearAllPoints()
        sort:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -68)
    end
    local count = FrameArt(frame).count
    count:ClearAllPoints()
    count:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -43)
    UpdateCount(frame)
    StyleTokenTracker(frame)
end

local function UpdateTitle(frame)
    local title = IsCombined(frame) and (INVENTORY_TOOLTIP or BAG_NAME_BACKPACK)
        or (frame:GetBagID() == KEYRING_CONTAINER and KEYRING or C_Container.GetBagName(frame:GetBagID()))
    FrameArt(frame).title:SetText(title)
end

local function DeferInventoryWork(frame, tag, callback)
    addonEnv.DeferOutsideSecureUpdate(frame, "inventory:" .. tag, function()
        callback(frame)
    end)
end

Refresh = function()
    if not installed or refreshing then return end
    if InCombatLockdown() then pending = true; return end
    refreshing, pending = true, false
    for frame in pairs(containers) do
        if frame:IsShown() and (IsCombined(frame) or IsCarriedBag(frame:GetBagID())) then
            if IsCombined(frame) then
                frame:SetBagSize()
            else
                frame:SetBagSize(ContainerFrame_GetContainerNumSlots(frame:GetBagID()))
            end
            frame:UpdateItemSlots()
            frame:UpdateFrameSize()
            frame:UpdateItemLayout()
            frame:Update()
            UpdateTitle(frame)
            LayoutControls(frame)
        end
    end
    UpdateContainerFrameAnchors()
    refreshing = false
end

local function SkinContainer(frame)
    if containers[frame] then return end
    if Locked(frame) then pending = true; return end
    containers[frame] = true

    -- Sizing runs after Blizzard's own UpdateFrameSize rather than overriding its CalculateWidth/CalculateHeight.
    hooksecurefunc(frame, "UpdateFrameSize", function(self)
        DeferInventoryWork(self, "frame-size", function(container)
            local _, height = BagLayout(container)
            container:SetSize(FrameWidth(container), GridTop(container) + height
                + (container.MoneyFrame and 58 or 38) + ExtraHeight(container))
        end)
    end)
    -- Keep mutations out of Blizzard's post-hook call chain, but finish before the next render.
    hooksecurefunc(frame, "UpdateItemLayout", function(self)
        DeferInventoryWork(self, "item-layout", function(container)
            LayoutItems(container)
            for _, button in ipairs(container.Items or {}) do UpdateItemVisibility(button) end
        end)
    end)
    hooksecurefunc(frame, "UpdateItems", function(self)
        DeferInventoryWork(self, "items", function(container)
            StyleItems(container)
            UpdateCount(container)
        end)
    end)
    hooksecurefunc(frame, "UpdateSearchBox", function(self)
        DeferInventoryWork(self, "controls", LayoutControls)
    end)
    hooksecurefunc(frame, "UpdateName", function(self)
        DeferInventoryWork(self, "title", UpdateTitle)
    end)
    if frame.UpdateCurrencyFrames then
        hooksecurefunc(frame, "UpdateCurrencyFrames", function(self)
            DeferInventoryWork(self, "controls", LayoutControls)
        end)
    end

    HideTextures(frame)
    for _, key in ipairs({"NineSlice", "PortraitContainer", "TitleContainer"}) do
        if frame[key] then frame[key]:SetAlpha(0) end
    end
    local shell = Panel(frame, "surface")
    addonEnv.RoundWindow(shell, true)
    local title = Text(shell, 18, "text", nil, "FFXIV_InventoryTitleTemplate")
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", IsCombined(frame) and -146 or -40, -10)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    FrameArt(frame).title = title
    Text(shell, 14, "accent", ITEMS, "FFXIV_InventoryItemsTemplate")
    local line = shell:CreateTexture(nil, "OVERLAY", "FFXIV_InventoryDividerTemplate")
    Themes.StyleDivider(line, shell, "OVERLAY")
    FrameArt(frame).count = Text(shell, 14, "accent", nil, "FFXIV_InventoryCountTemplate")
    local close = frame.CloseButton
    HideTextures(close)
    close:ClearAllPoints()
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    close:SetSize(24, 24)
    addonEnv.SkinWindowClose(close)
    -- Keep the native dropdown (bag filters, cleanup settings and controller options).
    local options = frame.PortraitButton
    options:ClearAllPoints()
    options:SetPoint("TOPRIGHT", frame, "TOPRIGHT", IsCombined(frame) and -38 or -PADDING,
        IsCombined(frame) and -8 or -39)
    options:SetSize(24, 24)
    HideTextures(options)
    local optionsPanel = Panel(options, "tab")
    addonEnv.StyleWindowControl(optionsPanel, options, "Button")
    optionsPanel:CreateTexture(nil, "OVERLAY", "FFXIV_InventoryOptionsIconTemplate")
    if frame.FilterIcon then
        frame.FilterIcon:ClearAllPoints()
        frame.FilterIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -124, -41)
        frame.FilterIcon:SetSize(18, 18)
    end
    if frame.MoneyFrame then
        if frame.MoneyFrame.Border then frame.MoneyFrame.Border:SetAlpha(0) end
        for _, key in ipairs({"GoldButton", "SilverButton", "CopperButton"}) do
            local denomination = frame.MoneyFrame[key]
            if denomination and denomination.Text then
                denomination.Text:SetFont(FONT, 12, "")
                denomination.Text:SetShadowColor(0, 0, 0, 0)
                Color(denomination.Text, "SetTextColor", "text")
            end
        end
    end
    if frame.CountContainer then frame.CountContainer:SetAlpha(0) end
    frame:HookScript("OnShow", function()
        if Locked(frame) then pending = true; return end
        UpdateTitle(frame)
        LayoutControls(frame)
    end)
end

local function InstallContainers()
    SkinContainer(ContainerFrameCombinedBags)
    for _, frame in ipairs(ContainerFrameContainer.ContainerFrames) do SkinContainer(frame) end
end

local function Install()
    if installed then return end
    local frame, manager = ContainerFrameCombinedBags, ContainerFrameSettingsManager
    -- Forever's pooled item buttons and native container frames are required.
    if not frame or not manager or not frame.AcquireNewItemButton
        or not frame.UpdateItemSlots or not NUM_TOTAL_BAG_FRAMES
        or not ContainerFrameContainer or not ContainerFrameContainer.ContainerFrames
        or not ContainerFrame_GenerateFrame then return end
    if InCombatLockdown() then pending = true; return end
    installed = true
    InstallContainers()
    hooksecurefunc("ContainerFrame_GenerateFrame", function(container)
        DeferInventoryWork(container, "generate-frame", function(frame)
            if containers[frame] or not IsCarriedBag(frame:GetBagID()) then return end
            if Locked(frame) then pending = true; return end
            SkinContainer(frame)
            frame:UpdateFrameSize()
            LayoutItems(frame)
            for _, button in ipairs(frame.Items or {}) do UpdateItemVisibility(button) end
            UpdateTitle(frame)
            LayoutControls(frame)
            UpdateContainerFrameAnchors()
        end)
    end)
    HideTextures(BagItemSearchBox)
    local searchPanel = Panel(BagItemSearchBox, "inset")
    searchPanel:ClearAllPoints()
    searchPanel:SetPoint("TOPLEFT", BagItemSearchBox, "TOPLEFT", -6, 4)
    searchPanel:SetPoint("BOTTOMRIGHT", BagItemSearchBox, "BOTTOMRIGHT", 2, -4)
    addonEnv.StyleWindowControl(searchPanel, BagItemSearchBox, "Search")
    BagItemSearchBox:SetFont(FONT, 12, "")
    Color(BagItemSearchBox, "SetTextColor", "text")
    if BagItemSearchBox.Instructions then Color(BagItemSearchBox.Instructions, "SetTextColor", "muted") end
    Refresh()
end

Themes.Register(function(palette)
    for region, methods in pairs(bindings) do
        for method, token in pairs(methods) do region[method](region, unpack(palette[token])) end
    end
end)

local function SyncItemVisibility()
    for frame in pairs(containers) do
        if frame:IsShown() then
            for _, button in ipairs(frame.Items or {}) do UpdateItemVisibility(button) end
        end
    end
end

watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:RegisterEvent("BAG_UPDATE_DELAYED")
watcher:RegisterEvent("BAG_UPDATE_COOLDOWN")
watcher:RegisterEvent("BAG_CONTAINER_UPDATE")
watcher:SetScript("OnEvent", function(_, event)
    Install()
    if not installed then return end
    if event == "PLAYER_REGEN_ENABLED" and pending then
        InstallContainers()
        Refresh()
    elseif event == "BAG_CONTAINER_UPDATE" then
        Refresh()
    elseif event == "BAG_UPDATE_COOLDOWN" then
        -- Blizzard re-shows empty-slot art during its own handler; sync after it.
        C_Timer.After(0, SyncItemVisibility)
    elseif event == "BAG_UPDATE_DELAYED" then
        for frame in pairs(containers) do
            if frame:IsShown() then UpdateCount(frame) end
        end
        SyncItemVisibility()
    end
end)
Install()

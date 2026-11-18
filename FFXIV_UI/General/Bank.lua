local _, addonEnv = ...
local Skin = addonEnv.Skin
local Themes = addonEnv.Themes
local L = addonEnv.L or setmetatable({}, {__index = function(_, key) return key end})
local Color, Hide, HideTextures, KeepHidden = Skin.Color, Skin.Hide, Skin.HideTextures, Skin.KeepHidden
local FRAME_WIDTH, FRAME_HEIGHT = 760, 520
local PANEL_LEFT, PANEL_RIGHT_INSET, PANEL_BOTTOM_INSET = 244, 24, 72
local TAB_RAIL_LEFT, TAB_RAIL_WIDTH, TAB_TOP = 18, 196, 60
local TAB_HEIGHT, TAB_GAP = 30, 8
local HEADER_DIVIDER_Y, DIVIDER_TOP_GAP, DIVIDER_BOTTOM_INSET = 36, 12, 20
local GRID_SEARCH_GAP, GRID_RIGHT_INSET, GRID_BAG_GAP = 24, 24, 8
local GRID_GAP_RATIO = 0.5
local BAG_BUTTON_SPACING, PURCHASE_ROW_GAP = 50, 8
local PURCHASE_GRID_LEFT = 28
local installed, pending = false, false
local frameArt = setmetatable({}, {__mode = "k"})
local tabSkins = setmetatable({}, {__mode = "k"})
local itemGridAnchors = setmetatable({}, {__mode = "k"})
local watcher = CreateFrame("Frame")

addonEnv.BankFrameArt = frameArt

local function Art(frame)
    local art = frameArt[frame]
    if not art then
        art = {}
        frameArt[frame] = art
    end
    return art
end

local function PaintTab(tab)
    local skin = tabSkins[tab]
    if not skin then return end

    local selected
    if tab.pageNumber ~= nil and skin.selected ~= nil then
        selected = skin.selected
    elseif type(tab.IsSelected) == "function" then
        selected = tab:IsSelected()
    elseif type(tab.GetChecked) == "function" then
        selected = tab:GetChecked()
    end
    local enabled = type(tab.IsEnabled) ~= "function" or tab:IsEnabled()
    addonEnv.UpdateExtractedTabArtwork(skin.art, selected, skin.hovered, not enabled)
    Color(skin.label, "SetTextColor", enabled and "tabText" or "muted")
end

local function TabLabel(tab)
    local data = tab.tabData
    if data then
        return data.name or data.purchasePromptTitle or data.nameText or ""
    end
    return tab.tooltipText or ""
end

local function SkinTab(tab)
    if not tab or tabSkins[tab] then
        PaintTab(tab)
        return
    end
    if InCombatLockdown() then
        pending = true
        return
    end

    local selected
    if tab.pageNumber ~= nil and tab.SelectedTexture
        and type(tab.SelectedTexture.IsShown) == "function" then
        selected = tab.SelectedTexture:IsShown()
    end

    HideTextures(tab, tab.SearchOverlay)
    if tab.HighlightTexture then KeepHidden(tab.HighlightTexture) end
    if type(tab.GetHighlightTexture) == "function" then KeepHidden(tab:GetHighlightTexture()) end

    local panel = CreateFrame("Frame", nil, tab)
    panel:SetAllPoints(tab)
    panel:SetFrameLevel(tab:GetFrameLevel() + 1)
    panel:EnableMouse(false)
    local art = addonEnv.CreateExtractedTabArtwork(panel)
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", panel, "LEFT", 8, 0)
    label:SetPoint("RIGHT", panel, "RIGHT", -8, 0)
    label:SetHeight(TAB_HEIGHT)
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    Skin.Text(label, "tabText", 10)

    local skin = {art = art, label = label, hovered = false, selected = selected}
    tabSkins[tab] = skin
    label:SetText(TabLabel(tab))
    PaintTab(tab)

    tab:HookScript("OnEnter", function()
        skin.hovered = true
        PaintTab(tab)
    end)
    local function ResetHover()
        skin.hovered = false
        PaintTab(tab)
    end
    tab:HookScript("OnLeave", ResetHover)
    tab:HookScript("OnHide", ResetHover)
    tab:HookScript("OnShow", function()
        label:SetText(TabLabel(tab))
        PaintTab(tab)
    end)
    if tab.pageNumber ~= nil and type(tab.SetChecked) == "function" then
        hooksecurefunc(tab, "SetChecked", function(_, checked)
            skin.selected = checked
            PaintTab(tab)
        end)
    end
    if type(tab.RefreshVisuals) == "function" then
        hooksecurefunc(tab, "RefreshVisuals", function()
            label:SetText(TabLabel(tab))
            PaintTab(tab)
        end)
    end
    if tab.pageNumber ~= nil and type(tab.SetPageInfo) == "function" then
        hooksecurefunc(tab, "SetPageInfo", function()
            label:SetText(TabLabel(tab))
            PaintTab(tab)
        end)
    end
end

local function UpdateTabText(tab)
    SkinTab(tab)
    local skin = tabSkins[tab]
    if skin then
        skin.label:SetText(TabLabel(tab))
        PaintTab(tab)
    end
end

local function SetPoint(frame, point, relativeTo, relativePoint, x, y)
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, x, y)
end

local function ActiveBankTabs(bankPanel)
    local byID = {}
    local pool = bankPanel.bankTabPool
    if pool and type(pool.EnumerateActive) == "function" then
        for tab in pool:EnumerateActive() do
            if tab.tabData and tab.tabData.ID ~= nil then
                byID[tab.tabData.ID] = tab
            end
        end
    end

    local ordered = {}
    for _, data in ipairs(bankPanel.purchasedBankTabData or {}) do
        local tab = byID[data.ID]
        if tab then
            ordered[#ordered + 1] = tab
            byID[data.ID] = nil
        end
    end
    local remaining = {}
    for _, tab in pairs(byID) do
        remaining[#remaining + 1] = tab
    end
    table.sort(remaining, function(left, right)
        return left.tabData.ID < right.tabData.ID
    end)
    for _, tab in ipairs(remaining) do
        ordered[#ordered + 1] = tab
    end
    return ordered
end

local function LayoutBankTabs(bankPanel, frame)
    local tabs = ActiveBankTabs(bankPanel)
    for index, tab in ipairs(tabs) do
        SkinTab(tab)
        tab:SetSize(TAB_RAIL_WIDTH, TAB_HEIGHT)
        SetPoint(tab, "TOPLEFT", frame, "TOPLEFT", TAB_RAIL_LEFT,
            -(TAB_TOP + (index - 1) * (TAB_HEIGHT + TAB_GAP)))
    end

    local nextIndex = #tabs
    local purchaseTab = bankPanel.PurchaseTab
    if purchaseTab then
        SkinTab(purchaseTab)
        if purchaseTab:IsShown() then
            purchaseTab:SetSize(TAB_RAIL_WIDTH, TAB_HEIGHT)
            if frame.BagText then
                SetPoint(purchaseTab, "TOPLEFT", frame, "TOPLEFT", TAB_RAIL_LEFT,
                    -(TAB_TOP + nextIndex * (TAB_HEIGHT + TAB_GAP)))
                nextIndex = nextIndex + 1
            else
                SetPoint(purchaseTab, "BOTTOMLEFT", bankPanel, "BOTTOMLEFT", PURCHASE_GRID_LEFT, 96)
            end
        end
    end
    return nextIndex
end

local function LayoutPageTabs(frame, startIndex)
    if InCombatLockdown() then
        pending = true
        return
    end
    local pool = frame.bankPageTabPool
    if not pool or type(pool.EnumerateActive) ~= "function" then return end
    local tabs = {}
    for tab in pool:EnumerateActive() do
        tabs[#tabs + 1] = tab
    end
    table.sort(tabs, function(left, right)
        if left.bankType ~= right.bankType then return left.bankType < right.bankType end
        return left.pageNumber < right.pageNumber
    end)
    for index, tab in ipairs(tabs) do
        SkinTab(tab)
        tab:SetSize(TAB_RAIL_WIDTH, TAB_HEIGHT)
        SetPoint(tab, "TOPLEFT", frame, "TOPLEFT", TAB_RAIL_LEFT,
            -(TAB_TOP + ((startIndex or 0) + index - 1) * (TAB_HEIGHT + TAB_GAP)))
    end
end

local function ItemGridColumns()
    if C_Bank and type(C_Bank.ShouldUsePlayerBagsInBank) == "function"
        and C_Bank.ShouldUsePlayerBagsInBank() then
        return 8
    end
    return 14
end

local function StyleItemButton(button)
    addonEnv.ApplyButtonSkin(button, nil, "Equipment")
    if button.ItemSlotBackground then button.ItemSlotBackground:SetAlpha(0) end

    local state = addonEnv.GetButtonSkinState(button)
    if not state then return end
    Color(state.backdrop, "SetVertexColor", "inset")
    Color(state.normal, "SetVertexColor", "border")
    if button.EmptyBagIcon then button.EmptyBagIcon:Hide() end

    local icon = button.icon or button.Icon
    local occupied = button.hasItem ~= nil and button.hasItem ~= false
    if button.hasItem == nil then
        local iconShown = icon and type(icon.IsShown) == "function" and icon:IsShown()
        occupied = button.itemInfo ~= nil or iconShown or false
    end
    if state.overlay and state.overlay.Gloss then
        state.overlay.Gloss:SetShown(occupied)
    end
end

local function LayoutItemGrid(bankPanel)
    if type(bankPanel.EnumerateValidItems) ~= "function" then return end
    local buttons = {}
    for button in bankPanel:EnumerateValidItems() do
        buttons[#buttons + 1] = button
    end
    local first
    for _, button in ipairs(buttons) do
        local point, relativeTo, relativePoint = button:GetPoint(1)
        if not first and point == "TOPLEFT" and relativeTo == bankPanel
            and relativePoint == "TOPLEFT" then
            first = button
        end
    end
    if not first then return end
    for _, button in ipairs(buttons) do
        StyleItemButton(button)
    end

    local _, _, _, x, y = first:GetPoint(1)
    local state = itemGridAnchors[first]
    local baseX, baseY = x or 0, y or 0
    if state and baseX == state.appliedX and baseY == state.appliedY then
        baseX = state.baseX
        baseY = state.baseY
    end

    local columns = ItemGridColumns()
    local slotWidth = first:GetWidth()
    if columns < 2 or slotWidth <= 0 then return end
    local availableWidth = bankPanel:GetWidth() - baseX - GRID_RIGHT_INSET
    local gap = math.min(
        (availableWidth - columns * slotWidth) / (columns - 1),
        slotWidth * GRID_GAP_RATIO
    )
    if gap < 0 then return end

    local gridWidth = columns * slotWidth + (columns - 1) * gap
    local appliedX = baseX + (availableWidth - gridWidth) / 2
    local appliedY = -68
    SetPoint(first, "TOPLEFT", bankPanel, "TOPLEFT", appliedX, appliedY)
    itemGridAnchors[first] = {
        baseX = baseX,
        baseY = baseY,
        appliedX = appliedX,
        appliedY = appliedY,
    }
    for _, button in ipairs(buttons) do
        if button ~= first then
            local buttonPoint, buttonRelative, buttonRelativePoint, buttonX, buttonY = button:GetPoint(1)
            if buttonPoint and buttonRelative and buttonRelativePoint then
                if buttonRelativePoint == "TOPRIGHT" then
                    SetPoint(button, buttonPoint, buttonRelative, buttonRelativePoint, gap, buttonY or 0)
                else
                    SetPoint(button, buttonPoint, buttonRelative, buttonRelativePoint, buttonX or 0, buttonY or 0)
                end
            end
        end
    end

    local lastRowFirst = first
    while true do
        local nextRowFirst
        for _, button in ipairs(buttons) do
            local buttonPoint, buttonRelative, buttonRelativePoint = button:GetPoint(1)
            if buttonPoint == "TOPLEFT" and buttonRelative == lastRowFirst
                and buttonRelativePoint == "BOTTOMLEFT" then
                nextRowFirst = button
                break
            end
        end
        if not nextRowFirst then break end
        lastRowFirst = nextRowFirst
    end

    return {
        lastRowFirst = lastRowFirst,
        width = gridWidth,
        columns = columns,
    }
end

local function LayoutLegacyPurchase(frame, bankPanel, grid)
    if not frame.BagText or not frame.BagCost then return end

    Skin.Text(frame.BagText, "accent", 14)
    Skin.Text(frame.BagCost, "text", 12)

    local first
    local firstSlotID
    local lastSlotID
    local pool = frame.itemButtonBagPool
    if pool and type(pool.EnumerateActive) == "function" then
        for button in pool:EnumerateActive() do
            addonEnv.ApplyButtonSkin(button, nil, "Equipment")
            if button.bagSlotID and (not firstSlotID or button.bagSlotID < firstSlotID) then
                first, firstSlotID = button, button.bagSlotID
            end
            if button.bagSlotID and (not lastSlotID or button.bagSlotID > lastSlotID) then
                lastSlotID = button.bagSlotID
            end
        end
    end
    if not first or not grid or not grid.lastRowFirst then return end

    local bagWidth = (lastSlotID - firstSlotID) * BAG_BUTTON_SPACING + first:GetWidth()
    SetPoint(first, "TOPLEFT", grid.lastRowFirst, "BOTTOMLEFT",
        (grid.width - bagWidth) / 2, -GRID_BAG_GAP)

    frame.BagText:SetText(L["Bag Slots"])
    frame.BagText:SetJustifyH("CENTER")
    frame.BagText:SetJustifyV("MIDDLE")
    SetPoint(frame.BagText, "TOP", first, "BOTTOM",
        (bagWidth - first:GetWidth()) / 2, -PURCHASE_ROW_GAP)

    local purchaseRow = Art(frame).purchaseRowAnchor
    if not purchaseRow then return end

    local costWidth = type(frame.BagCost.GetStringWidth) == "function"
        and frame.BagCost:GetStringWidth() or frame.BagCost:GetWidth()
    local money = bankPanel.MoneyDisplay
    local moneyShown = money and money:IsShown()
    local moneyWidth = moneyShown and money:GetWidth() or 0
    local purchaseButton = bankPanel.PurchaseButton
    local purchaseShown = purchaseButton and purchaseButton:IsShown()
    local purchaseWidth = purchaseShown and purchaseButton:GetWidth() or 0
    local rowWidth = costWidth
    if moneyShown then rowWidth = rowWidth + PURCHASE_ROW_GAP + moneyWidth end
    if purchaseShown then rowWidth = rowWidth + PURCHASE_ROW_GAP + purchaseWidth end
    local rowHeight = math.max(frame.BagCost:GetHeight(), moneyShown and money:GetHeight() or 0,
        purchaseShown and purchaseButton:GetHeight() or 0)
    purchaseRow:SetSize(math.max(1, rowWidth), math.max(1, rowHeight))
    SetPoint(purchaseRow, "TOP", frame.BagText, "BOTTOM", 0, -PURCHASE_ROW_GAP)
    SetPoint(frame.BagCost, "LEFT", purchaseRow, "LEFT", 0, 0)

    local previous = frame.BagCost
    if moneyShown then
        SetPoint(money, "LEFT", previous, "RIGHT", PURCHASE_ROW_GAP, 0)
        previous = money
    end
    if purchaseShown then
        SetPoint(purchaseButton, "LEFT", previous, "RIGHT", PURCHASE_ROW_GAP, 0)
        addonEnv.StyleButton(purchaseButton)
    end
end

local function LayoutSearch(frame, bankPanel)
    local search = frame.BankItemSearchBox or _G.BankItemSearchBox
    if not search then return end
    SetPoint(search, "TOPRIGHT", frame, "TOPRIGHT", -56, -48)
    if bankPanel.AutoSortButton then
        SetPoint(bankPanel.AutoSortButton, "LEFT", search, "RIGHT", 8, -1)
    end
end

local function LayoutMoneyFrame(bankPanel)
    local moneyFrame = bankPanel.MoneyFrame
    if not moneyFrame then return end
    moneyFrame.Border:SetAlpha(0)
    SetPoint(moneyFrame, "BOTTOMRIGHT", bankPanel, "BOTTOMRIGHT", 20, -32)
end

local function CreateDecor(frame, bankPanel)
    local art = Art(frame)
    if art.shell then return end

    HideTextures(frame)
    for _, key in ipairs({"NineSlice", "PortraitContainer", "PortraitFrame", "portrait"}) do
        if frame[key] then Hide(frame[key]) end
    end
    HideTextures(bankPanel)
    for _, key in ipairs({"NineSlice", "EdgeShadows"}) do
        if bankPanel[key] then Hide(bankPanel[key]) end
    end

    art.shell = Skin.Panel(frame)
    addonEnv.RoundWindow(art.shell, true)
    art.headerDivider = art.shell:CreateTexture(nil, "OVERLAY")
    art.headerDivider:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -HEADER_DIVIDER_Y)
    art.headerDivider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -HEADER_DIVIDER_Y)
    art.headerDivider:SetHeight(1)
    Themes.StyleDivider(art.headerDivider, art.shell, "OVERLAY")

    art.tabsDivider = art.shell:CreateTexture(nil, "OVERLAY")
    art.tabsDivider:SetPoint("TOPLEFT", frame, "TOPLEFT", TAB_RAIL_LEFT + TAB_RAIL_WIDTH + 14,
        -(HEADER_DIVIDER_Y + DIVIDER_TOP_GAP))
    art.tabsDivider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", TAB_RAIL_LEFT + TAB_RAIL_WIDTH + 14,
        DIVIDER_BOTTOM_INSET)
    art.tabsDivider:SetWidth(1)
    Themes.StyleDivider(art.tabsDivider, art.shell, "OVERLAY", 0, true)
    art.purchaseRowAnchor = CreateFrame("Frame", nil, frame)
    art.purchaseRowAnchor:EnableMouse(false)

    local title = frame.TitleContainer and frame.TitleContainer.TitleText
        or frame.TitleText or _G.BankFrameTitleText
    if title then
        title:ClearAllPoints()
        title:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -10)
        title:SetJustifyH("LEFT")
        title:SetWordWrap(false)
        Skin.Text(title, "text", 18)
    end

    local close = frame.CloseButton
    if close then
        HideTextures(close)
        close:ClearAllPoints()
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
        close:SetSize(24, 24)
        addonEnv.SkinWindowClose(close)
    end

    local search = frame.BankItemSearchBox or _G.BankItemSearchBox
    if search then addonEnv.StyleEditBox(search) end

    if bankPanel.Header and bankPanel.Header.Text then
        Skin.Text(bankPanel.Header.Text, "accent", 14)
    end
    for _, key in ipairs({"PurchasePrompt", "LockPrompt"}) do
        local prompt = bankPanel[key]
        if prompt then
            HideTextures(prompt)
            if prompt.Border then Hide(prompt.Border) end
            local promptPanel = Skin.Panel(prompt)
            addonEnv.RoundWindow(promptPanel, true)
            Skin.Fonts(prompt, "text")
        end
    end
end

local function Layout(frame)
    local bankPanel = frame and frame.BankPanel
    if not bankPanel then return end
    if InCombatLockdown() then
        pending = true
        return
    end

    CreateDecor(frame, bankPanel)
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    bankPanel:ClearAllPoints()
    bankPanel:SetPoint("LEFT", frame, "LEFT", PANEL_LEFT, 0)
    bankPanel:SetSize(FRAME_WIDTH - PANEL_LEFT - PANEL_RIGHT_INSET, FRAME_HEIGHT - PANEL_BOTTOM_INSET)

    local nextTabIndex = LayoutBankTabs(bankPanel, frame)
    LayoutSearch(frame, bankPanel)
    local grid = LayoutItemGrid(bankPanel)
    LayoutLegacyPurchase(frame, bankPanel, grid)
    LayoutMoneyFrame(bankPanel)
    LayoutPageTabs(frame, nextTabIndex)
    pending = false

    if type(UpdateUIPanelPositions) == "function" then
        UpdateUIPanelPositions(frame)
    end
end

local function Hook(owner, method, callback)
    local ownerType = type(owner)
    if (ownerType == "table" or ownerType == "userdata")
        and type(owner[method]) == "function" then
        hooksecurefunc(owner, method, callback)
    end
end

local function Install()
    if installed or not BankFrame or not BankFrame.BankPanel
        or type(BankPanelMixin) ~= "table" or type(BankPanelTabMixin) ~= "table"
        or type(BankFrameMixin) ~= "table" then
        return
    end
    if InCombatLockdown() then
        pending = true
        return
    end

    installed = true
    local bankPanel = BankFrame.BankPanel
    Hook(bankPanel, "RefreshBankTabs", function() Layout(BankFrame) end)
    Hook(bankPanel, "Reset", function() Layout(BankFrame) end)
    Hook(bankPanel, "GenerateItemSlotsForSelectedTab", function() Layout(BankFrame) end)
    Hook(BankFrame, "SetTab", function(frame) Layout(frame) end)
    Hook(BankFrame, "UpdateWidthForSelectedTab", function(frame) Layout(frame) end)
    Hook(BankFrame, "RefreshPageTabs", function(frame) Layout(frame) end)
    Hook(BankFrame, "RefreshBagButtons", function(frame) Layout(frame) end)

    BankFrame:HookScript("OnShow", function(frame) Layout(frame) end)
    CreateDecor(BankFrame, BankFrame.BankPanel)
    Layout(BankFrame)
end

watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" and pending then
        Install()
        if installed then Layout(BankFrame) end
    else
        Install()
    end
end)

if type(BankFrame_Open) == "function" then
    hooksecurefunc("BankFrame_Open", function()
        Install()
        if installed then Layout(BankFrame) end
    end)
end

Themes.Register(function()
    for tab in pairs(tabSkins) do PaintTab(tab) end
end)

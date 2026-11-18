local _, namespace = ...
local combat = false
local methods = {}
local created = {}
local applyTemplate = assert(loadfile("tests\\support\\PanelTemplates.lua"))()

local function object(kind, parent)
    local result = setmetatable({
        kind = kind or "Frame", parent = parent, shown = true, enabled = true, level = 1,
        regions = {}, children = {}, scripts = {}, points = {},
    }, {__index = methods})
    if parent then
        local list = (kind == "Texture" or kind == "FontString") and parent.regions or parent.children
        list[#list + 1] = result
    end
    created[#created + 1] = result
    return result
end

function CreateFrame(_, _, parent, template)
    local frame = object("Frame", parent)
    applyTemplate(frame, parent, template)
    return frame
end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetChildren() return unpack(self.children) end
function methods:GetParent() return self.parent end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(value) self.level = value end
function methods:SetAllPoints(target) self.allPoints = target end
function methods:SetBackdrop(value) self.backdrop = value end
function methods:SetBackdropColor(...) self.backdropColor = {...} end
function methods:SetBackdropBorderColor(...) self.backdropBorderColor = {...} end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetTextColor(...) self.color = {...} end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetTexture(value) self.texture = value end
function methods:SetTexCoord(...) self.texCoords = {...} end
function methods:SetHorizTile(value) self.horizTile = value end
function methods:SetVertTile(value) self.vertTile = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetShadowColor(...) self.shadow = {...} end
function methods:SetShadowOffset(...) self.shadowOffset = {...} end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetFont(...) self.font = {...} end
function methods:GetFont() return self.font and self.font[1] or "font.ttf", self.font and self.font[2] or 12, "" end
function methods:SetText(value) self.text = value end
function methods:GetText() return self.text end
function methods:GetStringWidth() return self.stringWidth or self.width or #(self.text or "") * 8 end
function methods:SetJustifyH(value) self.justifyH = value end
function methods:SetJustifyV(value) self.justifyV = value end
function methods:SetWordWrap(value) self.wordWrap = value end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:GetSize() return self.width or 0, self.height or 0 end
function methods:GetWidth() return self.width or 0 end
function methods:GetHeight() return self.height or 0 end
function methods:SetWidth(value) self.width = value end
function methods:SetHeight(value) self.height = value end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:GetPoint(index)
    local point = self.points[index or 1]
    if point then return unpack(point) end
end
function methods:CreateTexture(_, _, template)
    local texture = object("Texture", self)
    applyTemplate(texture, self, template)
    return texture
end
function methods:CreateFontString(_, _, template)
    local label = object("FontString", self)
    applyTemplate(label, self, template)
    return label
end
function methods:HookScript(name, callback)
    local old = self.scripts[name]
    self.scripts[name] = function(...)
        if old then old(...) end
        callback(...)
    end
end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetShown(value) self.shown = value end
function methods:IsEnabled() return self.enabled end
function methods:SetEnabled(value) self.enabled = value end
function methods:IsProtected() return false end
function methods:RegisterEvent() end

function InCombatLockdown() return combat end
function hooksecurefunc(target, name, callback)
    if type(target) == "string" then target, name, callback = _G, target, name end
    local original = assert(target[name], "missing native method: " .. name)
    target[name] = function(...)
        local result = {original(...)}
        callback(...)
        return unpack(result)
    end
end

local function iterator(values)
    local index = 0
    return function()
        index = index + 1
        return values[index]
    end
end

local function pool(values)
    return {EnumerateActive = function() return iterator(values) end}
end

local namespaceEnv = {}
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", namespaceEnv)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", namespaceEnv)
assert(loadfile("FFXIV_UI\\General\\RoundedPanels.lua"))("FFXIV_UI", namespaceEnv)
assert(loadfile("FFXIV_UI\\General\\WindowControls.lua"))("FFXIV_UI", namespaceEnv)
namespaceEnv.StyleEditBox = function(box) box.styled = true end
namespaceEnv.SkinWindowClose = function(button) button.styled = true end
namespaceEnv.L = setmetatable({}, {__index = function(_, key) return key end})
local buttonSkinStates = setmetatable({}, {__mode = "k"})
namespaceEnv.GetButtonSkinState = function(button) return buttonSkinStates[button] end
namespaceEnv.ApplyButtonSkin = function(button, _, style)
    assert(style == "Equipment", "bank item buttons must use the equipment skin")
    local state = buttonSkinStates[button]
    if not state then
        state = {
            backdrop = button:CreateTexture(),
            normal = button:CreateTexture(),
            overlay = {Gloss = button:CreateTexture()},
        }
        buttonSkinStates[button] = state
    end
end

C_Bank = {ShouldUsePlayerBagsInBank = function() return true end}

BankPanelMixin = {
    RefreshBankTabs = function(self)
        self.tabRefreshes = (self.tabRefreshes or 0) + 1
        for _, tab in ipairs(self.tabs) do
            tab:SetSize(32, 32)
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, -25)
        end
    end,
    GenerateItemSlotsForSelectedTab = function(self)
        local columns = C_Bank.ShouldUsePlayerBagsInBank() and 8 or 14
        local rowStarter, lastButton
        for index, button in ipairs(self.itemButtons) do
            button:ClearAllPoints()
            if index == 1 then
                button:SetPoint("TOPLEFT", self, "TOPLEFT", columns == 8 and 47 or 26, -63)
                rowStarter = button
            elseif (index - 1) % columns == 0 then
                button:SetPoint("TOPLEFT", rowStarter, "BOTTOMLEFT", 0, -10)
                rowStarter = button
            else
                button:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", 13, 0)
            end
            lastButton = button
        end
    end,
    Reset = function(self)
        self:GenerateItemSlotsForSelectedTab()
    end,
}
BankPanelTabMixin = {
    Init = function(self, data)
        self.tabData = data
        self:RefreshVisuals()
    end,
    RefreshVisuals = function() end,
}
BankFrameMixin = {
    OnShow = function() end,
    SetTab = function() end,
    UpdateWidthForSelectedTab = function(self) self:SetSize(738, 460) end,
    RefreshPageTabs = function(self)
        for index, tab in ipairs(self.pageTabs or {}) do
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, -60)
            tab:SetPageInfo(tab.bankType, tab.pageNumber, index == 1 and 1 or nil)
        end
    end,
    RefreshBagButtons = function(self)
        if self.bagButtons and self.bagButtons[1] then
            self.bagButtons[1]:ClearAllPoints()
            self.bagButtons[1]:SetPoint("LEFT", self, "BOTTOMLEFT", 200, 115)
        end
    end,
}
BankPageTabMixin = {
    SetPageInfo = function(tab, bankType, pageNumber, currentPage)
        tab.bankType, tab.pageNumber = bankType, pageNumber
        tab.tooltipText = "Page " .. pageNumber
        tab:SetChecked(pageNumber == currentPage)
    end,
}

local frame = object()
frame:SetSize(738, 460)
frame.Background = frame:CreateTexture()
frame.NineSlice = object("Frame", frame)
frame.CloseButton = object("Button", frame)
frame.CloseButton.scripts.OnClick = function() return "native close" end
frame.TitleText = frame:CreateFontString()
frame.TitleText:SetText("Banque")
frame.BankItemSearchBox = object("EditBox", frame)
frame.BankItemSearchBox.scripts.OnTextChanged = function() return "native search" end

local bankPanel = object("Frame", frame)
frame.BankPanel = bankPanel
bankPanel:SetSize(738, 460)
bankPanel.NineSlice = object("Frame", bankPanel)
bankPanel.EdgeShadows = object("Frame", bankPanel)
bankPanel.Header = object("Frame", bankPanel)
bankPanel.Header.Text = bankPanel.Header:CreateFontString()
bankPanel.Header.Text:SetText("Banque")
bankPanel.AutoSortButton = object("Button", bankPanel)
bankPanel.AutoSortButton.scripts.OnClick = function() return "native sort" end
bankPanel.tabs = {}
bankPanel.purchasedBankTabData = {
    {ID = 1, name = "Banque principale"},
    {ID = 2, name = "Artisanat"},
}
for index, data in ipairs(bankPanel.purchasedBankTabData) do
    local tab = object("Button", bankPanel)
    tab.enabled, tab.selected = true, index == 1
    tab.tabData = data
    tab.SearchOverlay = tab:CreateTexture()
    tab.HighlightTexture = tab:CreateTexture()
    tab.Icon = tab:CreateTexture()
    tab.scripts.OnClick = function() return "native bank tab" end
    function tab:IsSelected() return self.selected end
    function tab:RefreshVisuals() return BankPanelTabMixin.RefreshVisuals(self) end
    bankPanel.tabs[index] = tab
end
bankPanel.bankTabPool = pool(bankPanel.tabs)
bankPanel.PurchaseTab = object("Button", bankPanel)
bankPanel.PurchaseTab.tabData = {ID = -1, purchasePromptTitle = "Acheter un onglet"}
bankPanel.PurchaseTab.SearchOverlay = bankPanel.PurchaseTab:CreateTexture()
bankPanel.PurchaseTab.scripts.OnClick = function() return "native purchase tab" end
function bankPanel.PurchaseTab:IsSelected() return false end
bankPanel.PurchaseTab:SetShown(true)

local firstSlot = object("Button", bankPanel)
firstSlot:SetSize(37, 37)
bankPanel.firstSlot = firstSlot
bankPanel.itemButtons = {firstSlot}
local reverseItemButtons = false
local function addItemSlotArt(button, index)
    button.icon = button:CreateTexture()
    button.icon:SetShown(index == 1)
    button.itemInfo = index == 1 and {itemID = index} or nil
    button.ItemSlotBackground = button:CreateTexture()
    button.ItemSlotBackground:SetAlpha(1)
end
addItemSlotArt(firstSlot, 1)
for index = 2, 16 do
    local button = object("Button", bankPanel)
    button:SetSize(37, 37)
    addItemSlotArt(button, index)
    bankPanel.itemButtons[index] = button
end
function bankPanel:EnumerateValidItems()
    local buttons = {}
    if reverseItemButtons then
        for index = #self.itemButtons, 1, -1 do
            buttons[#buttons + 1] = self.itemButtons[index]
        end
    else
        for _, button in ipairs(self.itemButtons) do
            buttons[#buttons + 1] = button
        end
    end
    return iterator(buttons)
end
function bankPanel:GenerateItemSlotsForSelectedTab()
    return BankPanelMixin.GenerateItemSlotsForSelectedTab(self)
end
local purchaseButton = object("Button", bankPanel)
purchaseButton.Text = purchaseButton:CreateFontString()
purchaseButton.Text:SetText("Purchase")
local bankButton = object("Button", frame)
local nextBankButton = object("Button", frame)
bankButton:SetSize(28, 28)
nextBankButton:SetSize(28, 28)
bankButton.bagSlotID, nextBankButton.bagSlotID = 2, 3
purchaseButton.scripts.OnClick = function() return "native tab purchase" end
bankButton.scripts.OnClick = function() return "native purchase" end
frame.BagText = frame:CreateFontString()
frame.BagCost = frame:CreateFontString()
frame.BagCost:SetText("Cost:")
frame.BagCost.stringWidth = 35
bankPanel.MoneyDisplay = object("Frame", bankPanel)
bankPanel.MoneyDisplay:SetSize(75, 20)
bankPanel.MoneyFrame = object("Frame", bankPanel)
bankPanel.MoneyFrame:SetSize(394, 25)
bankPanel.MoneyFrame:SetPoint("BOTTOMRIGHT", bankPanel, "BOTTOMRIGHT", -3, 3)
bankPanel.MoneyFrame.Border = object("Texture", bankPanel.MoneyFrame)
bankPanel.PurchaseButton = purchaseButton
purchaseButton:SetSize(124, 21)
frame.bagButtons = {bankButton, nextBankButton}
frame.itemButtonBagPool = pool(frame.bagButtons)
frame.pageTabs = {object("Button", frame), object("Button", frame)}
frame.pageTabs[1].bankType, frame.pageTabs[1].pageNumber = 1, 1
frame.pageTabs[2].bankType, frame.pageTabs[2].pageNumber = 2, 1
frame.pageTabs[1].tooltipText, frame.pageTabs[2].tooltipText = "Page 1", "Page 2"
frame.pageTabs[1].scripts.OnClick = function() return "native page tab" end
frame.pageTabs[1].IsSelected = function() return false end
frame.pageTabs[2].IsSelected = function() return true end
for _, tab in ipairs(frame.pageTabs) do
    tab.SelectedTexture = tab:CreateTexture()
    tab.SetChecked = function(self, checked)
        self.checked = checked
        self.SelectedTexture:SetShown(checked)
    end
end
for _, tab in ipairs(frame.pageTabs) do
    tab.SetPageInfo = function(self, bankType, pageNumber, currentPage)
        return BankPageTabMixin.SetPageInfo(self, bankType, pageNumber, currentPage)
    end
end
frame.bankPageTabPool = pool(frame.pageTabs)

function UpdateUIPanelPositions(target) target.positionsUpdated = true end
for method, callback in pairs(BankFrameMixin) do frame[method] = callback end
for method, callback in pairs(BankPanelMixin) do bankPanel[method] = callback end
local nativeRefreshPageTabs = BankFrameMixin.RefreshPageTabs
local nativeRefreshBagButtons = BankFrameMixin.RefreshBagButtons
local nativeResetBankPanel = BankPanelMixin.Reset
frame:SetScript("OnShow", function(target)
    nativeRefreshPageTabs(target)
    nativeRefreshBagButtons(target)
    nativeResetBankPanel(target.BankPanel)
end)
BankFrame = frame

local first = #created + 1
assert(loadfile("FFXIV_UI\\General\\Bank.lua"))("FFXIV_UI", namespaceEnv)
local watcher = created[first]
assert(watcher, "Bank skin did not create its event watcher")
local function fire(event) watcher.scripts.OnEvent(watcher, event) end
fire("PLAYER_LOGIN")
frame.scripts.OnShow(frame)
for index, button in ipairs(bankPanel.itemButtons) do
    assert(buttonSkinStates[button], "bank slot skin was not applied to item button " .. index)
end

local function offset(point) return point and point[4], point and point[5] end
assert(frame.width == 760 and frame.height == 520, "bank window dimensions differ from the updated layout")
assert(bankPanel.width == 492 and bankPanel.height == 448, "bank content was not expanded beside the tab rail")
assert(bankPanel.points[1][2] == frame and bankPanel.points[1][4] == 244,
    "bank content panel was not shifted right of the tab rail")
assert(namespaceEnv.BankFrameArt[frame].shell and namespaceEnv.BankFrameArt[frame].tabsDivider,
    "window shell or tab divider is missing")
assert(namespaceEnv.BankFrameArt[frame].headerDivider.points[1][5] == -36,
    "header divider was not raised")
assert(frame.TitleText.text == "Banque" and frame.TitleText.font[2] == 18,
    "native localized title was not retained and styled")
assert(frame.BankItemSearchBox.styled and frame.CloseButton.styled,
    "native search/close controls were not styled")
assert(frame.CloseButton.scripts.OnClick() == "native close", "native close action was replaced")
assert(frame.BankItemSearchBox.scripts.OnTextChanged() == "native search", "native search action was replaced")
assert(frame.BankItemSearchBox.points[1][1] == "TOPRIGHT"
    and frame.BankItemSearchBox.points[1][5] == -48,
    "search box was not moved lower")
assert(bankPanel.AutoSortButton.points[1][2] == frame.BankItemSearchBox
    and bankPanel.AutoSortButton.points[1][4] == 8
    and bankPanel.AutoSortButton.points[1][5] == -1,
    "cleanup button was not moved with the search box")
assert(bankPanel.AutoSortButton.scripts.OnClick() == "native sort",
    "native cleanup action was replaced")
assert(bankPanel.MoneyFrame.points[1][2] == bankPanel and bankPanel.MoneyFrame.points[1][4] == 20
    and bankPanel.MoneyFrame.points[1][5] == -32 and bankPanel.MoneyFrame.Border.alpha == 0,
    "current money display is not anchored inside the bank panel")

local firstTab = bankPanel.tabs[1]
local secondTab = bankPanel.tabs[2]
assert(firstTab.width == 196 and firstTab.height == 30 and firstTab.points[1][2] == frame
    and firstTab.points[1][4] == 18 and firstTab.points[1][5] == -60,
    "bank tabs were not moved to the left rail")
assert(firstTab.children[1].FFXIVUIExtractedTabArt, "FFXIV tab artwork was not created")
assert(firstTab.children[1].regions[1].texture:find("Tab%-Selected%-Dark%.tga"),
    "selected tab artwork is not applied")
assert(firstTab.children[1].regions[4].text == "Banque principale", "native tab label was not retained")
assert(secondTab.children[1].regions[4].text == "Artisanat", "customized tab label was not retained")
assert(firstTab.scripts.OnClick(firstTab) == "native bank tab", "native bank tab action was replaced")
firstTab.scripts.OnEnter(firstTab)
assert(firstTab.children[1].regions[1].color[1] == 1.12, "tab hover brightness was not applied")
firstTab.scripts.OnLeave(firstTab)
firstTab.selected = false
firstTab:RefreshVisuals()
assert(firstTab.children[1].regions[1].texture:find("Tab%-Inactive%-Dark%.tga"),
    "selected-state refresh did not update FFXIV tab art")
firstTab.selected = true
firstTab.enabled = false
firstTab:RefreshVisuals()
assert(firstTab.children[1].regions[4].color[1] == namespaceEnv.Themes.GetPalette().muted[1],
    "disabled tab label is not muted")
firstTab.enabled = true
firstTab:RefreshVisuals()
local nativeData = bankPanel.purchasedBankTabData[1]
BankPanelTabMixin.Init(firstTab, {ID = 1, name = "Banque renommée"})
assert(firstTab.children[1].regions[4].text == "Banque renommée", "reused tab label was not refreshed")
BankPanelTabMixin.Init(firstTab, nativeData)

reverseItemButtons = true
bankPanel:Reset()
local gridPoint = firstSlot.points[1]
local gridGap = (421 - 8 * 37) / 7
local lastSlot = bankPanel.itemButtons[#bankPanel.itemButtons]
local _, lastRelative, lastRelativePoint, lastGap, lastY = lastSlot:GetPoint(1)
assert(gridPoint[2] == bankPanel and gridPoint[4] == 47 and gridPoint[5] == -68
    and bankPanel.points[1][4] == 244
    and math.abs(bankPanel.itemButtons[2].points[1][4] - gridGap) < 0.01
    and lastRelative == bankPanel.itemButtons[#bankPanel.itemButtons - 1]
    and lastRelativePoint == "TOPRIGHT" and math.abs(lastGap - gridGap) < 0.01
    and lastY == 0,
    "last bank item slot is not aligned with the rest of the grid")
local emptySkin = buttonSkinStates[bankPanel.itemButtons[2]]
local populatedSkin = buttonSkinStates[firstSlot]
local palette = namespaceEnv.Themes.GetPalette()
for _, button in ipairs(bankPanel.itemButtons) do
    assert(buttonSkinStates[button] and button.ItemSlotBackground.alpha == 0,
        "every bank slot must receive the inventory item-slot treatment")
end
assert(emptySkin and populatedSkin and bankPanel.itemButtons[2].ItemSlotBackground.alpha == 0
    and emptySkin.backdrop.color[1] == palette.inset[1]
    and emptySkin.normal.color[1] == palette.border[1]
    and emptySkin.overlay.Gloss.shown == false
    and populatedSkin.overlay.Gloss.shown == true,
    "bank item slots do not match the inventory background treatment")
assert(frame.BagText.text == "Bag Slots"
    and frame.BagText.points[1][2] == frame.bagButtons[1]
    and frame.BagText.points[1][3] == "BOTTOM" and frame.BagText.points[1][4] == 25
    and frame.BagText.points[1][5] == -8,
    "bag-slot label is not centered below the bag slots")
assert(frame.bagButtons[1].points[1][2] == bankPanel.itemButtons[9]
    and math.abs(frame.bagButtons[1].points[1][4] - 171.5) < 0.01
    and frame.bagButtons[1].points[1][5] == -8,
    "Forever bag slots are not below storage")
local purchaseRow = namespaceEnv.BankFrameArt[frame].purchaseRowAnchor
assert(frame.BagCost.points[1][2] == purchaseRow and frame.BagCost.points[1][4] == 0
    and purchaseRow.points[1][2] == frame.BagText
    and purchaseRow.points[1][3] == "BOTTOM" and purchaseRow.points[1][5] == -8
    and bankPanel.MoneyDisplay.points[1][2] == frame.BagCost
    and purchaseButton.points[1][2] == bankPanel.MoneyDisplay
    and purchaseRow.width == 250,
    "Forever purchase cost is not below the bag slots")
local purchaseArt
for _, child in ipairs(purchaseButton.children) do
    if child.FFXIVUIControlArt then purchaseArt = child.FFXIVUIControlArt end
end
assert(purchaseArt and #purchaseArt.fill == 3 and #purchaseArt.border == 3,
    "Forever purchase button is not using the FFXIV_UI control material")
assert(purchaseButton.scripts.OnClick() == "native tab purchase"
    and bankButton.scripts.OnClick() == "native purchase",
    "native purchase control was not preserved")
assert(frame.pageTabs[1].points[1][2] == frame and frame.pageTabs[1].points[1][4] == 18
    and frame.pageTabs[1].points[1][5] <= -60
    and frame.pageTabs[1].width == 196 and frame.pageTabs[1].height == 30,
    "Forever page tabs are not styled and kept inside the left rail")
assert(frame.pageTabs[1].children[1].FFXIVUIExtractedTabArt
    and frame.pageTabs[1].children[1].regions[4].text == "Page 1"
    and frame.pageTabs[1].children[1].regions[1].texture:find("Tab%-Selected%-Dark%.tga")
    and frame.pageTabs[2].children[1].regions[1].texture:find("Tab%-Inactive%-Dark%.tga"),
    "Forever page tabs do not show the checked page's selected FFXIV art")
frame.pageTabs[1]:SetChecked(false)
assert(frame.pageTabs[1].children[1].regions[1].texture:find("Tab%-Inactive%-Dark%.tga"),
    "page-tab checked state did not update its FFXIV artwork")
frame.pageTabs[1]:SetChecked(true)
assert(frame.pageTabs[1].children[1].regions[1].texture:find("Tab%-Selected%-Dark%.tga"),
    "page-tab selected state did not update its FFXIV artwork")
assert(frame.pageTabs[1].scripts.OnClick(frame.pageTabs[1]) == "native page tab",
    "native page-tab action was replaced")
frame:RefreshPageTabs()
assert(frame.pageTabs[1].points[1][4] == 18,
    "native Forever page-tab refresh restored the tab to the right edge")
local divider = namespaceEnv.BankFrameArt[frame].tabsDivider
assert(divider.points[1][5] == -48 and divider.points[2][5] == 20,
    "left divider overlaps the header divider or frame bottom")

local textureCount = #firstTab.children[1].regions
local objectCount = #created
fire("PLAYER_LOGIN")
bankPanel:RefreshBankTabs()
assert(#firstTab.children[1].regions == textureCount and #created == objectCount,
    "repeated layout duplicated tab art or overlays")
assert(firstTab.scripts.OnClick(firstTab) == "native bank tab", "native tab action changed after relayout")
assert(bankPanel.PurchaseTab.scripts.OnClick(bankPanel.PurchaseTab) == "native purchase tab",
    "native purchase-tab action was replaced")

combat = true
bankPanel:RefreshBankTabs()
bankPanel:GenerateItemSlotsForSelectedTab()
frame:RefreshPageTabs()
assert(firstTab.width == 32 and firstTab.points[1][3] == "TOPRIGHT",
    "bank tab geometry changed during combat")
assert(firstSlot.points[1][4] == 47, "bank grid geometry changed during combat")
assert(frame.pageTabs[1].points[1][4] == 0, "page tab geometry changed during combat")
combat = false
fire("PLAYER_REGEN_ENABLED")
assert(firstTab.width == 196 and firstTab.points[1][2] == frame
    and firstSlot.points[1][4] == 47 and firstSlot.points[1][5] == -68
    and firstTab.points[1][5] == -60 and bankPanel.points[1][4] == 244
    and frame.pageTabs[1].points[1][4] == 18,
    "deferred bank layout did not resume after combat")

frame.BagText, frame.BagCost, frame.itemButtonBagPool, frame.bankPageTabPool = nil, nil, nil, nil
C_Bank.ShouldUsePlayerBagsInBank = function() return false end
frame.scripts.OnShow(frame)
assert(firstSlot.points[1][4] == 26 and firstSlot.points[1][5] == -63
    and bankPanel.itemButtons[2].points[1][4] == 13,
    "Retail's native grid was changed when 14 columns do not fit the updated frame width")
assert(bankPanel.PurchaseTab.points[1][2] == bankPanel
    and bankPanel.PurchaseTab.points[1][1] == "BOTTOMLEFT"
    and bankPanel.PurchaseTab.points[1][4] == 28,
    "Retail purchase tab is not placed below the storage grid")

print("PASS bank shell, localized native tabs, client purchase layouts, idempotence, and combat deferral")

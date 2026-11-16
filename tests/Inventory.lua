local addonName, ns = ...
local combat, created = false, {}
local methods = {}
local applyControlTemplate = assert(loadfile("tests\\support\\PanelTemplates.lua"))()
local function object(kind, parent)
    local result = setmetatable({
        kind = kind or "Frame", parent = parent, shown = false, level = 1,
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
    applyControlTemplate(frame, parent, template)
    return frame
end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return table.unpack(self.regions) end
function methods:GetParent() return self.parent end
function methods:SetParent(parent) self.parent = parent end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(level) self.level = level end
function methods:SetAllPoints(target) self.allPoints = target end
function methods:SetBackdrop(value) self.backdrop = value end
function methods:SetBackdropColor(...) self.color = {...} end
function methods:SetBackdropBorderColor(...) self.borderColor = {...} end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetTextColor(...) self.color = {...} end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetTexture(value, horizontalWrap, verticalWrap)
    self.texture, self.horizontalWrap, self.verticalWrap = value, horizontalWrap, verticalWrap
end
function methods:SetJustifyH(value) self.justify = value end
function methods:SetWordWrap(value) self.wordWrap = value end
function methods:SetTexCoord(...) self.texCoords = {...} end
function methods:SetBlendMode(mode) self.blendMode = mode end
function methods:SetHorizTile(value) self.horizTile = value end
function methods:SetVertTile(value) self.vertTile = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetShadowColor() end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetFont(...) self.font = {...} end
function methods:SetText(text) assert(self.font); self.text = text end
function methods:SetWordWrap(value) self.wrap = value end
function methods:CreateTexture(_, _, template)
    local texture = object("Texture", self)
    applyControlTemplate(texture, self, template)
    if template == "FFXIV_CircularArrowBaseTemplate" or template == "FFXIV_CircularArrowGlyphTemplate"
        or template == "FFXIV_WindowCloseIconTemplate" then
        local file = assert(io.open("FFXIV_UI\\General\\WindowControls.xml", "rb"))
        local xml = file:read("*a")
        file:close()
        texture:SetTexture(assert(xml:match('<Texture name="' .. template .. '" virtual="true" file="([^"]+)"/>')))
    end
    return texture
end
function methods:CreateMaskTexture() return object("Texture", self) end
function methods:AddMaskTexture(mask) self.mask = mask end
function methods:CreateFontString(_, _, template)
    local label = object("FontString", self)
    if template then label.font = {template, 12, ""} end
    applyControlTemplate(label, self, template)
    return label
end
function methods:GetFont() return self.font and self.font[1] or "Interface\\AddOns\\FFXIV_UI\\Media\\Fonts\\AxisRegular.ttf", self.font and self.font[2] or 12, self.font and self.font[3] or "" end
function methods:SetFont(font, size) self.font = {font, size, ""} end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetHeight() return self.height end
function methods:GetSize() return self.width or 0, self.height or 0 end
function methods:Show()
    local changed = not self.shown
    self.shown = true
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:HookScript(name, callback)
    local old = self.scripts[name]
    self.scripts[name] = function(...) if old then old(...) end; callback(...) end
end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent() end
function methods:IsProtected() return self.protected == true end
function InCombatLockdown() return combat end
function hooksecurefunc(target, name, callback)
    if type(target) == "string" then target, name, callback = _G, target, name end
    local original = assert(target[name], "missing native method: " .. name)
    target[name] = function(...) original(...); callback(...) end
end
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local namespace = {}
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\RoundedPanels.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\WindowControls.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Core.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Items.lua"))("FFXIV_UI", namespace)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Spells.lua"))("FFXIV_UI", namespace)
local skinStates = setmetatable({}, {__mode = "k"})
local function skinState(button)
    skinStates[button] = skinStates[button] or {}
    return skinStates[button]
end
namespace.GetButtonSkinState = skinState
local skinCalls = 0
namespace.ApplyButtonSkin = function(button, _, style)
    assert(style == "Equipment")
    skinCalls = skinCalls + 1
    local state = skinState(button)
    state.backdrop = state.backdrop or button:CreateTexture()
    state.normal = state.normal or button:CreateTexture()
    state.overlay = state.overlay or {Gloss = button:CreateTexture()}
    state.backdrop:SetSize(button.width * 58 * 0.92 / 56, button.width * 58 * 0.92 / 56)
    state.normal:SetSize(button.width * 58 * 0.92 / 52, button.width * 58 * 0.92 / 52)
end
local first = #created + 1
assert(loadfile("FFXIV_UI\\General\\Inventory.lua"))("FFXIV_UI", namespace)
local watcher = created[first]
local function event(name) watcher.scripts.OnEvent(watcher, name) end
C_Timer = C_Timer or {After = function(_, callback) callback() end}
event("PLAYER_LOGIN")
assert(#created == first, "missing native bag implementation should wait")

NUM_TOTAL_BAG_FRAMES, KEYRING_CONTAINER = 5, -2
INVENTORY_TOOLTIP, BAG_NAME_BACKPACK, ITEMS, BAG_FILTER_TITLE_SORTING, KEYRING =
    "Inventory", "Backpack", "Items", "Options", "Keyring"
local sizes = {[0] = 16, 8, 6, 0, 4, 6, [-2] = 9, [11] = 12}
local free = {[0] = 14, 7, 6, 0, 4, 4, [-2] = 8, [11] = 12}
local data = {["0:1"] = {item = 100, count = 6, quest = true}, ["0:2"] = {item = 200},
    ["1:1"] = {item = 300}, ["5:1"] = {item = 400}, ["5:2"] = {item = 500}, ["-2:1"] = {item = 700}}
C_Container = {}
function C_Container.GetContainerNumSlots(id) return sizes[id] end
function C_Container.GetContainerNumFreeSlots(id) return free[id] end
function C_Container.GetBagName(id) return id == -2 and KEYRING or "Bag " .. id end
local extended = 4
function ContainerFrame_GetContainerNumSlots(id) return sizes[id] + (id == 0 and extended or 0) end
local native = {}
function native:GetBagID() return self.id end
function native:SetBagID(id) self.id = id end
function native:IsBackpack() return self.backpack == true end
function native:MatchesBagID(id)
    if self == ContainerFrameCombinedBags then return id >= 0 and id <= 4 end
    return self.id == id
end
function native:IsBagOpen(id) return self.shown and self:MatchesBagID(id) and id or nil end
function native:SetBagSize(size)
    if self == ContainerFrameCombinedBags then
        size = 0
        for bag = 0, 4 do size = size + ContainerFrame_GetContainerNumSlots(bag) end
    end
    self.size = size
end
function native:GetBagSize() return self.size end
function native:GetColumns() return self == ContainerFrameCombinedBags and 10 or 4 end
function native:CalculateWidth() return 178 end
function native:CalculateHeight() return 200 end
function native:AcquireNewItemButton()
    local index = #self.Items + 1
    local button = self.pool[index]
    if not button then
        button = object("ItemButton", self)
        button.icon, button.ItemSlotBackground = button:CreateTexture(), button:CreateTexture()
        button.EmptyBagIcon = button:CreateTexture()
        function button:SyncAppearanceWithHasItem()
            if self.hasItem then self.EmptyBagIcon:Hide()
            else self.EmptyBagIcon:Show(); self.icon:Show() end
        end
        function button:GetBagID() return self.bag end
        function button:GetID() return self.slot end
        function button:Initialize(bag, slot) self.bag, self.slot = bag, slot; self:Show() end
        button.scripts.OnClick = function(self) return self.bag, self.slot end
        button.scripts.OnEnter = function() return "native tooltip" end
        button.scripts.OnReceiveDrag = function() return "native drag" end
        self.pool[index] = button
    end
    self.Items[index] = button
    return button
end
function native:UpdateItemSlots()
    for _, button in ipairs(self.Items) do button:Hide() end
    self.Items = {}
    local startBag, endBag = self.id, self.id
    if self == ContainerFrameCombinedBags then startBag, endBag = 4, 0 end
    for bag = startBag, endBag, -1 do
        for slot = ContainerFrame_GetContainerNumSlots(bag), 1, -1 do
            self:AcquireNewItemButton():Initialize(bag, slot)
        end
    end
end
function native:UpdateFrameSize() self:SetSize(self:CalculateWidth(), self:CalculateHeight()) end
function native:UpdateItemLayout()
    assert(#self.Items == self.size, "native item count differs from capacity")
    self:LayoutAddSlots()
end
function native:LayoutAddSlots() self.addSlotsPositioned = true end
function native:UpdateName() self.TitleContainer.text = C_Container.GetBagName(self.id) end
function native:UpdateSearchBox()
    if self:IsBackpack() or self == ContainerFrameCombinedBags then
        BagItemSearchBox:SetParent(self)
        BagItemAutoSortButton:SetParent(self)
        BagItemSearchBox:ClearAllPoints()
        BagItemSearchBox:SetPoint("TOPLEFT", self, "TOPLEFT", 42, -37)
    end
end
function native:UpdateItems()
    for _, button in ipairs(self.Items) do
        button.itemData = data[button.bag .. ":" .. button.slot]
        button.hasItem = button.itemData and 1 or nil
        button.filtered, button.locked = "native search result", "native lock state"
        button:SyncAppearanceWithHasItem()
    end
end
-- Forever: BAG_UPDATE_COOLDOWN (spell casts, procs) re-syncs empty-slot art without UpdateItems.
function native:UpdateCooldowns()
    for _, button in ipairs(self.Items) do button:SyncAppearanceWithHasItem() end
end
function native:Update()
    self:UpdateSearchBox()
    if self.UpdateCurrencyFrames then self:UpdateCurrencyFrames() end
    self:UpdateItems()
end
local function container(backpack)
    local frame = object()
    for key, method in pairs(native) do frame[key] = method end
    frame.id, frame.size, frame.shown, frame.backpack, frame.Items, frame.pool = 0, 0, false, backpack, {}, {}
    frame.NineSlice, frame.PortraitContainer, frame.TitleContainer = object(), object(), object()
    frame.CloseButton, frame.PortraitButton, frame.FilterIcon = object("Button", frame), object("Button", frame), object()
    frame.nativeArt = frame:CreateTexture()
    frame.CloseButton.scripts.OnClick = function() CloseBag(frame.id) end
    frame.PortraitButton.scripts.OnClick = function() return "native bag menu", frame.id end
    if backpack then
        frame.MoneyFrame = object("Frame", frame)
        frame.MoneyFrame.Border = object()
        for _, key in ipairs({"GoldButton", "SilverButton", "CopperButton"}) do
            frame.MoneyFrame[key] = object("Button", frame.MoneyFrame)
            frame.MoneyFrame[key].Text = frame.MoneyFrame[key]:CreateFontString(nil, nil, "GameFontNormal")
        end
        function frame:UpdateCurrencyFrames() self.MoneyFrame:Show() end
    end
    return frame
end
local root, backpack, reagent = container(true), container(true), container(false)
ContainerFrameCombinedBags = root
local pool = {backpack, container(false), container(false), container(false), container(false), reagent, container(false)}
ContainerFrameContainer = {ContainerFrames = pool}
BagItemSearchBox, BagItemAutoSortButton = object("EditBox", backpack), object("Button", backpack)
BagItemSearchBox.Instructions = BagItemSearchBox:CreateFontString(nil, nil, "GameFontNormal")
BagItemSearchBox.art = BagItemSearchBox:CreateTexture()
BagItemAutoSortButton.scripts.OnClick = function() return "native sort" end
local gamepad = false
ContainerFrameSettingsManager = {isUsingCombinedBags = false}
local manager = ContainerFrameSettingsManager
function manager:IsUsingCombinedBags(id)
    return (self.isUsingCombinedBags or gamepad) and (id == nil or id >= 0 and id <= 4)
end
function manager:GetTokenTrackerIfShown(frame) return frame.tracker end
local function shownBag(id)
    if root:IsBagOpen(id) then return root end
    for _, frame in ipairs(pool) do if frame:IsBagOpen(id) then return frame end end
end
function IsBagOpen(id) return shownBag(id) ~= nil end
function IsAnyBagOpen()
    if root.shown then return true end
    for _, frame in ipairs(pool) do if frame.shown then return true end end
    return false
end
function CloseAllBags()
    root:Hide()
    for _, frame in ipairs(pool) do frame:Hide() end
end
function CloseBackpack() local frame = shownBag(0); if frame then frame:Hide() end end
function CloseBag(id) local frame = shownBag(id); if frame then frame:Hide() end end
function UpdateContainerFrameAnchors() root.anchorsUpdated = true end
function ContainerFrame_GenerateFrame(frame, size, id)
    frame:SetBagID(id); frame:SetBagSize(size); frame:UpdateItemSlots(); frame:Show()
    frame:UpdateName(); frame:UpdateFrameSize(); frame:UpdateItemLayout(); frame:Update()
    UpdateContainerFrameAnchors()
end
function OpenBag(id)
    if shownBag(id) then return end
    local frame
    if manager:IsUsingCombinedBags(id) then frame = root
    elseif id == 0 then frame = backpack
    elseif id == 5 then frame = reagent
    else
        for _, candidate in ipairs(pool) do
            if candidate ~= backpack and candidate ~= reagent and not candidate.shown then frame = candidate; break end
        end
    end
    print("OPENBAG ID:", id, "COMBINED:", manager:IsUsingCombinedBags(id), "FRAME IS ROOT:", frame == root)
    assert(frame, "no free native frame")
    ContainerFrame_GenerateFrame(frame, ContainerFrame_GetContainerNumSlots(id), manager:IsUsingCombinedBags(id) and 0 or id)
end
function OpenBackpack() OpenBag(0) end
local function OpenAllBagsInternal()
    OpenBackpack()
    for bag = manager:IsUsingCombinedBags() and 5 or 1, NUM_TOTAL_BAG_FRAMES do
        if sizes[bag] > 0 then OpenBag(bag) end
    end
end
-- Preserve the native close-then-count ordering, including the reagent bag and keyring.
function ToggleAllBags()
    local bagsOpen, totalBags = 0, 1
    if IsBagOpen(0) then bagsOpen = bagsOpen + 1; CloseBackpack() end
    if IsBagOpen(KEYRING_CONTAINER) then bagsOpen = bagsOpen + 1; CloseBag(KEYRING_CONTAINER) end
    local combined = manager:IsUsingCombinedBags()
    for bag = 1, NUM_TOTAL_BAG_FRAMES do
        if not (combined and bag <= 4) then
            if sizes[bag] > 0 then totalBags = totalBags + 1 end
            if IsBagOpen(bag) then CloseBag(bag); bagsOpen = bagsOpen + 1 end
        end
    end
    if bagsOpen < totalBags then OpenAllBagsInternal() end
end
function manager:OnCombinedBagSettingChanged(value)
    local open = {}
    for bag = -2, NUM_TOTAL_BAG_FRAMES do if IsBagOpen(bag) then open[#open + 1] = bag end end
    CloseAllBags()
    self.isUsingCombinedBags = value
    for _, bag in ipairs(open) do OpenBag(bag) end
end
CloseAllBags()
OpenBackpack(); OpenBag(5)
local routing, matching, opening, sizing, slots =
    manager.IsUsingCombinedBags, root.MatchesBagID, root.IsBagOpen, root.SetBagSize, root.UpdateItemSlots
combat = true
local before = #created
event("ADDON_LOADED")
assert(#created == before and backpack.shown and reagent.shown, "installation changed inventory in combat")
combat = false
event("PLAYER_REGEN_ENABLED")
assert(backpack.shown and reagent.shown and not root.shown and not manager:IsUsingCombinedBags(),
    "installation must preserve native Combine Bags and open windows")
assert(manager.IsUsingCombinedBags == routing and root.MatchesBagID == matching
    and root.IsBagOpen == opening and root.SetBagSize == sizing and root.UpdateItemSlots == slots,
    "addon must not replace native routing, open-state or item enumeration")

local function same(actual, expected)
    for i = 1, #expected do assert(actual[i] == expected[i], "theme color differs") end
end
local function checkFrame(frame, count, title)
    assert(frame.FFXIVUICount.text == count and frame.FFXIVUITitle.text == title)
    assert(frame.nativeArt.alpha == 0 and frame.NineSlice.alpha == 0 and frame.TitleContainer.alpha == 0)
    assert(frame.CloseButton.FFXIVUICloseIcon.texture == "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\Close.tga")
    assert(frame.PortraitButton.scripts.OnClick() == "native bag menu")
    local positions = {}
    for _, button in ipairs(frame.Items) do
        assert(button.width == 40 and button.height == 40 and button:GetParent() == frame)
        local point = button.points[1]
        local key = point[4] .. ":" .. point[5]
        assert(not positions[key], "overlapping item slots"); positions[key] = true
        assert(point[4] >= 16 and point[4] + 40 <= frame.width - 16)
        if not (-point[5] + 40 <= frame.height - (frame.MoneyFrame and 58 or 38)) then
            print("FAIL FRAME:", frame.id or "combined", "height:", frame.height, "point[5]:", point[5], "bag:", button.bag, "slot:", button.slot)
        end
        assert(-point[5] + 40 <= frame.height - (frame.MoneyFrame and 58 or 38))
        assert((button.icon.shown or false) == (button.itemData ~= nil))
        assert(not button.EmptyBagIcon.shown, "native empty bag icon visible")
        assert((skinState(button).overlay.Gloss.shown or false) == (button.itemData ~= nil))
        assert(button.filtered == "native search result" and button.locked == "native lock state")
        local bag, slot = button.scripts.OnClick(button)
        assert(bag == button.bag and slot == button.slot and button.scripts.OnEnter() == "native tooltip"
            and button.scripts.OnReceiveDrag() == "native drag", "native item handlers changed")
    end
end
checkFrame(backpack, "2/16", "Bag 0")
checkFrame(reagent, "2/6", "Bag 5")
assert(backpack.width == 244 and backpack.height == 335 and reagent.width == 244 and reagent.height == 197)
assert(reagent:GetColumns() == 5 and next(reagent.FFXIVUIBagHeaders) == nil)
assert(BagItemSearchBox:GetParent() == backpack and BagItemSearchBox.width == 166)
assert(reagent.Items[1].points[1][5] == -119 and reagent.Items[#reagent.Items].points[1][5] == -76)
print("PASS themed separate backpack/reagent windows, exact dimensions, native controls and hidden redundant headings")

assert(namespace.SetInventoryLayout("bags"))
manager:OnCombinedBagSettingChanged(true)
checkFrame(root, "3/34", "Inventory"); checkFrame(reagent, "2/6", "Bag 5")
assert(root.shown and reagent.shown and not backpack.shown)
assert(root.width == 472 and root.height == 462 and root.size == 38 and #root.Items == 38)
assert(root.FFXIVUIBagHeaders[5] == nil and not root:MatchesBagID(5) and not manager:IsUsingCombinedBags(5))
assert(BagItemSearchBox:GetParent() == root and BagItemSearchBox.width == 394)
local byLocation = {}
for _, button in ipairs(root.Items) do
    byLocation[button.bag .. ":" .. button.slot] = button
    local header = root.FFXIVUIBagHeaders[button.bag]
    assert(header.shown and header.Title.text == (button.bag == 0 and "Backpack" or "Bag " .. button.bag))
    assert(button.points[1][4] == header.points[1][4] + 4 + (button.slot - 1) % 5 * 43)
    assert(button.points[1][5] == header.points[1][5] - 24 - math.floor((button.slot - 1) / 5) * 43)
end
assert(byLocation["5:1"] == nil and byLocation["0:1"].points[1][5] == -132)
ToggleAllBags(); assert(not IsAnyBagOpen(), "open-all toggle reopened combined bags")
ToggleAllBags(); assert(root.shown and reagent.shown)
OpenBag(-2)
local keyring = assert(shownBag(-2))
checkFrame(keyring, "1/9", "Keyring")
assert(keyring ~= root and keyring.width == 244 and keyring.height == 197 and next(keyring.FFXIVUIBagHeaders) == nil)
assert(not manager:IsUsingCombinedBags(-2) and not root:MatchesBagID(-2))
ToggleAllBags(); assert(not IsAnyBagOpen(), "open-all toggle did not close the keyring")
ToggleAllBags(); OpenBag(-2)
print("PASS combined bags exclude reagent/keyring, retain per-bag headings, and open-all closes every window")

local shell = root.FFXIVUICount:GetParent()
local rounded = {}
for _, region in ipairs(shell.regions) do
    if region ~= shell.FFXIVUIGrain and region.texture and region.texture:find("\\Panels\\", 1, true) then
        rounded[#rounded + 1] = region
    end
end
assert(#shell.FFXIVUIWindowRim == 8 and #shell.FFXIVUIWindowInterior == 9
    and #shell.FFXIVUIWindowLighting == 6 and not shell.backdrop)
local regionCount = #shell.regions
namespace.RoundWindow(shell); assert(#shell.regions == regionCount)
local optionsArt = reagent.PortraitButton.children[1].FFXIVUIControlArt
local searchArt = BagItemSearchBox.children[1].FFXIVUIControlArt
assert(#optionsArt.fill == 3 and #optionsArt.border == 3 and #searchArt.fill == 3 and #searchArt.border == 0)
local searchOutline = BagItemSearchBox.children[1].FFXIVUIFocusOutline
assert(#searchOutline == 8, "search outline must be nine-sliced")
for _, piece in ipairs(searchOutline) do
    assert(not piece.shown and piece.texture:match("ButtonSkins\\General\\Highlight$") and piece.blendMode == "ADD")
end
assert(searchOutline[1].texCoords[2] == 48 / 128 and searchOutline[1].texCoords[4] == 48 / 128, "corner slice is wrong")
BagItemSearchBox.scripts.OnEditFocusGained(BagItemSearchBox)
for _, piece in ipairs(searchOutline) do
    assert(piece.shown, "focused search box shows no outline")
    same(piece.color, namespace.Themes.GetPalette().indicator)
end
BagItemSearchBox.scripts.OnEditFocusLost(BagItemSearchBox)
for _, piece in ipairs(searchOutline) do
    assert(not piece.shown, "unfocused search box keeps outline")
end
for _, name in ipairs(namespace.Themes.GetNames()) do
    assert(namespace.Themes.Set(name))
    local palette = namespace.Themes.GetPalette()
    for _, frame in ipairs({root, backpack, reagent, keyring}) do
        same(frame.FFXIVUICount:GetParent().color, palette.surface)
        same(frame.FFXIVUICount.color, palette.accent)
        same(frame.FFXIVUITitle.color, palette.text)
        for _, button in ipairs(frame.Items) do
            same(skinState(button).backdrop.color, palette.inset)
            same(skinState(button).normal.color, palette.border)
        end
        if frame.MoneyFrame then
            for _, key in ipairs({"GoldButton", "SilverButton", "CopperButton"}) do
                same(frame.MoneyFrame[key].Text.color, palette.text)
            end
        end
    end
    same(BagItemSearchBox.color, palette.text); same(BagItemSearchBox.Instructions.color, palette.muted)
    local material = name:find("^Clear ") and "Clear" or name == "Classic FF" and "Classic" or "Standard"
    assert(optionsArt.fill[1].texture:find("Button-fill-" .. material .. ".tga", 1, true))
    assert(not shell.FFXIVUIGrain)
    for _, texture in ipairs(shell.FFXIVUIWindowRim) do
        assert(texture.texture:find("Window-Rim-Dark.tga", 1, true) and texture.color == nil)
    end
end
local grain = shell.FFXIVUIWindowInterior[5].texture
assert(grain.horizontalWrap == "REPEAT" and grain.verticalWrap == "REPEAT" and grain.horizTile and grain.vertTile)
for _, size in ipairs({{472, 486}, {244, 197}, {838, 546}}) do
    shell.scripts.OnSizeChanged(shell, size[1], size[2])
    assert(grain.texCoords[2] == (size[1] - 8) / 128 and grain.texCoords[4] == (size[2] - 8) / 128)
end
shell:SetSize(472, 486); shell.scripts.OnShow(shell)
assert(grain.texCoords[2] == 464 / 128 and grain.texCoords[4] == 478 / 128)
reagent.PortraitButton.scripts.OnEnter(); same(optionsArt.fill[1].color, namespace.Themes.GetPalette().selected)
reagent.PortraitButton.scripts.OnLeave(); same(optionsArt.fill[1].color, namespace.Themes.GetPalette().tab)
root.CloseButton.scripts.OnEnter(); assert(root.CloseButton.FFXIVUICloseIcon.color[1] == 1)
root.CloseButton.scripts.OnLeave(); assert(root.CloseButton.FFXIVUICloseIcon.color[1] == 0.85)
print("PASS all eight themes, rounded materials/grain, gold close emblems, controls and shared search")

assert(namespace.SetInventoryLayout("unified") and FFXIV_UI_DB.inventoryLayout == "unified")
assert(root.height == 464 and root.width == 472)
for _, button in ipairs(root.Items) do
    assert(type(button.points[1][4]) == "number" and type(button.points[1][5]) == "number")
end
for _, header in pairs(root.FFXIVUIBagHeaders) do assert(not header.shown) end
checkFrame(reagent, "2/6", "Bag 5"); checkFrame(keyring, "1/9", "Keyring")
assert(namespace.SetInventoryLayout("bags") and root.height == 462)
manager:OnCombinedBagSettingChanged(false)
assert(not root.shown and backpack.shown and reagent.shown and shownBag(-2))
for bag = 0, 5 do
    if sizes[bag] > 0 then
        local frame = assert(shownBag(bag))
        assert(frame.width == 244 and next(frame.FFXIVUIBagHeaders) == nil,
            "individual bag retained a redundant section label")
    end
end
ToggleAllBags(); assert(not IsAnyBagOpen(), "individual open-all did not close")
ToggleAllBags(); assert(not root.shown and backpack.shown and reagent.shown and shownBag(4))
assert(namespace.SetInventoryLayout("unified"))
for _, frame in ipairs(pool) do if frame.shown then assert(frame.width == 244) end end
local saved = FFXIV_UI_DB
FFXIV_UI_DB = {inventoryLayout = "bags"}
assert(namespace.GetInventoryLayout() == "bags")
FFXIV_UI_DB = saved
local messages, originalPrint = {}, print
print = function(message) messages[#messages + 1] = message end
assert(not namespace.SetInventoryLayout("invalid")); print = originalPrint
assert(#messages == 1 and namespace.GetInventoryLayout() == "unified")
print("PASS layout selector and native Combine Bags work independently; separate bags never get section headings")

local reused = assert(shownBag(2))
reused:Hide()
local reusedTitle, reusedShell, children =
    reused.FFXIVUITitle, reused.FFXIVUICount:GetParent(), #reused.children - #reused.pool
ContainerFrame_GenerateFrame(reused, sizes[-2], -2)
checkFrame(reused, "1/9", "Keyring")
reused:Hide(); ContainerFrame_GenerateFrame(reused, sizes[2], 2)
checkFrame(reused, "0/6", "Bag 2")
assert(reused.FFXIVUITitle == reusedTitle and reused.FFXIVUICount:GetParent() == reusedShell
    and #reused.children - #reused.pool == children, "native frame reuse duplicated themed artwork")
local late = container(false)
pool[#pool + 1] = late
ContainerFrame_GenerateFrame(late, sizes[-2], -2)
checkFrame(late, "1/9", "Keyring")
late:Hide()
sizes[5], free[5] = 12, 10
event("BAG_CONTAINER_UPDATE")
assert(reagent.size == 12 and #reagent.Items == 12 and reagent.height == 240 and reagent.FFXIVUICount.text == "2/12")
reagent.CloseButton.scripts.OnClick(); assert(not reagent.shown and backpack.shown)
OpenBag(5); assert(reagent.shown and not root.shown)
manager:OnCombinedBagSettingChanged(true)
assert(root.shown and reagent.shown and not backpack.shown)
root.tracker = object(); root.tracker.height = 20
root:UpdateFrameSize(); root:UpdateCurrencyFrames()
assert(root.height == 484 and root.FFXIVUICount.points[1][1] == "TOPRIGHT" and root.FFXIVUICount.points[1][4] == -40 and root.FFXIVUICount.points[1][5] == -43, "count must sit on the Items line, right-aligned")
print("PASS pooled frame reuse, reagent replacement, independent close actions and watched-currency space")

assert(namespace.SetInventoryLayout("bags"))
combat = true
-- Unprotected native bags opened in combat must get the addon grid, not Blizzard's default layout.
local combatFrame = container(false)
pool[#pool + 1] = combatFrame
ContainerFrame_GenerateFrame(combatFrame, sizes[-2], -2)
checkFrame(combatFrame, "1/9", "Keyring")
combatFrame:UpdateCooldowns(); root:UpdateCooldowns(); event("BAG_UPDATE_COOLDOWN")
checkFrame(combatFrame, "1/9", "Keyring")
combatFrame:Hide()
for _, button in ipairs(root.Items) do button.points = {{"BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0}} end
BagItemSearchBox:ClearAllPoints(); BagItemSearchBox:SetPoint("TOPLEFT", root, "TOPLEFT", 42, -37)
root:UpdateItemLayout(); root:UpdateSearchBox()
checkFrame(root, root.FFXIVUICount.text, "Inventory")
assert(BagItemSearchBox.points[1][4] == 22 and BagItemSearchBox.points[1][5] == -73,
    "search box kept the native combat position")
local calls, oldHeight = skinCalls, root.height
local lockedFrame = container(false)
lockedFrame.protected = true
pool[#pool + 1] = lockedFrame
ContainerFrame_GenerateFrame(lockedFrame, sizes[-2], -2)
assert(lockedFrame.FFXIVUITitle == nil, "protected frame artwork/geometry changed in combat")
sizes[1], free[1] = 30, 29
event("BAG_CONTAINER_UPDATE")
assert(namespace.SetInventoryLayout("bags"))
assert(root.height == oldHeight and skinCalls == calls, "protected geometry changed during combat")
namespace.Themes.Set("Clear Pink")
same(reagent.FFXIVUICount:GetParent().color, namespace.Themes.GetPalette().surface)
local empty = byLocation["0:3"]
-- Rebuilds can reuse a different button for the same slot.
for _, button in ipairs(root.Items) do if button.bag == 0 and button.slot == 3 then empty = button end end
data["0:3"] = {item = 600}; root:UpdateItems()
assert(empty.icon.shown and skinState(empty).overlay.Gloss.shown)
data["0:3"] = nil; root:UpdateItems()
assert(not empty.icon.shown and not skinState(empty).overlay.Gloss.shown)
assert(skinState(empty).backdrop.width == 40 * 58 * 0.92 / 56
    and skinState(empty).normal.width == 40 * 58 * 0.92 / 52)
free[0] = 13; event("BAG_UPDATE_DELAYED")
assert(root.FFXIVUICount.text == "4/56" and reagent.FFXIVUICount.text == "2/12")
combat = false; lockedFrame.protected = false; event("PLAYER_REGEN_ENABLED")
assert(skinCalls > calls and root.height == 568 and #root.Items == 60)
checkFrame(lockedFrame, "1/9", "Keyring")
local count = #created
event("ADDON_LOADED"); assert(#created == count, "installation is not idempotent")
CloseAllBags(); manager:OnCombinedBagSettingChanged(false); gamepad = true
ToggleAllBags()
assert(root.shown and reagent.shown and not backpack.shown, "native controller combined mode was overridden")
ToggleAllBags(); assert(not IsAnyBagOpen())
assert(root.FFXIVUITitle.justify == "LEFT", "Inventory title must be left-aligned")
assert(root.FFXIVUITitle.font[2] == 18 and root.FFXIVUICount.font[2] == 14, "title and count sizes changed")
assert(root.PortraitButton.width == 24 and root.PortraitButton.height == 24, "options button must be a 24px gear")
local tokenButton = object()
tokenButton.Border = object()
tokenButton.Border.alpha = 1
root.tracker.tokenButtons = {tokenButton}
root:UpdateCurrencyFrames()
assert(tokenButton.Border.alpha == 0, "currency icon frame must be removed")
print("PASS combat-safe themes/counts/visibility, deferred layout, idempotency and native controller routing")
print("PASS inventory title left-aligned and currency icon frames removed")

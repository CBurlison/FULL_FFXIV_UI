local addonName, ns = ...
local objects, methods, combat = {}, {}, false
local applyControlTemplate = assert(loadfile("tests\\support\\PanelTemplates.lua"))()
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local fontMethods = {GetFont = true, SetFont = true, SetText = true, SetTextColor = true,
    GetTextColor = true, SetShadowColor = true, SetShadowOffset = true, SetJustifyH = true,
    SetJustifyV = true, SetWordWrap = true}
local function object(kind, parent)
    local value = setmetatable({kind = kind, parent = parent, regions = {}, children = {}, points = {},
        scripts = {}, width = 40, height = 32, level = 4, shown = true, alpha = 1, enabled = true},
        {__index = function(self, key)
            if fontMethods[key] and self.kind ~= "FontString" and self.kind ~= "EditBox" then return nil end
            if key == "GetFontString" and self.kind ~= "Button" and self.kind ~= "DropdownButton" then return nil end
            return methods[key]
        end})
    if parent then
        local list = (kind == "Texture" or kind == "FontString") and parent.regions or parent.children
        list[#list + 1] = value
    end
    objects[#objects + 1] = value
    return value
end
function CreateFrame(kind, _, parent, template)
    local frame = object(kind, parent)
    applyControlTemplate(frame, parent, template)
    return frame
end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return unpack(self.regions) end
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
function methods:CreateFontString() return object("FontString", self) end
function methods:CreateMaskTexture() return object("Texture", self) end
function methods:AddMaskTexture(mask) self.mask = mask end
function methods:RemoveMaskTexture(mask) if self.mask == mask then self.mask = nil end end
function methods:GetFont() return self.font, self.fontSize, "" end
function methods:SetFont(font, size) self.font, self.fontSize = font, size end
function methods:SetText(text) assert(self.font, "font not set"); self.text = text end
function methods:GetStringHeight() return self.text and self.text ~= "" and self.fontSize or 0 end
function methods:SetShadowColor(...) self.shadow = {...} end
function methods:SetShadowOffset() end
function methods:SetTextColor(...) self.color = {...} end
function methods:GetTextColor() return unpack(self.color or {1, 1, 1, 1}) end
function methods:GetFontString() return self.Text end
function methods:SetJustifyH(value) self.justify = value end
function methods:SetJustifyV(value) self.justifyV = value end
function methods:SetWordWrap(value) self.wordWrap = value end
function methods:SetTexture(path) self.texture = path end
function methods:GetTexture() return self.texture end
function methods:SetAtlas(atlas) self.atlas = atlas end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:SetStatusBarColor(...) self.color = {...} end
function methods:SetTexCoord(...) self.coords = {...} end
function methods:GetTexCoord() return unpack(self.coords or {0, 1, 0, 1}) end
function methods:SetDrawLayer() end
function methods:SetBlendMode() end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:SetAllPoints(owner) self.allPoints = owner end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:GetNumPoints() return #self.points end
function methods:GetPoint(index) return unpack(self.points[index]) end
function methods:SetSize(w, h)
    local changed = self.width ~= w or self.height ~= h
    self.width, self.height = w, h
    if changed and self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self, w, h) end
end
function methods:SetWidth(w) self:SetSize(w, self.height) end
function methods:SetHeight(h) self:SetSize(self.width, h) end
function methods:GetSize() return self.width, self.height end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(level) self.level = level end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetBackdrop(value) self.backdrop = value end
function methods:SetBackdropColor(...) self.backdropColor = {...} end
function methods:SetBackdropBorderColor(...) self.borderColor = {...} end
function methods:SetHorizTile() end
function methods:SetVertTile() end
function methods:IsShown() return self.shown end
function methods:IsProtected() return false end
function methods:IsEnabled() return self.enabled end
function methods:SetEnabled(value)
    self.enabled = value
    local callback = self.scripts[value and "OnEnable" or "OnDisable"]
    if callback then callback(self) end
end
function methods:GetID() return self.id end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetShown(shown) self.shown = shown end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript(name, callback)
    local old = self.scripts[name]
    self.scripts[name] = function(...) if old then old(...) end; callback(...) end
end
function methods:RegisterEvent() end
function methods:RegisterUnitEvent() end
function methods:ForEachFrame(callback) for _, row in ipairs(self.frames) do callback(row) end end
function InCombatLockdown() return combat end
function hooksecurefunc(owner, name, callback)
    local original = assert(owner[name], name)
    owner[name] = function(...) original(...); callback(...) end
end
C_Timer = {After = function(_, callback) callback() end}
ScrollUtil = {}
function ScrollUtil.AddInitializedFrameCallback(box, callback, owner)
    assert(not box.callback, "duplicate scroll callback")
    box.callback = function(row) callback(owner, row) end
end
local function label(parent, text)
    local value = parent:CreateFontString()
    value:SetFont("native", 12)
    value:SetText(text or "Localized native label")
    return value
end
local function button(parent)
    local value = object("Button", parent)
    value.Background = value:CreateTexture()
    value.Text = label(value)
    value.scripts.OnClick = function() return "native action" end
    return value
end
local function rank(parent)
    local bar = object("Frame", parent)
    bar.width, bar.height = 200, 18
    for _, key in ipairs({"Background", "Border", "Fill", "Flare"}) do bar[key] = bar:CreateTexture() end
    bar.Rank = object("Frame", bar)
    bar.Rank:SetPoint("LEFT", bar, "LEFT", 0, -3)
    bar.Rank:SetPoint("RIGHT", bar, "RIGHT", 0, -3)
    bar.Rank.Text = label(bar.Rank, "Blacksmithing 75 / 300")
    bar.Rank.Text:SetSize(0, 9)
    function bar:Update(info)
        self.ratio = info.max > 0 and info.rank / info.max or 0
        self.Rank.Text:SetTextColor(1, 1, 1)
    end
    bar:Update({rank = 75, max = 300})
    return bar
end
local function recipe(parent)
    local row = object("Frame", parent)
    row.Label, row.Count = label(row, "Native Recipe"), label(row, "12")
    row.learned = true
    row.SkillUps = object("Frame", row)
    row.SkillUps.Text = label(row.SkillUps, "+1")
    row.SkillUps.Text:SetTextColor(1, 0.5, 0)
    row.SelectedOverlay, row.HighlightOverlay = row:CreateTexture(), row:CreateTexture()
    row.scripts.OnClick = function() return "native recipe selection" end
    function row:SetLabelFontColors() self.Label:SetVertexColor(1, 1, 0); self.Count:SetVertexColor(1, 1, 0) end
    return row
end
local function header(parent)
    local row = object("Frame", parent)
    row.Background = row:CreateTexture()
    row.ButtonText = label(row, "Armor (4)")
    row.CollapseButton = button(row)
    row.RankBar = object("StatusBar", row)
    function row.CollapseButton:UpdateCollapsedState(collapsed) self.collapsed = collapsed end
    function row:CheckHighlightTitle() self.ButtonText:SetTextColor(1, 1, 0) end
    row.CollapseButton:UpdateCollapsedState(false)
    row.scripts.OnClick = function() row.CollapseButton:UpdateCollapsedState(not row.CollapseButton.collapsed) end
    return row
end
local env = {}
Enum = {PowerType = {Rage = 1, Energy = 3, Mana = 0}}
Enum.SpellBookItemType = {Spell = 1, Flyout = 3}
Enum.SpellBookSpellBank = {Player = 0}
local ownedReagents = {[2840] = 2}
Professions = {GetReagentName = function(reagent) return reagent.itemID == 2840 and "Copper Bar" end}
ProfessionsUtil = {GetReagentQuantityInPossession = function(reagent) return ownedReagents[reagent.itemID] end}
local bookItems = {
    [1] = {spellID = 2018, itemType = 1},
    [2] = {spellID = 3273, itemType = 1},
}
C_SpellBook = {GetSpellBookItemInfo = function(index) return bookItems[index] end}
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\RoundedPanels.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\WindowControls.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Core.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Items.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Spells.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\ButtonSkins.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Professions.lua"))("FFXIV_UI", env)
local function S(button) return env.GetButtonSkinState(button) or {} end
local watcher = objects[#objects]
local function event(name) watcher.scripts.OnEvent(watcher, name) end
event("PLAYER_LOGIN")

ProfessionsFrame = object("Frame")
local frame = ProfessionsFrame
frame.width, frame.height = 750, 594
frame.TitleContainer = object("Frame", frame)
frame.TitleContainer.TitleText = label(frame.TitleContainer, "Professions")
frame.CloseButton = button(frame)
frame.Bg = frame:CreateTexture()
frame.NineSlice = object("Frame", frame)
frame.PortraitContainer = object("Frame", frame)
frame.rightProfessionTabs = {}
for i = 1, 8 do
    local tab = object("Frame", frame)
    tab.id = i
    tab.Icon, tab.Background, tab.Mask = tab:CreateTexture(), tab:CreateTexture(), tab:CreateTexture()
    tab.Icon:SetTexture("Native profession icon " .. i)
    tab.Icon:AddMaskTexture(tab.Mask)
    tab.skillLine = ({0, 164, 171, 185, 356, 129, 186, 333})[i]
    tab.TabGlow = tab:CreateTexture()
    tab.tooltipText = "Native profession"
    tab.scripts.OnMouseUp = function() return "native profession switch" end
    function tab:SetChecked(value) self.checked = value end
    if i == 1 then frame.ProfessionsOverviewTab = tab else table.insert(frame.rightProfessionTabs, tab) end
end
frame.rightProfessionTabs[7]:Hide()
frame.selectedGamepadTabID = 1
frame.TabIndicators = object("Frame", frame)
frame.TabIndicators.isVertical = true
frame.TabIndicators.currentIndex = 1
function frame.TabIndicators:UpdateTabVisibility()
    self.updates = (self.updates or 0) + 1
    self.currentIndex = 1
    self.visibleTabs = {frame.ProfessionsOverviewTab}
    for _, tab in ipairs(frame.rightProfessionTabs) do
        if tab:IsShown() then self.visibleTabs[#self.visibleTabs + 1] = tab end
    end
end
function frame.TabIndicators:SetCurrentIndex(index) self.currentIndex = index end
function frame.TabIndicators:UpdateTabIndicators() end
function frame:RightTabSelected(tab)
    self.selectedGamepadTabID = tab.id
    self.ProfessionsOverviewTab:SetChecked(tab == self.ProfessionsOverviewTab)
    for _, other in ipairs(self.rightProfessionTabs) do other:SetChecked(other == tab) end
end
function frame:RefreshRightTabs() end
function frame:Update() end
function frame:SelectBookPage() end
frame.BookPage = object("Frame", frame)
local book = frame.BookPage
book.Background = book:CreateTexture()
book.ProfessionsContentFrame = object("Frame", book)
function book:Update() end
for _, key in ipairs({"PrimaryProfession1", "PrimaryProfession2", "SecondaryProfession1",
    "SecondaryProfession2", "SecondaryProfession3"}) do
    local card = object("Frame", book.ProfessionsContentFrame)
    book.ProfessionsContentFrame[key] = card
    card.Background = card:CreateTexture()
    card.ProfessionName = label(card, "Blacksmithing")
    card.skillLine = key == "SecondaryProfession3" and 129 or 164
    card.professionInitialized, card.spellOffset = true, key == "SecondaryProfession3" and 1 or 0
    card.icon = card:CreateTexture()
    card.icon:SetTexture("native card icon")
    card.StatusBar = rank(card)
    card.UnlearnButton = button(card)
    card.UnlearnButton:SetPoint("LEFT", card.StatusBar, "RIGHT", 1, -4)
    card.GamepadUnlearnButton = object("Frame", card)
    local spell = button(card)
    spell.id = 1
    spell.width = 46
    spell.IconTexture, spell.IconTextureOverlay = spell:CreateTexture(), spell:CreateTexture()
    spell.IconTexture:SetTexture("native spell")
    spell.spellString, spell.subSpellString = label(spell), label(spell)
    card.spellButtons = {spell}
end
frame.CraftingPage = object("Frame", frame)
local page = frame.CraftingPage
frame.Pages = {book, page}
page.RankBar = rank(page)
page.RecipeList = object("Frame", page)
local list = page.RecipeList
list.Background = list:CreateTexture()
list.BackgroundNineSlice = object("Frame", list)
list.SearchBox = object("EditBox", list)
list.SearchBox:SetFont("native", 12)
list.SearchBox.Instructions = label(list.SearchBox, "Search")
list.FilterDropdown = button(list)
list.ScrollBox = object("Frame", list)
list.ScrollBar = object("Frame", list)
local category, row = header(list.ScrollBox), recipe(list.ScrollBox)list.ScrollBox.frames = {category, row}
page.SchematicForm = object("Frame", page)
local form = page.SchematicForm
form.OutputText = label(form, "Copper Sword")
form.OutputIcon = button(form)
form.OutputIcon.Icon = form.OutputIcon:CreateTexture()
form.OutputIcon.IconBorder = form.OutputIcon:CreateTexture()
form.OutputIcon.NativeCircle = form.OutputIcon:CreateTexture()
function form.OutputIcon:GetNormalTexture() return self.NativeCircle end
form.OutputIcon.CountShadow = form.OutputIcon:CreateTexture()
form.OutputIcon.Count = label(form.OutputIcon, "1")
form.Description = label(form, "Native description")
form.RequiredTools = label(form, "Requires: Flint and Tinder")
form.RequiredTools:Hide()
form.FavoriteButton = button(form)
form.Reagents = object("Frame", form)
local slots = {}
form.reagentSlotPool = {}
function form.reagentSlotPool:EnumerateActive()
    local index = 0
    return function() index = index + 1; return slots[index] end
end
local function reagent(structured)
    local slot = object("Frame", form)
    slot.Name = label(slot, "Copper Bar")
    slot.nameText, slot.available = "2/6 Copper Bar", false
    function slot:GetNameColor()
        return {GetRGB = function() if slot.available then return 1, 1, 1 else return 0.5, 0.5, 0.5 end end}
    end
    function slot:Update()
        self.Name:SetText(self.available and "|cffffffff" .. self.nameText .. "|r"
            or "|cff808080" .. self.nameText .. "|r")
    end
    slot.Button = button(slot)
    slot.Button.Icon = slot.Button:CreateTexture()
    slot.Button.IconBorder = slot.Button:CreateTexture()
    slot.Button.InputOverlay = object("Frame", slot.Button)
    function slot.Button:UpdateOverlay() end
    function slot.Button:SetModifyingRequired(value) self.showLargeAddIcon = value end
    slot.Button.Count = label(slot.Button, "2/6")
    slot.Button.Count:SetTextColor(1, 0.1, 0.1)
    if structured then
        slot.reagentSlotSchematic = {required = true, quantityRequired = 6, reagents = {{itemID = 2840}}}
        function slot:GetReagentSlotSchematic() return self.reagentSlotSchematic end
    end
    slots[#slots + 1] = slot
    return slot
end
local firstReagent = reagent(true)
function form:Init() end
function page:Refresh() end
function page:SchematicPostInit() end
page.CreateButton, page.CreateAllButton = button(page), button(page)
page.CreateMultipleInputBox = object("EditBox", page)
page.CreateMultipleInputBox:SetFont("native", 12)
page.CreateMultipleInputBox:SetText("3")
page.CreateMultipleInputBox.DecrementButton, page.CreateMultipleInputBox.IncrementButton = button(page), button(page)
page.TutorialButton, page.LinkButton = button(page), button(page)
frame.TabSystem = {tabs = {button(frame)}}
local nativeClick = page.CreateButton.scripts.OnClick
combat = true
local before = #objects
event("ADDON_LOADED")
assert(#objects == before and frame.height == 594, "installed in combat")
combat = false
event("PLAYER_REGEN_ENABLED")
local function color(actual, expected)
    for i = 1, 3 do
        assert(math.abs(actual[i] - expected[i]) < 0.0001,
            debug.traceback("color mismatch: " .. table.concat(actual, ",") .. " vs " .. table.concat(expected, ",")))
    end
end
assert(frame.height == 642 and page.points[1][5] == -48)
assert(frame.Bg.alpha == 0 and book.Background.alpha == 0)
assert(frame.CloseButton.width == 24 and frame.CloseButton.points[1][4] == -6)
assert(not frame.TabIndicators.isVertical and frame.TabIndicators.currentIndex == 1)
for _, tab in ipairs({frame.ProfessionsOverviewTab, unpack(frame.rightProfessionTabs, 1, 6)}) do
    assert(tab.height == 40 and tab.width == 40 and tab.points[1][5] == -34)
    assert(not tab.Icon.mask, "native mask clips supplied profession icon")
    if tab.skillLine ~= 129 then
        assert(tab.Icon.coords[1] == 0 and tab.Icon.coords[2] == 1, "supplied profession icon cropped")
    end
    assert(tab.points[1][4] + tab.width < frame.width and tab.Icon.alpha == 1)
    assert(not tab.GetChecked, "test must match SetChecked-only native API")
end
assert(row.Label.text == "Native Recipe" and row.Count.text == "12")
assert(row.SkillUps.Text.color[2] == 0.5, "skill-up semantic color lost")
local comboRoot = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\ComboBox-"
assert(category.FFXIVUIHeader.pieces[1].region.texture == comboRoot .. "Open-Dark.tga")
category.scripts.OnClick()
assert(category.FFXIVUIHeader.pieces[1].region.texture == comboRoot .. "Closed-Dark.tga"
    and category.ButtonText.text == "Armor (4)")
assert(category.Background.alpha == 0 and category.ButtonText.points[1][4] == 26)
assert(page.CreateButton.scripts.OnClick == nativeClick and nativeClick() == "native action")
assert(page.CreateMultipleInputBox.text == "3")
assert(page.TutorialButton.points[1][2] == page and page.TutorialButton.points[1][4] == 12 and page.TutorialButton.points[1][5] == -42,
    "info button moved off the title row")
assert(page.LinkButton.points[1][3] == "TOPRIGHT" and page.LinkButton.points[1][4] == -12 and page.LinkButton.points[1][5] == -42,
    "link button clear of the rank bar")
assert(S(form.OutputIcon).style == "Equipment" and S(firstReagent.Button).normal)
assert(form.OutputIcon.IconBorder.alpha == 1 and firstReagent.Button.IconBorder.alpha == 1,
    "native item-quality indicators suppressed")
assert(not form.OutputIcon.NativeCircle.shown and form.OutputIcon.CountShadow.alpha == 0)
assert(form.OutputIcon.IconBorder.atlas == "Professions-Slot-Frame"
    and form.OutputIcon.IconBorder.allPoints == form.OutputIcon.Icon,
    "output quality border still uses oversized circular artwork")
form.OutputIcon.IconBorder:SetVertexColor(0.2, 0.7, 1)
form.OutputIcon.IconBorder:SetAtlas("auctionhouse-itemicon-border-white")
assert(form.OutputIcon.IconBorder.atlas == "Professions-Slot-Frame",
    "native item refresh restored circular quality border")
assert(form.OutputIcon.IconBorder.color[1] == 0.2 and form.OutputIcon.IconBorder.color[2] == 0.7,
    "square output border lost native item-quality coloring")
firstReagent.Button:SetModifyingRequired(true)
assert(firstReagent.Button.FFXIVUIRequiredAddIcon.shown, "required-modification add indicator lost")
firstReagent.Button.locked = true
firstReagent.Button:UpdateOverlay()
assert(not firstReagent.Button.FFXIVUIRequiredAddIcon.shown, "locked reagent shows add action")
assert(S(book.ProfessionsContentFrame.PrimaryProfession1.spellButtons[1]).normal)
local primary = book.ProfessionsContentFrame.PrimaryProfession1
assert(primary.StatusBar.height == 22 and primary.UnlearnButton.height == 22)
assert(primary.UnlearnButton.points[1][2] == primary.StatusBar and primary.UnlearnButton.points[1][5] == 0,
    "unlearn button not centered on skill bar")
assert(primary.GamepadUnlearnButton.points[1][5] == 0)
assert(primary.FFXIVUIOverviewPanel and not primary.FFXIVUIOverviewPanel.backdrop,
    "overview card uses a square backdrop instead of rounded artwork")
local content = book.ProfessionsContentFrame
assert(-content.PrimaryProfession2.points[1][5] >= primary.height + 8)
assert(-content.SecondaryProfession1.points[1][5]
    >= -content.PrimaryProfession2.points[1][5] + content.PrimaryProfession2.height + 8)
for _, key in ipairs({"PrimaryProfession1", "PrimaryProfession2", "SecondaryProfession1",
    "SecondaryProfession2", "SecondaryProfession3"}) do
    local card = content[key]
    for _, spell in ipairs(card.spellButtons) do
        assert(-spell.points[1][5] + spell.height <= card.height, "overview ability exceeds its panel")
        assert(spell.spellString.points[2][2] == card, "overview ability label is not bounded to its card")
    end
end
assert(page.FFXIVUIRankDivider.height == 1 and page.FFXIVUICenterDivider.width == 1)
assert(page.FFXIVUICenterDivider.points[2][2] == list)
assert(list.FFXIVUISearchPanel.height == 64)
assert(list.FFXIVUISearchPanel.regions[1].text == "Recipe Search")
assert(list.SearchBox.points[1][2] == list.FFXIVUISearchPanel and list.SearchBox.points[1][5] == -34)
assert(list.ScrollBox.points[1][2] == list.FFXIVUISearchPanel)
assert(list.ScrollBar.FFXIVUIScrollBar, "recipe list scroll bar must use the Menu style")
assert(form.OutputIcon.points[1][2] == form.FFXIVUIRecipeHeader)
assert(form.FavoriteButton.points[1][2] == form.FFXIVUIRecipeHeader
    and form.FavoriteButton.scripts.OnClick() == "native action")
assert(list.FFXIVUISearchPanel.level < list.SearchBox.level, "search panel covers native search content")
assert(form.FFXIVUIRecipeHeader.level < form.level, "recipe header covers native item text")
assert(list.FFXIVUISearchPanel.FFXIVUIBackground.level < list.SearchBox.level)
assert(form.FFXIVUIRecipeHeader.FFXIVUIBackground.level < form.level)
assert(form.FFXIVUIRecipeHeader.height == 76)
assert(form.Description.points[1][2] == form.FFXIVUIRecipeHeader
    and form.Description.points[1][3] == "BOTTOMLEFT" and form.Description.points[1][5] == -12,
    "recipe description must be outside and below the item header")
assert(form.Reagents.points[1][2] == form.Description and firstReagent.points[1][2] == form.Reagents,
    "reagent rows must sit below the Reagents label instead of overlapping it")
form.RequiredTools:Show()
form:Init()
assert(form.RequiredTools.points[1][2] == form.FFXIVUIRecipeHeader
    and form.RequiredTools.points[1][3] == "BOTTOMLEFT" and form.RequiredTools.points[1][5] == -12,
    "recipe requirements overlap the header border")
assert(form.Description.points[1][2] == form.RequiredTools
    and form.Description.points[1][3] == "BOTTOMLEFT" and form.Description.points[1][5] == -8,
    "recipe description must follow visible requirements")
assert(form.RequiredTools.text == "Requires: Flint and Tinder", "native requirements text was replaced")
form.RequiredTools:Hide()
form:Init()
assert(form.Description.points[1][2] == form.FFXIVUIRecipeHeader,
    "hidden requirements leave a gap above the description")
assert(firstReagent.FFXIVUIColumns and firstReagent.Button.Count.alpha == 0)
assert(firstReagent.FFXIVUIRequired.points[1][4] == nil and firstReagent.Button.points[1][4] == 32)
assert(firstReagent.FFXIVUIOwned.points[1][4] == 76 and firstReagent.Name.points[1][4] == 144)
assert(firstReagent.FFXIVUIReagentDivider.width == 1)
assert(firstReagent.Button.scripts.OnClick() == "native action")
for _, bar in ipairs({page.RankBar, primary.StatusBar}) do
    assert(bar.Rank.allPoints == bar and #bar.Rank.points == 0, "native rank offset remains")
    assert(bar.Rank.Text.points[1][5] == -2 and bar.Rank.Text.points[2][5] == 2,
        "rank label not bounded by container")
    assert(bar.Rank.Text.justifyV == "MIDDLE" and bar.Rank.Text.wordWrap == false)
end
local iconRoot = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Professions\\"
assert(primary.icon.texture == iconRoot .. "Blacksmith.tga")
assert(primary.spellButtons[1].IconTexture.texture ~= nil
    and not tostring(primary.spellButtons[1].IconTexture.texture):find("SpellIcons", 1, true),
    "profession ability icon replaced with custom artwork")
assert(not tostring(book.ProfessionsContentFrame.SecondaryProfession3.spellButtons[1].IconTexture.texture)
    :find("SpellIcons", 1, true), "overview ability icon replaced with custom artwork")
assert(frame.ProfessionsOverviewTab.Icon.texture == iconRoot .. "Professions.tga",
    "overview button ignores supplied profession-window artwork")
local iconNames = {[164] = "Blacksmith", [165] = "Leatherworker", [171] = "Alchemist",
    [182] = "Herbalism", [185] = "Cooking", [186] = "Mining", [197] = "Tailoring",
    [202] = "Engineer", [333] = "Enchanting", [356] = "Fishing", [129] = "FirstAid"}
local tab = frame.rightProfessionTabs[1]
local squarePanel = tab.children[1]
local squareArt = assert(squarePanel.FFXIVUIControlArt, "profession tab lost theme materials")
assert(not squarePanel.backdrop and #squareArt.fill == 1 and #squareArt.border == 1,
    "square tab should use full rounded square textures, not pointed-end artwork or a flat backdrop")
assert(squareArt.fill[1].texture:find("Square-fill-Standard.tga", 1, true))
assert(tab.TabGlow.texture == squareArt.fill[1].texture and tab.TabGlow.color[4] == 0.15,
    "notification retains curved side-tab artwork")
tab.scripts.OnEnter()
color(squareArt.fill[1].color, env.Themes.GetPalette().selected)
tab.scripts.OnLeave()
color(squareArt.fill[1].color, env.Themes.GetPalette().tab)
local lastNative
for id, name in pairs(iconNames) do
    tab.skillLine = id
    tab.Icon:SetTexture("native " .. id)
    frame:RefreshRightTabs()
    assert(tab.Icon.texture == iconRoot .. name .. ".tga")
    tab.Icon:SetTexture("native refresh " .. id)
    lastNative = "native refresh " .. id
    assert(tab.Icon.texture == iconRoot .. name .. ".tga", "native refresh restored WoW artwork")
end
tab.skillLine = 393
frame:RefreshRightTabs()
assert(tab.Icon.texture == lastNative, "unmapped profession retained another profession's artwork")
tab.Icon:SetTexture("native Skinning")
assert(tab.Icon.texture == "native Skinning")
tab.skillLine = 164
frame:RefreshRightTabs()
page.RankBar:Update({rank = 150, max = 300})
assert(page.RankBar.FFXIVUIRankFill.width == (page.RankBar.width - 4) / 2)
page.RankBar:Update({rank = 300, max = 300})
assert(page.RankBar.FFXIVUIRankFill.width == page.RankBar.width - 4 and page.RankBar.FFXIVUIRankFill.shown)
page.RankBar:Update({rank = 0, max = 0})
assert(not page.RankBar.FFXIVUIRankFill.shown)
print("PASS overview, crafting, native square slots, progress, top tabs, section toggles and actions")
local function luminance(rgb)
    local total = 0
    for i, weight in ipairs({0.2126, 0.7152, 0.0722}) do
        local value = rgb[i]
        total = total + weight * (value <= 0.04045 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4)
    end
    return total
end
for _, theme in ipairs(env.Themes.GetNames()) do
    env.Themes.Set(theme)
    row:SetLabelFontColors()
    category:CheckHighlightTitle()
    local palette = env.Themes.GetPalette()
    local material = theme:find("^Clear ") and "Clear" or theme == "Classic FF" and "Classic" or "Standard"
    assert(squareArt.fill[1].texture:find("Square-fill-" .. material .. ".tga", 1, true),
        "square tab does not follow theme material")
    assert(squareArt.border[1].texture:find("Square-border-" .. material .. ".tga", 1, true))
    color(squareArt.fill[1].color, palette.tab)
    color(squareArt.border[1].color, palette.border)
    tab:SetChecked(true)
    color(squareArt.fill[1].color, palette.selected)
    color(squareArt.border[1].color, palette.accent)
    assert(squareArt.fill[1].desaturated and squareArt.border[1].desaturated,
        "profession tab artwork retains its baked-in gold tint")
    assert(tab.TabGlow.desaturated)
    color(tab.TabGlow.color, palette.tab)
    assert(tab.TabGlow.texture == squareArt.fill[1].texture, "notification material differs from tab")
    tab:SetChecked(false)
    color(row.Label.color, palette.text)
    color(category.ButtonText.color, palette.text)
    assert(category.FFXIVUIHeader.pieces[1].region.texture:find("ComboBox-", 1, true))
    color(page.RankBar.FFXIVUIRankFill.color, palette.accent)
    page.RankBar:Update({rank = 50, max = 75})
    local textLuminance = luminance(page.RankBar.Rank.Text.color)
    for _, filled in ipairs({false, true}) do
        local background = {}
        for i = 1, 3 do
            local alpha = filled and page.RankBar.FFXIVUIRankFill.alpha or 0
            background[i] = palette.accent[i] * alpha + palette.inset[i] * (1 - alpha)
        end
        local backdropLuminance = luminance(background)
        local contrast = (math.max(textLuminance, backdropLuminance) + 0.05)
            / (math.min(textLuminance, backdropLuminance) + 0.05)
        assert(contrast >= 4.5, theme .. " rank text contrast below 4.5:1")
    end
    color(firstReagent.Button.Count.color, palette.detrimental)
    firstReagent:Update()
    assert(firstReagent.Name.text == "Copper Bar", "reagent name still contains combined quantities")
    assert(firstReagent.FFXIVUIRequired.text == 6 and firstReagent.FFXIVUIOwned.text == 2)
    color(firstReagent.Name.color, palette.muted)
end
firstReagent.Button.Count:SetTextColor(1, 1, 1)
env.Themes.Set("Light")
color(firstReagent.Button.Count.color, env.Themes.GetPalette().text)
firstReagent.available = true
firstReagent:Update()
color(firstReagent.Name.color, env.Themes.GetPalette().text)
firstReagent.nameText = "6/6 Copper Bar"
ownedReagents[2840] = 6
firstReagent:Update()
assert(firstReagent.Name.text == "Copper Bar" and firstReagent.FFXIVUIOwned.text == 6, "live quantities lost")
page.CreateButton:SetEnabled(false)
color(page.CreateButton.Text.color, env.Themes.GetPalette().muted)
page.CreateButton:SetEnabled(true)
color(page.CreateButton.Text.color, env.Themes.GetPalette().tabText)
row.learned = false
row:SetLabelFontColors()
color(row.Label.color, env.Themes.GetPalette().muted)
frame:RightTabSelected(frame.rightProfessionTabs[2])
assert(frame.rightProfessionTabs[2].checked and not frame.ProfessionsOverviewTab.checked)
assert(frame.TabIndicators.currentIndex == 3, "native visibility refresh lost selected profession")
frame:SetWidth(782)
assert(frame.height == 642 and page.points[1][5] == -48)
print("PASS all themes, native color refreshes, reagent availability, selection and page widths")
local lateRow = recipe(list.ScrollBox)
list.ScrollBox.frames[#list.ScrollBox.frames + 1] = lateRow
local lateSlot = reagent()
combat = true
before = #objects
env.Themes.Set("Clear Pink")
list.ScrollBox.callback(lateRow)
form:Init()
assert(#objects == before and not S(lateSlot.Button).style)
combat = false
event("PLAYER_REGEN_ENABLED")
assert(S(lateSlot.Button).style and lateRow.Label.font:find("AxisRegular"))
frame.rightProfessionTabs[7]:Show()
frame:RefreshRightTabs()
assert(frame.rightProfessionTabs[7].points[1][4] + 40 < frame.width)
before = #objects
frame:Update()
page:Refresh()
form:Init()
book:Update()
event("PLAYER_LOGIN")
assert(#objects == before and frame.height == 642, "refresh duplicates artwork or grows window")
assert(page.CreateButton.scripts.OnClick == nativeClick)
local originalSchematic = firstReagent.reagentSlotSchematic
firstReagent.reagentSlotSchematic = {required = false, reagents = {{itemID = 2840}}}
firstReagent:Update()
assert(not firstReagent.FFXIVUIColumns and not firstReagent.FFXIVUIRequired.shown
    and not firstReagent.FFXIVUIOwned.shown and firstReagent.Button.Count.alpha == 1,
    "pooled optional reagent retained required-only quantities")
assert(firstReagent.Button.width == firstReagent.FFXIVUINativeReagentGeometry.button.width,
    "pooled reagent did not restore native button geometry")
firstReagent.reagentSlotSchematic = originalSchematic
form:Init()
assert(firstReagent.FFXIVUIColumns and firstReagent.Button.Count.alpha == 0)
print("PASS delayed loading, combat deferral, pooled rows/reagents, profession changes and idempotency")
print("PASS rounded compact overview, divider-only crafting, labeled search, favorite header and structured live reagent columns")
print("PASS supplied/First Aid icons, native refreshes, rounded square theme materials, centered rank/unlearn geometry and 4.5:1 text contrast")

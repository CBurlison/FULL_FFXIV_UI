local addonName, ns = ...
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local objects, methods, combat = {}, {}, false
local applyControlTemplate = assert(loadfile("tests\\support\\PanelTemplates.lua"))()
local spellbookSource = assert(io.open("FFXIV_UI\\General\\Spellbook.xml", "rb")):read("*a")
local function applySpellbookTemplate(value, parent, template)
    if not template or not template:find("^FFXIV_SpellbookHeader") then return end
    local kind, attributes, body = spellbookSource:match('<(%w+) name="' .. template .. '"([^>]-)>(.-)</%1>')
    assert(kind == value:GetObjectType(), "Unexpected Spellbook template type: " .. template)
    value.template = template
    if attributes:find('enableMouse="false"', 1, true) then value:EnableMouse(false) end
    local justify = attributes:match('justifyH="([^"]+)"')
    if justify then value:SetJustifyH(justify) end
    local height = body:match('<Size y="([^"]+)"/>')
    if height then value:SetHeight(tonumber(height)) end
    for anchor in body:gmatch("<Anchor (.-)/>") do
        local point = assert(anchor:match('point="([^"]+)"'))
        value:SetPoint(point, parent, point, tonumber(anchor:match('x="([^"]+)"')) or 0,
            tonumber(anchor:match('y="([^"]+)"')) or 0)
    end
end
local timers = {}
C_Timer = {After = function(_, callback) timers[#timers + 1] = callback end}
local function flush()
    local callbacks = timers
    timers = {}
    for _, callback in ipairs(callbacks) do callback() end
    assert(#timers == 0, "layout refresh schedules itself indefinitely")
end
function CreateColor(...) return {...} end
function methods:SetGradient(direction, startColor, endColor)
    self.gradient = {direction, startColor, endColor}
end
local function object(kind, parent)
    local value = setmetatable({kind = kind or "Frame", parent = parent, regions = {}, children = {}, scripts = {},
        points = {}, shown = true, alpha = 1, enabled = true, width = 40, height = 32, level = 5},
        {__index = methods})
    objects[#objects + 1] = value
    if parent and (kind == "Texture" or kind == "FontString") then
        parent.regions[#parent.regions + 1] = value
    elseif parent then
        parent.children[#parent.children + 1] = value
    end
    return value
end
function CreateFrame(kind, _, parent, template)
    local frame = object(kind, parent)
    applyControlTemplate(frame, parent, template)
    applySpellbookTemplate(frame, parent, template)
    return frame
end
function methods:CreateTexture(_, _, template)
    local texture = object("Texture", self)
    applyControlTemplate(texture, self, template)
    applySpellbookTemplate(texture, self, template)
    if template == "FFXIV_CircularArrowBaseTemplate" or template == "FFXIV_CircularArrowGlyphTemplate"
        or template == "FFXIV_WindowCloseIconTemplate" then
        local file = assert(io.open("FFXIV_UI\\General\\WindowControls.xml", "rb"))
        local xml = file:read("*a")
        file:close()
        texture:SetTexture(assert(xml:match('<Texture name="' .. template .. '" virtual="true" file="([^"]+)"/>')))
    end
    return texture
end
function methods:CreateFontString(_, _, template)
    local text = object("FontString", self)
    applySpellbookTemplate(text, self, template)
    return text
end
function methods:CreateMaskTexture() return object("Texture", self) end
function methods:GetObjectType() return self.kind end
function methods:IsProtected() return self.protected == true end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetChildren() return unpack(self.children) end
function methods:SetAllPoints(owner) self.allPoints = owner end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:GetNumPoints() return #self.points end
function methods:GetPoint(index)
    local point = self.points[index]
    if point then return unpack(point) end
end
function methods:SetSize(w, h)
    assert(w > 0 and h > 0, "invalid frame size")
    local changed = self.width ~= w or self.height ~= h
    self.width, self.height = w, h
    if changed and self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self) end
end
function methods:SetWidth(w) self:SetSize(w, self.height) end
function methods:SetHeight(h) self:SetSize(self.width, h) end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetSize() return self.width, self.height end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameLevel() return self.level end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetBackdrop(value) self.backdrop = value end
function methods:SetBackdropColor(...) self.bg = {...} end
function methods:SetBackdropBorderColor(...) self.border = {...} end
function methods:SetTexture(value) self.texture = value; return true end
function methods:SetColorTexture(...) self.color = {...} end
function methods:SetDrawLayer(layer, sublevel) self.drawLayer, self.sublevel = layer, sublevel end
function methods:SetHorizTile() end
function methods:SetVertTile() end
function methods:GetTexture() return self.texture end
function methods:SetTexCoord(...) self.coords = {...} end
function methods:SetBlendMode(mode) self.blendMode = mode end
function methods:GetTexCoord() return unpack(self.coords or {0, 1, 0, 1}) end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetAlpha(value) self.alpha = value end
function methods:GetAlpha() return self.alpha end
function methods:SetFont(...) self.font = {...} end
function methods:SetFontObject(value) self.fontObject = value end
function methods:GetFont() if self.font then return unpack(self.font) end end
function methods:SetTextColor(...) self.color = {...} end
function methods:GetTextColor() return unpack(self.color or {1, 1, 1, 1}) end
function methods:SetShadowColor() end
function methods:SetJustifyH(value) self.justify = value end
function methods:SetWordWrap(value) self.wrap = value end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:SetText(value)
    assert(self.kind ~= "FontString" or self.font, "FontString:SetText(): Font not set")
    self.text = value
end
function methods:GetText() return self.text end
function methods:IsSelected() return self.isSelected end
function methods:IsForceDisabled() return self.forceDisabled end
function methods:GetTooltipText() return self.tooltipText end
function methods:SetTabSelected(value) self.isSelected = value; self.Text:SetAlpha(1) end
function methods:SetTabEnabled(value) self.forceDisabled = not value end
function methods:SetEnabled(value)
    self.enabled = value
    local callback = self.scripts[value and "OnEnable" or "OnDisable"]
    if callback then callback(self) end
end
function methods:IsEnabled() return self.enabled end
function methods:IsShown() return self.shown end
function methods:SetShown(value) self.shown = value end
function methods:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:GetScript(name) return self.scripts[name] end
function methods:HookScript(name, callback)
    local original = self.scripts[name]
    self.scripts[name] = function(...) if original then original(...) end; callback(...) end
end
function methods:RegisterEvent() end
function InCombatLockdown() return combat end
function hooksecurefunc(owner, name, callback)
    local original = assert(owner[name], name)
    owner[name] = function(...) original(...); callback(...) end
end
EventRegistry = {callbacks = {}}
function EventRegistry:RegisterCallback(name, callback)
    assert(not self.callbacks[name], "duplicate registry callback")
    self.callbacks[name] = callback
end
ScrollUtil = {}
function ScrollUtil.AddInitializedFrameCallback(box, callback, owner)
    assert(not box.initialized, "duplicate preview callback")
    box.initialized = function(row) callback(owner, row) end
end
function methods:ForEachFrame(callback) for _, row in ipairs(self.frames) do callback(row) end end
local env = {}
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\RoundedPanels.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\WindowControls.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Core.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Items.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Spells.lua"))("FFXIV_UI", env)
env.ApplyButtonSkin = function(button, regions, style)
    button.skin = style
    regions.Icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)
end
local function label(parent, value)
    local text = parent:CreateFontString()
    text:SetFont("native", 12, "OUTLINE")
    text:SetText(value or "Localized text")
    return text
end
local function button(parent)
    local value = object("Button", parent)
    value.Text = label(value)
    value.Background = value:CreateTexture()
    value.scripts.OnClick = function() return "native click" end
    return value
end
local function row()
    local value = object()
    value.Backplate = value:CreateTexture()
    value.Button = button(value)
    value.Button.Icon = value.Button:CreateTexture()
    value.Button.Border = value.Button:CreateTexture()
    value.Button.scripts.OnDragStart = function() return "native drag" end
    value.Button.scripts.OnEnter = function() return "native tooltip" end
    value.Name, value.SubName, value.RequiredLevel = label(value), label(value), label(value)
    value.spellBookItemInfo = {spellID = 1278067}
    function value:UpdateVisuals()
        self.Name:SetAlpha(0.6)
        self.Button.Icon:SetAlpha(0.6)
        self.Button.Icon:SetVertexColor(0.5, 0.5, 0.5)
        self.Name:SetTextColor(0, 0, 0)
        self.Button.Border:SetAlpha(1)
    end
    return value
end
assert(loadfile("FFXIV_UI\\General\\Spellbook.lua"))("FFXIV_UI", env)
local watcher = objects[#objects]
local function event(name) watcher.scripts.OnEvent(watcher, name) end
local host = object()
host:SetHeight(880)
PlayerSpellsFrame = host
host.spellBookMinimizedWidth, host.spellBookMaximizedWidth = 809, 1618
host.NineSlice, host.PortraitContainer = object(), object()
host.NineSlice.TopEdge = host.NineSlice:CreateTexture()
host.PortraitContainer.portrait = host.PortraitContainer:CreateTexture()
host.CloseButton = button(host)
host.CloseButton:SetPoint("TOPRIGHT", host, "TOPRIGHT", 4, 5)
host.CloseButton:SetSize(32, 32)
host.MaximizeMinimizeButton = object()
host.MaximizeMinimizeButton.MaximizeButton = button(host.MaximizeMinimizeButton)
host.MaximizeMinimizeButton.MinimizeButton = button(host.MaximizeMinimizeButton)
host.TitleContainer = object()
host.TitleContainer.TitleText = label(host.TitleContainer, "Spellbook")
host.TitleContainer.TitleText:SetFont("native-title", 14, "OUTLINE")
host.TitleContainer.TitleText:SetTextColor(1, 0.8, 0)
host.nativeBackground = host:CreateTexture()
host.nativeBackground:SetAlpha(0.7)
local book = object("Frame", host)
book:SetHeight(812)
book:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 0, 4)
host.SpellBookFrame = book
book.isMinimized = true
book.minimizedWidth, book.maximizedWidth = 806, 1612
book.SearchBox = object("EditBox", book)
book.SearchBox.Instructions = label(book.SearchBox, "Search localized")
book.SearchBox.text = "existing query"
book.SearchBox.scripts.OnTextChanged = function() return "native search" end
book.SettingsDropdown = button(book)
local filterChoices, filterRoot = {}, {}
local originalMenuUtil = MenuUtil
MenuUtil = {TraverseMenu = function(description, callback)
    assert(description == filterRoot)
    for _, choice in ipairs(filterChoices) do callback(choice) end
end}
for index = 1, 2 do
    local choice = {selected = index == 2, initializers = {}}
    function choice:IsRadio() return false end
    function choice:IsCheckbox() return true end
    function choice:IsSelected() return self.selected end
    function choice:AddInitializer(initializer)
        for _, existing in ipairs(self.initializers) do if existing == initializer then return end end
        self.initializers[#self.initializers + 1] = initializer
    end
    filterChoices[index] = choice
end
function book.SettingsDropdown:GetMenuDescription() return filterRoot end
function book.SettingsDropdown:OnMenuAssigned() end
function book.SettingsDropdown:OnMenuOpened(menu) self.openMenu = menu end
function book.SettingsDropdown:OnMenuClosed() self.openMenu = nil end
book.HelpPlateButton = button(book)
book.AssistedCombatRotationSpellFrame = object("Frame", book)
local rotation = book.AssistedCombatRotationSpellFrame
rotation:SetPoint("TOPRIGHT", book, "TOPRIGHT", -20, -7)
rotation.Label = label(rotation, "Single-Button")
rotation.Icon = button(rotation)
rotation.Icon.scripts.OnDragStart = function() return "native rotation drag" end
rotation.Icon.scripts.OnEnter = function() return "native rotation tooltip" end
book.PreviousCategoryIcon = object("Frame", book)
book.SearchPreviewContainer = object()
book.SearchPreviewContainer.Background = book.SearchPreviewContainer:CreateTexture()
book.SearchPreviewContainer.ScrollBox = object()
local previewBox = book.SearchPreviewContainer.ScrollBox
local previewRow = button(previewBox)
previewRow.Name = label(previewRow)
previewRow.IconFrame = previewRow:CreateTexture()
previewRow.HighlightTexture = previewRow:CreateTexture()
previewBox.frames = {previewRow}
book.CategoryTabSystem = object()
local system = book.CategoryTabSystem
system.tabs = {}
function system:GetTabButton(id) return self.tabs[id] end
function system:Layout()
    self:SetWidth(self.fixedWidth or 700)
    for _, tab in ipairs(self.tabs) do
        if not tab.ignoreInLayout then tab:SetPoint("LEFT", self, "LEFT", 100, 0) end
    end
    function system:OnCleaned() end
end
function system:SetTabShown(id, value)
    book.categoryMixins[id].available = value
    self.tabs[id]:SetShown(value)
end
book.categoryMixins = {}
local skillLines = {}
C_SpellBook = {GetSpellBookSkillLineInfo = function(index) return skillLines[index] end}
for index, name in ipairs({"General localized", "Holy localized", "Pet localized", "Outfits localized"}) do
    local tab = button(system)
    tab.Icon = tab:CreateTexture()
    tab.Label = label(tab, name)
    tab.LabelContainer = object("Frame", tab)
    tab.LabelContainer.Text = label(tab.LabelContainer, name)
    tab.nativeFontString = object("FontString")
    tab.nativeFontString:SetFont("native", 12, "OUTLINE")
    tab.nativeFontString:SetText(name)
    function tab:GetFontString() return self.nativeFontString end
    tab.shown = index ~= 3
    system.tabs[index] = tab
    tab.tooltipText = name
    local category = {skillLineIndex = index <= 2 and index or nil, available = index ~= 3}
    skillLines[index] = {name = name}
    function category:GetTabID() return index end
    function category:GetName() return index > 2 and name or nil end
    function category:IsAvailable() return self.available end
    book.categoryMixins[index] = category
end
system.tabs[1].isSelected = true
book.PagedSpellsFrame = object()
local paged = book.PagedSpellsFrame
paged.frames = {object(), row()}
paged.frames[2].TextContainer = object("Frame", paged.frames[2])
paged.ViewFrames = {object("Frame", paged), object("Frame", paged)}
paged.cachedTemplateInfos = {HEADER = {height = 40}, SPELL = {height = 60}}
function paged:ProcessTemplateInfo() end
function paged:InternalGetTemplateInfo(key) return self.cachedTemplateInfos[key] end
function paged:ProcessElementFrame() end
function paged:UpdateLayouts()
    assert(self.dataProvider, "native grid rebuilt before a data provider was attached")
    self.layoutUpdates = (self.layoutUpdates or 0) + 1
    for _, frame in ipairs(self.frames) do
        self:ProcessElementFrame(frame, {templateKey = frame.Button and "SPELL" or "HEADER"})
    end
    EventRegistry.callbacks["PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged"]()
end
paged.frames[1].Text = label(paged.frames[1], "General localized")
paged.frames[1].Border = paged.frames[1]:CreateTexture()
function paged:EnumerateFrames() return ipairs(self.frames) end
paged.PagingControls = object()
paged.PagingControls.PageText = label(paged.PagingControls, "Page 1/3")
paged.PagingControls.PrevPageButton = button(paged.PagingControls)
paged.PagingControls.NextPageButton = button(paged.PagingControls)
function host:UpdateSize()
    self:SetWidth(book:IsShown() and (book.isMinimized and 577 or 1154) or 1218)
end
function book:ApplyInputModeSizing()
    self.minimizedWidth, self.maximizedWidth = 806, 1612
    self:SetWidth(self.isMinimized and self.minimizedWidth or self.maximizedWidth)
    host:SetWidth(self.isMinimized and 577 or 1154)
end
function book:ResizeSearchBox()
    self.SearchBox:SetWidth(152 - system:GetWidth() - 10)
end
system:SetScript("OnSizeChanged", function() book:ResizeSearchBox() end)
function book:SetMinimized(value)
    self.isMinimized = value
    self.viewsPerPage = value and 1 or 2
    self:SetWidth(value and self.minimizedWidth or self.maximizedWidth)
    host:UpdateSize()
end
function host:SetMinimized(value)
    book:Hide()
    system:Hide()
    for _, tab in ipairs(system.tabs) do tab:Hide() end
    book:SetMinimized(value)
    book:Show()
end
function host.MaximizeMinimizeButton:Minimize() host:SetMinimized(true) end
function host.MaximizeMinimizeButton:Maximize() host:SetMinimized(false) end
function book:UpdateDisplayedSpells() end
function book:OnPagedSpellsUpdate() end
function book:UpdateAllSpellData() end
function book:CreateCategoryMixins() end
function book:UpdateAttic()
    self.AssistedCombatRotationSpellFrame:ClearAllPoints()
    self.AssistedCombatRotationSpellFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", -20, -7)
    self.AssistedCombatRotationSpellFrame:SetShown(self.rotationAvailable ~= false)
    self.HelpPlateButton:Show()
    self:ResizeSearchBox()
end
local nativeClick = system.tabs[2].scripts.OnClick
local nativeSearch = book.SearchBox.scripts.OnTextChanged
local spell = paged.frames[2]
local nativeDrag, nativeTooltip = spell.Button.scripts.OnDragStart, spell.Button.scripts.OnEnter
combat = true
event("ADDON_LOADED")
assert(host.spellBookMinimizedWidth == 809, "protected layout changed in combat")
combat = false
event("PLAYER_REGEN_ENABLED")
assert(not paged.layoutUpdates and book.FFXIVUIGridNeedsLayout,
    "load-on-demand grid refresh was not deferred until data becomes available")
event("PLAYER_LOGIN")
assert(not paged.layoutUpdates, "another event rebuilt the grid without a data provider")
paged.dataProvider = {}
book:UpdateDisplayedSpells()
assert(not book.FFXIVUIGridNeedsLayout, "deferred grid refresh did not complete")
assert(host.width == 1013 and book.width == 1010, "compact widths do not include sidebar")
assert(spell.width == book.FFXIVUIPageWidth / 2 - 8,
    "default collapsed spell list must fit two columns without widening the window")
assert(book.SearchBox.points[1][4] == 14 and book.SearchBox.points[1][5] == -22)
assert(book.SearchBox.width == 152 and book.SearchBox.text == "existing query")
assert(book.SearchBox.scripts.OnTextChanged == nativeSearch)
assert(not book.HelpPlateButton:IsShown() and book.HelpPlateButton.mouse == false,
    "spellbook information button must be hidden and unable to intercept mouse input")
book.HelpPlateButton:Show()
book.HelpPlateButton:SetShown(true)
assert(not book.HelpPlateButton:IsShown(), "native refresh restored the overlapping information button")
assert(#rotation.points == 1 and rotation.points[1][1] == "BOTTOMLEFT"
    and rotation.points[1][2] == book and rotation.points[1][3] == "BOTTOMLEFT"
    and rotation.points[1][4] == 14 and rotation.points[1][5] == 10
    and rotation.width == 176 and rotation.height == 40,
    "single-button rotation control must fit near the sidebar bottom edge")
assert(book.PreviousCategoryIcon.points[1][5] == 64,
    "controller prompts must move above the lowered rotation control")
assert(rotation.Icon.scripts.OnClick() == "native click"
    and rotation.Icon.scripts.OnDragStart() == "native rotation drag"
    and rotation.Icon.scripts.OnEnter() == "native rotation tooltip",
    "relocating the rotation control replaced native icon actions or tooltips")
book:ApplyInputModeSizing()
assert(host.width == 1013 and book.width == 1010,
    "native show-time sizing reset the compact sidebar width")
book:UpdateAttic()
assert(rotation.points[1][1] == "BOTTOMLEFT" and rotation.points[1][5] == 10
    and not book.HelpPlateButton:IsShown(), "native attic update restored header overlap")
book.rotationAvailable = false
book:UpdateAttic()
assert(not rotation:IsShown(), "sidebar layout must not force unavailable rotation controls to show")
assert(book.PreviousCategoryIcon.points[1][5] == 16,
    "controller prompts must return to the bottom when the rotation control is unavailable")
book.rotationAvailable = true
book:UpdateAttic()
assert(rotation:IsShown() and rotation.points[1][1] == "BOTTOMLEFT")
assert(not book.SettingsDropdown.FFXIVUIArrowLabel, "settings still uses a letter instead of a menu icon")
local menuLines = 0
for _, region in ipairs(book.SettingsDropdown.regions) do
    if region.texture == "Interface\\Buttons\\WHITE8X8" then
        menuLines = menuLines + 1
        assert(region.width == 12 and region.height == 2)
        assert(region.points[1][5] == 4 - (menuLines - 1) * 4)
    end
end
assert(menuLines == 3, "settings menu icon must contain three lines")
do
    local dropdown = book.SettingsDropdown
    local menu = object("Frame")
    menu.NineSlice = object("Frame", menu)
    local nativeBackground = menu:CreateTexture()
    local popupTextures = {}
    function menu:AttachTexture()
        local texture = self:CreateTexture()
        popupTextures[#popupTextures + 1] = texture
        return texture
    end
    dropdown:OnMenuOpened(menu)
    assert(dropdown.openMenu == menu and #popupTextures == 9 and nativeBackground.alpha == 0
        and menu.NineSlice.alpha == 0
        and popupTextures[1].texture:find("ComboBox-Menu-Dark.tga", 1, true),
        "hamburger popup must use the shared character combo-box background without replacing its native callback")
    dropdown:OnMenuAssigned()
    dropdown:OnMenuAssigned()
    local rows = {}
    local function Refresh(row, choice)
        for _, texture in ipairs(row.selectionTextures) do texture:Hide() end
        row.selectionTextures = {}
        row.leftTexture1:Show()
        row.leftTexture2:Show()
        choice.initializers[1](row, choice)
    end
    for index, choice in ipairs(filterChoices) do
        assert(#choice.initializers == 1, "multi-select refresh duplicated its styling initializer")
        local row = object("Button", menu)
        row.fontString = label(row, index == 1 and "Hide Passives" or "Second filter")
        row.fontString:SetSize(100, 20)
        row.leftTexture1, row.leftTexture2 = row:CreateTexture(), row:CreateTexture()
        row.selectionTextures = {}
        function row:AttachTexture()
            local texture = self:CreateTexture()
            self.selectionTextures[#self.selectionTextures + 1] = texture
            return texture
        end
        row:SetScript("OnClick", function()
            choice.selected = not choice.selected
            Refresh(row, choice)
        end)
        Refresh(row, choice)
        rows[index] = row
        assert(not row.leftTexture1:IsShown() and not row.leftTexture2:IsShown(),
            "multi-select choices must hide the checkbox and checkmark")
    end
    assert(rows[1].FFXIVUICheckArt.texture:find("Unchecked.tga", 1, true)
        and rows[2].FFXIVUICheckArt.texture:find("Checked.tga", 1, true),
        "only enabled filters must show the checked checkbox texture")
    rows[1].scripts.OnClick()
    assert(filterChoices[1].selected and filterChoices[2].selected
        and rows[1].FFXIVUICheckArt.texture:find("Checked.tga", 1, true),
        "enabling one filter must update its checkbox without clearing other selections")
    rows[1].scripts.OnClick()
    assert(not filterChoices[1].selected and filterChoices[2].selected
        and rows[1].FFXIVUICheckArt.texture:find("Unchecked.tga", 1, true),
        "disabling a filter must update its checkbox without changing other selections")

    -- Reopen: the compositor flushes keys written on pooled rows and the pool hands rows back in another order.
    dropdown:OnMenuClosed()
    for _, row in ipairs(rows) do
        for _, child in ipairs(row.children) do
            assert(not child:IsShown(), "closing the menu must hide checkbox art on pooled rows")
        end
        for key in pairs(row) do
            if type(key) == "string" and key:find("^FFXIVUI") then row[key] = nil end
        end
    end
    rows[1], rows[2] = rows[2], rows[1]
    dropdown:OnMenuOpened(menu)
    for index, choice in ipairs(filterChoices) do
        local row = rows[index]
        row:SetScript("OnClick", function()
            choice.selected = not choice.selected
            Refresh(row, choice)
        end)
        Refresh(row, choice)
        assert(#row.children == 1, "reopening the menu stacked a second checkbox over the pooled row")
    end
    assert(rows[1].FFXIVUICheckArt.texture:find("Unchecked.tga", 1, true)
        and rows[2].FFXIVUICheckArt.texture:find("Checked.tga", 1, true),
        "reopened menu must show each filter's own state, not the pooled row's previous state")
    rows[1].scripts.OnClick()
    flush()
    assert(filterChoices[1].selected and rows[1].FFXIVUICheckArt.texture:find("Checked.tga", 1, true)
        and rows[1].children[1]:IsShown(),
        "clicking after reopening must update the visible checkbox")
end
MenuUtil = originalMenuUtil
assert(book.height == 812 and host.height == 850, "spellbook height must match native height")
assert(book.points[1][1] == "TOPLEFT" and book.points[1][2] == host and book.points[1][5] == -34,
    "book frame follows the native top anchor")
assert(paged.cachedTemplateInfos.SPELL.height == 48 and paged.cachedTemplateInfos.HEADER.height == 32)
assert(paged.yPadding == 8 and paged.spacerSize == 16)
assert(paged.frames[2].height == 48 and paged.frames[1].height == 32)
assert(paged.frames[2].Button.points[1][4] == 10)
assert(paged.frames[2].TextContainer.points[1][4] == 60)
assert(paged.frames[1].FFXIVUIHeader.regions[1].gradient[1] == "VERTICAL")
local categoryHeader = paged.frames[1].FFXIVUIHeader
assert(#categoryHeader.regions == 18 and not categoryHeader.backdrop,
    "category header still uses a square backdrop border")
assert(categoryHeader.regions[1].width == 6 and categoryHeader.regions[1].height == 6)
assert(categoryHeader.regions[1].texture:find("surface.tga", 1, true)
    and categoryHeader.regions[10].texture:find("Panel-Border-Dark.tga", 1, true))
for index = 10, 18 do
    local border = categoryHeader.regions[index]
    assert(border.color[1] == 1 and border.color[2] == 1 and border.color[3] == 1 and border.color[4] == 1,
        "Dark category header borders must preserve the extracted artwork without palette tinting")
end
assert(categoryHeader.regions[1].gradient[2][1] < categoryHeader.regions[1].gradient[3][1],
    "category header gradient must be lighter at the top")
for _, view in ipairs(paged.ViewFrames) do
    assert(view.height == 740 and view.width == 774 and view.points[1][5] == -12)
end
assert(paged.layoutUpdates == 1, "initial compaction must recalculate native page distribution")
assert(paged.points[1][5] == -8)
assert(book.FFXIVUIFooterDivider.points[1][5] == 42)
assert(book.FFXIVUIFooterDivider.points[1][4] == 206,
    "footer divider extends into the sidebar")
local pagingPoint = paged.PagingControls.points[1]
local displayMode = book.FFXIVUIDisplayMode
assert(pagingPoint[1] == "LEFT" and pagingPoint[3] == "BOTTOMLEFT" and pagingPoint[4] == 220)
assert(pagingPoint[5] == displayMode.points[1][5] + displayMode.height / 2,
    "paging controls are not centered at the same height as display mode")
assert(previewRow.IconFrame.alpha == 0 and previewRow.scripts.OnClick() == "native click")
local previewLate = button(previewBox)
previewLate.Name = label(previewLate)
previewBox.initialized(previewLate)
assert(previewLate.Name.font[1]:find("AxisRegular"))
assert(paged.points[1][4] == 204 and paged.width == 40, "native page grid replaced")
for index, expectedY in pairs({[1] = 0, [2] = -36, [4] = -72}) do
    local tab = system.tabs[index]
    assert(tab.width == 184 and tab.height == 32 and tab.points[1][5] == expectedY)
    assert(tab.Icon.alpha == 0 and tab.Text.alpha == 0 and tab.Label.alpha == 0
        and tab.LabelContainer.Text.alpha == 0
        and tab:GetFontString().alpha == 0 and not tab:GetFontString():IsShown(),
        "native category labels must remain hidden inside child frames as well as on the tab")
    for _, region in ipairs({tab:GetRegions()}) do
        assert(region ~= tab:GetFontString(), "native font-string fixture must be absent from the region scan")
    end
    assert(tab.FFXIVUICategoryLabel.text == tab.tooltipText)
    assert(tab.FFXIVUICategoryLabel.height == 28 and not tab.FFXIVUIControlArt,
        "category label unbounded or boxed artwork restored")
end
system.tabs[1].Label:SetAlpha(1)
assert(system.tabs[1].Label.alpha == 0, "native category label alpha refresh restored duplicate sidebar text")
do
    local nativeLabel = system.tabs[1]:GetFontString()
    nativeLabel:Show()
    nativeLabel:SetShown(true)
    nativeLabel:SetAlpha(1)
    assert(not nativeLabel:IsShown() and nativeLabel.alpha == 0,
        "native button font strings must stay hidden even when absent from GetRegions and explicitly shown")
    local replacement = object("FontString")
    replacement:SetFont("native", 12, "OUTLINE")
    replacement:SetText("Recreated native category name")
    system.tabs[1].nativeFontString = replacement
    book:UpdateAllSpellData()
    assert(not replacement:IsShown() and replacement.alpha == 0
        and system.tabs[1].FFXIVUICategoryLabel:IsShown(),
        "native font-string replacement must be hidden without suppressing the custom category name")
end
local lateCategoryLabel = label(object("Frame", system.tabs[1].LabelContainer), "Late native category text")
book:UpdateDisplayedSpells()
assert(lateCategoryLabel.alpha == 0 and system.tabs[1].FFXIVUICategoryLabel.alpha == 1,
    "late native category font strings must be hidden without hiding the custom category name")
system.tabs[1].LabelContainer.Text:SetAlpha(1)
assert(system.tabs[1].LabelContainer.Text.alpha == 0,
    "native alpha refresh must not restore nested duplicate category text")
local firstHighlight = system.tabs[1].FFXIVUICategoryHighlight[2]
local secondHighlight = system.tabs[2].FFXIVUICategoryHighlight[2]
assert(firstHighlight:IsShown() and not secondHighlight:IsShown())
assert(firstHighlight.gradient[2][4] == 0.24 and firstHighlight.gradient[3][4] == 0)
system.tabs[2].scripts.OnEnter()
assert(secondHighlight:IsShown() and secondHighlight.gradient[2][4] == 0.6)
system.tabs[2].scripts.OnLeave()
assert(not secondHighlight:IsShown(), "unselected category retains hovered background")
assert(not system.tabs[3]:IsShown(), "unavailable pet tab shown")
assert(system.tabs[2].scripts.OnClick == nativeClick and nativeClick() == "native click")
system.tabs[2]:SetTabSelected(true)
assert(system.tabs[2].Text.alpha == 0, "native selection restored hidden icon-tab label")
flush()
system:Layout()
system:OnCleaned()
assert(#timers == 1, "native layout/cleanup should coalesce their deferred refresh")
flush()
assert(system.tabs[2].points[1][5] == -36 and system.width == 1, "native layout overwrote sidebar")
book:ResizeSearchBox()
book:UpdateAttic()
assert(book.SearchBox.width == 152)
system:SetTabShown(3, true)
assert(system.tabs[4].points[1][5] == -108, "newly available category not inserted")
print("PASS search-first text-only sidebar, localized categories, visibility, native selection and layout refreshes")

-- Simulate native opening work that finishes after the page's OnShow callbacks.
book:Show()
book:ClearAllPoints()
book:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 0, 4)
book.SearchBox:ClearAllPoints()
book.SearchBox:SetPoint("RIGHT", book, "RIGHT", -30, 0)
system.tabs[2]:ClearAllPoints()
system.tabs[2]:SetPoint("LEFT", system, "LEFT", 50, 0)
host.NineSlice:SetAlpha(1)
flush()
assert(book.SearchBox.points[1][1] == "TOPLEFT" and system.tabs[2].points[1][5] == -36,
    "first-show late native anchors were not corrected")
assert(book.points[1][1] == "TOPLEFT" and book.points[1][5] == -34,
    "late native anchoring restored the blank area above content")
assert(host.NineSlice.alpha == 0 and host.FFXIVUISpellbookTitle.font[1]:find("AxisRegular"))
assert(host.NineSlice.TopEdge.alpha == 0 and host.PortraitContainer.portrait.alpha == 0)
assert(host.TitleContainer.TitleText.alpha == 0 and host.FFXIVUISpellbookTitle.justify == "LEFT")
assert(host.FFXIVUISpellbookTitle.text == "Spellbook" and host.MaximizeMinimizeButton.alpha == 0)
assert(book.FFXIVUIDisplayMode, "font initialization interrupted header/display-mode setup")
local header = host.FFXIVUISpellbookTitle.parent
assert(#header.regions == 3, "header has a separate panel fill")
assert(not header.FFXIVUIHeader, "main Spellbook title must retain its divider-only styling")
assert(header.template == "FFXIV_SpellbookHeaderTemplate" and header.height == 30 and header.mouse == false)
assert(header.points[1][1] == "TOPLEFT" and header.points[1][4] == 8 and header.points[1][5] == -4)
assert(header.points[2][1] == "TOPRIGHT" and header.points[2][4] == -8 and header.points[2][5] == -4)
local label = host.FFXIVUISpellbookTitle
assert(label.template == "FFXIV_SpellbookHeaderTitleTemplate" and label.height == 26 and label.justify == "LEFT")
assert(label.points[1][1] == "LEFT" and label.points[1][4] == 12 and label.points[2][4] == -36)
local headerDivider
for _, region in ipairs(header.regions) do
    if region.template == "FFXIV_SpellbookHeaderDividerTemplate" then headerDivider = region end
end
assert(headerDivider and headerDivider.height == 1, "header divider should come from the template")
assert(headerDivider.points[1][1] == "BOTTOMLEFT" and headerDivider.points[1][5] == 0)
assert(headerDivider.points[2][1] == "BOTTOMRIGHT")
assert(book.FFXIVUISidebarDivider.width == 1)
assert(book.FFXIVUISidebarDivider.points[1][2] == header
    and book.FFXIVUISidebarDivider.points[2][4] == 204)
assert(host.CloseButton.width == 24 and host.CloseButton.height == 24)
assert(host.CloseButton.points[1][2] == header and host.CloseButton.points[1][4] == -2,
    "close button not inset inside header")
print("PASS first-show deferred layout and chrome correction without clicking a category")

assert(spell.Button.skin == "Equipment" and spell.Button.Icon.resolver == nil,
    "spellbook ability icon should keep native artwork")
local card = spell.FFXIVUISpellCard
assert(#card.regions == 9 and not card.FFXIVUIControlArt, "spell card still uses pill/button artwork")
assert(card.regions[1].width == 6 and card.regions[1].height == 6,
    "spell card corners stretch with entry dimensions")
assert(card.regions[1].texture:find("surface.tga", 1, true))
spell.Button.scripts.OnEnter()
for _, texture in ipairs(card.regions) do
    for channel = 1, 4 do
        assert(texture.color[channel] == env.Themes.GetPalette().tab[channel],
            "spell hover changed entry background")
    end
end
assert(spell.Button.scripts.OnEnter == nativeTooltip, "card installed an extra hover effect")
if spell.Button.scripts.OnLeave then spell.Button.scripts.OnLeave() end
spell:UpdateVisuals()
assert(spell.Name.alpha == 0.6 and spell.Button.Icon.alpha == 0.6 and spell.Button.Icon.color[1] == 0.5,
    "unlearned spell state lost")
assert(spell.Button.Border.alpha == 0 and spell.Name.color[1] == env.Themes.GetPalette().text[1])
assert(spell.Button.scripts.OnDragStart == nativeDrag and nativeDrag() == "native drag")
assert(nativeTooltip() == "native tooltip")
assert(paged.PagingControls.PageText.text == "Page 1/3")
assert(paged.PagingControls.NextPageButton.scripts.OnClick() == "native click")
local previous = paged.PagingControls.PrevPageButton
assert(previous.width == 22 and previous.height == 22)
previous:SetEnabled(false)
assert(previous.alpha == 1)
assert(previous.FFXIVUIArrowTexture.texture:find("Arrow-Left-Disabled.tga", 1, true))
assert(previous.FFXIVUIArrowTexture.width == 30 and previous.FFXIVUIArrowTexture.height == 30)
previous:SetEnabled(true)
assert(previous.alpha == 1)
assert(previous.FFXIVUIArrowTexture.texture:find("Arrow-Left-Enabled.tga", 1, true))
assert(previous.FFXIVUIArrowTexture.width == 30 and previous.FFXIVUIArrowTexture.height == 30)
paged.frames[#paged.frames + 1] = row()
EventRegistry.callbacks["PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged"]()
assert(paged.frames[3].Button.skin == "Equipment", "new pooled spell not themed")
for _, name in ipairs(env.Themes.GetNames()) do
    env.Themes.Set(name)
    if name == "Dark" then
        assert(categoryHeader.regions[10].texture:find("Panel-Border-Dark.tga", 1, true)
            and categoryHeader.regions[10].color[1] == 1,
            "theme refresh must retain untinted Dark panel-border artwork on category headers")
    end
    assert(spell.Name.color[1] == env.Themes.GetPalette().text[1])
    assert(system.tabs[1].FFXIVUICategoryLabel.color[1] == env.Themes.GetPalette().accent[1])
    assert(firstHighlight.gradient[2][1] == env.Themes.GetPalette().accent[1])
    assert(card.regions[1].color[1] == env.Themes.GetPalette().tab[1])
end
print("PASS themed spell rows, headers and paging; pooled rows, ability icons, semantic states and all themes")

book:SetMinimized(false)
assert(host.width == 1822 and book.width == 1816 and book.viewsPerPage == 2)
assert(host.height == 850 and book.height == 812)
paged.frames[1]:SetWidth(1400)
paged.frames[2]:SetWidth(900)
book:SetMinimized(true)
assert(host.width == 1013 and book.width == 1010 and book.viewsPerPage == 1)
assert(paged.frames[1].width == 774 and paged.frames[2].width == 379,
    "collapsed spellbook must keep full-width headers and half-width spell cards")
do
    local reflowHeader, reflowFirst, reflowSecond = paged.frames[1], paged.frames[2], row()
    paged.frames[#paged.frames + 1] = reflowSecond
    reflowHeader:ClearAllPoints(); reflowHeader:SetPoint("TOPLEFT", paged.ViewFrames[1], "TOPLEFT", 0, 0)
    reflowFirst:ClearAllPoints(); reflowFirst:SetPoint("TOPLEFT", paged.ViewFrames[1], "TOPLEFT", 0, -40)
    reflowSecond:ClearAllPoints(); reflowSecond:SetPoint("TOPLEFT", paged.ViewFrames[2], "TOPLEFT", 400, -40)
    paged:UpdateLayouts()
    assert(reflowSecond.points[1][2] == paged.ViewFrames[2] and reflowSecond.points[1][4] == 400
        and reflowSecond.points[1][5] == -40 and reflowSecond.width == book.FFXIVUIPageWidth / 2 - 8,
        "collapsed spellbook must preserve the native second column and fit its card in-pane")
end
local display = book.FFXIVUIDisplayMode
assert(display.buttons[1].FFXIVUISelected and not display.buttons[2].FFXIVUISelected)
for _ = 1, 3 do
    display.buttons[2].scripts.OnClick()
    flush()
    assert(not display.buttons[1].FFXIVUISelected and display.buttons[2].FFXIVUISelected)
    assert(system:IsShown() and system.tabs[1]:IsShown() and system.tabs[2]:IsShown())
    assert(system.tabs[2].FFXIVUICategoryLabel.text == "Holy localized")
    assert(rotation.points[1][1] == "BOTTOMLEFT" and rotation.points[1][5] == 10
        and not book.HelpPlateButton:IsShown(), "expanded spellbook restored overlapping header controls")
    display.buttons[1].scripts.OnClick()
    flush()
    assert(display.buttons[1].FFXIVUISelected and not display.buttons[2].FFXIVUISelected)
    assert(system:IsShown() and system.tabs[1]:IsShown())
    assert(system.tabs[1].Label.alpha == 0 and rotation.points[1][1] == "BOTTOMLEFT",
        "compact spellbook restored duplicate category names or the rotation header anchor")
end
system:SetTabShown(3, false)
assert(not system.tabs[3]:IsShown(), "sidebar repair restored unavailable pet category")
book:Hide()
host:UpdateSize()
assert(host.width == 1218 and host.nativeBackground.alpha == 0.7 and host.NineSlice.alpha == 1)
assert(host.height == 880, "spellbook height leaked into talent window")
assert(book.height == 812 and book.points[1][1] == "BOTTOMLEFT" and book.points[1][5] == 4,
    "native book geometry was not restored for talents")
assert(host.TitleContainer.TitleText.font[1] == "native-title")
assert(host.NineSlice.TopEdge.alpha == 1 and host.PortraitContainer.portrait.alpha == 1)
assert(host.MaximizeMinimizeButton.alpha == 1 and host.TitleContainer.TitleText.alpha == 1)
assert(not host.CloseButton.FFXIVUICloseIcon:IsShown(), "spellbook close art leaked to talents")
assert(host.CloseButton.width == 32 and host.CloseButton.height == 32)
assert(host.CloseButton.points[1][1] == "TOPRIGHT" and host.CloseButton.points[1][4] == 4
    and host.CloseButton.points[1][5] == 5, "native close geometry not restored for talents")
book:Show()
host:UpdateSize()
assert(host.width == 1013 and host.NineSlice.alpha == 0 and host.CloseButton.FFXIVUICloseIcon:IsShown())
local before = #objects
for _ = 1, 3 do event("ADDON_LOADED"); book:UpdateAllSpellData(); book:CreateCategoryMixins() end
flush()
assert(#objects == before and host.spellBookMinimizedWidth == 1013, "duplicate art or repeated width growth")
assert(paged.cachedTemplateInfos.SPELL.height == 48, "repeated install compounded height reduction")
paged.cachedTemplateInfos.FRESH = {height = 60}
paged:ProcessTemplateInfo(paged.cachedTemplateInfos.FRESH)
assert(paged.cachedTemplateInfos.FRESH.height == 48, "new template cache bypassed compaction")
display.buttons[2].scripts.OnClick()
flush()
assert(not book.isMinimized and spell.width == 379, "expanded spellbook did not prepare its two-column rows")
book:ApplyInputModeSizing()
assert(host.width == 1822 and book.width == 1816,
    "native show-time sizing reset the expanded sidebar width")
spell:ClearAllPoints()
spell:SetPoint("TOPLEFT", paged.ViewFrames[2], "TOPLEFT", 400, -40)
combat = true
event("PLAYER_REGEN_DISABLED")
assert(not display.buttons[1]:IsEnabled() and not display.buttons[2]:IsEnabled())
spell.Button.protected = true
local buttonPoint, buttonRelative, buttonRelativePoint, buttonX, buttonY = spell.Button:GetPoint(1)
host:SetMinimized(true)
book:ApplyInputModeSizing()
paged:UpdateLayouts()
local newButtonPoint, newButtonRelative, newButtonRelativePoint, newButtonX, newButtonY =
    spell.Button:GetPoint(1)
assert(book.isMinimized and host.width == 1013 and book.width == 1010
    and spell.width == book.FFXIVUIPageWidth / 2 - 8
    and spell.points[1][2] == paged.ViewFrames[2] and spell.points[1][4] == 400,
    "combat minimize must preserve the second column within the existing window width")
assert(newButtonPoint == buttonPoint and newButtonRelative == buttonRelative
    and newButtonRelativePoint == buttonRelativePoint and newButtonX == buttonX and newButtonY == buttonY,
    "combat layout changed geometry on an individually protected spell button")
spell.Button.protected = nil
assert(system:IsShown() and system.tabs[1]:IsShown(),
    "combat minimize left the sidebar categories hidden")
local compactPageWidth = book.FFXIVUIPageWidth
paged.ViewFrames[1].protected = true
local protectedViewWidth = paged.ViewFrames[1].width
book:SetMinimized(false)
assert(not book.isMinimized and book.FFXIVUIPageWidth == compactPageWidth
    and paged.ViewFrames[1].width == protectedViewWidth and spell.width == compactPageWidth / 2 - 8,
    "one protected view blocked independent spell-row layout")
paged.ViewFrames[1].protected = nil
local late = row()
paged.frames[#paged.frames + 1] = late
book:UpdateDisplayedSpells()
book:Show()
flush()
assert(not late.Button.skin)
combat = false
event("PLAYER_REGEN_ENABLED")
assert(late.Button.skin == "Equipment" and spell.width == compactPageWidth / 2 - 8,
    "combat-deferred row styling or two-column layout did not resume after combat")
assert(display.buttons[1]:IsEnabled() and display.buttons[2]:IsEnabled())
combat = true
book:Hide()
assert(host.CloseButton.width == 24, "close geometry changed during combat")
combat = false
event("PLAYER_REGEN_ENABLED")
assert(host.CloseButton.width == 32 and host.CloseButton.points[1][5] == 5,
    "deferred native close restoration did not run")
book:Show()
flush()
assert(host.CloseButton.width == 24 and host.CloseButton.points[1][2] == header)
print("PASS divider-only shell, flat fixed-radius cards, close containment and deferred restoration")
print("PASS portrait-free left title, display-mode state and repeated expansion/category availability")
print("PASS native sidebar labels and help button stay hidden; rotation control retains native behavior in the sidebar footer")
print("PASS compact/expanded widths, two-column combat layout, protected-frame deferral, late loading and idempotency")
local talentHeader = object("Frame", host)
env.TalentsUI = {UpdateCloseButton = function(owner)
    assert(owner == host)
    if combat then return true end
    owner.CloseButton.FFXIVUICloseIcon:Show()
    owner.CloseButton:ClearAllPoints()
    owner.CloseButton:SetSize(24, 24)
    owner.CloseButton:SetPoint("RIGHT", talentHeader, "RIGHT", -2, 0)
    return true
end}
book:Hide()
assert(host.CloseButton.FFXIVUICloseIcon:IsShown()
    and host.CloseButton.points[1][2] == talentHeader,
    "Spellbook restored native close geometry over the styled talent header")
book:Show()
flush()
assert(host.CloseButton.points[1][2] == header)
combat = true
book:Hide()
assert(host.CloseButton.points[1][2] == header)
combat = false
event("PLAYER_REGEN_ENABLED")
assert(host.CloseButton.points[1][2] == talentHeader)
print("PASS shared close ownership across spellbook/talent switching and deferred updates")

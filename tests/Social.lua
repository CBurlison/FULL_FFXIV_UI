local addonName, ns = ...
io.stdout:setvbuf("no")
local methods, objects, combat = {}, {}, false
local applyControlTemplate = assert(loadfile("tests\\support\\PanelTemplates.lua"))()
local retail = arg and arg[1] == "retail"
function GetBuildInfo() return "", "", "", retail and 120000 or 16001 end
table.unpack = table.unpack or unpack
unpack = unpack or table.unpack
local function object(kind, parent)
    local value = setmetatable({kind = kind or "Frame", regions = {}, children = {}, scripts = {},
        parent = parent, points = {}, width = 338, height = 424, level = 4, alpha = 1, shown = true,
        enabled = true, fontSize = 12, id = 0}, {__index = methods})
    if parent then
        local list = (kind == "Texture" or kind == "FontString") and parent.regions or parent.children
        list[#list + 1] = value
    end
    objects[#objects + 1] = value
    return value
end
function CreateFrame(kind, _, parent, template)
    local frame = object(kind, parent)
    frame.template = template
    applyControlTemplate(frame, parent, template)
    return frame
end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetChildren() return unpack(self.children) end
function methods:CreateTexture(_, layer, template)
    local texture = object("Texture", self)
    texture.layer, texture.template = layer, template
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
function methods:CreateFontString(_, layer, template)
    local fontString = object("FontString", self)
    fontString.layer, fontString.template = layer, template
    applyControlTemplate(fontString, self, template)
    return fontString
end
function methods:GetFont() return self.font, self.fontSize, "" end
function methods:SetFont(font, size) self.font, self.fontSize = font, size end
function methods:SetShadowColor(...) self.shadow = {...} end
function methods:SetTextColor(...) self.color = {...} end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:GetFontString() return self.Text end
function methods:SetTexture(path) self.texture = path; return true end
function methods:GetTexture() return self.texture end
function methods:SetAtlas(atlas) self.atlas, self.texture = atlas, nil; self:SetTexCoord(0.2, 0.4, 0.6, 0.8) end
function methods:GetAtlas() return self.atlas end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:SetChecked(value) self.checked = value end
function methods:SetColorTexture(...) self.color = {...}; self.colorTexture = {...} end
function methods:SetVertexColor(...) self.color = {...} end
function methods:SetTexCoord(...) self.coords = {...} end
function methods:SetBlendMode(mode) self.blendMode = mode end
function methods:GetTexCoord() return unpack(self.coords or {0, 1, 0, 1}) end
function methods:SetRotation(value) self.rotation = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetAllPoints(owner) self.allPoints = owner end
function methods:ClearAllPoints() self.points = {} end
function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetSize() return self.width, self.height end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetWordWrap(value) self.wordWrap = value end
function methods:SetMaxLines(value) self.maxLines = value end
function methods:SetJustifyH(value) self.justifyH = value end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(level) self.level = level end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetBackdrop(value) self.backdrop = value end
function methods:SetHorizTile() end
function methods:SetVertTile() end
function methods:GetID() return self.id end
function methods:IsEnabled() return self.enabled end
function methods:SetEnabled(enabled)
    self.enabled = enabled
    local callback = self.scripts[enabled and "OnEnable" or "OnDisable"]
    if callback then callback(self) end
end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:SetShown(value) self.shown = value end
function methods:IsShown() return self.shown end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript(name, callback)
    local old = self.scripts[name]
    self.scripts[name] = function(...) if old then old(...) end; callback(...) end
end
function methods:RegisterEvent() end
function InCombatLockdown() return combat end
C_Timer = {After = function(_, callback) callback() end}
local fileIDs = {
    ["interface\\friendsframe\\statusicon-online"] = 1001,
    ["interface\\friendsframe\\statusicon-away"] = 1002,
    ["interface\\friendsframe\\statusicon-dnd"] = 1003,
    ["interface\\friendsframe\\statusicon-offline"] = 1004,
}
function GetFileIDFromPath(path) return fileIDs[path:lower()] end
function hooksecurefunc(owner, name, callback)
    if type(owner) == "string" then owner, name, callback = _G, owner, name end
    local original = assert(owner[name], name)
    owner[name] = function(...) original(...); callback(...) end
end
function methods:ForEachFrame(callback) for _, row in ipairs(self.frames) do callback(row) end end
ScrollUtil = {}
function ScrollUtil.AddInitializedFrameCallback(box, callback, owner)
    assert(not box.callback, "duplicate row callback")
    box.callback = function(row) callback(owner, row) end
end
Menu = {}
function Menu.ModifyMenu(tag, callback)
    Menu.modifiers = Menu.modifiers or {}
    assert(not Menu.modifiers[tag], "duplicate menu modifier")
    Menu.modifiers[tag] = callback
    if tag == "MENU_FRIENDS_STATUS" then Menu.modify = callback end
end
MenuUtil = {}
function MenuUtil.TraverseMenu(root, callback)
    for _, element in ipairs(root) do callback(element) end
end
local env = {}
assert(loadfile("FFXIV_UI\\General\\Themes.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\SkinUtils.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\RoundedPanels.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\WindowControls.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Core.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Items.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Tooltips\\Spells.lua"))("FFXIV_UI", env)
assert(loadfile("FFXIV_UI\\General\\Social.lua"))("FFXIV_UI", env)
local watcher = objects[#objects]
local function event(name) watcher.scripts.OnEvent(watcher, name) end
event("PLAYER_LOGIN")
assert(not Menu.modify, "installed without native Friends UI")

local function text(parent, value)
    local label = parent:CreateFontString()
    label:SetText(value)
    return label
end
local function button(parent)
    local value = object("Button", parent)
    value.Background = value:CreateTexture()
    value.Text = text(value, "Localized native label")
    value.Icon = value:CreateTexture()
    value.scripts.OnClick = function() return "native action" end
    return value
end
local function shell(parent)
    local value = object("Frame", parent)
    value.Background = value:CreateTexture()
    value.NineSlice = object("Frame", value)
    value.Inset = object("Frame", value)
    value.Inset.Background = value.Inset:CreateTexture()
    value.PortraitContainer = object("Frame", value)
    value.TitleContainer = object("Frame", value)
    value.TitleContainer.TitleText = text(value.TitleContainer, "Localized title")
    value.CloseButton = button(value)
    return value
end
local function list(parent)
    local value = object("Frame", parent)
    value.ScrollBox = object("Frame", value)
    value.ScrollBox.frames = {}
    return value
end
local nativeRoot = "Interface\\FriendsFrame\\StatusIcon-"
local function friend(parent, status)
    local row = button(parent)
    row.background, row.highlight = row.Background, row:CreateTexture()
    row.status, row.gameIcon, row.Favorite = row:CreateTexture(), row:CreateTexture(), row:CreateTexture()
    row.name, row.info = text(row, "Native player, Level 60"), text(row, "Native location")
    row.travelPassButton, row.summonButton = button(row), button(row)
    row.status:SetTexture(nativeRoot .. status)
    return row
end
function FriendsFrame_Update() end
function FriendsFrame_UpdateFriendButton(row, status)
    row.status:SetTexture(nativeRoot .. status)
    row.name:SetTextColor(0.51, 0.773, 1)
    row.background:SetAlpha(1)
end
function FriendsFrame_UpdateFriendInviteButton() end
function IgnoreList_InitButton() end
function WhoList_InitButton() end
SocialUIFrame = shell()
SocialUIFrame.width, SocialUIFrame.height = 410, 675
SocialUIFrame.selectedTab = 1
SocialUIFrame.PortraitFrame = object("Frame", SocialUIFrame)
SocialUIFrame.BattleNetBar = object("Frame", SocialUIFrame)
SocialUIFrame.BattleNetBar.Background = SocialUIFrame.BattleNetBar:CreateTexture()
local bar = object("Frame", SocialUIFrame.BattleNetBar)
SocialUIFrame.BattleNetBar.ControlsContainer = bar
bar.OnlineStatusDropdown, bar.BattleNetMenuButton = button(bar), button(bar)
function bar.OnlineStatusDropdown:OnMenuOpened() end
function bar.BattleNetMenuButton:OnMenuOpened() end
bar.OnlineStatusDropdown.Text:SetText("|A:friends-status-online:19:19|a")
bar.PersonalBattleTagDisplay = object("Frame", bar)
bar.PersonalBattleTagDisplay.DisplayText = text(bar.PersonalBattleTagDisplay, "Native#1234")
local modernList = list(SocialUIFrame)
modernList.ScrollBar = object("Frame", modernList)
modernList.ActionButton = button(modernList)
modernList.FilterBar = object("Frame", modernList)
modernList.FilterBar.SearchFilterDropdown = button(modernList.FilterBar)
modernList.FilterBar.SearchBar = object("EditBox", modernList.FilterBar)
modernList.FilterBar.SearchBar:SetText("Native search")
local raidView = object("Frame", SocialUIFrame)
raidView.RaidInfoButton = button(raidView)
raidView.ConvertToRaidButton = button(raidView)
local raidInfoClick = raidView.RaidInfoButton.scripts.OnClick
local convertToRaidClick = raidView.ConvertToRaidButton.scripts.OnClick
SocialUIFrame.tabDefinitions = {friends = {contentFrame = modernList}, raid = {contentFrame = raidView}}
local modernTab = button(SocialUIFrame)
modernTab.tabData = {tabName = "Contacts", tabOrder = 1, tabType = 1}
modernTab.Count = text(modernTab, "3")
modernTab.TabGlow = modernTab:CreateTexture()
local modernTabList = {modernTab}
function SocialUIFrame:EnumerateTabs()
    local index = 0
    return function() index = index + 1; return modernTabList[index] end
end
function SocialUIFrame:RefreshTabs() end
function SocialUIFrame:RefreshContentFrame() end
local card = button(modernList)
card.FriendName, card.Name, card.Level, card.Class, card.Location = text(card, "Native Friend"),
    text(card, "Native Character"), text(card, "60"), text(card, "Mage"), text(card, "Native location")
card.PresenceHolder = object("Frame", card)
card.PresenceHolder.PresenceIcon = card.PresenceHolder:CreateTexture()
card.PresenceHolder.PresenceIcon:SetAtlas("friends-status-offline")
card.PartyButton = button(card)
card.PartyButton.ActionIcon = card.PartyButton:CreateTexture()
function card:InitializeDisplay()
    self.FriendName:SetTextColor(0.5, 0.77, 1)
    self.Background:SetAlpha(1)
end
function card:LayoutScaledContent() end
local function header(parent, title, collapsed)
    local row = object("Button", parent)
    row.NormalTexture, row.HighlightTexture = row:CreateTexture(), row:CreateTexture()
    row.ButtonText = text(row, title)
    row.CollapseButton = object("Button", row)
    row.CollapseButton.Icon = row.CollapseButton:CreateTexture()
    row.CollapseButton.Highlight = row.CollapseButton:CreateTexture()
    function row.CollapseButton:UpdateCollapsedState(value)
        self.collapsed = value
        self.Icon:SetAtlas(value and "common-button-list-plus" or "common-button-list-minus")
        self.Highlight:SetAtlas("native collapse highlight")
    end
    function row:UpdateCollapsedState(value) self.CollapseButton:UpdateCollapsedState(value) end
    function row:CheckHighlightTitle() self.ButtonText:SetTextColor(0.5, 0.5, 0.5) end
    row.scripts.OnClick = function(self)
        self:UpdateCollapsedState(not self.CollapseButton.collapsed)
        self.nativeToggleCount = (self.nativeToggleCount or 0) + 1
    end
    row.scripts.OnEnter = function(self) self:CheckHighlightTitle() end
    row.scripts.OnLeave = row.scripts.OnEnter
    row:UpdateCollapsedState(collapsed)
    return row
end
local friendsHeader = header(modernList, "Friends List 0/1", false)
modernList.ScrollBox.frames = {friendsHeader, card}
local recentList, requestsList = list(SocialUIFrame), list(SocialUIFrame)
recentList.ScrollBar = object("Frame", recentList)
local recentHeader = header(recentList, "Recent Allies", true)
local requestsHeader = header(requestsList, "Friend Requests", false)
recentList.ScrollBox.frames, requestsList.ScrollBox.frames = {recentHeader}, {requestsHeader}
SocialUIFrame.tabDefinitions.recent = {contentFrame = recentList}
SocialUIFrame.tabDefinitions.requests = {contentFrame = requestsList}
combat = true
local modernCount = #objects
event("ADDON_LOADED")
assert(#objects == modernCount and SocialUIFrame.NineSlice.alpha == 1, "modern UI installed in combat")
combat = false
event("PLAYER_REGEN_ENABLED")
local socialRoot = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Social\\"
local panelRoot = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\"
assert(not FriendsFrame, "modern-only test accidentally depends on legacy frame")
assert(SocialUIFrame.NineSlice.alpha == 0 and SocialUIFrame.PortraitFrame.alpha == 0)
assert(SocialUIFrame.CloseButton.FFXIVUICloseIcon and SocialUIFrame.width == 490 and SocialUIFrame.height == 716)
local socialTitle = SocialUIFrame.FFXIVUISocialTitle
assert(socialTitle.text == "Contacts" and socialTitle.justifyH == "LEFT"
    and socialTitle.points[1][1] == "TOPLEFT" and socialTitle.points[1][4] == 20
    and socialTitle.points[2][1] == "TOPRIGHT" and socialTitle.points[2][4] == -38,
    "Retail title does not show the selected tab at the left side of the window")
assert(SocialUIFrame.CloseButton.width == 24 and SocialUIFrame.CloseButton.height == 24)
local closePoint = SocialUIFrame.CloseButton.points[1]
assert(#SocialUIFrame.CloseButton.points == 1 and closePoint[1] == "TOPRIGHT"
    and closePoint[2] == SocialUIFrame and closePoint[4] == -6 and closePoint[5] == -6,
    "close button extends outside the window")
local barPoint = SocialUIFrame.BattleNetBar.points[1]
assert(barPoint[2] == SocialUIFrame and barPoint[1] == "TOP" and barPoint[5] == -34,
    "BattleNetBar is not anchored at the top of the social window")
assert(bar.OnlineStatusDropdown.Text.text == "|T" .. socialRoot .. "Online.tga:19:19|t")
assert(bar.BattleNetMenuButton.Icon.alpha == 0)
assert(modernTab.Icon.alpha == 0)
assert(bar.OnlineStatusDropdown.FFXIVUIComboMenuProbe.texture == panelRoot .. "ComboBox-Menu-Dark.tga")
assert(bar.BattleNetMenuButton.FFXIVUICircularArrow.direction == "down")
assert(bar.BattleNetMenuButton.FFXIVUICircularArrow.base.texture:find("Arrow-Button-Circle.tga", 1, true))
local menuPoint = bar.BattleNetMenuButton.points[1]
assert(bar.BattleNetMenuButton.width == 30 and bar.BattleNetMenuButton.height == 26
    and menuPoint[2] == SocialUIFrame.BattleNetBar and menuPoint[4] == -6 and menuPoint[5] == -2)
assert(-barPoint[5] >= -closePoint[5] + SocialUIFrame.CloseButton.height + 4,
    "Battle.net bar overlaps close button")
local statusPoints = bar.OnlineStatusDropdown.points
assert(bar.OnlineStatusDropdown.width == 90 and bar.OnlineStatusDropdown.height == 24
    and statusPoints[1][2] == SocialUIFrame.BattleNetBar and statusPoints[1][5] == -2
    and statusPoints[2][1] == "LEFT" and statusPoints[2][2] == SocialUIFrame.BattleNetBar and statusPoints[2][4] == 20,
    "presence dropdown does not align with BattleNetBar's left inset")
assert(modernTab.points[1][2] == SocialUIFrame.BattleNetBar and modernTab.points[1][3] == "BOTTOM")
assert(modernTab.points[1][5] == -4 and modernTab.points[2][2] == SocialUIFrame
    and modernTab.points[2][4] == 22 and modernTab.width == 446 and modernTab.height == 30)
assert(modernList.points[1][5] == -36, "content overlaps the internal tab row")
assert(SocialUIFrame.BattleNetBar.width == SocialUIFrame.width - 4,
    "fixed Battle.net bar keeps page content inset inside the wider social window")
assert(modernList.FilterBar.points[1][2] == modernList and modernList.FilterBar.points[1][4] == 20
    and modernList.FilterBar.points[2][2] == modernList and modernList.FilterBar.points[2][4] == -20,
    "filter row does not stretch across the page")
assert(modernList.FilterBar.SearchBar.points[1][2] == modernList.FilterBar
    and modernList.FilterBar.SearchBar.points[2][2] == modernList.FilterBar.SearchFilterDropdown
    and modernList.FilterBar.SearchBar.points[2][4] == -10,
    "search field does not fill the space before the filter dropdown")
assert(modernList.FilterBar.SearchBar.text == "Native search", "resizing reset the active search query")
assert(modernList.ScrollBox.points[1][2] == modernList and modernList.ScrollBox.points[1][5] == -52
    and modernList.ScrollBox.points[2][2] == modernList and modernList.ScrollBox.points[2][4] == -30,
    "friends list retains a fixed native width")
assert(modernList.ScrollBar.points[1][2] == modernList.ScrollBox
    and modernList.ScrollBar.points[2][2] == modernList.ScrollBox and modernList.ScrollBar.width == 12)
assert(modernList.ScrollBar.FFXIVUIScrollBar, "list scroll bar must be styled")
assert(recentList.ScrollBar.FFXIVUIScrollBar, "recent allies scroll bar must use the Menu style")
local menuScroll = object("Frame", modernList)
menuScroll.Track = object("Frame", menuScroll)
menuScroll.Track.Thumb = object("Frame", menuScroll.Track)
local trackArt = object("Texture", menuScroll.Track)
local thumbPieces = {}
for _, slice in ipairs({"Begin", "Middle", "End"}) do
    thumbPieces[slice] = object("Texture", menuScroll.Track.Thumb)
    menuScroll.Track.Thumb[slice] = thumbPieces[slice]
end
menuScroll.Back = object("Frame", menuScroll)
env.StyleScrollBar(menuScroll, "Menu")
local thumb = menuScroll.Track.Thumb
assert(thumbPieces.Begin.alpha == 0 and thumbPieces.Middle.alpha == 0 and thumbPieces.End.alpha == 0,
    "native thumb art must be hidden by alpha")
local overlay = {}
for index = 4, #thumb.regions do overlay[#overlay + 1] = thumb.regions[index] end
assert(#overlay == 3, "menu thumb must draw three addon-owned pill pieces")
local top, bottom, middle = overlay[1], overlay[2], overlay[3]
assert(top.texture:find("Bar%-Pill%.tga$") and bottom.texture:find("Bar%-Pill%.tga$"),
    "menu thumb must use the pill art")
assert(top.coords[1] == 0 and top.coords[3] == 0.25 and middle.coords[1] == 0.25 and bottom.coords[1] == 0.75,
    "pill thumb must be sliced into begin, middle and end")
assert(top.height == 8 and bottom.height == 8, "pill caps must be 8px tall")
assert(math.abs(top.color[1] - 0.337) < 0.001 and top.color[4] == 1,
    "menu thumb must use the grey base tint")
assert(trackArt.shown == false and menuScroll.Back.shown == false, "menu scroll bar must hide track art and arrows")
local chatScroll = object("Frame", modernList)
chatScroll.Track = object("Frame", chatScroll)
chatScroll.Track.Thumb = object("Frame", chatScroll.Track)
env.StyleScrollBar(chatScroll, "Chat")
local chatThumb = chatScroll.Track.Thumb
local chatTrackLine = chatScroll.Track.regions[#chatScroll.Track.regions]
assert(chatTrackLine.width == 1 and math.abs(chatTrackLine.color[1] - 0.784) < 0.001,
    "chat track line must be a 1px grey line")
local chatGold = chatThumb.regions[1]
assert(chatGold.width == 4 and math.abs(chatGold.color[1] - 0.851) < 0.001, "chat thumb must stay a 4px gold bar")
assert(#chatThumb.regions == 1, "chat thumb must not draw an outline")
assert(modernList.ActionButton.points[1][2] == modernList
    and modernList.ActionButton.points[1][1] == "BOTTOM" and modernList.ActionButton.points[1][4] == 0,
    "footer action is not centered on the full-width page")
assert(recentList.ScrollBox.points[2][5] == 12 and requestsList.ScrollBox.points[2][5] == 12,
    "pages without footer actions reserve unnecessary bottom space")
local modernLabel = modernTab.FFXIVUISocialTabLabel
assert(modernLabel.text == "Contacts" and modernLabel.fontSize == 10 and modernLabel.maxLines == 2)
assert(modernLabel.template == "FFXIV_SocialTabLabelTemplate" and modernLabel.height == 28
    and modernLabel.points[1][1] == "LEFT" and modernLabel.points[1][4] == 18
    and modernLabel.points[2][1] == "RIGHT" and modernLabel.points[2][4] == -30,
    "tab label geometry does not come from the XML template")
assert(modernTab.TabGlow.alpha == 1, "native tab notification glow suppressed")
for _, panel in ipairs({modernList.FilterBar.SearchFilterDropdown.children[1]}) do
    local shadow = assert(panel.FFXIVUIControlShadow, "capsule control lacks a drop shadow")
    local source = panel.FFXIVUIControlArt.fill[1]
    local layers = assert(shadow.sources[source])
    assert(shadow.level < panel.level and shadow.mouse == false and #layers == 3)
    assert(layers[1].points[1][2] == source and layers[1].points[1][5] == -2)
    assert(layers[1].color[1] == 0 and layers[1].color[4] == 0.18)
    local originalTexture, originalCoordinates = source.texture, source.coords
    source:SetTexture("shadow synchronization test")
    source:SetTexCoord(0.1, 0.2, 0.3, 0.4)
    assert(layers[1].texture == source.texture and layers[1].coords[1] == 0.1
        and layers[1].coords[4] == 0.4, "drop shadow does not follow its source artwork")
    source:SetTexture(originalTexture)
    source:SetTexCoord(unpack(originalCoordinates))
    local originalLevel, count = panel.level, #objects
    panel:SetFrameLevel(9)
    assert(shadow.level == 8, "drop shadow moved above the control after a frame-level change")
    panel:SetFrameLevel(originalLevel)
    env.AddTextureShadow(panel, source)
    assert(#objects == count, "repeated styling duplicated shadow textures")
end
for _, raidButton in ipairs({raidView.RaidInfoButton, raidView.ConvertToRaidButton}) do
    assert(raidButton.Background.alpha == 0 and raidButton.children[1].FFXIVUIControlArt,
        "raid action retains native rectangular button artwork")
end
assert(raidView.RaidInfoButton.scripts.OnClick == raidInfoClick
    and raidView.ConvertToRaidButton.scripts.OnClick == convertToRaidClick,
    "raid action styling replaced native click handlers")
assert(raidInfoClick() == "native action" and convertToRaidClick() == "native action")
assert(card.PresenceHolder.PresenceIcon.texture == socialRoot .. "Offline.tga")
assert(card.FriendName.color[1] == env.Themes.GetPalette().muted[1])
assert(card.PartyButton.ActionIcon.texture == socialRoot .. "LFG.tga")
assert(card.PartyButton.scripts.OnClick() == "native action")
assert(modernList.ActionButton.scripts.OnClick() == "native action")
assert(modernList.FilterBar.SearchBar.text == "Native search")
local comboRoot = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Panels\\ComboBox-"
local function comboPath(row)
    return comboRoot .. (row.CollapseButton.collapsed and "Closed" or "Open") .. "-Dark.tga"
end
local function assertComboState(row)
    for _, piece in ipairs(row.FFXIVUIHeader.pieces) do
        assert(piece.region.texture == comboPath(row), "header combo art does not match collapse state")
    end
end
for _, row in ipairs({friendsHeader, recentHeader, requestsHeader}) do
    assert(row.FFXIVUIHeader and row.NormalTexture.alpha == 0 and row.HighlightTexture.alpha == 0)
    local bar = row.FFXIVUIHeader.bar
    assert(bar.parent == row and bar.allPoints == row and bar.mouse == false and bar.level == row.level)
    local pieces = row.FFXIVUIHeader.pieces
    assert(#pieces == 3 and pieces[1].region.width == 20 and pieces[3].region.width == 12)
    assert(pieces[1].region.coords[1] == 0 and pieces[2].region.coords[1] == 26 / 512
        and pieces[3].region.coords[2] == 339 / 512)
    assert(row.ButtonText.points[1][1] == "LEFT" and row.ButtonText.points[1][2] == bar
        and row.ButtonText.points[1][4] == 26, "header title not padded past the combo arrow")
    local count, click = #objects, row.scripts.OnClick
    env.StyleComboCollapsibleHeader(row)
    assert(#objects == count and row.scripts.OnClick == click, "header styling replaced native action or duplicated artwork")
    assert(row.CollapseButton.Icon.alpha == 0 and row.CollapseButton.Highlight.alpha == 0)
    assertComboState(row)
    local title, height = row.ButtonText.text, row.height
    row.scripts.OnClick(row)
    assert(row.nativeToggleCount == 1)
    assertComboState(row)
    row.scripts.OnClick(row)
    assert(row.nativeToggleCount == 2)
    assertComboState(row)
    assert(row.ButtonText.text == title and row.height == height, "header label or native extent changed")
end
card.PartyButton.ActionIcon:SetAtlas("friends-icon-friendsInGroup-dis")
assert(card.PartyButton.ActionIcon.texture == socialRoot .. "LFG.tga" and card.PartyButton.ActionIcon.coords[1] == 0)
card.PartyButton:SetEnabled(false)
assert(card.PartyButton.ActionIcon.desaturated and card.PartyButton.ActionIcon.color[1] == 0.45)
card.PartyButton:SetEnabled(true)
assert(not card.PartyButton.ActionIcon.desaturated and card.PartyButton.ActionIcon.color[1] == 1)
for atlas, image in pairs({["friends-status-online"] = "Online", ["friends-status-away"] = "AFK",
    ["friends-status-busy"] = "Busy", ["friends-status-offline"] = "Offline"}) do
    card.PresenceHolder.PresenceIcon:SetAtlas(atlas)
    assert(card.PresenceHolder.PresenceIcon.texture == socialRoot .. image .. ".tga")
    assert(card.PresenceHolder.PresenceIcon.coords[2] == 1, "presence retains atlas sprite coordinates")
end
for _, name in ipairs(env.Themes.GetNames()) do
    env.Themes.Set(name)
    card:InitializeDisplay()
    assert(card.Background.alpha == 0 and card.FriendName.color[1] == env.Themes.GetPalette().muted[1])
    modernTab:SetChecked(true)
    local art = modernTab.children[1].FFXIVUIExtractedTabArt
    local fill = art.fill[1]
    local themeName = name:gsub(" ", "-")
    assert(fill.texture:find("Tab-Selected-" .. themeName .. ".tga", 1, true), "selected tab ignores theme")
    assert(#art.fill == 3 and #art.border == 0 and fill.width == 23 and art.fill[3].width == 17)
    assert(fill.coords[1] == 39 / 512 and fill.coords[3] == 10 / 64 and fill.coords[4] == 53 / 64)
    modernTab:SetChecked(false)
    assert(fill.texture:find("Tab-Inactive-" .. themeName .. ".tga", 1, true), "inactive tab ignores theme")
    modernTab.scripts.OnEnter(modernTab)
    assert(fill.color[1] == 1.12 and fill.texture:find("Tab-Inactive-", 1, true),
        "hover displays a selected indicator on an inactive tab")
    modernTab.scripts.OnLeave(modernTab)
    assert(fill.color[1] == 1)
    for _, raidButton in ipairs({raidView.RaidInfoButton, raidView.ConvertToRaidButton}) do
        local artwork = raidButton.children[1].FFXIVUIControlArt
        assert(artwork.fill[1].color[1] == env.Themes.GetPalette().tab[1])
        raidButton:SetEnabled(false)
        assert(raidButton.Text.color[1] == env.Themes.GetPalette().muted[1])
        raidButton:SetEnabled(true)
        assert(raidButton.Text.color[1] == env.Themes.GetPalette().tabText[1])
    end
    for _, row in ipairs({friendsHeader, recentHeader, requestsHeader}) do
        local palette = env.Themes.GetPalette()
        assertComboState(row)
        assert(row.ButtonText.color[1] == palette.text[1], "header title ignores theme")
        row.scripts.OnEnter(row)
        assert(row.ButtonText.color[1] == palette.text[1], "native hover overwrites header text")
        row.scripts.OnLeave(row)
        assert(row.ButtonText.color[1] == palette.text[1])
    end
end
local modernOption = {data = 4}
function modernOption:AddInitializer(callback) self.initializer = callback end
Menu.modifiers.MENU_SOCIAL_UI_BATTLE_NET_PRESENCE(bar.OnlineStatusDropdown, {modernOption})
local modernOptionButton = button()
modernOptionButton.Text:SetText("|A:friends-status-offline:19:19|a Native Appear Offline")
modernOption.initializer(modernOptionButton)
assert(modernOptionButton.Text.text == "|T" .. socialRoot .. "Offline.tga:19:19|t Native Appear Offline")
assert(modernOption.data == 4, "modern presence enum changed")
modernCount = #objects
SocialUIFrame:RefreshTabs()
SocialUIFrame:RefreshContentFrame()
assert(modernCount == #objects, "modern refresh duplicates artwork")
local recycledHeader = header(requestsList, "New Requests 2/5", true)
requestsList.ScrollBox.frames[#requestsList.ScrollBox.frames + 1] = recycledHeader
combat = true
requestsList.ScrollBox.callback(recycledHeader)
assert(not recycledHeader.FFXIVUIHeader, "new header styled during combat")
combat = false
event("PLAYER_REGEN_ENABLED")
assert(recycledHeader.FFXIVUIHeader and recycledHeader.FFXIVUIHeader.pieces[1].region.texture
    == comboRoot .. "Closed-Dark.tga")
recycledHeader.ButtonText:SetText("Updated Requests 1/5")
modernCount = #objects
requestsList.ScrollBox.callback(recycledHeader)
assert(modernCount == #objects and recycledHeader.ButtonText.text == "Updated Requests 1/5")
print("PASS themed collapsible headers across all three lists, native toggles, hover, all themes and pooled/combat rows")
local lateModernTab = button(SocialUIFrame)
lateModernTab.tabData = {tabName = "Recent Allies", tabOrder = 2, tabType = 2}
lateModernTab.Count = text(lateModernTab, "1")
modernTabList[#modernTabList + 1] = lateModernTab
combat = true
modernCount = #objects
SocialUIFrame:RefreshTabs()
assert(modernCount == #objects and lateModernTab.Background.alpha == 1, "modern dynamic tab styled in combat")
combat = false
event("PLAYER_REGEN_ENABLED")
SocialUIFrame:RefreshTabs()
assert(lateModernTab.Background.alpha == 0 and lateModernTab.Icon.alpha == 0)
assert(lateModernTab.points[2][4] == 243 and lateModernTab.width == 225)
lateModernTab:SetChecked(true)
assert(socialTitle.text == "Recent Allies", "selecting a different Retail tab does not update the window title")
modernTab:SetChecked(false)
assert(socialTitle.text == "Recent Allies", "deselecting the previous tab restores a stale title")
local thirdTab, fourthTab = button(SocialUIFrame), button(SocialUIFrame)
thirdTab.tabData, fourthTab.tabData = {tabName = "Friend Requests", tabOrder = 3}, {tabName = "Raid", tabOrder = 4}
thirdTab.Count, fourthTab.Count = text(thirdTab, "2"), text(fourthTab, "4")
modernTabList = {fourthTab, lateModernTab, thirdTab, modernTab}
SocialUIFrame:RefreshTabs()
assert(SocialUIFrame.height == 716 and modernList.points[1][5] == -36)
assert(modernTab.width == 114.5 and modernTab.points[2][4] == 22)
assert(fourthTab.points[2][4] == 353.5 and fourthTab.points[1][5] == -4, "tabs do not share one top row")
assert(thirdTab.points[2][4] == 243, "pool iteration order changed native tab order")
assert(lateModernTab.points[2][4] == modernTab.points[2][4] + modernTab.width - 4,
    "social tabs do not use character-screen interlocking spacing")
assert(thirdTab.FFXIVUISocialTabLabel.text == "Friend Requests"
    and thirdTab.FFXIVUISocialTabLabel.wordWrap and thirdTab.FFXIVUISocialTabLabel.maxLines == 2
    and thirdTab.width - 48 >= 66,
    "friend requests tab lacks room for its full label and native count")
for _, tab in ipairs(modernTabList) do
    assert(tab.points[2][4] >= 22 and tab.points[2][4] + tab.width <= SocialUIFrame.width - 22,
        "tab extends outside the main window")
end
modernTabList = {lateModernTab, modernTab}
SocialUIFrame:RefreshTabs()
assert(SocialUIFrame.height == 716 and modernList.points[1][5] == -36, "removed tabs leave empty row")
modernTab:SetChecked(true)
assert(modernLabel.text == "Contacts" and modernTab.Count.text == "3"
    and socialTitle.text == "Contacts", "selection loses labels, title or native counters")
print("PASS active SocialUIFrame without legacy FriendsFrame, modern cards/atlases, LFG party actions and dynamic tabs")
print("PASS single-row themed tabs without GetChecked, native ordering, content offsets, inset close and stable height")
SocialUIFrame:SetWidth(600)
SocialUIFrame:RefreshTabs()
assert(SocialUIFrame.width == 600, "minimum width shrinks an already wider social window")
assert(SocialUIFrame.BattleNetBar.width == 596, "content header did not follow the wider window")
SocialUIFrame:SetWidth(410)
SocialUIFrame:RefreshTabs()
SocialUIFrame:RefreshTabs()
assert(SocialUIFrame.width == 490 and SocialUIFrame.height == 716,
    "native refresh lost the minimum width or repeatedly enlarged the social window")
assert(SocialUIFrame.BattleNetBar.width == 486, "content header retained its previous window width")
print("PASS stable wider social window, full friend-request label and themed native raid actions")

FriendsFrame = shell()
FriendsFrame.selectedTab = 1
FriendsFrame:SetPoint("TOPLEFT", "native UI panel anchor", 0, 0)
FriendsFrame.IgnoreListWindow = shell(FriendsFrame)
FriendsFrame.IgnoreListWindow.ScrollBox = list().ScrollBox
FriendsFrame.IgnoreListWindow.UnignorePlayerButton = button(FriendsFrame.IgnoreListWindow)
FriendsListFrame = list(FriendsFrame)
FriendsListFrame.ScrollBox.frames = {friend(FriendsListFrame, "Online"), friend(FriendsListFrame, "Offline")}
FriendsListFrame.ScrollBox.frames[2].status:SetTexture(1004)
FriendsTabHeader = object("Frame", FriendsFrame)
FriendsTabHeader.TabSystem = object("Frame", FriendsTabHeader)
local headerTabs = {}
for index = 1, 3 do
    local tab = button(FriendsTabHeader.TabSystem)
    tab.id = index
    function tab:IsSelected() return self.selected end
    function tab:SetTabSelected(value) self.selected = value end
    tab.selected = index == 1
    headerTabs[index] = tab
end
for index = 1, 4 do
    local tab = button(FriendsFrame)
    tab.id = index
    tab.Text:SetText(({"Contacts", "Who", "Raid", "Quick Join"})[index])
    tab:SetPoint("TOPLEFT", FriendsFrame, "BOTTOMLEFT", 0, -2)
    _G["FriendsFrameTab" .. index] = tab
end
FriendsFrameBattlenetFrame = object("Frame", FriendsTabHeader)
FriendsFrameBattlenetFrame.Background = FriendsFrameBattlenetFrame:CreateTexture()
FriendsFrameBattlenetFrame.Tag = text(FriendsFrameBattlenetFrame, "Native BattleTag")
FriendsFrameBattlenetFrame.ContactsMenuButton = button(FriendsFrameBattlenetFrame)
FriendsFrameBattlenetFrame.BroadcastFrame = shell(FriendsFrameBattlenetFrame)
local broadcast = FriendsFrameBattlenetFrame.BroadcastFrame
broadcast.Border = object("Frame", broadcast)
broadcast.UpdateButton, broadcast.CancelButton = button(broadcast), button(broadcast)
broadcast.EditBox = object("EditBox", broadcast)
broadcast.EditBox.PromptText = text(broadcast.EditBox, "Native prompt")
broadcast.EditBox:SetText("Native broadcast")
FriendsFrameStatusDropdown = button(FriendsTabHeader)
function FriendsFrameStatusDropdown:OnMenuOpened() end
function FriendsFrameBattlenetFrame.ContactsMenuButton:OnMenuOpened() end
FriendsFrameStatusDropdown.Text:SetText("|T" .. nativeRoot .. "Online.tga:16:16:0:0|t")
FriendsFrameAddFriendButton, FriendsFrameSendMessageButton = button(FriendsFrame), button(FriendsFrame)
QuickJoinFrame = list(FriendsFrame)
QuickJoinFrame.JoinQueueButton = button(QuickJoinFrame)
WhoFrame, RecentAlliesFrame = list(FriendsFrame), object("Frame", FriendsFrame)
WhoFrame.WhoButton = button(WhoFrame)
WhoFrame.ScrollBar = object("Frame", WhoFrame)
RecentAlliesFrame.List = list(RecentAlliesFrame)
combat = true
local count = #objects
event("ADDON_LOADED")
assert(count == #objects and not FriendsFrame.FFXIVUIGrain, "installed in combat")
combat = false
event("PLAYER_REGEN_ENABLED")
local root = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Social\\"
local online, offline = unpack(FriendsListFrame.ScrollBox.frames)
assert(online.status.texture == root .. "Online.tga" and offline.status.texture == root .. "Offline.tga")
assert(online.background.alpha == 0 and online.gameIcon.alpha == 1 and online.Favorite.alpha == 1)
assert(online.travelPassButton.Icon.alpha == 1 and online.summonButton.Icon.alpha == 1)
assert(WhoFrame.ScrollBar.FFXIVUIScrollBar, "Who list scroll bar must use the Menu style")
assert(online.scripts.OnClick() == "native action" and FriendsFrameAddFriendButton.scripts.OnClick() == "native action")
assert(FriendsFrame.width == 338 and FriendsFrame.height == (retail and 472 or 424) and #FriendsFrame.points == 1)
assert(FriendsFrame.TitleContainer.TitleText.text == (retail and "Contacts" or "Localized title")
    and online.name.text == "Native player, Level 60")
assert(FriendsFrameStatusDropdown.Text.text == "|T" .. root .. "Online.tga:16:16:0:0|t")
assert(FriendsFrameStatusDropdown.Icon.alpha == (retail and 0 or 1), "unexpected dropdown icon visibility")
if retail then
    local first = FriendsFrameTab1.points[1]
    assert(first[1] == "TOPLEFT" and first[2] == FriendsFrame and first[3] == "TOPLEFT"
        and first[4] == 22 and first[5] == -66, "Retail main tabs remain below the window")
    assert(FriendsListFrame.points[1][5] == -48 and WhoFrame.points[1][5] == -48
        and QuickJoinFrame.points[1][5] == -48, "Retail content overlaps relocated navigation")
    assert(FriendsFrame.Inset.points[1][2] == FriendsFrame and FriendsFrame.Inset.points[1][5] == -132
        and FriendsFrame.Inset.points[2][5] == 28, "Who and other inset-anchored lists overlap Retail tabs")
    assert(FriendsFrame.TitleContainer.TitleText.justifyH == "LEFT")
    assert(FriendsTabHeader.TabSystem.points[1][5] == -100
        and headerTabs[1].width > 90, "Retail sub-tabs are collapsed or overlap the main tabs")
    local status, menu = FriendsFrameStatusDropdown, FriendsFrameBattlenetFrame.ContactsMenuButton
    assert(status.points[1][2] == FriendsFrame and status.points[1][4] == 20
        and status.points[1][5] == -36 and status.width == 90 and status.height == 24)
    assert(menu.points[1][1] == "TOPRIGHT" and menu.points[1][2] == FriendsFrame
        and menu.points[1][4] == -20 and menu.width == 30 and menu.height == 26)
    assert(status.FFXIVUIComboBox and menu.FFXIVUICircularArrow and menu.FFXIVUICircularArrow.direction == "down")
    local height, objectCount = FriendsFrame.height, #objects
    FriendsFrame_Update()
    FriendsFrame:Show()
    assert(FriendsFrame.height == height and #objects == objectCount, "Retail refresh grows or duplicates the UI")
    combat = true
    FriendsFrame_Update()
    assert(FriendsFrame.height == height)
    combat = false
    event("PLAYER_REGEN_ENABLED")
    assert(FriendsFrame.height == height)
    print("PASS Retail FriendsFrame internal navigation, left title, themed aligned menus and stable refresh")
end
assert(FriendsFrame.CloseButton.FFXIVUICloseIcon and FriendsFrame.NineSlice.alpha == 0)
FriendsFrame.NineSlice:SetAlpha(1)
assert(FriendsFrame.NineSlice.alpha == 0, "native border returned")
assert(headerTabs[1].children[1].regions[1].texture:find("Tab-Selected-", 1, true), "selected header has no selected artwork")
headerTabs[1]:SetTabSelected(false)
assert(headerTabs[1].children[1].regions[1].texture:find("Tab-Inactive-", 1, true), "unselected header uses bottom tab ID")
headerTabs[2]:SetTabSelected(true)
FriendsFrame.selectedTab = 3
FriendsFrame_Update()
if retail then assert(FriendsFrame.TitleContainer.TitleText.text == "Raid", "Retail title does not follow native selection") end
assert(FriendsFrameTab3.children[1].regions[1].texture:find("Tab-Selected-", 1, true)
    and FriendsFrameTab1.children[1].regions[1].texture:find("Tab-Inactive-", 1, true))
FriendsFrameTab2 = nil
FriendsFrameTab3.id, FriendsFrameTab4.id = 2, 3
FriendsFrame.selectedTab = 2
FriendsFrame_Update()
assert(FriendsFrameTab3.children[1].regions[1].texture:find("Tab-Selected-", 1, true)
    and FriendsFrameTab4.children[1].regions[1].texture:find("Tab-Inactive-", 1, true),
    "Camelot tabs were selected by global suffix instead of native ID")
assert(FriendsFrameTab3.points[1][2] == FriendsFrameTab1 and FriendsFrameTab3.points[1][4] == -4)
assert(headerTabs[2].points[1][2] == headerTabs[1] and headerTabs[2].points[1][4] == -4)
print("PASS native window/actions, both tab systems, notifications and status artwork")

for native, image in pairs({Online = "Online", Away = "AFK", DnD = "Busy", Offline = "Offline"}) do
    FriendsFrame_UpdateFriendButton(online, native)
    assert(online.status.texture == root .. image .. ".tga", native)
    assert(online.background.alpha == 0)
end
online.status:SetTexture("UnknownNativeStatus")
assert(online.status.texture == "UnknownNativeStatus", "unknown status replaced with invented state")
online.status:SetTexture(12345)
assert(online.status.texture == 12345, "numeric native texture ID not preserved")
online.status:SetTexture(1002)
assert(online.status.texture == root .. "AFK.tga", "known native texture ID not mapped")
local late = friend(FriendsListFrame, "Away")
FriendsListFrame.ScrollBox.frames[#FriendsListFrame.ScrollBox.frames + 1] = late
FriendsListFrame.ScrollBox.callback(late)
assert(late.status.texture == root .. "AFK.tga" and late.name.fontSize == 12)
for _, name in ipairs(env.Themes.GetNames()) do
    env.Themes.Set(name)
    local palette = env.Themes.GetPalette()
    assert(offline.name.color[1] == palette.muted[1] and offline.name.color[2] == palette.muted[2])
    FriendsFrame_UpdateFriendButton(late, "Online")
    assert(late.name.color[1] == palette.text[1] and late.name.color[2] == palette.text[2], name)
end
FriendsFrameSendMessageButton:SetEnabled(false)
assert(FriendsFrameSendMessageButton.Text.color[1] == env.Themes.GetPalette().muted[1])
FriendsFrameSendMessageButton:SetEnabled(true)
assert(FriendsFrameSendMessageButton.Text.color[1] == env.Themes.GetPalette().tabText[1])
local element = {data = nativeRoot .. "Away", responder = function() return "native status action" end}
function element:AddInitializer(callback) self.initializer = callback end
Menu.modify(FriendsFrameStatusDropdown, {element})
local option = button()
option.Text:SetText("|T" .. nativeRoot .. "Away.tga:16:16:0:0|t Native localized Away")
element.initializer(option)
assert(option.Text.text == "|T" .. root .. "AFK.tga:16:16:0:0|t Native localized Away")
assert(element.data == nativeRoot .. "Away" and element.responder() == "native status action")
FriendsFrameStatusDropdown.Text:SetText("|T" .. nativeRoot .. "DnD.tga:16:16:0:0|t")
assert(FriendsFrameStatusDropdown.Text.text == "|T" .. root .. "Busy.tga:16:16:0:0|t")
print("PASS all presence states, recycled rows, all themes and native status-menu data")

count = #objects
event("ADDON_LOADED")
FriendsFrame:Show()
assert(#objects == count, "duplicate artwork")
combat = true
local combatTab = button(FriendsTabHeader.TabSystem)
function combatTab:IsSelected() return false end
function combatTab:SetTabSelected() end
count = #objects
FriendsFrame_Update()
assert(count == #objects, "new tab styled during combat")
local combatRow = friend(FriendsListFrame, "Online")
FriendsListFrame.ScrollBox.frames[#FriendsListFrame.ScrollBox.frames + 1] = combatRow
count = #objects
FriendsListFrame.ScrollBox.callback(combatRow)
assert(#objects == count and not combatRow.status.FFXIVUISocialStatus, "new row styled during combat")
combat = false
event("PLAYER_REGEN_ENABLED")
assert(combatRow.status.texture == root .. "Online.tga", "deferred row was not skinned")
assert(#combatTab.children == 1, "deferred tab was not skinned")
assert(not watcher.scripts.OnUpdate, "permanent update loop")
print("PASS late loading, idempotency and combat-deferred installation/pooled rows")

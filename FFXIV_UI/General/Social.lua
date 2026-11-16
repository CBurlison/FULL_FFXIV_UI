local addonName, ns = ...
local addonEnv = ns
local Skin = addonEnv.Skin
local ROOT = "Interface\\AddOns\\FFXIV_UI\\Media\\Textures\\Social\\"
local Themes = addonEnv.Themes
local TAB_SPACING = -4
local SOCIAL_MIN_WIDTH = 490
local statusImages = {
    ["interface\\friendsframe\\statusicon-online"] = "Online",
    ["interface\\friendsframe\\statusicon-away"] = "AFK",
    ["interface\\friendsframe\\statusicon-dnd"] = "Busy",
    ["interface\\friendsframe\\statusicon-offline"] = "Offline",
}
local presenceImages = {
    ["friends-status-online"] = "Online", ["friends-status-away"] = "AFK",
    ["friends-status-busy"] = "Busy", ["friends-status-offline"] = "Offline",
}
local statusIDs = {}
if GetFileIDFromPath then
    for path, image in pairs(statusImages) do
        local id = GetFileIDFromPath(path)
        if id and id > 0 then statusIDs[id] = image end
    end
end
local shells, tabs, lists, rows = {}, {}, {}, {}
local pending, menuInstalled, rowHooksInstalled = false, false, false
local watcher = CreateFrame("Frame")
local Install
local function RetailFriends()
    return GetBuildInfo and select(4, GetBuildInfo()) >= 100000
end

local function StatusImage(path)
    local image = type(path) == "string" and statusImages[path:lower():gsub("%.tga$", "")] or statusIDs[path]
    return image and ROOT .. image .. ".tga"
end

local function StatusText(text)
    if not text then return end
    text = text:gsub("|A:([^:|]+):([^|]+)|a", function(atlas, dimensions)
        local image = presenceImages[atlas]
        return image and "|T" .. ROOT .. image .. ".tga:" .. dimensions .. "|t"
            or "|A:" .. atlas .. ":" .. dimensions .. "|a"
    end)
    return text:gsub("(|T)([^:|]+)", function(prefix, path)
        return prefix .. (StatusImage(path) or path)
    end)
end

local Color, Text, Hide, HideTextures, Fonts, Panel = Skin.Color, Skin.Text, Skin.Hide, Skin.HideTextures,
    Skin.Fonts, Skin.Panel

local function Shell(frame)
    if not frame or shells[frame] then return end
    shells[frame] = true
    HideTextures(frame)
    Hide(frame.NineSlice)
    Hide(frame.PortraitContainer)
    Hide(frame.PortraitFrame)
    Hide(frame.portrait)
    if frame.Inset then
        HideTextures(frame.Inset)
        Hide(frame.Inset.NineSlice)
    end
    addonEnv.RoundWindow(Panel(frame), true)
    Fonts(frame)
    local title = frame.TitleContainer and frame.TitleContainer.TitleText or frame.TitleText
    Text(title, "text", 18)
    if title then title:SetHeight(22) end
    local close = frame.CloseButton
    if close then
        HideTextures(close)
        close:ClearAllPoints()
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
        close:SetSize(24, 24)
        addonEnv.SkinWindowClose(close)
    end
end

local Control = addonEnv.StyleButton
local SocialComboBox = addonEnv.StyleComboBox
local function Dropdown(button) addonEnv.StyleButton(button, "Dropdown") end
local Input = addonEnv.StyleEditBox

local function UpdateTab(tab)
    local skin = tabs[tab]
    local selected
    if tab.IsSelected then selected = tab:IsSelected()
    else selected = FriendsFrame.selectedTab == tab:GetID() end
    addonEnv.UpdateExtractedTabArtwork(skin.art, selected, skin.hovered, tab.IsEnabled and not tab:IsEnabled())
    local label = tab.Text or tab:GetFontString()
    Text(label, "tabText", 12)
    label:ClearAllPoints()
    label:SetPoint("CENTER", tab, "CENTER", 4, 0)
end

local function Tab(tab)
    if tabs[tab] then UpdateTab(tab); return end
    HideTextures(tab)
    local panel = Panel(tab)
    panel:SetFrameLevel(math.max(0, tab:GetFrameLevel() - 1))
    tabs[tab] = {art = addonEnv.CreateExtractedTabArtwork(panel)}
    if tab.SetTabSelected then hooksecurefunc(tab, "SetTabSelected", UpdateTab) end
    tab:HookScript("OnEnter", function() tabs[tab].hovered = true; UpdateTab(tab) end)
    local function Reset() tabs[tab].hovered = false; UpdateTab(tab) end
    tab:HookScript("OnLeave", Reset)
    tab:HookScript("OnHide", Reset)
    tab:HookScript("OnEnable", Reset)
    tab:HookScript("OnDisable", Reset)
    tab:HookScript("OnShow", function() UpdateTab(tab) end)
    UpdateTab(tab)
end

local function Status(texture)
    if not texture or texture.FFXIVUISocialStatus then return end
    texture.FFXIVUISocialStatus = true
    local function Update(self, path)
        if path ~= self.FFXIVUISocialImage then
            self.FFXIVUISocialImage = StatusImage(path)
            if self.FFXIVUISocialImage then self:SetTexture(self.FFXIVUISocialImage) end
        end
    end
    local path = texture:GetTexture()
    hooksecurefunc(texture, "SetTexture", Update)
    Update(texture, path)
end

local function Presence(texture)
    if not texture or texture.FFXIVUIPresence then return end
    texture.FFXIVUIPresence = true
    local function Update(self, atlas)
        local image = presenceImages[atlas]
        self.FFXIVUISocialImage = image and ROOT .. image .. ".tga"
        if image then
            self:SetTexture(self.FFXIVUISocialImage)
            self:SetTexCoord(0, 1, 0, 1)
        end
    end
    local atlas = texture:GetAtlas()
    hooksecurefunc(texture, "SetAtlas", Update)
    Update(texture, atlas)
end

local function PartyButton(button)
    if not button or button.FFXIVUIPartyIcon then return end
    local icon = button.ActionIcon
    if not icon then return end
    for _, region in ipairs({button:GetRegions()}) do
        if region:GetObjectType() == "Texture" and region ~= icon then Hide(region) end
    end
    addonEnv.StyleWindowControl(Panel(button), button, "Button")
    local function Update()
        icon:SetTexture(ROOT .. "LFG.tga")
        icon:SetTexCoord(0, 1, 0, 1)
        icon:SetSize(28, 28)
        icon:SetDesaturated(not button:IsEnabled())
        local brightness = button:IsEnabled() and 1 or 0.45
        icon:SetVertexColor(brightness, brightness, brightness)
    end
    button.FFXIVUIPartyIcon = icon
    hooksecurefunc(icon, "SetAtlas", Update)
    button:HookScript("OnEnable", Update)
    button:HookScript("OnDisable", Update)
    Update()
end

local function Row(row)
    if InCombatLockdown() then pending = true; return end
    if row.ButtonText and row.CollapseButton and row.UpdateCollapsedState then
        addonEnv.StyleComboCollapsibleHeader(row)
        return
    end
    if not rows[row] then
        rows[row] = true
        Hide(row.background or row.Background)
        local highlight = row.highlight or row.Highlight or row.GetHighlightTexture and row:GetHighlightTexture()
        if highlight then
            highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
            Color(highlight, "SetVertexColor", "accent")
            highlight:SetAlpha(0.18)
        end
        if row.Selected then
            row.Selected:SetTexture("Interface\\Buttons\\WHITE8X8")
            Color(row.Selected, "SetVertexColor", "accent")
            row.Selected:SetAlpha(0.2)
        end
        Status(row.status)
        if row.PresenceHolder then Presence(row.PresenceHolder.PresenceIcon) end
        if row.FriendName then
            for _, method in ipairs({"InitializeDisplay", "LayoutScaledContent"}) do
                if row[method] then hooksecurefunc(row, method, Row) end
            end
        end
    end
    Fonts(row)
    if row.status then
        local offline = row.status.FFXIVUISocialImage == ROOT .. "Offline.tga"
        Text(row.name, offline and "muted" or "text", 12)
        Text(row.info, "muted", 10)
    end
    Text(row.Title, "accent", 12)
    Text(row.ButtonText, "accent", 12)
    if row.FriendName then
        local offline = row.PresenceHolder and row.PresenceHolder.PresenceIcon.FFXIVUISocialImage == ROOT .. "Offline.tga"
        Text(row.FriendName, offline and "muted" or "text", 14)
        for _, key in ipairs({"Name", "Level", "Class", "Location"}) do Text(row[key], "muted", 12) end
    end
    PartyButton(row.PartyButton)
    Control(row.AcceptButton)
    Control(row.DeclineButton)
end

local function List(frame)
    if not frame then return end
    addonEnv.StyleListScrollBar(frame)
    local scrollBox = frame.ScrollBox
    if not scrollBox then return end
    if not lists[scrollBox] then
        lists[scrollBox] = true
        ScrollUtil.AddInitializedFrameCallback(scrollBox, function(_, row) Row(row) end, watcher)
    end
    scrollBox:ForEachFrame(Row)
end

local function RefreshTabs()
    if InCombatLockdown() then pending = true; return end
    local function LayoutRow(ordered, owner)
        if #ordered == 0 then return end
        local width = (owner:GetWidth() - 44 - (#ordered - 1) * TAB_SPACING) / #ordered
        for index, tab in ipairs(ordered) do
            tab:SetSize(width, 30)
            if index > 1 then
                tab:ClearAllPoints()
                tab:SetPoint("LEFT", ordered[index - 1], "RIGHT", TAB_SPACING, 0)
            end
            local label = tab.Text or tab:GetFontString()
            label:SetWidth(math.max(1, width - 30))
            label:SetWordWrap(true)
            label:SetMaxLines(2)
            label:SetHeight(28)
        end
    end
    local bottomTabs = {}
    for index = 1, 4 do
        local tab = _G["FriendsFrameTab" .. index]
        if tab then
            Tab(tab)
            if tab:IsShown() then bottomTabs[#bottomTabs + 1] = tab end
        end
    end
    LayoutRow(bottomTabs, FriendsFrame)
    if RetailFriends() and bottomTabs[1] then
        bottomTabs[1]:ClearAllPoints()
        bottomTabs[1]:SetPoint("TOPLEFT", FriendsFrame, "TOPLEFT", 22, -66)
        local title = FriendsFrame.TitleContainer and FriendsFrame.TitleContainer.TitleText or FriendsFrame.TitleText
        if title then
            title:ClearAllPoints()
            title:SetPoint("TOPLEFT", FriendsFrame, "TOPLEFT", 20, -12)
            title:SetPoint("TOPRIGHT", FriendsFrame, "TOPRIGHT", -38, -12)
            title:SetJustifyH("LEFT")
            for _, tab in ipairs(bottomTabs) do
                if FriendsFrame.selectedTab == tab:GetID() then
                    title:SetText((tab.Text or tab:GetFontString()):GetText())
                end
            end
        end
    end
    local system = FriendsTabHeader and FriendsTabHeader.TabSystem
    if system then
        if RetailFriends() then
            system:ClearAllPoints()
            system:SetPoint("TOPLEFT", FriendsFrame, "TOPLEFT", 22, -100)
            system:SetSize(FriendsFrame:GetWidth(), 30)
        end
        local headerTabs = {}
        for _, tab in ipairs({system:GetChildren()}) do
            if tab.SetTabSelected then
                Tab(tab)
                if tab:IsShown() then headerTabs[#headerTabs + 1] = tab end
            end
        end
        LayoutRow(headerTabs, system)
        if RetailFriends() and headerTabs[1] then
            headerTabs[1]:ClearAllPoints()
            headerTabs[1]:SetPoint("TOPLEFT", system, "TOPLEFT")
        end
    end
end

local function StatusDropdown(dropdown)
    if not dropdown or dropdown.FFXIVUISocialStatus then return end
    dropdown.FFXIVUISocialStatus = true
    -- Keep native status strings as selection data; only replace their visible artwork.
    local function ReplaceText(self, text)
        local mapped = StatusText(text)
        if mapped ~= text then self:SetText(mapped) end
    end
    for _, region in ipairs({dropdown:GetRegions()}) do
        if region:GetObjectType() == "FontString" then
            hooksecurefunc(region, "SetText", ReplaceText)
            ReplaceText(region, region:GetText())
        end
    end
end

local function StatusMenu(_, description)
    MenuUtil.TraverseMenu(description, function(element)
        element:AddInitializer(function(button)
            for _, region in ipairs({button:GetRegions()}) do
                if region:GetObjectType() == "FontString" then region:SetText(StatusText(region:GetText())) end
            end
        end)
    end)
end

local modernTabs = {}
local function LayoutModernTitle(frame)
    local title = frame.FFXIVUISocialTitle
    if not title then
        title = frame.TitleContainer and frame.TitleContainer.TitleText or frame.TitleText
        if not title then return end
        title:ClearAllPoints()
        title:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -12)
        title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -38, -12)
        title:SetHeight(22)
        title:SetJustifyH("LEFT")
        Text(title, "text", 18)
        frame.FFXIVUISocialTitle = title
    end
end

local function ModernTab(tab)
    if modernTabs[tab] then return end
    for _, region in ipairs({tab:GetRegions()}) do
        if region:GetObjectType() == "Texture" and region ~= tab.TabGlow then Hide(region) end
    end
    local panel = Panel(tab)
    local art = addonEnv.CreateExtractedTabArtwork(panel)
    local label = panel:CreateFontString(nil, "OVERLAY", "FFXIV_SocialTabLabelTemplate")
    tab.FFXIVUISocialTabLabel = label
    label:SetWordWrap(true)
    label:SetMaxLines(2)
    tab.Count:ClearAllPoints()
    tab.Count:SetPoint("RIGHT", tab, "RIGHT", -8, 0)
    tab.Count:SetSize(20, 18)
    if tab.TabGlow then
        tab.TabGlow:ClearAllPoints()
        tab.TabGlow:SetAllPoints(tab)
    end
    local checked = tab.tabData and SocialUIFrame.selectedTab == tab.tabData.tabType
    local hovered = false
    local function Update(_, value)
        if value ~= nil then checked = value end
        addonEnv.UpdateExtractedTabArtwork(art, checked, hovered, tab.IsEnabled and not tab:IsEnabled())
        label:SetText(tab.tabData and tab.tabData.tabName)
        Text(label, "tabText", 10)
        Text(tab.Count, "tabText", 12)
        if checked and SocialUIFrame.FFXIVUISocialTitle and tab.tabData then
            SocialUIFrame.FFXIVUISocialTitle:SetText(tab.tabData.tabName)
        end
    end
    modernTabs[tab] = Update
    hooksecurefunc(tab, "SetChecked", Update)
    tab:HookScript("OnEnter", function() hovered = true; Update() end)
    local function Reset() hovered = false; Update() end
    tab:HookScript("OnLeave", Reset)
    tab:HookScript("OnHide", Reset)
    tab:HookScript("OnEnable", Reset)
    tab:HookScript("OnDisable", Reset)
    Update()
end

local function LayoutModernTabs(frame)
    LayoutModernTitle(frame)
    frame:SetWidth(math.max(SOCIAL_MIN_WIDTH, frame:GetWidth()))
    frame.BattleNetBar:SetWidth(frame:GetWidth() - 4)
    local ordered = {}
    for tab in frame:EnumerateTabs() do ordered[#ordered + 1] = tab end
    table.sort(ordered, function(left, right)
        local a, b = left.tabData, right.tabData
        if a.tabOrder ~= b.tabOrder then return a.tabOrder < b.tabOrder end
        return a.tabName < b.tabName
    end)
    local width = frame:GetWidth() - 44
    local columns = #ordered
    local extraHeight = columns > 0 and 41 or 0
    frame.FFXIVUISocialBaseHeight = frame.FFXIVUISocialBaseHeight or frame:GetHeight()
    frame:SetHeight(frame.FFXIVUISocialBaseHeight + extraHeight)
    for index, tab in ipairs(ordered) do
        ModernTab(tab)
        modernTabs[tab]()
        tab:ClearAllPoints()
        tab:SetPoint("TOP", frame.BattleNetBar, "BOTTOM", 0, -4)
        tab:SetPoint("LEFT", frame, "LEFT", 22 + (index - 1) * ((width + TAB_SPACING) / columns), 0)
        tab:SetSize((width - (columns - 1) * TAB_SPACING) / columns, 30)
    end
    for _, tabData in pairs(frame.tabDefinitions) do
        local content = tabData.contentFrame
        if content then
            content:ClearAllPoints()
            content:SetPoint("TOPLEFT", frame.BattleNetBar, "BOTTOMLEFT", 0, 5 - extraHeight)
            content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
        end
    end
end

local function InstallModern()
    local frame = SocialUIFrame
    if not frame then return end
    if InCombatLockdown() then pending = true; return end
    if not shells[frame] then
        Shell(frame)
        frame:HookScript("OnShow", function()
            Install()
            C_Timer.After(0, function()
                if InCombatLockdown() then pending = true; return end
                LayoutModernTabs(frame)
            end)
        end)
        for _, method in ipairs({"RefreshTabs", "RefreshContentFrame", "LayoutTabs", "UpdateTabs"}) do
            if frame[method] then
                hooksecurefunc(frame, method, function()
                    C_Timer.After(0, function()
                        if InCombatLockdown() then pending = true; return end
                        LayoutModernTabs(frame)
                    end)
                end)
            end
        end
    end
    local bar = frame.BattleNetBar
    if bar then
        HideTextures(bar)
        bar:ClearAllPoints()
        bar:SetPoint("TOP", frame, "TOP", 0, -34)
        bar:SetWidth(frame:GetWidth() - 4)
        local container = bar.ControlsContainer
        if container then
            HideTextures(container)
            SocialComboBox(container.OnlineStatusDropdown)
            StatusDropdown(container.OnlineStatusDropdown)
            local status = container.OnlineStatusDropdown
            if status then
                status:ClearAllPoints()
                status:SetPoint("TOP", bar, "TOP", 0, -2)
                status:SetPoint("LEFT", bar, "LEFT", 20, 0)
                status:SetSize(90, 24)
            end
            local menu = container.BattleNetMenuButton
            if menu then
                for _, region in ipairs({menu:GetRegions()}) do
                    if region:GetObjectType() == "Texture" then Hide(region) end
                end
                if menu.NineSlice then Hide(menu.NineSlice) end
                if not menu.OnMenuOpened then menu.OnMenuOpened = function() end end
                addonEnv.StyleCircularArrowButton(menu, "down")
                addonEnv.StyleComboBoxMenu(menu)
            end
            if menu then
                menu:ClearAllPoints()
                menu:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -6, -2)
                menu:SetSize(30, 26)
            end
            if container.PersonalBattleTagDisplay then Fonts(container.PersonalBattleTagDisplay) end
        end
    end
    LayoutModernTabs(frame)
    C_Timer.After(0, function() LayoutModernTabs(frame) end)
    for _, tabData in pairs(frame.tabDefinitions) do
        local content = tabData.contentFrame
        if content then
            Fonts(content)
            Control(content.ActionButton)
            Control(content.RaidInfoButton)
            Control(content.ConvertToRaidButton)
            if content.FilterBar then
                local filter = content.FilterBar
                filter:ClearAllPoints()
                filter:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -8)
                filter:SetPoint("TOPRIGHT", content, "TOPRIGHT", -20, -8)
                filter:SetHeight(30)
                local search, dropdown = filter.SearchBar, filter.SearchFilterDropdown
                Input(search)
                Dropdown(dropdown)
                if dropdown then
                    dropdown:ClearAllPoints()
                    dropdown:SetPoint("RIGHT", filter, "RIGHT")
                    dropdown:SetSize(116, 26)
                end
                if search then
                    search:ClearAllPoints()
                    search:SetPoint("LEFT", filter, "LEFT")
                    search:SetPoint("RIGHT", dropdown or filter, dropdown and "LEFT" or "RIGHT", dropdown and -10 or 0, 0)
                    search:SetHeight(26)
                end
            end
            if content.ScrollBox then
                content.ScrollBox:ClearAllPoints()
                content.ScrollBox:SetPoint("TOPLEFT", content, "TOPLEFT", 20, content.FilterBar and -52 or -10)
                content.ScrollBox:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, content.ActionButton and 48 or 12)
                if content.ScrollBar then
                    content.ScrollBar:ClearAllPoints()
                    content.ScrollBar:SetPoint("TOPLEFT", content.ScrollBox, "TOPRIGHT", 8, 0)
                    content.ScrollBar:SetPoint("BOTTOMLEFT", content.ScrollBox, "BOTTOMRIGHT", 8, 0)
                    content.ScrollBar:SetWidth(12)
                end
            end
            if content.ActionButton then
                content.ActionButton:ClearAllPoints()
                content.ActionButton:SetPoint("BOTTOM", content, "BOTTOM", 0, 10)
            end
            List(content)
        end
    end
    local ignore = frame.IgnoreListFrame
    Shell(ignore)
    if ignore then Control(ignore.BlockButton); Control(ignore.UnblockButton); List(ignore) end
    local broadcast = frame.BattleNetBroadcastFrame
    Shell(broadcast)
    if broadcast then
        Hide(broadcast.Border)
        Control(broadcast.UpdateButton)
        Control(broadcast.CancelButton)
        Input(broadcast.EditBox)
    end
    Shell(frame.BattleNetUnavailableNoticeFrame)
    if frame.BattleNetUnavailableNoticeFrame then Hide(frame.BattleNetUnavailableNoticeFrame.Border) end
end

local presenceMenuInstalled = false
local function LayoutRetailFriends()
    local frame = FriendsFrame
    if not RetailFriends() then return end
    frame.FFXIVUISocialBaseHeight = frame.FFXIVUISocialBaseHeight or frame:GetHeight()
    frame:SetHeight(frame.FFXIVUISocialBaseHeight + 48)
    if frame.Inset then
        frame.Inset:ClearAllPoints()
        frame.Inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -132)
        frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 28)
    end
    for _, content in pairs({FriendsListFrame, WhoFrame, RaidFrame, QuickJoinFrame}) do
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -48)
        content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    end
    local bnet = FriendsFrameBattlenetFrame
    if bnet then
        bnet:ClearAllPoints()
        bnet:SetPoint("TOP", frame, "TOP", 0, -36)
        local menu = bnet.ContactsMenuButton
        if menu then
            for _, region in ipairs({menu:GetRegions()}) do
                if region:GetObjectType() == "Texture" then Hide(region) end
            end
            if menu.NineSlice then Hide(menu.NineSlice) end
            if not menu.OnMenuOpened then menu.OnMenuOpened = function() end end
            addonEnv.StyleCircularArrowButton(menu, "down")
            addonEnv.StyleComboBoxMenu(menu)
        end
        if menu then
            menu:ClearAllPoints()
            menu:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -36)
            menu:SetSize(30, 26)
        end
    end
    local status = FriendsFrameStatusDropdown
    SocialComboBox(status)
    if status then
        status:ClearAllPoints()
        status:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -36)
        status:SetSize(90, 24)
    end
end

Install = function()
    if InCombatLockdown() then pending = true; return end
    pending = false
    InstallModern()
    if not presenceMenuInstalled and SocialUIFrame and Menu and Menu.ModifyMenu then
        presenceMenuInstalled = true
        Menu.ModifyMenu("MENU_SOCIAL_UI_BATTLE_NET_PRESENCE", StatusMenu)
    end
    if not FriendsFrame then return end
    if not shells[FriendsFrame] then
        Shell(FriendsFrame)
        FriendsFrame:HookScript("OnShow", Install)
        hooksecurefunc("FriendsFrame_Update", function()
            if InCombatLockdown() then pending = true; return end
            LayoutRetailFriends()
            RefreshTabs()
        end)
    end
    if not rowHooksInstalled then
        rowHooksInstalled = true
        for _, name in ipairs({"FriendsFrame_UpdateFriendButton", "FriendsFrame_UpdateFriendInviteButton",
            "IgnoreList_InitButton", "WhoList_InitButton"}) do
            if _G[name] then hooksecurefunc(name, Row) end
        end
    end
    Shell(FriendsFrame.IgnoreListWindow)
    if FriendsFrame.IgnoreListWindow then Control(FriendsFrame.IgnoreListWindow.UnignorePlayerButton) end
    local bnet = FriendsFrameBattlenetFrame
    if bnet then
        if not shells[bnet] then
            shells[bnet] = true
            HideTextures(bnet)
            Fonts(bnet)
        end
        local broadcast = bnet.BroadcastFrame
        Shell(broadcast)
        if broadcast then
            Hide(broadcast.Border)
            Control(broadcast.UpdateButton)
            Control(broadcast.CancelButton)
            Input(broadcast.EditBox)
        end
        Shell(bnet.UnavailableInfoFrame)
    end
    StatusDropdown(FriendsFrameStatusDropdown)
    if RetailFriends() then
        LayoutRetailFriends()
    else
        Dropdown(FriendsFrameStatusDropdown)
        if bnet then
            local menu = bnet.ContactsMenuButton
            if menu then
                for _, region in ipairs({menu:GetRegions()}) do
                    if region:GetObjectType() == "Texture" then Hide(region) end
                end
                if menu.NineSlice then Hide(menu.NineSlice) end
                if not menu.OnMenuOpened then menu.OnMenuOpened = function() end end
                addonEnv.StyleCircularArrowButton(menu, "down")
                addonEnv.StyleComboBoxMenu(menu)
            end
        end
    end
    if not menuInstalled and Menu and Menu.ModifyMenu then
        menuInstalled = true
        Menu.ModifyMenu("MENU_FRIENDS_STATUS", StatusMenu)
    end
    Control(FriendsFrameAddFriendButton)
    Control(FriendsFrameSendMessageButton)
    if QuickJoinFrame then Control(QuickJoinFrame.JoinQueueButton); List(QuickJoinFrame) end
    if WhoFrame then
        Fonts(WhoFrame)
        Control(WhoFrame.WhoButton)
        Input(WhoFrameEditBox)
        List(WhoFrame)
    end
    List(FriendsListFrame)
    List(FriendsFrame.IgnoreListWindow)
    if RecentAlliesFrame then List(RecentAlliesFrame.List) end
    RefreshTabs()
end

Themes.Register(function()
    for tab in pairs(tabs) do UpdateTab(tab) end
    for _, update in pairs(modernTabs) do update() end
end)
local handlers = {
    ADDON_LOADED = Install,
    PLAYER_LOGIN = Install,
    PLAYER_REGEN_ENABLED = function() if pending then Install() end end,
}
for event in pairs(handlers) do watcher:RegisterEvent(event) end
watcher:SetScript("OnEvent", function(_, event)
    local handler = handlers[event]
    if handler then handler() end
end)
Install()
